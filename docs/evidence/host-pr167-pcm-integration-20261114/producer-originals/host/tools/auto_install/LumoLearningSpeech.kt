package dev.ullmann.lumo

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.MediaDataSource
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.CancellationException
import java.util.concurrent.Executors
import java.util.concurrent.Future

/** Original F2 synthesis and real playback, confined to the native lesson.
 * No microphone, system TTS, online service or learning score is involved. */
class LumoLearningSpeech(context: Context, options: JSONObject) {
    private val main = Handler(Looper.getMainLooper())
    private val bridge = LumoOfflineSpeechBridge(context.applicationContext)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private val envelopeWorker = Executors.newSingleThreadExecutor { job ->
        Thread(job, "LumoSpeechEnvelope").apply { isDaemon = true }
    }
    private var envelopeTask: Future<*>? = null
    private var envelope = LumoSpeechEnvelope.EMPTY
    private val allowed = options.optString("game") == "learning" &&
        options.optBoolean("learningVoiceEnabled", false) &&
        options.optBoolean("localVoiceLicenseAccepted", false)
    private val speed = options.optDouble("learningVoiceRate", 1.0)
        .takeIf { it.isFinite() }?.coerceIn(0.70, 1.60)?.toFloat() ?: 1.0f
    private var player: MediaPlayer? = null
    private var audioSource: WavSource? = null
    private var generation = 0L
    private var utterance = 0
    private var state = "idle"
    private var active = false
    private var destroyed = false
    @Volatile private var snapshot = "{\"state\":\"idle\",\"id\":0,\"positionMs\":0,\"durationMs\":0,\"envelope\":0,\"audible\":false}"

    // Avoid blocking the UI/render thread on a temporary WAV write. Android
    // reads the completed local synthesis buffer directly; release drops it.
    private class WavSource(bytes: ByteArray) : MediaDataSource() {
        @Volatile private var data = bytes
        override fun getSize(): Long = data.size.toLong()
        override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
            val source = data
            if (position < 0 || position >= source.size) return -1
            val count = minOf(size, source.size - position.toInt())
            source.copyInto(buffer, offset, position.toInt(), position.toInt() + count)
            return count
        }
        override fun close() { data = ByteArray(0) }
    }

    private val pulse = object : Runnable {
        override fun run() {
            publish()
            if (!destroyed && state == "playing") main.postDelayed(this, 50)
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
                    // Synthesis is complete, but there is no audible playback
                    // yet. Derive its real envelope away from the UI thread.
                    envelopeTask = envelopeWorker.submit {
                        try {
                            val measured = LumoSpeechEnvelope.fromWave(bytes)
                            main.post {
                                if (token != generation || !active || destroyed) return@post
                                envelopeTask = null
                                envelope = measured
                                preparePlayback(bytes, token, id)
                            }
                        } catch (_: CancellationException) {
                            // Stop/pause owns the published idle state.
                        } catch (_: Exception) {
                            main.post { failed(token) }
                        }
                    }
                }

                override fun error(code: String, message: String?, details: Any?) { failed(token) }
                override fun notImplemented() { failed(token) }
            })
        }
        return true
    }

    private fun preparePlayback(bytes: ByteArray, token: Long, id: Int) {
        try {
            val source = WavSource(bytes)
            audioSource = source
            val playback = MediaPlayer()
            player = playback
            playback.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            playback.setDataSource(source)
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
        envelopeTask?.cancel(true)
        envelopeTask = null
        envelope = LumoSpeechEnvelope.EMPTY
        player?.let { try { it.release() } catch (_: Exception) {} }
        player = null
        audioSource?.close()
        audioSource = null
    }

    private fun publish() {
        val playback = player
        val playing = state == "playing" && playback != null &&
            try { playback.isPlaying } catch (_: Exception) { false }
        val position = if (playing) try { playback!!.currentPosition } catch (_: Exception) { 0 } else 0
        val duration = if (playing) try { playback!!.duration } catch (_: Exception) { 0 } else 0
        val audible = playing && allowed && active && !destroyed && try {
            audioManager != null && !audioManager.isStreamMute(AudioManager.STREAM_MUSIC) &&
                audioManager.getStreamVolume(AudioManager.STREAM_MUSIC) > 0
        } catch (_: Exception) { false }
        snapshot = JSONObject().put("state", state).put("id", utterance)
            .put("positionMs", position).put("durationMs", duration)
            .put("audible", audible).put("envelopeAvailable", envelope.available)
            .put("envelope", if (audible) envelope.amplitudeAt(position) else 0.0).toString()
    }

    fun destroy() {
        main.post {
            if (destroyed) return@post
            stopOnMain()
            destroyed = true
            active = false
            bridge.destroy()
            envelopeWorker.shutdownNow()
        }
    }
}
