package dev.ullmann.lumo

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

/** The existing central player plays the WAV. This is only local synthesis. */
class LumoOfflineSpeechBridge(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())
    private val worker = ScheduledThreadPoolExecutor(1).apply {
        removeOnCancelPolicy = true
        executeExistingDelayedTasksAfterShutdownPolicy = false
    }
    private val revision = AtomicLong(0)
    private var pending: Request? = null
    @Volatile private var engine: LumoOfflineSpeechEngine? = null
    private val modelAsset = "lumo_offline_voice"
    private class Request(val id: Long, val result: MethodChannel.Result) {
        val finished = AtomicBoolean(false)
        var future: Future<*>? = null
    }

    fun attach(flutter: FlutterEngine) {
        MethodChannel(flutter.dartExecutor.binaryMessenger, "lumo_lernen/offline_speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "availability" -> {
                        try {
                            context.assets.open("$modelAsset/model-manifest.json").close()
                            result.success(mapOf(
                                "available" to true, "profile" to LumoOfflineSpeechEngine.PROFILE,
                                "preset" to LumoOfflineSpeechEngine.PRESET, "language" to "de",
                                "local" to true, "sampleRate" to LumoOfflineSpeechEngine.SAMPLE_RATE
                            ))
                        } catch (_: Exception) {
                            result.success(mapOf("available" to false, "local" to true))
                        }
                    }
                    "synthesize" -> {
                        val text = call.argument<String>("text")
                        val style = call.argument<String>("style") ?: "warm"
                        // Licensing assent is not an online/privacy/microphone consent.
                        if (call.argument<Boolean>("localLicenseAccepted") != true) {
                            result.error("local_license", "Lokale Sprachlizenz nicht bestätigt.", null)
                        } else if (text.isNullOrBlank() || text.length > 220 ||
                            style !in setOf("warm", "greeting", "explain", "celebrate", "comfort", "question")) {
                            result.error("local_input", "Ungültiger lokaler Sprachtext.", null)
                        } else {
                            cancelCurrent()
                            val request = Request(revision.incrementAndGet(), result)
                            pending = request
                            request.future = worker.submit {
                                try {
                                    if (request.id != revision.get()) throw InterruptedException()
                                    // Immutable weights are verified when opening a model,
                                    // not rehashed for every subsequent spoken sentence.
                                    val voice = engine ?: LumoOfflineSpeechEngine(
                                        prepareModels(request.id)
                                    ).also { engine = it }
                                    val started = System.nanoTime()
                                    val wav = voice.synthesize(text, style) { request.id != revision.get() }
                                    val elapsed = (System.nanoTime() - started) / 1_000_000
                                    main.post {
                                        if (request.id == revision.get() &&
                                            request.finished.compareAndSet(false, true)) {
                                            if (pending === request) pending = null
                                            result.success(mapOf(
                                                "wav" to wav, "profile" to LumoOfflineSpeechEngine.PROFILE,
                                                "preset" to LumoOfflineSpeechEngine.PRESET,
                                                "language" to "de", "local" to true,
                                                "sampleRate" to LumoOfflineSpeechEngine.SAMPLE_RATE,
                                                "synthesisMs" to elapsed
                                            ))
                                        }
                                    }
                                } catch (_: Throwable) {
                                    main.post {
                                        if (request.finished.compareAndSet(false, true)) {
                                            if (pending === request) pending = null
                                            result.error("local_unavailable",
                                                "Die lokale Lumo-Stimme konnte diesen Satz nicht erzeugen.", null)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    "cancel" -> { cancelCurrent(); result.success(true) }
                    else -> result.notImplemented()
                }
            }
    }

    private fun cancelCurrent() {
        revision.incrementAndGet()
        engine?.cancel()
        pending?.let { request ->
            request.future?.cancel(false)
            if (request.finished.compareAndSet(false, true)) {
                request.result.error("local_cancelled", "Sprachausgabe beendet.", null)
            }
        }
        pending = null
    }

    private fun digest(file: File): String {
        val sha = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { source ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = source.read(buffer)
                if (count < 0) break
                sha.update(buffer, 0, count)
            }
        }
        return sha.digest().joinToString("") { "%02x".format(it.toInt() and 255) }
    }

    private fun prepareModels(requestId: Long): File {
        val manifest = context.assets.open("$modelAsset/model-manifest.json").use {
            JSONObject(it.bufferedReader().readText())
        }
        check(manifest.getString("profile") == LumoOfflineSpeechEngine.PROFILE)
        check(manifest.getString("preset") == LumoOfflineSpeechEngine.PRESET)
        check(manifest.getInt("speaker_id") == LumoOfflineSpeechEngine.SPEAKER_ID)
        check(manifest.getInt("sample_rate") == LumoOfflineSpeechEngine.SAMPLE_RATE)
        val directory = File(context.noBackupFilesDir, LumoOfflineSpeechEngine.PROFILE)
        check(directory.isDirectory || directory.mkdirs())
        val hashes = manifest.getJSONObject("file_sha256")
        val names = hashes.keys().asSequence().toList()
        for (name in names) {
            check(name.matches(Regex("[A-Za-z0-9_.-]+")))
            if (requestId != revision.get()) throw InterruptedException()
            val target = File(directory, name)
            val expected = hashes.getString(name)
            if (target.isFile && digest(target) == expected) continue
            // Only regenerate our own immutable model cache, never user files.
            val temporary = File(directory, "$name.installing")
            context.assets.open("$modelAsset/$name").use { input ->
                temporary.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        if (requestId != revision.get()) throw InterruptedException()
                        val count = input.read(buffer)
                        if (count < 0) break
                        output.write(buffer, 0, count)
                    }
                }
            }
            check(digest(temporary) == expected)
            if (requestId != revision.get()) throw InterruptedException()
            if (target.exists()) check(target.delete())
            check(temporary.renameTo(target))
        }
        return directory
    }

    fun release() {
        cancelCurrent()
        worker.execute { engine?.close(); engine = null }
    }

    fun destroy() {
        release()
        worker.shutdown()
    }
}
