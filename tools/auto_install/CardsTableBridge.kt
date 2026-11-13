package dev.ullmann.lumo

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import org.json.JSONObject

/** Private mailbox between Flutter and the isolated :lumo_game process.
 * Only the Dart Cards controller owns rules, hidden cards, persistence and rewards.
 */
object CardsTableBridge {
    private const val MAX_BYTES = 262144
    private val tokenPattern = Regex("[a-f0-9]{32}")

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
        MethodChannel(messenger, "lumo_lernen/cards_table").setMethodCallHandler { call, result ->
            try {
                val token = call.argument<String>("token") ?: ""
                synchronized(this) {
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

    @Synchronized
    fun state(root: File, token: String): String = try {
        read(File(session(root, token), "state.json"))?.toString() ?: "{}"
    } catch (_: Exception) { "{}" }

    @Synchronized
    fun submit(root: File, token: String, payload: String): Boolean {
      return try {
        require(payload.toByteArray(Charsets.UTF_8).size <= 4096)
        val dir = session(root, token)
        val state = read(File(dir, "state.json")) ?: return false
        val request = JSONObject(payload)
        require(request.optString("token") == token)
        val sequence = request.optLong("sequence", -1)
        require(sequence > state.optLong("ack", 0) && sequence <= 1000000000L)
        require(request.optInt("revision", -1) == state.optInt("revision", -2))
        val previous = read(File(dir, "request.json"))
        // At most one unacknowledged action. Repeating it is harmless.
        if (previous != null && previous.optLong("sequence") > state.optLong("ack", 0)) {
            return previous.toString() == request.toString()
        }
        require(request.optString("action") in setOf("play", "draw", "color", "answer", "handover", "pause", "resume", "call"))
        write(File(dir, "request.json"), request)
        true
    } catch (_: Exception) { false }
    }

    @Synchronized
    fun pulse(root: File, token: String, active: Boolean): Boolean {
      return try {
        val dir = session(root, token)
        if (!File(dir, "state.json").isFile) return false
        write(File(dir, "lifecycle.json"), JSONObject().put("active", active)
            .put("stamp", System.currentTimeMillis()), durable = false)
        true
    } catch (_: Exception) { false }
    }
}
