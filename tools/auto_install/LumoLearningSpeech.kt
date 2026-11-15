package dev.ullmann.lumo

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.MediaDataSource
import android.os.Handler
import android.os.Build
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.CancellationException
import java.util.concurrent.Executors
import java.util.concurrent.Future

/** Original F2 synthesis and real playback for the native lesson and village.
 * No microphone, system TTS, online service or learning score is involved. */
class LumoLearningSpeech(context: Context, options: JSONObject) {
    private val main = Handler(Looper.getMainLooper())
    private val bridge = LumoOfflineSpeechBridge(context.applicationContext)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private val launchSession = options.optString("sessionId", "")
    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var focusRequest: AudioFocusRequest? = null
    private var focusListener: AudioManager.OnAudioFocusChangeListener? = null
    private var focusHeld = false
    private val envelopeWorker = Executors.newSingleThreadExecutor { job ->
        Thread(job, "LumoSpeechEnvelope").apply { isDaemon = true }
    }
    private var envelopeTask: Future<*>? = null
    private var envelope = LumoSpeechEnvelope.EMPTY
    private val allowed = options.optString("game") in setOf("learning", "build") &&
        options.optBoolean("learningVoiceEnabled", false) &&
        options.optBoolean("localVoiceLicenseAccepted", false)
    private val speed = options.optDouble("learningVoiceRate", 1.0)
        .takeIf { it.isFinite() }?.coerceIn(0.70, 1.60)?.toFloat() ?: 1.0f
    private var player: MediaPlayer? = null
    private var audioSource: WavSource? = null
    private var generation = 0L
    private var utterance = 0
    private var state = "idle"
    @Volatile private var active = false
    @Volatile private var destroyed = false
    private var speechScope: SpeechScope? = null
    private var newestScope: SpeechScope? = null
    private val acceptedUtterances = LinkedHashSet<String>()
    @Volatile private var snapshot = "{\"scopeVersion\":1,\"state\":\"idle\",\"id\":0,\"positionMs\":0,\"durationMs\":0,\"envelope\":0,\"audible\":false}"

    /** Optional correlation metadata only. No child identity or transcript is
     * retained here; the actual native lesson still owns learning results. */
    private data class SpeechScope(
        val sessionId: String,
        val taskId: String,
        val turnId: String,
        val utteranceId: String,
        val contextRevision: Int,
    ) {
        val key: String get() = "$sessionId|$utteranceId"
        fun appendTo(value: JSONObject) {
            value.put("sessionId", sessionId).put("taskId", taskId)
                .put("turnId", turnId).put("utteranceId", utteranceId)
                .put("contextRevision", contextRevision)
        }
    }

    private fun readScope(request: JSONObject): SpeechScope? {
        fun identifier(key: String): String {
            val value = request.opt(key) as? String ?: throw IllegalArgumentException()
            require(value.length in 1..160 && value.all {
                it.isLetterOrDigit() || it in ".:_-"
            })
            return value
        }
        val keys = arrayOf("sessionId", "taskId", "turnId", "utteranceId", "contextRevision")
        if (keys.none { request.has(it) }) return null
        require(keys.all { request.has(it) })
        val number = request.opt("contextRevision") as? Number ?: throw IllegalArgumentException()
        val revision = number.toDouble()
        require(revision.isFinite() && revision >= 0 && revision <= Int.MAX_VALUE &&
            revision == kotlin.math.floor(revision))
        val scope = SpeechScope(identifier("sessionId"), identifier("taskId"),
            identifier("turnId"), identifier("utteranceId"), revision.toInt())
        require(launchSession.isEmpty() || scope.sessionId == launchSession)
        return scope
    }

    private fun acceptScope(scope: SpeechScope?): Boolean {
        if (scope == null) return true // Older learning/build callers stay supported.
        val previous = newestScope
        if (previous != null && (scope.sessionId != previous.sessionId ||
            scope.contextRevision < previous.contextRevision ||
            (scope.contextRevision == previous.contextRevision && scope.taskId != previous.taskId))) {
            return false
        }
        if (!acceptedUtterances.add(scope.key)) return false
        while (acceptedUtterances.size > 64) acceptedUtterances.remove(acceptedUtterances.first())
        newestScope = scope
        return true
    }

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

    @Synchronized
    fun speak(payload: String): Boolean {
        if (!allowed || !active || destroyed || payload.length > 1400) return false
        val request = try { JSONObject(payload) } catch (_: Exception) { return false }
        val text = request.optString("text", "")
        val id = request.optInt("id", 0)
        val style = request.optString("style", "explain")
        val scope = try { readScope(request) } catch (_: IllegalArgumentException) { return false }
        if (id <= 0 || text.isBlank() || text.length > 220 ||
            style !in setOf("warm", "greeting", "explain", "celebrate", "comfort", "question")) return false
        if (!acceptScope(scope)) return false
        main.post {
            if (!active || destroyed) return@post
            stopOnMain()
            val token = generation
            utterance = id
            speechScope = scope
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
            playback.setAudioAttributes(audioAttributes)
            playback.setDataSource(source)
            playback.setOnPreparedListener {
                if (token != generation || !active || destroyed) return@setOnPreparedListener
                try {
                    if (!requestPlaybackFocus(token)) {
                        failed(token)
                        return@setOnPreparedListener
                    }
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

    private fun stopOnMain(nextState: String = "idle") {
        generation++
        bridge.cancel()
        releasePlayer()
        state = nextState
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
        abandonPlaybackFocus()
    }

    @Suppress("DEPRECATION")
    private fun requestPlaybackFocus(token: Long): Boolean {
        val manager = audioManager ?: return false
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            main.post {
                // Queued callbacks from a released utterance cannot stop its
                // successor. An interruption never silently replays speech.
                if (token == generation && focusHeld && !destroyed && change < 0) {
                    stopOnMain("interrupted")
                }
            }
        }
        focusListener = listener
        val result = if (Build.VERSION.SDK_INT >= 26) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setWillPauseWhenDucked(true)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener(listener, main).build()
            focusRequest = request
            manager.requestAudioFocus(request)
        } else {
            manager.requestAudioFocus(listener, AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        focusHeld = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        if (!focusHeld) abandonPlaybackFocus()
        return focusHeld
    }

    @Suppress("DEPRECATION")
    private fun abandonPlaybackFocus() {
        val request = focusRequest
        val listener = focusListener
        focusRequest = null
        focusListener = null
        focusHeld = false
        try {
            if (Build.VERSION.SDK_INT >= 26 && request != null) {
                audioManager?.abandonAudioFocusRequest(request)
            } else if (listener != null) {
                audioManager?.abandonAudioFocus(listener)
            }
        } catch (_: Exception) {
            // Playback is already released. No automatic focus retry.
        }
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
        val current = JSONObject().put("scopeVersion", 1).put("state", state).put("id", utterance)
            .put("positionMs", position).put("durationMs", duration)
            .put("audible", audible).put("envelopeAvailable", envelope.available)
            .put("envelope", if (audible) envelope.amplitudeAt(position) else 0.0)
        speechScope?.appendTo(current)
        snapshot = current.toString()
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
