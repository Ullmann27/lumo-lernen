package android.speech

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import java.util.concurrent.Executor

interface RecognitionListener {
    fun onReadyForSpeech(params: Bundle?)
    fun onBeginningOfSpeech()
    fun onRmsChanged(rmsdB: Float)
    fun onBufferReceived(buffer: ByteArray?)
    fun onEndOfSpeech()
    fun onPartialResults(partialResults: Bundle?)
    fun onResults(results: Bundle?)
    fun onError(error: Int)
    fun onEvent(eventType: Int, params: Bundle?)
}
class RecognitionSupport(val installedOnDeviceLanguages: List<String>,
    val supportedOnDeviceLanguages: List<String> = emptyList())
interface RecognitionSupportCallback {
    fun onSupportResult(support: RecognitionSupport)
    fun onError(error: Int)
}
object RecognizerIntent {
    const val ACTION_RECOGNIZE_SPEECH = "recognize"
    const val EXTRA_LANGUAGE_MODEL = "languageModel"
    const val LANGUAGE_MODEL_FREE_FORM = "freeForm"
    const val EXTRA_LANGUAGE = "language"
    const val EXTRA_PARTIAL_RESULTS = "partial"
    const val EXTRA_MAX_RESULTS = "maximum"
    const val EXTRA_PREFER_OFFLINE = "offline"
}

class SpeechRecognizer {
    lateinit var listener: RecognitionListener
    var support: RecognitionSupportCallback? = null
    var intent: Intent? = null
    var active = false
    var destroyed = false
    var stopCalls = 0
    fun setRecognitionListener(value: RecognitionListener) { listener = value }
    fun startListening(value: Intent) { check(!destroyed); intent = value; active = true }
    fun stopListening() { stopCalls++; active = false }
    fun cancel() { active = false }
    fun destroy() { active = false; destroyed = true }
    fun checkRecognitionSupport(intent: Intent, executor: Executor, callback: RecognitionSupportCallback) {
        support = callback
    }
    companion object {
        const val RESULTS_RECOGNITION = "results"
        const val CONFIDENCE_SCORES = "confidence"
        const val ERROR_NETWORK_TIMEOUT = 1
        const val ERROR_NETWORK = 2
        const val ERROR_AUDIO = 3
        const val ERROR_SERVER = 4
        const val ERROR_CLIENT = 5
        const val ERROR_SPEECH_TIMEOUT = 6
        const val ERROR_NO_MATCH = 7
        const val ERROR_RECOGNIZER_BUSY = 8
        const val ERROR_INSUFFICIENT_PERMISSIONS = 9
        const val ERROR_LANGUAGE_NOT_SUPPORTED = 12
        const val ERROR_LANGUAGE_UNAVAILABLE = 13
        var localAvailable = true
        var disappearDuringCreate = false
        var defaultCreates = 0
        val created = mutableListOf<SpeechRecognizer>()
        fun isOnDeviceRecognitionAvailable(activity: Activity): Boolean = localAvailable
        fun createOnDeviceSpeechRecognizer(activity: Activity): SpeechRecognizer {
            if (!localAvailable || disappearDuringCreate) throw UnsupportedOperationException()
            return SpeechRecognizer().also { created.add(it) }
        }
        fun createSpeechRecognizer(activity: Activity): SpeechRecognizer {
            defaultCreates++
            return SpeechRecognizer().also { created.add(it) }
        }
    }
}
