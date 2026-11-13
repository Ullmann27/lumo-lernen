package dev.ullmann.lumo

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import org.json.JSONObject

/** Private mailbox between Flutter and the isolated :lumo_game process.
 * Only the Dart Cards controller owns rules, hidden cards, persistence and rewards.
 */
object CardsTableBridge {
    @Volatile private var attached = false
    fun isAttached(): Boolean = attached
    fun detach() { attached = false }
    private const val MAX_BYTES = 262144
    private val tokenPattern = Regex("[a-f0-9]{32}")

    // :lumo_game has a separate VM. A JVM monitor alone cannot protect close
    // against a native heartbeat recreating lifecycle.json after cleanup.
    private inline fun <T> locked(root: File, action: () -> T): T = synchronized(this) {
        val base = File(root, "lumo_cards_table_v1")
        check(base.isDirectory || base.mkdirs())
        RandomAccessFile(File(base, "bridge.lock"), "rw").use { file ->
            file.channel.lock().use { action() }
        }
    }

    private fun session(root: File, token: String): File {
        require(tokenPattern.matches(token)) { "Invalid Cards table token" }
        return File(File(root, "lumo_cards_table_v1"), token)
    }

    private fun read(file: File): JSONObject? {
        if (!file.isFile) return null
        require(file.length() in 1..MAX_BYTES.toLong()) { "Invalid Cards mailbox size" }
        return JSONObject(file.readText(Charsets.UTF_8))
    }

    private fun write(file: File, value: JSONObject, durable: Boolean = true) {
        val bytes = value.toString().toByteArray(Charsets.UTF_8)
        require(bytes.size in 1..MAX_BYTES) { "Cards mailbox too large" }
        check(file.parentFile?.isDirectory == true || file.parentFile?.mkdirs() == true)
        val pending = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(pending).use { it.write(bytes); if (durable) it.fd.sync() }
        check(pending.renameTo(file)) { "Cards mailbox rename failed" }
    }

    fun attach(messenger: BinaryMessenger, root: File) {
        attached = true
        MethodChannel(messenger, "lumo_lernen/cards_table").setMethodCallHandler { call, result ->
            try {
                val token = call.argument<String>("token") ?: ""
                locked(root) {
                    val dir = session(root, token)
                    when (call.method) {
                        "open" -> {
                            check(!dir.exists()) { "Cards token already used" }
                            val state = JSONObject(call.argument<String>("state") ?: "{}")
                            require(state.optString("token") == token)
                            write(File(dir, "state.json"), state)
                            result.success(true)
                        }
                        "publish" -> {
                            check(File(dir, "state.json").isFile) { "Cards table closed" }
                            val state = JSONObject(call.argument<String>("state") ?: "{}")
                            require(state.optString("token") == token)
                            write(File(dir, "state.json"), state)
                            result.success(true)
                        }
                        "poll" -> {
                            check(File(dir, "state.json").isFile) { "Cards table closed" }
                            val reply = JSONObject()
                            reply.put("request", read(File(dir, "request.json")))
                            reply.put("lifecycle", read(File(dir, "lifecycle.json")))
                            result.success(reply.toString())
                        }
                        "close" -> {
                            // Delete only this generated session's known temporary files.
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
                result.error("cards_storage", "Der Kartentisch wartet auf die gespeicherte Runde.", null)
            }
        }
    }

    fun state(root: File, token: String): String = try {
        locked(root) { read(File(session(root, token), "state.json"))?.toString() ?: "{}" }
    } catch (_: Exception) { "{}" }

    fun submit(root: File, token: String, payload: String): Boolean = try {
        locked(root) {
            require(payload.toByteArray(Charsets.UTF_8).size <= 4096)
            val dir = session(root, token)
            val state = read(File(dir, "state.json"))
            if (state == null) {
                false
            } else {
                val request = JSONObject(payload)
                require(request.optString("token") == token)
                val sequence = request.optLong("sequence", -1)
                require(sequence > state.optLong("ack", 0) && sequence <= 1000000000L)
                require(request.optInt("revision", -1) == state.optInt("revision", -2))
                val previous = read(File(dir, "request.json"))
                // At most one unacknowledged action. Repeating it is harmless.
                if (previous != null && previous.optLong("sequence") > state.optLong("ack", 0)) {
                    previous.toString() == request.toString()
                } else {
                    require(request.optString("action") in setOf("play", "draw", "color", "answer", "handover", "pause", "resume", "call"))
                    write(File(dir, "request.json"), request)
                    true
                }
            }
        }
    } catch (_: Exception) { false }

    fun pulse(root: File, token: String, active: Boolean): Boolean = try {
        locked(root) {
            val dir = session(root, token)
            if (!File(dir, "state.json").isFile) {
                false
            } else {
                val previous = read(File(dir, "lifecycle.json"))
                val pauseEpoch = ((previous?.optLong("pauseEpoch", 0) ?: 0) +
                    if (!active && previous?.optBoolean("active") == true) 1 else 0).coerceAtMost(1000000000L)
                write(File(dir, "lifecycle.json"), JSONObject().put("active", active)
                    .put("pauseEpoch", pauseEpoch).put("stamp", System.currentTimeMillis()), durable = false)
                true
            }
        }
    } catch (_: Exception) { false }
}
