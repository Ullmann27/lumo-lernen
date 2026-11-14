package dev.ullmann.lumo

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import org.json.JSONObject

/** Separate, bounded C4 transport. The existing Cards channel is untouched. */
object ConnectFourBridge {
    private const val LIMIT = 32768
    private val tokens = Regex("[a-f0-9]{32}")
    private val owners = Regex("[a-f0-9]{64}")
    private val live = mutableSetOf<String>()
    private var attached = false
    @Synchronized fun hasAuthority(token: String): Boolean = attached && live.contains(token)
    @Synchronized fun detach() { attached = false; live.clear() }

    private inline fun <T> locked(root: File, action: () -> T): T = synchronized(this) {
        val base = File(root, "lumo_connect_four_session_v1")
        check(base.isDirectory || base.mkdirs())
        RandomAccessFile(File(base, "bridge.lock"), "rw").use { file ->
            file.channel.lock().use { action() }
        }
    }
    private fun directory(root: File, token: String): File {
        require(tokens.matches(token))
        return File(File(root, "lumo_connect_four_session_v1"), token)
    }
    private fun read(file: File): JSONObject? {
        if (!file.isFile) return null
        require(file.length() in 1..LIMIT.toLong())
        return JSONObject(file.readText(Charsets.UTF_8))
    }
    private fun write(file: File, value: JSONObject, durable: Boolean = true) {
        val data = value.toString().toByteArray(Charsets.UTF_8)
        require(data.size in 1..LIMIT)
        check(file.parentFile?.isDirectory == true || file.parentFile?.mkdirs() == true)
        val tmp = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(tmp).use { it.write(data); if (durable) it.fd.sync() }
        check(tmp.renameTo(file))
    }
    private fun integer(obj: JSONObject, name: String): Long {
        val raw = obj.opt(name)
        require(raw is Int || raw is Long)
        return (raw as Number).toLong()
    }
    private fun checkedState(payload: String, token: String): JSONObject {
        require(payload.toByteArray(Charsets.UTF_8).size <= LIMIT)
        val state = JSONObject(payload)
        require(integer(state, "schema") == 1L && state.optString("game") == "connect_four")
        require(state.optString("token") == token && tokens.matches(state.optString("roundId")))
        require(owners.matches(state.optString("owner")))
        require(integer(state, "revision") in 1..1000000000L)
        require(integer(state, "ack") in 0..1000000000L)
        require(integer(state, "rejected") in 0..1000000000L)
        return state
    }
    @Synchronized fun attach(messenger: BinaryMessenger, root: File) {
        live.clear(); attached = true
        MethodChannel(messenger, "lumo_lernen/connect_four").setMethodCallHandler { call, result ->
            try {
                val token = call.argument<String>("token") ?: ""
                locked(root) {
                    val dir = directory(root, token)
                    when (call.method) {
                        "open" -> {
                            check(attached && live.isEmpty() && !dir.exists())
                            val state = checkedState(call.argument<String>("state") ?: "{}", token)
                            write(File(dir, "state.json"), state)
                            live.add(token); result.success(true)
                        }
                        "publish" -> {
                            check(hasAuthority(token) && File(dir, "state.json").isFile)
                            write(File(dir, "state.json"), checkedState(call.argument<String>("state") ?: "{}", token))
                            result.success(true)
                        }
                        "poll" -> {
                            check(hasAuthority(token) && File(dir, "state.json").isFile)
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
            } catch (_: Exception) { result.error("connect_four_storage", "Deine Runde konnte noch nicht bestätigt werden.", null) }
        }
    }
    fun state(root: File, token: String): String = try {
        locked(root) { read(File(directory(root, token), "state.json"))?.toString() ?: "{}" }
    } catch (_: Exception) { "{}" }

    fun submit(root: File, token: String, payload: String): Boolean = try {
        locked(root) {
            require(payload.toByteArray(Charsets.UTF_8).size in 1..2048)
            val dir = directory(root, token)
            val state = read(File(dir, "state.json"))
            if (state == null) false else {
                val request = JSONObject(payload)
                require(request.optString("token") == token && request.optString("roundId") == state.optString("roundId"))
                require(integer(request, "revision") == integer(state, "revision"))
                val consumed = maxOf(integer(state, "ack"), integer(state, "rejected"))
                val sequence = integer(request, "sequence")
                require(sequence > consumed && sequence <= 1000000000L)
                val action = request.optString("action")
                val allowed = when (action) {
                    "drop" -> { require(integer(request, "column") in 0..6); setOf("column") }
                    "level" -> { require(request.optString("level") in setOf("leicht", "mittel", "schlau")); setOf("level") }
                    "mode" -> { require(request.opt("twoPlayers") is Boolean); setOf("twoPlayers") }
                    "pause", "resume", "exit", "restart" -> emptySet()
                    else -> throw IllegalArgumentException("Unknown C4 intent")
                } + setOf("token", "roundId", "revision", "sequence", "action")
                require(request.keys().asSequence().all { it in allowed })
                val previous = read(File(dir, "request.json"))
                if (previous != null && integer(previous, "sequence") > consumed) {
                    previous.toString() == request.toString()
                } else { write(File(dir, "request.json"), request); true }
            }
        }
    } catch (_: Exception) { false }

    fun pulse(root: File, token: String, active: Boolean): Boolean = try {
        locked(root) {
            val dir = directory(root, token)
            if (!File(dir, "state.json").isFile) false else {
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
