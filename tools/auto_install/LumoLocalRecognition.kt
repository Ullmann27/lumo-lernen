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
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import java.util.concurrent.Executor

/** Android implementation of the native MethodChannel used by speech_to_text
 * 7.5.0 / speech_to_text_platform_interface 2.5.0. MainActivity attaches this
 * AFTER automatic plugin registration, intentionally replacing that channel's
 * entire native handler. The package's Dart API and event schema stay intact.
 *
 * The upstream Android plugin may choose the default network-capable recognizer
 * when on-device service availability changes. This adapter has no such path:
 * every capture creates an on-device recognizer, or returns an error. No raw
 * audio is retained, no model is downloaded, and no transcript is logged.
 */
class LumoLocalRecognition(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val main = Handler(Looper.getMainLooper())
    private val executor = Executor { work -> main.post(work) }
    private var foreground = false
    private var destroyed = false
    private var generation = 0L
    private var recognizer: SpeechRecognizer? = null
    private var pendingPermission: MethodChannel.Result? = null
    private val localeQueries = mutableSetOf<LocaleQuery>()

    companion object {
        const val CHANNEL = "plugin.csdcorp.com/speech_to_text"
        const val PERMISSION_REQUEST = 8317
        private const val LOCALE_TIMEOUT_MS = 4000L
    }

    init { channel.setMethodCallHandler(this) }

    fun onDeviceAvailable(): Boolean = !destroyed &&
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        try { SpeechRecognizer.isOnDeviceRecognitionAvailable(activity) }
        catch (_: Exception) { false }

    private fun microphoneGranted(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (destroyed) {
            result.error("recognizer_unavailable", "Die lokale Spracheingabe ist geschlossen.", null)
            return
        }
        when (call.method) {
            "has_permission" -> result.success(microphoneGranted())
            "initialize" -> initialize(result)
            "has_on_device_support" -> {
                val locale = call.argument<String>("localeId")?.replace('_', '-')
                if (locale == null) result.success(onDeviceAvailable())
                else if (Build.VERSION.SDK_INT < 33) result.success(false)
                else queryLocales { languages ->
                    result.success(languages.any { it.equals(locale, ignoreCase = true) })
                }
            }
            "locales" -> queryLocales { languages ->
                result.success(languages.map { language ->
                    val locale = Locale.forLanguageTag(language)
                    "$language:${locale.getDisplayName(Locale.GERMAN)}"
                })
            }
            "listen" -> listen(call, result)
            "stop" -> {
                val current = recognizer
                if (current == null) result.success(false)
                else try {
                    current.stopListening()
                    status("notListening")
                    result.success(true)
                } catch (_: Exception) {
                    cancelCapture()
                    result.error("recognizer_unavailable", "Die Spracheingabe wurde beendet.", null)
                }
            }
            "cancel" -> {
                cancelCapture()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: MethodChannel.Result) {
        if (!onDeviceAvailable()) {
            result.success(false)
            return
        }
        if (microphoneGranted()) {
            result.success(true)
            return
        }
        if (pendingPermission != null || !foreground) {
            result.success(false)
            return
        }
        pendingPermission = result
        try {
            activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST)
        } catch (_: Exception) {
            pendingPermission = null
            result.success(false)
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>,
        grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val pending = pendingPermission
        pendingPermission = null
        val index = permissions.indexOf(Manifest.permission.RECORD_AUDIO)
        val granted = index >= 0 && index < grantResults.size &&
            grantResults[index] == PackageManager.PERMISSION_GRANTED
        pending?.success(granted && microphoneGranted() && onDeviceAvailable())
        return true
    }

    private fun listen(call: MethodCall, result: MethodChannel.Result) {
        if (call.argument<Boolean>("onDevice") != true) {
            result.error("on_device_required", "Lumo verwendet ausschließlich lokale Spracherkennung.", null)
            return
        }
        if (!foreground || !microphoneGranted() || !onDeviceAvailable()) {
            result.error("recognizer_unavailable", "Die lokale Spracheingabe ist nicht bereit.", null)
            return
        }
        val language = (call.argument<String>("localeId") ?: "de-DE").replace('_', '-')
        if (!language.matches(Regex("[a-zA-Z]{2,8}(-[a-zA-Z0-9]{1,8})*"))) {
            result.error("invalid_language", "Die Spracheingabe benötigt eine gültige Sprache.", null)
            return
        }
        cancelCapture()
        val token = generation
        try {
            // Recheck and creation occur on the same UI-thread operation.
            // If the service disappears, creation fails. There is no default
            // recognizer, intent lookup or remote recognition alternative.
            val capture = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
            recognizer = capture
            capture.setRecognitionListener(object : RecognitionListener {
                private fun current() = !destroyed && foreground &&
                    generation == token && recognizer === capture
                override fun onReadyForSpeech(params: Bundle?) {
                    if (current()) status("listening")
                }
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {
                    if (current() && rmsdB.isFinite())
                        channel.invokeMethod("soundLevelChange", rmsdB.toDouble())
                }
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    if (current()) status("notListening")
                }
                override fun onPartialResults(partialResults: Bundle?) {
                    if (current()) publishWords(partialResults, false)
                }
                override fun onResults(results: Bundle?) {
                    if (!current()) return
                    val delivered = publishWords(results, true)
                    finishCapture(token, delivered)
                }
                override fun onError(error: Int) {
                    if (!current()) return
                    channel.invokeMethod("notifyError", JSONObject()
                        .put("errorMsg", errorName(error))
                        .put("permanent", error != SpeechRecognizer.ERROR_NO_MATCH &&
                            error != SpeechRecognizer.ERROR_SPEECH_TIMEOUT).toString())
                    finishCapture(token, false)
                }
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                .putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS,
                    call.argument<Boolean>("partialResults") != false)
                .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 8)
                .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            capture.startListening(intent)
            // 'listening' is emitted by onReadyForSpeech, not by this return.
            result.success(true)
        } catch (_: Exception) {
            cancelCapture()
            result.error("recognizer_unavailable", "Die lokale Spracheingabe konnte nicht starten.", null)
        }
    }

    private fun publishWords(bundle: Bundle?, finalResult: Boolean): Boolean {
        val words = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION).orEmpty()
        if (words.isEmpty()) return false
        val confidences = bundle?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
        val alternatives = JSONArray()
        words.take(8).forEachIndexed { index, text ->
            val confidence = confidences?.getOrNull(index)?.takeIf {
                it.isFinite() && it >= 0f && it <= 1f
            }?.toDouble() ?: -1.0
            alternatives.put(JSONObject().put("recognizedWords", text)
                .put("recognizedPhrases", JSONObject.NULL).put("confidence", confidence))
        }
        channel.invokeMethod("textRecognition", JSONObject()
            .put("alternates", alternatives).put("resultType", if (finalResult) 2 else 0).toString())
        return words.firstOrNull()?.isNotBlank() == true
    }

    private fun errorName(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_AUDIO -> "error_audio_error"
        SpeechRecognizer.ERROR_CLIENT -> "error_client"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "error_permission"
        SpeechRecognizer.ERROR_NETWORK -> "error_network"
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "error_network_timeout"
        SpeechRecognizer.ERROR_NO_MATCH -> "error_no_match"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "error_busy"
        SpeechRecognizer.ERROR_SERVER -> "error_server"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "error_speech_timeout"
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "error_language_not_supported"
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "error_language_unavailable"
        else -> "error_recognizer_unavailable"
    }

    private fun finishCapture(token: Long, delivered: Boolean) {
        if (token != generation) return
        releaseCapture()
        status("notListening")
        status(if (delivered) "done" else "doneNoResult")
    }

    private fun releaseCapture() {
        generation++
        val previous = recognizer
        recognizer = null
        try { previous?.cancel() } catch (_: Exception) {}
        try { previous?.destroy() } catch (_: Exception) {}
    }

    private fun cancelCapture() {
        val hadCapture = recognizer != null
        releaseCapture()
        if (hadCapture) {
            status("notListening")
            status("doneNoResult")
        }
    }

    private fun status(value: String) { channel.invokeMethod("notifyStatus", value) }

    private inner class LocaleQuery(
        val recognizer: SpeechRecognizer,
        val complete: (List<String>) -> Unit
    ) {
        var finished = false
        val deadline = Runnable { finish(emptyList()) }
        fun finish(languages: List<String>) {
            if (finished) return
            finished = true
            main.removeCallbacks(deadline)
            localeQueries.remove(this)
            try { recognizer.destroy() } catch (_: Exception) {}
            complete(languages)
        }
    }

    private fun queryLocales(complete: (List<String>) -> Unit) {
        if (!onDeviceAvailable() || !microphoneGranted()) {
            complete(emptyList())
            return
        }
        if (Build.VERSION.SDK_INT < 33) {
            // API31-32 cannot enumerate installed local models. German is a
            // candidate only; listen still either runs locally or fails.
            complete(listOf("de-DE"))
            return
        }
        var query: LocaleQuery? = null
        try {
            val local = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
            val pending = LocaleQuery(local, complete)
            query = pending
            localeQueries.add(pending)
            main.postDelayed(pending.deadline, LOCALE_TIMEOUT_MS)
            local.checkRecognitionSupport(
                Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                    .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM),
                executor,
                object : RecognitionSupportCallback {
                    override fun onSupportResult(support: RecognitionSupport) {
                        pending.finish(support.installedOnDeviceLanguages
                            .map { it.replace('_', '-') }.distinct())
                    }
                    override fun onError(error: Int) { pending.finish(emptyList()) }
                })
        } catch (_: Exception) {
            if (query != null) query.finish(emptyList()) else complete(emptyList())
        }
    }

    fun setForeground(value: Boolean) {
        if (destroyed) return
        foreground = value
        if (!value) {
            cancelCapture()
            localeQueries.toList().forEach { it.finish(emptyList()) }
        }
    }

    fun destroy() {
        if (destroyed) return
        setForeground(false)
        destroyed = true
        pendingPermission?.success(false)
        pendingPermission = null
        channel.setMethodCallHandler(null)
    }
}
