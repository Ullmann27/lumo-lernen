package dev.ullmann.lumo

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/** Original F2 synthesis and real playback, confined to the native lesson.
 * No microphone, system TTS, online service or learning score is involved. */
class LumoLearningSpeech(context: Context, options: JSONObject) {
    private val main = Handler(Looper.getMainLooper())
    private val bridge = LumoOfflineSpeechBridge(context.applicationContext)
    private val directory = context.cacheDir
    private val allowed = options.optString("game") == "learning" &&
        options.optBoolean("learningVoiceEnabled", false) &&
        options.optBoolean("localVoiceLicenseAccepted", false)
    private val speed = options.optDouble("learningVoiceRate", 1.0)
        .takeIf { it.isFinite() }?.coerceIn(0.70, 1.60)?.toFloat() ?: 1.0f
    private var player: MediaPlayer? = null
    private var audioFile: File? = null
    private var generation = 0L
    private var utterance = 0
    private var state = "idle"
    private var active = false
    private var destroyed = false
    @Volatile private var snapshot = "{\"state\":\"idle\",\"id\":0,\"positionMs\":0,\"durationMs\":0}"

    private val pulse = object : Runnable {
        override fun run() {
            publish()
            if (!destroyed && state == "playing") main.postDelayed(this, 150)
        }
    }

    fun status(): String = snapshot

    fun setActive(value: Boolean) {
        main.post {
            if (destroyed) return@post
            active = value
            if (!value) {
                stopOnMain()
                bridge.release()
            }
        }
    }

    fun speak(payload: String): Boolean {
        if (!allowed || payload.length > 1400) return false
        val request = try { JSONObject(payload) } catch (_: Exception) { return false }
        val text = request.optString("text", "")
        val id = request.optInt("id", 0)
        val style = request.optString("style", "explain")
        if (id <= 0 || text.isBlank() || text.length > 220 ||
            style !in setOf("warm", "greeting", "explain", "celebrate", "comfort", "question")) return false
        main.post {
            if (!active || destroyed) return@post
            stopOnMain()
            val token = generation
            utterance = id
            state = "preparing"
            publish()
            bridge.synthesize(text, style, true, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (token != generation || !active || destroyed) return
                    val bytes = (result as? Map<*, *>)?.get("wav") as? ByteArray
                    if (bytes == null || bytes.size < 44) {
                        failed(token)
                        return
                    }
                    try {
                        val file = File.createTempFile("lumo-learning-", ".wav", directory)
                        audioFile = file
                        file.writeBytes(bytes)
                        val playback = MediaPlayer()
                        player = playback
                        playback.setAudioAttributes(AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                        playback.setDataSource(file.absolutePath)
                        playback.setOnPreparedListener {
                            if (token != generation || !active || destroyed) return@setOnPreparedListener
                            try {
                                playback.playbackParams = playback.playbackParams.setSpeed(speed)
                                playback.start()
                                state = "playing"
                                Log.i("LumoLearningSpeech", "started id=$id profile=${LumoOfflineSpeechEngine.PROFILE}")
                                main.post(pulse)
                            } catch (_: Exception) { failed(token) }
                        }
                        playback.setOnCompletionListener {
                            if (token != generation) return@setOnCompletionListener
                            releasePlayer()
                            state = "completed"
                            publish()
                            Log.i("LumoLearningSpeech", "completed id=$id")
                        }
                        playback.setOnErrorListener { _, _, _ -> failed(token); true }
                        playback.prepareAsync()
                    } catch (_: Exception) { failed(token) }
                }

                override fun error(code: String, message: String?, details: Any?) { failed(token) }
                override fun notImplemented() { failed(token) }
            })
        }
        return true
    }

    fun stop() { main.post { if (!destroyed) stopOnMain() } }

    private fun stopOnMain() {
        generation++
        bridge.cancel()
        releasePlayer()
        state = "idle"
        publish()
    }

    private fun failed(token: Long) {
        if (token != generation || destroyed) return
        releasePlayer()
        state = "unavailable"
        publish()
    }

    private fun releasePlayer() {
        main.removeCallbacks(pulse)
        player?.let { try { it.release() } catch (_: Exception) {} }
        player = null
        audioFile?.delete()
        audioFile = null
    }

    private fun publish() {
        val playback = player
        val playing = state == "playing" && playback != null
        val position = if (playing) try { playback!!.currentPosition } catch (_: Exception) { 0 } else 0
        val duration = if (playing) try { playback!!.duration } catch (_: Exception) { 0 } else 0
        snapshot = JSONObject().put("state", state).put("id", utterance)
            .put("positionMs", position).put("durationMs", duration).toString()
    }

    fun destroy() {
        main.post {
            if (destroyed) return@post
            stopOnMain()
            destroyed = true
            active = false
            bridge.destroy()
        }
    }
}
