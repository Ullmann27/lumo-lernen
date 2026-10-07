package dev.ullmann.lumo

import android.content.Context
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.RandomAccessFile

/** Durable events shared by Flutter and the isolated engine process. No child identity. */
object GameEventStore {
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
        require(result.optString("game") in setOf("kart", "jump", "puzzle", "build", "rhythm", "treasure"))
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

    fun recordReturn(context: Context, destination: String) = locked(context) { file ->
        val state = read(file)
        state.put("destination", if (destination == "learn") "learn" else "games")
        write(file, state)
    }

    fun pending(context: Context): String = locked(context) { file -> read(file).toString() }

    fun clear(context: Context) = locked(context) { file ->
        write(file, JSONObject().put("results", JSONArray()))
    }

    fun acknowledge(context: Context, ids: List<String>, destination: String?) = locked(context) { file ->
        val state = read(file)
        val results = state.optJSONArray("results") ?: JSONArray()
        val retained = JSONArray()
        for (index in 0 until results.length()) {
            val result = results.getJSONObject(index)
            if (result.optString("resultId") !in ids) retained.put(result)
        }
        state.put("results", retained)
        if (destination != null && state.optString("destination") == destination) state.remove("destination")
        write(file, state)
    }
}
