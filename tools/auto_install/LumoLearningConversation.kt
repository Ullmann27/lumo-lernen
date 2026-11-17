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
    private var taskRetired = false
    private var recognizer: SpeechRecognizer? = null
    private var turn = 0L
    private var lastReply = ""
    private var currentExplanation = lesson.optString("explanation", "")
    private var objects = lesson.optJSONArray("objectIds") ?: JSONArray()
    private var patternUnit: List<String> = emptyList()
    // A scene may narrow the original task owner's explicit permissions.
    private val launchActions = checkedActions(lesson.optJSONArray("allowedActions")
        ?: scope.optJSONArray("allowedActions"))
    private var allowedActions = launchActions
    @Volatile private var snapshot = "{\"state\":\"idle\"}"

    init {
        scope = JSONObject(scope.toString()).put("sessionId", launchSession)
        publish("idle")
    }

    fun status(): String = snapshot

    private fun parsed(payload: String): JSONObject? =
        if (payload.length > 16000) null else try { JSONObject(payload) } catch (_: Exception) { null }

    private fun identity(request: JSONObject): JSONObject = request.optJSONObject("scope") ?: request

    private fun checkedActions(supplied: JSONArray?): Set<String> =
        strings(supplied).filter { it in setOf("explain", "repeat", "slower", "hint", "stop") }.toSet() + "stop"

    private fun retireContext(state: String = "idle") {
        generation++
        lastReply = ""
        currentExplanation = ""
        objects = JSONArray()
        patternUnit = emptyList()
        val token = generation
        main.post {
            synchronized(lock) {
                if (generation != token || destroyed) return@post
                stopRecognition()
                stopAudio()
                publish(if (active) state else "paused")
            }
        }
    }

    private fun sameIdentity(request: JSONObject): Boolean {
        val received = identity(request)
        return received.optInt("protocolVersion") == 1 &&
            received.optString("sessionId") == launchSession &&
            received.optString("taskId") == scope.optString("taskId") &&
            received.optLong("revision", -1) == scope.optLong("revision", 0) &&
            received.optLong("cancelEpoch", -1) == scope.optLong("cancelEpoch", 0) &&
            received.opt("stepId").takeUnless { it === JSONObject.NULL } ==
                scope.opt("stepId").takeUnless { it === JSONObject.NULL }
    }

    /** Godot supplies the checked group under parameters, not in the launch
     * descriptor. Accept only the smallest repeated unit of that immutable
     * descriptor; this adapter grants neither actions nor answer evaluation. */
    private fun checkedPatternUnit(request: JSONObject): List<String>? {
        val supplied = patternTokens(request.optJSONObject("parameters")
            ?.optJSONArray("patternUnit"), 1, 4) ?: return null
        val sequence = patternTokens(lesson.optJSONArray("sequence"), 4, 12) ?: return null
        val rawPeriod = (lesson.opt("period") as? Number)?.toDouble() ?: return null
        if (!rawPeriod.isFinite() || rawPeriod < 1 || rawPeriod > 4 ||
            rawPeriod != rawPeriod.toInt().toDouble()) return null
        val period = rawPeriod.toInt()
        val smallest = (1..4).firstOrNull { length ->
            sequence.size >= length * 2 &&
                (length until sequence.size).all { sequence[it] == sequence[it % length] }
        }
        return supplied.takeIf { smallest == period && it == sequence.take(period) }
    }

    private fun patternTokens(array: JSONArray?, minimum: Int, maximum: Int): List<String>? {
        if (array == null || array.length() !in minimum..maximum) return null
        val result = ArrayList<String>()
        for (index in 0 until array.length()) {
            val value = array.opt(index)
            if (value !is String || value.isEmpty() || value.trim() != value ||
                value.codePointCount(0, value.length) > 24 ||
                value.any { it.code < 32 || it.code in 127..159 || it.code in 8232..8233 }) return null
            result.add(value)
        }
        return result
    }

    fun updateContext(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val next = identity(request)
        val nextStep = next.opt("stepId")
        synchronized(lock) {
            if (destroyed || taskRetired || next.optInt("protocolVersion") != 1 ||
                next.optString("sessionId") != launchSession ||
                next.optLong("revision", -1) < 0 || next.optLong("cancelEpoch", -1) < 0 ||
                (nextStep != null && nextStep !== JSONObject.NULL && nextStep !is String) ||
                (nextStep is String && (nextStep.isEmpty() || nextStep.length > 120))) return false
            if (next.optString("taskId") != scope.optString("taskId")) {
                // The scene's numeric/word descriptor belongs to one task.
                // Another task requires another launch, not old cached help.
                taskRetired = true
                allowedActions = setOf("stop")
                retireContext("cancelled")
                return false
            }
            if (request.optString("kind", lesson.optString("kind")) != lesson.optString("kind")) return false
            if (next.optLong("revision") < scope.optLong("revision", 0) ||
                next.optLong("cancelEpoch") < scope.optLong("cancelEpoch", 0)) return false
            val changed = !sameIdentity(request)
            val suppliedActions = request.optJSONArray("allowedActions")
            if (request.has("allowedActions") && suppliedActions == null) return false
            val nextActions = if (suppliedActions != null) checkedActions(suppliedActions)
                else if (changed) setOf("stop") else allowedActions
            if (!launchActions.containsAll(nextActions)) return false
            val nextPatternUnit = if (lesson.optString("kind") == "pattern")
                checkedPatternUnit(request) ?: return false else emptyList()
            if (changed || nextActions != allowedActions) retireContext()
            scope = JSONObject().put("protocolVersion", 1).put("sessionId", launchSession)
                .put("taskId", next.optString("taskId"))
                .put("revision", next.optLong("revision"))
                .put("cancelEpoch", next.optLong("cancelEpoch"))
                .put("stepId", nextStep ?: JSONObject.NULL)
            request.optString("explanation").takeIf { it.length <= 1200 }
                ?.let { currentExplanation = it }
            request.optJSONArray("objectIds")?.let { supplied ->
                if (supplied.length() <= 128 && strings(supplied).all { it.matches(Regex("[a-zA-Z0-9_-]{1,80}")) }) {
                    objects = JSONArray(supplied.toString())
                }
            }
            patternUnit = nextPatternUnit
            allowedActions = nextActions
        }
        return true
    }

    fun request(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val text = request.optString("text").trim()
        val action = if (LumoLearningDialogLogic.isStop(text)) "stop"
            else request.optString("action", "explain")
        val nextTurn = request.optLong("turnId", 0)
        val token: Long
        synchronized(lock) {
            if (!active || destroyed || taskRetired || !sameIdentity(request) || nextTurn <= turn ||
                text.length > 1200 || action !in allowedActions ||
                (text.isEmpty() && action !in setOf("explain", "repeat", "slower", "hint", "stop"))) return false
            generation++
            token = generation
            turn = nextTurn
        }
        main.post {
            synchronized(lock) {
                if (!current(token, request)) return@post
                stopRecognition()
                stopAudio()
                if (action == "stop") {
                    publish("cancelled", transcript = text, action = "stop")
                    return@post
                }
                val context = LumoLearningDialogLogic.Context(
                    lesson.optString("kind"), lesson.optInt("a"), lesson.optInt("b"), lesson.optInt("extra"),
                    lesson.optString("word"), lesson.optString("plantPart"), currentExplanation,
                    strings(lesson.optJSONArray("syllables")), patternUnit
                )
                val reply = LumoLearningDialogLogic.answerIfAllowed(context, text, action, allowedActions)
                if (reply == null) {
                    publish("unavailable", reply = "Diese Hilfe ist bei der aktuellen Aufgabe nicht freigegeben.")
                    return@post
                }
                val repeated = if (reply.action in setOf("repeat", "slower") && lastReply.isNotBlank()) lastReply else reply.text
                lastReply = repeated
                val objectId = reply.objectId.takeIf { strings(objects).contains(it) } ?: ""
                publish("ready", text, repeated, reply.action, objectId,
                    if (reply.slower) (baseRate * 0.75).coerceAtLeast(0.70) else baseRate)
            }
        }
        return true
    }

    fun startListening(payload: String): Boolean {
        val request = parsed(payload) ?: return false
        val nextTurn = request.optLong("turnId", 0)
        val token: Long
        synchronized(lock) {
            if (!active || destroyed || taskRetired || !sameIdentity(request) || nextTurn <= turn || !microphoneAllowed) return false
            generation++
            token = generation
            turn = nextTurn
        }
        main.post {
          synchronized(lock) {
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
                    private fun currentCapture(): Boolean = current(token, request) && recognizer === listener
                    override fun onReadyForSpeech(params: Bundle?) {
                        if (currentCapture()) publishCurrent(token, request, "listening")
                    }
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {
                        if (currentCapture()) publishCurrent(token, request, "recognizing")
                    }
                    override fun onError(error: Int) {
                        if (!currentCapture()) return
                        stopRecognition()
                        publishCurrent(token, request, "error", reply = "Ich habe dich noch nicht verstanden. Du kannst es erneut sagen oder deine Frage eintippen.")
                    }
                    override fun onResults(results: Bundle?) {
                        if (!currentCapture()) return
                        val heard = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()?.trim()?.take(1200).orEmpty()
                        stopRecognition()
                        if (LumoLearningDialogLogic.isStop(heard)) {
                            stopAudio()
                            publishCurrent(token, request, "cancelled", transcript = heard, action = "stop")
                        } else if (heard.isNotEmpty()) {
                            // Recognition is a candidate. The child edits or confirms it.
                            publishCurrent(token, request, "transcribed", transcript = heard)
                        } else publishCurrent(token, request, "error", reply = "Ich habe keine Wörter erkannt. Versuche es noch einmal.")
                    }
                    override fun onPartialResults(partialResults: Bundle?) {
                        if (!currentCapture()) return
                        val heard = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()?.take(1200).orEmpty()
                        publishCurrent(token, request, "listening", transcript = heard)
                    }
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
                publishCurrent(token, request, "starting")
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
                publishCurrent(token, request, "error", reply = "Das Mikrofon konnte nicht starten. Du kannst deine Frage eintippen.")
            }
          }
        }
        return true
    }

    private fun current(token: Long, request: JSONObject): Boolean = synchronized(lock) {
        !destroyed && !taskRetired && active && generation == token && sameIdentity(request)
    }

    private fun publishCurrent(token: Long, request: JSONObject, state: String,
                               transcript: String = "", reply: String = "", action: String = "") {
        synchronized(lock) {
            if (current(token, request)) publish(state, transcript, reply, action)
        }
    }

    fun setActive(value: Boolean) {
        synchronized(lock) {
            active = value
            if (!value) {
                generation++
                val token = generation
                main.post {
                    synchronized(lock) {
                        if (generation != token || destroyed) return@post
                        stopRecognition()
                        stopAudio()
                        publish(if (active) "idle" else "paused")
                    }
                }
            }
        }
    }

    fun stop() {
        synchronized(lock) {
            generation++
            val token = generation
            main.post {
                synchronized(lock) {
                    if (generation != token || destroyed) return@post
                    stopRecognition(); stopAudio(); publish("cancelled")
                }
            }
        }
    }

    fun destroy() {
        synchronized(lock) { generation++; destroyed = true; active = false }
        main.post { stopRecognition(); stopAudio(); lastReply = ""; publish("cancelled") }
    }

    private fun stopRecognition() {
        val previous = recognizer
        recognizer = null
        previous?.let { try { it.cancel() } catch (_: Exception) {} }
        previous?.let { try { it.destroy() } catch (_: Exception) {} }
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
