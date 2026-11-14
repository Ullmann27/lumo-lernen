package dev.ullmann.lumo

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import org.json.JSONObject

/** Private transport only. Rules, saved rounds and rewards remain in Dart. */
object TableGamesBridge {
    private const val LIMIT = 32768
    private val tokens = Regex("[a-f0-9]{32}")
    private val owners = Regex("[a-f0-9]{64}")
    private val live = mutableMapOf<String, String>()
    private var attached = false

    @Synchronized fun hasAuthority(token: String, game: String): Boolean =
        attached && game in setOf("memory", "quiz") && live[token] == game

    @Synchronized fun detach() { attached = false; live.clear() }

    private inline fun <T> locked(root: File, action: () -> T): T = synchronized(this) {
        val base = File(root, "lumo_table_games_session_v1")
        check(base.isDirectory || base.mkdirs())
        RandomAccessFile(File(base, "bridge.lock"), "rw").use { file ->
            file.channel.lock().use { action() }
        }
    }

    private fun directory(root: File, token: String): File {
        require(tokens.matches(token))
        return File(File(root, "lumo_table_games_session_v1"), token)
    }

    private fun read(file: File): JSONObject? {
        if (!file.isFile) return null
        require(file.length() in 1..LIMIT.toLong())
        return JSONObject(file.readText(Charsets.UTF_8))
    }

    private fun write(file: File, value: JSONObject, durable: Boolean = true) {
        val bytes = value.toString().toByteArray(Charsets.UTF_8)
        require(bytes.size in 1..LIMIT)
        check(file.parentFile?.isDirectory == true || file.parentFile?.mkdirs() == true)
        val temporary = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(temporary).use { it.write(bytes); if (durable) it.fd.sync() }
        check(temporary.renameTo(file))
    }

    private fun integer(value: JSONObject, key: String): Long {
        val raw = value.opt(key)
        require(raw is Int || raw is Long)
        return (raw as Number).toLong()
    }

    private fun checkedState(payload: String, token: String): JSONObject {
        require(payload.toByteArray(Charsets.UTF_8).size in 1..LIMIT)
        val state = JSONObject(payload)
        require(integer(state, "schema") == 1L && state.optString("game") in setOf("memory", "quiz"))
        require(state.optString("token") == token && tokens.matches(state.optString("roundId")))
        require(owners.matches(state.optString("owner")))
        require(integer(state, "revision") in 1..1000000000L)
        require(integer(state, "ack") in 0..1000000000L)
        require(integer(state, "rejected") in 0..1000000000L)
        return state
    }

    @Synchronized fun attach(messenger: BinaryMessenger, root: File) {
        live.clear(); attached = true
        MethodChannel(messenger, "lumo_lernen/table_games").setMethodCallHandler { call, result ->
            try {
                val token = call.argument<String>("token") ?: ""
                locked(root) {
                    val dir = directory(root, token)
                    when (call.method) {
                        "open" -> {
                            check(attached && live.isEmpty() && !dir.exists())
                            val state = checkedState(call.argument<String>("state") ?: "{}", token)
                            write(File(dir, "state.json"), state)
                            live[token] = state.getString("game")
                            result.success(true)
                        }
                        "publish" -> {
                            val previous = read(File(dir, "state.json"))
                                ?: throw IllegalStateException("Missing table session")
                            val next = checkedState(call.argument<String>("state") ?: "{}", token)
                            check(hasAuthority(token, previous.getString("game")))
                            require(next.getString("game") == previous.getString("game"))
                            require(next.getString("owner") == previous.getString("owner"))
                            require(integer(next, "revision") > integer(previous, "revision"))
                            require(integer(next, "ack") >= integer(previous, "ack"))
                            require(integer(next, "rejected") >= integer(previous, "rejected"))
                            write(File(dir, "state.json"), next)
                            result.success(true)
                        }
                        "poll" -> {
                            check(attached && live.containsKey(token) && File(dir, "state.json").isFile)
                            result.success(JSONObject().put("request", read(File(dir, "request.json")))
                                .put("lifecycle", read(File(dir, "lifecycle.json"))).toString())
                        }
                        "close" -> {
                            live.remove(token)
                            for (name in listOf("state.json", "request.json", "lifecycle.json")) {
                                for (suffix in listOf("", ".tmp")) {
                                    val file = File(dir, name + suffix)
                                    check(!file.exists() || file.delete())
                                }
                            }
                            check(!dir.exists() || dir.delete())
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                }
            } catch (_: Exception) {
                result.error("table_game_storage", "Deine Spielrunde konnte noch nicht bestätigt werden.", null)
            }
        }
    }

    fun state(root: File, token: String, game: String): String = try {
        locked(root) {
            val value = read(File(directory(root, token), "state.json"))
            if (value?.optString("game") == game) value.toString() else "{}"
        }
    } catch (_: Exception) { "{}" }

    fun submit(root: File, token: String, game: String, payload: String): Boolean = try {
        locked(root) {
            require(payload.toByteArray(Charsets.UTF_8).size in 1..2048)
            val dir = directory(root, token)
            val state = read(File(dir, "state.json"))
            if (state == null || state.optString("game") != game) false else {
                val request = JSONObject(payload)
                val fields = request.keys().asSequence().associateWith { request.get(it) }
                require(TableGameIntent.valid(game, fields))
                require(request.getString("token") == token && request.getString("roundId") == state.getString("roundId"))
                require(integer(request, "revision") == integer(state, "revision"))
                val consumed = maxOf(integer(state, "ack"), integer(state, "rejected"))
                require(integer(request, "sequence") > consumed)
                val previous = read(File(dir, "request.json"))
                if (previous != null && integer(previous, "sequence") > consumed) {
                    previous.toString() == request.toString()
                } else { write(File(dir, "request.json"), request); true }
            }
        }
    } catch (_: Exception) { false }

    fun pulse(root: File, token: String, game: String, active: Boolean): Boolean = try {
        locked(root) {
            val dir = directory(root, token)
            val state = read(File(dir, "state.json"))
            if (state == null || state.optString("game") != game) false else {
                val previous = read(File(dir, "lifecycle.json"))
                val epoch = ((previous?.optLong("pauseEpoch", 0) ?: 0) +
                    if (!active && previous?.optBoolean("active") == true) 1 else 0).coerceAtMost(1000000000L)
                write(File(dir, "lifecycle.json"), JSONObject().put("active", active)
                    .put("pauseEpoch", epoch).put("stamp", System.currentTimeMillis()), false)
                true
            }
        }
    } catch (_: Exception) { false }
}
