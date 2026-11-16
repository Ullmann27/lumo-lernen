package dev.ullmann.lumo

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import org.json.JSONArray
import org.json.JSONObject

/** One native lesson's local dialogue. Transcripts stay in RAM and are never
 * scored or sent to a network service. Only explicit taps start on-device ASR. */
class LumoLearningConversation(
    private val activity: Activity,
    options: JSONObject,
    private val stopAudio: () -> Unit
) {
    private val main = Handler(Looper.getMainLooper())
    private val lock = Any()
    private val lesson = JSONObject(options.optJSONObject("learning")?.toString() ?: "{}")
    private val launchSession = options.optString("sessionId")
    private val microphoneAllowed = options.optBoolean("learningMicrophoneEnabled", false)
    private val baseRate = options.optDouble("learningVoiceRate", 1.0).coerceIn(0.70, 1.60)
    private var scope = lesson.optJSONObject("scope") ?: JSONObject()
    private var generation = 0L
    private var active = false
    private var destroyed = false
    private var recognizer: SpeechRecognizer? = null
    private var turn = 0L
    private var lastReply = ""
    private var currentExplanation = lesson.optString("explanation", "")
    private var objects = lesson.optJSONArray("objectIds") ?: JSONArray()
    private var allowedActions = setOf("explain", "repeat", "slower", "hint", "stop")
    @Volatile private var snapshot = "{\"state\":\"idle\"}"

    init {
        scope = JSONObject(scope.toString()).put("sessionId", launchSession)
        publish("idle")
    }

    fun status(): String = snapshot

    private fun parsed(payload: String): JSONObject? =
        if (payload.length > 16000) null else try { JSONObject(payload) } catch (_: Exception) { null }

    private fun identity(request: JSONObject): JSONObject = request.optJSONObject("scope") ?: request

    private fun sameIdentity(request: JSONObject): Boolean {
        val received = identity(request)
        return received.optInt("protocolVersion") == 1 &&
            received.optString("sessionId") == launchSession &&
            received.optString("taskId") == scope.optString("taskId") &&
            received.optLong("revision", -1) == scope.optLong("revision", 0) &&
            received.optLong("cancelEpoch", -1) == scope.optLong("cancelEpoch", 0) &&
            received.optString("stepId") == scope.optString("stepId")
    }

    fun updateContext(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val next = identity(request)
        synchronized(lock) {
            if (destroyed || next.optInt("protocolVersion") != 1 ||
                next.optString("sessionId") != launchSession ||
                next.optString("taskId") != scope.optString("taskId") ||
                next.optLong("revision", -1) < scope.optLong("revision", 0) ||
                next.optLong("cancelEpoch", -1) < scope.optLong("cancelEpoch", 0) ||
                next.optString("stepId").length > 120 ||
                request.optString("kind", lesson.optString("kind")) != lesson.optString("kind")) return false
            val changed = !sameIdentity(request)
            if (changed) generation++
            scope = JSONObject().put("protocolVersion", 1).put("sessionId", launchSession)
                .put("taskId", next.optString("taskId"))
                .put("revision", next.optLong("revision"))
                .put("cancelEpoch", next.optLong("cancelEpoch"))
                .put("stepId", next.optString("stepId"))
            request.optString("explanation").takeIf { it.isNotBlank() && it.length <= 1200 }
                ?.let { currentExplanation = it }
            request.optJSONArray("objectIds")?.let { supplied ->
                if (supplied.length() <= 128 && strings(supplied).all { it.matches(Regex("[a-zA-Z0-9_-]{1,80}")) }) {
                    objects = JSONArray(supplied.toString())
                }
            }
            request.optJSONArray("allowedActions")?.let { supplied ->
                allowedActions = strings(supplied).filter { it in setOf("explain", "repeat", "slower", "hint", "stop") }.toSet() + "stop"
            }
            if (changed) main.post { stopRecognition(); publish("idle") }
        }
        return true
    }

    fun request(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val text = request.optString("text").trim()
        val action = request.optString("action", "explain")
        val nextTurn = request.optLong("turnId", 0)
        val token: Long
        synchronized(lock) {
            if (!active || destroyed || !sameIdentity(request) || nextTurn <= turn ||
                text.length > 1200 || action !in allowedActions ||
                (text.isEmpty() && action !in setOf("explain", "repeat", "slower", "hint", "stop"))) return false
            generation++
            token = generation
            turn = nextTurn
        }
        main.post {
            if (!current(token, request)) return@post
            stopRecognition()
            stopAudio()
            if (LumoLearningDialogLogic.isStop(text) || action == "stop") {
                publish("cancelled", transcript = text, action = "stop")
                return@post
            }
            publish("thinking", transcript = text)
            val context = LumoLearningDialogLogic.Context(
                lesson.optString("kind"), lesson.optInt("a"), lesson.optInt("b"), lesson.optInt("extra"),
                lesson.optString("word"), lesson.optString("plantPart"), currentExplanation,
                strings(lesson.optJSONArray("syllables")), strings(lesson.optJSONArray("patternUnit"))
            )
            val reply = LumoLearningDialogLogic.answer(context, text, action)
            if (!current(token, request)) return@post
            val repeated = if (action == "repeat" && lastReply.isNotBlank()) lastReply else reply.text
            lastReply = repeated
            val objectId = reply.objectId.takeIf { strings(objects).contains(it) } ?: ""
            publish("ready", text, repeated, reply.action, objectId,
                if (reply.slower) (baseRate * 0.75).coerceAtLeast(0.70) else baseRate)
        }
        return true
    }

    fun startListening(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val nextTurn = request.optLong("turnId", 0)
        val token: Long
        synchronized(lock) {
            if (!active || destroyed || !sameIdentity(request) || nextTurn <= turn || !microphoneAllowed) return false
            generation++
            token = generation
            turn = nextTurn
        }
        main.post {
            if (!current(token, request)) return@post
            stopRecognition()
            stopAudio()
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                !SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)) {
                publish("error", reply = "Die Offline-Spracherkennung ist hier nicht verfügbar. Du kannst deine Frage eintippen.")
                return@post
            }
            if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                publish("permission", reply = "Erlaube das Mikrofon und tippe danach erneut auf das Mikrofon.")
                activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 8264)
                return@post
            }
            try {
                val listener = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
                recognizer = listener
                listener.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        if (current(token, request)) publish("listening")
                    }
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {
                        if (current(token, request)) publish("recognizing")
                    }
                    override fun onError(error: Int) {
                        if (!current(token, request)) return
                        stopRecognition()
                        publish("error", reply = "Ich habe dich noch nicht verstanden. Du kannst es erneut sagen oder deine Frage eintippen.")
                    }
                    override fun onResults(results: Bundle?) {
                        if (!current(token, request)) return
                        val heard = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()?.trim()?.take(1200).orEmpty()
                        stopRecognition()
                        if (LumoLearningDialogLogic.isStop(heard)) {
                            stopAudio()
                            publish("cancelled", transcript = heard, action = "stop")
                        } else if (heard.isNotEmpty()) {
                            // Recognition is a candidate. The child edits or confirms it.
                            publish("transcribed", transcript = heard)
                        } else publish("error", reply = "Ich habe keine Wörter erkannt. Versuche es noch einmal.")
                    }
                    override fun onPartialResults(partialResults: Bundle?) {
                        if (!current(token, request)) return
                        val heard = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()?.take(1200).orEmpty()
                        publish("listening", transcript = heard)
                    }
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
                publish("listening")
                listener.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, "de-DE")
                    putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                })
                main.postDelayed({
                    if (current(token, request) && recognizer === listener) listener.stopListening()
                }, 30000)
            } catch (_: Exception) {
                stopRecognition()
                publish("error", reply = "Das Mikrofon konnte nicht starten. Du kannst deine Frage eintippen.")
            }
        }
        return true
    }

    private fun current(token: Long, request: JSONObject): Boolean = synchronized(lock) {
        !destroyed && active && generation == token && sameIdentity(request)
    }

    fun setActive(value: Boolean) {
        synchronized(lock) {
            active = value
            if (!value) generation++
        }
        if (!value) main.post { stopRecognition(); publish("paused") }
    }

    fun stop() {
        synchronized(lock) { generation++ }
        main.post { stopRecognition(); stopAudio(); publish("cancelled") }
    }

    fun destroy() {
        synchronized(lock) { generation++; destroyed = true; active = false }
        main.post { stopRecognition(); lastReply = ""; publish("cancelled") }
    }

    private fun stopRecognition() {
        recognizer?.let { try { it.cancel(); it.destroy() } catch (_: Exception) {} }
        recognizer = null
    }

    private fun publish(state: String, transcript: String = "", reply: String = "",
                        action: String = "", objectId: String = "", rate: Double = baseRate) {
        synchronized(lock) {
            val value = JSONObject(scope.toString()).put("scope", JSONObject(scope.toString()))
                .put("turnId", turn).put("state", state).put("transcript", transcript)
                .put("reply", reply).put("action", action).put("objectId", objectId)
                .put("rate", rate).put("microphoneAllowed", microphoneAllowed)
                .put("source", "local_checked_lesson").put("wordTimingAvailable", false)
                .put("phonemeTimingAvailable", false)
            snapshot = value.toString()
        }
    }

    private fun strings(array: JSONArray?): List<String> =
        if (array == null) emptyList() else (0 until array.length()).map { array.optString(it) }
}
