package dev.ullmann.lumo

import android.content.Context
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.RandomAccessFile

/** Durable events shared by Flutter and the isolated engine process. No child identity. */
object GameEventStore {
    const val CALLER_RETURN_SESSION = "callerReturnSession"

    fun validCallerSession(value: String): Boolean =
        value.matches(Regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"))

    private fun <T> locked(context: Context, block: (AtomicFile) -> T): T = synchronized(this) {
        val directory = context.filesDir
        RandomAccessFile(File(directory, "lumo_game_events.lock"), "rw").use { lockFile ->
            lockFile.channel.lock().use {
                block(AtomicFile(File(directory, "lumo_game_events.json")))
            }
        }
    }

    private fun read(file: AtomicFile): JSONObject {
        if (!file.baseFile.exists() && !File(file.baseFile.path + ".bak").exists()) {
            return JSONObject().put("results", JSONArray())
        }
        return JSONObject(file.openRead().use { it.readBytes().toString(Charsets.UTF_8) })
    }

    private fun write(file: AtomicFile, value: JSONObject) {
        val stream = file.startWrite()
        try {
            stream.write(value.toString().toByteArray(Charsets.UTF_8))
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    fun recordReward(context: Context, payload: String): Boolean = locked(context) { file ->
        val result = JSONObject(payload)
        val id = result.optString("resultId")
        require(id.length in 1..160 && result.optString("status") == "completed")
        // "cards" = Kartentisch (Sternenstich, Sternenleiter, Lumo-Quartett), "run" = Lumo Lauf.
        require(result.optString("game") in setOf("kart", "jump", "run", "skypost", "cards", "puzzle", "build", "rhythm", "treasure", "chess"))
        require(result.optInt("stars", -1) in 0..100)
        if (result.has("xp")) require(result.optInt("xp", -1) in 0..1000)
        val state = read(file)
        val results = state.optJSONArray("results") ?: JSONArray()
        if ((0 until results.length()).none { results.getJSONObject(it).optString("resultId") == id }) {
            results.put(result)
            state.put("results", results)
            write(file, state)
        }
        true
    }

    fun recordReturn(context: Context, destination: String, callerSession: String? = null) = locked(context) { file ->
        require(callerSession == null || validCallerSession(callerSession))
        val state = read(file)
        state.put("destination", if (destination == "learn") "learn" else "games")
        if (callerSession == null) state.remove(CALLER_RETURN_SESSION)
        else state.put(CALLER_RETURN_SESSION, callerSession)
        write(file, state)
    }

    /** A new explicit caller launch supersedes old navigation, never earned rewards. */
    fun beginCallerReturn(context: Context) = locked(context) { file ->
        val state = read(file)
        if (state.has("destination") || state.has(CALLER_RETURN_SESSION)) {
            state.remove("destination")
            state.remove(CALLER_RETURN_SESSION)
            write(file, state)
        }
    }

    /** Hide only this live caller's navigation. The on-disk cold-host fallback remains. */
    fun pending(context: Context, liveCallerSession: String? = null): String = locked(context) { file ->
        val state = read(file)
        if (liveCallerSession != null && validCallerSession(liveCallerSession) &&
            state.optString(CALLER_RETURN_SESSION) == liveCallerSession) {
            state.remove("destination")
            state.remove(CALLER_RETURN_SESSION)
        }
        state.toString()
    }

    /** Commit before resolving launch3D; a newer/different return must survive. */
    fun completeCallerReturn(context: Context, destination: String, session: String): Boolean = locked(context) { file ->
        if (!validCallerSession(session)) return@locked false
        val state = read(file)
        if (state.optString("destination") != destination || state.optString(CALLER_RETURN_SESSION) != session) {
            false
        } else {
            state.remove("destination")
            state.remove(CALLER_RETURN_SESSION)
            write(file, state)
            true
        }
    }

    /**
     * Runs [block] while no process writes events (same cross-process file lock
     * as every write). Returns null when the lock stays busy beyond [timeoutMs],
     * so a leftover engine is never killed in the middle of a reward write.
     */
    fun <T> whileNoWriter(context: Context, timeoutMs: Long, block: () -> T): T? = synchronized(this) {
        RandomAccessFile(File(context.filesDir, "lumo_game_events.lock"), "rw").use { lockFile ->
            val deadline = System.nanoTime() + timeoutMs * 1_000_000
            var lock = lockFile.channel.tryLock()
            while (lock == null && System.nanoTime() < deadline) {
                Thread.sleep(25)
                lock = lockFile.channel.tryLock()
            }
            lock?.use { block() }
        }
    }

    fun clear(context: Context) = locked(context) { file ->
        write(file, JSONObject().put("results", JSONArray()))
    }

    fun acknowledge(context: Context, ids: List<String>, destination: String?,
                    liveCallerSession: String? = null) = locked(context) { file ->
        val state = read(file)
        val results = state.optJSONArray("results") ?: JSONArray()
        val retained = JSONArray()
        for (index in 0 until results.length()) {
            val result = results.getJSONObject(index)
            if (result.optString("resultId") !in ids) retained.put(result)
        }
        state.put("results", retained)
        // An older Flutter read may acknowledge the same destination after a new
        // caller return was written. Only its ActivityResult can consume that
        // live-owned return; a recreated host without an owner uses normal ACK.
        if (destination != null && state.optString("destination") == destination &&
            !(liveCallerSession != null && state.has(CALLER_RETURN_SESSION))) {
            state.remove("destination")
            state.remove(CALLER_RETURN_SESSION)
        }
        write(file, state)
    }
}

/**
 * Die letzten Spielstarts für das Spiel-Startprotokoll im Elternbereich.
 * Nur lokal im App-Speicher, nie gesendet. Schreibt ausschließlich der
 * Flutter-Prozess; ein kaputtes Protokoll wird verworfen, nie ein Spielstand.
 */
object GameStartJournal {
    const val LIMIT = 20
    private const val FILE = "lumo_game_starts.json"
    private val routerLoaded = Regex("""\[Router\] loaded:([A-Za-z0-9_]+)""")
    private val epochLine = Regex("""^\s*(\d{9,11})\.(\d{3})\s""")
    private val dateLine = Regex("""^\s*(?:(\d{4})-)?(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s""")

    private fun file(context: Context) = AtomicFile(File(context.filesDir, FILE))

    private fun read(file: AtomicFile): JSONArray = try {
        if (!file.baseFile.exists() && !File(file.baseFile.path + ".bak").exists()) JSONArray()
        else JSONArray(file.openRead().use { it.readBytes().toString(Charsets.UTF_8) })
    } catch (_: Exception) { JSONArray() }

    private fun write(file: AtomicFile, entries: JSONArray) {
        val stream = file.startWrite()
        try {
            stream.write(entries.toString().toByteArray(Charsets.UTF_8))
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    private fun <T> edit(context: Context, block: (JSONArray) -> T): T = synchronized(this) {
        val target = file(context)
        val entries = read(target)
        val value = block(entries)
        val kept = JSONArray()
        for (index in maxOf(0, entries.length() - LIMIT) until entries.length()) kept.put(entries.get(index))
        write(target, kept)
        value
    }

    private fun find(entries: JSONArray, id: String): JSONObject? =
        (0 until entries.length()).map { entries.getJSONObject(it) }.lastOrNull { it.optString("id") == id }

    /** Neuer Start; Ergebnis bleibt „running“, bis die Rückkehr eintrifft. */
    fun begin(context: Context, scene: String, startedAt: Long, note: String? = null): String = edit(context) { entries ->
        // Ein noch offener älterer Start hat nie eine Rückkehr erreicht (Host neu aufgebaut).
        for (index in 0 until entries.length()) {
            val older = entries.getJSONObject(index)
            if (older.optString("outcome") == "running") older.put("outcome", "host_closed")
        }
        val id = "start-$startedAt-${entries.length()}"
        entries.put(JSONObject().put("id", id).put("scene", scene).put("startedAt", startedAt)
            .put("outcome", "running").apply { if (note != null) put("note", note) })
        id
    }

    /** Abgelehnter oder gescheiterter Start, der nie ein Spiel geöffnet hat. */
    fun refused(context: Context, scene: String, at: Long, outcome: String, detail: String? = null) = edit(context) { entries ->
        entries.put(JSONObject().put("id", "start-$at-${entries.length()}").put("scene", scene)
            .put("startedAt", at).put("endedAt", at).put("outcome", outcome)
            .apply { if (detail != null) put("detail", detail.take(200)) })
    }

    fun finish(context: Context, id: String, endedAt: Long, outcome: String, detail: String? = null) = edit(context) { entries ->
        find(entries, id)?.apply {
            if (optString("outcome") == "running") {
                put("endedAt", endedAt).put("outcome", outcome)
                if (detail != null) put("detail", detail.take(200))
            }
        }
    }

    /** Trägt „geladen nach x s“ aus dem logcat-Text nach (Godot meldet das nur als Logzeile). */
    fun applyLoadTimes(context: Context, log: String, now: Long, year: Int) = edit(context) { entries ->
        for (index in 0 until entries.length()) {
            val entry = entries.getJSONObject(index)
            if (entry.has("loadedAfterMs") || entry.optString("outcome") in setOf("game_running", "exception", "refused")) continue
            val started = entry.optLong("startedAt")
            val ended = if (entry.has("endedAt")) entry.optLong("endedAt") else now
            loadedAfterMs(log, entry.optString("scene"), started, ended, year)?.let {
                entry.put("loadedAfterMs", it.first).put("loadedScene", it.second)
            }
        }
    }

    fun entries(context: Context): String = synchronized(this) { read(file(context)).toString() }

    /** Zeitpunkt einer logcat-Zeile (-v epoch oder -v threadtime [year]); null wenn unbekannt. */
    fun lineTime(line: String, year: Int, zone: java.util.TimeZone = java.util.TimeZone.getDefault()): Long? {
        epochLine.find(line)?.let { return it.groupValues[1].toLong() * 1000 + it.groupValues[2].toLong() }
        val match = dateLine.find(line) ?: return null
        val values = match.groupValues
        val calendar = java.util.Calendar.getInstance(zone)
        calendar.clear()
        calendar.set(values[1].ifEmpty { year.toString() }.toInt(), values[2].toInt() - 1, values[3].toInt(),
            values[4].toInt(), values[5].toInt(), values[6].toInt())
        calendar.set(java.util.Calendar.MILLISECOND, values[7].toInt())
        return calendar.timeInMillis
    }

    /** Erste `[Router] loaded:`-Zeile im Startfenster; bevorzugt die gestartete Szene. */
    fun loadedAfterMs(log: String, scene: String, startedAt: Long, endedAt: Long, year: Int,
                      zone: java.util.TimeZone = java.util.TimeZone.getDefault()): Pair<Long, String>? {
        var fallback: Pair<Long, String>? = null
        for (line in log.lineSequence()) {
            val loaded = routerLoaded.find(line)?.groupValues?.get(1) ?: continue
            val time = lineTime(line, year, zone) ?: continue
            if (time < startedAt - 1000 || time > endedAt + 1000) continue
            val value = Pair(maxOf(0L, time - startedAt), loaded)
            if (loaded == scene) return value
            if (fallback == null) fallback = value
        }
        return fallback
    }
}
