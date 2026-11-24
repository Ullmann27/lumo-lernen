package dev.ullmann.lumo

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.speech.RecognitionSupport
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

private var checks = 0
private fun verify(value: Boolean, reason: String) { check(value) { reason }; checks++ }
private class Reply : MethodChannel.Result {
    var completions = 0
    var value: Any? = null
    var error: String? = null
    var missing = false
    override fun success(value: Any?) { check(completions++ == 0); this.value = value }
    override fun error(code: String, message: String?, details: Any?) {
        check(completions++ == 0); error = code
    }
    override fun notImplemented() { check(completions++ == 0); missing = true }
}
private fun call(name: String, args: Map<String, Any?> = emptyMap()): Reply = Reply().also {
    checkNotNull(MethodChannel.latest.handler).onMethodCall(MethodCall(name, args), it)
}
private fun words(text: String, confidence: Float = .9f): Bundle = Bundle().apply {
    values[SpeechRecognizer.RESULTS_RECOGNITION] = arrayListOf(text, "alternative")
    values[SpeechRecognizer.CONFIDENCE_SCORES] = floatArrayOf(confidence, .3f)
}

fun main() {
    val activity = Activity()
    val bridge = LumoLocalRecognition(activity, object : BinaryMessenger {})
    bridge.setForeground(true)
    val channel = MethodChannel.latest
    verify(channel.name == LumoLocalRecognition.CHANNEL, "Pinned Dart API uses the same channel")
    verify(call("has_permission").value == true, "Has-permission is answered")
    verify(call("unknown-method").missing, "Unknown method is answered, not left pending")

    SpeechRecognizer.localAvailable = false
    verify(call("initialize").value == false, "No local service refuses initialization")
    verify(SpeechRecognizer.created.isEmpty(), "No recognizer created without local capability")
    verify(call("has_on_device_support").value == false, "Local support never reports network availability")
    SpeechRecognizer.localAvailable = true
    activity.permission = false
    val denied = call("initialize")
    verify(denied.completions == 0 && activity.permissionRequests == 1,
        "Initialization waits for the actual Android permission result")
    bridge.onRequestPermissionsResult(LumoLocalRecognition.PERMISSION_REQUEST,
        arrayOf(Manifest.permission.RECORD_AUDIO), intArrayOf(PackageManager.PERMISSION_DENIED))
    verify(denied.value == false && denied.completions == 1, "Denied microphone has one false result")
    verify(SpeechRecognizer.created.isEmpty(), "Denied microphone never starts a recorder")
    val granted = call("initialize")
    activity.permission = true
    bridge.onRequestPermissionsResult(LumoLocalRecognition.PERMISSION_REQUEST,
        arrayOf(Manifest.permission.RECORD_AUDIO), intArrayOf(PackageManager.PERMISSION_GRANTED))
    verify(granted.value == true && granted.completions == 1, "Permission grant resolves once")
    verify(!bridge.onRequestPermissionsResult(77, emptyArray(), intArrayOf()), "Foreign permission request is ignored")
    verify(call("listen", mapOf("onDevice" to false)).error == "on_device_required",
        "Every network-capable request is rejected at the native boundary")

    val args = mapOf("onDevice" to true, "localeId" to "de_DE", "partialResults" to true)
    SpeechRecognizer.disappearDuringCreate = true
    verify(call("listen", args).error == "recognizer_unavailable",
        "A service disappearing between check and creation fails closed")
    verify(SpeechRecognizer.defaultCreates == 0, "No default recognizer is a fallback")
    SpeechRecognizer.disappearDuringCreate = false
    channel.events.clear()
    verify(call("listen", args).value == true, "Valid request reaches local capture")
    val first = SpeechRecognizer.created.last()
    verify(first.intent!!.extras[RecognizerIntent.EXTRA_LANGUAGE] == "de-DE", "Locale normalization is preserved")
    verify(first.intent!!.extras[RecognizerIntent.EXTRA_PREFER_OFFLINE] == true, "Intent also prefers offline")
    verify(channel.events.none { it == ("notifyStatus" to "listening") }, "Return does not invent ready-for-speech")
    first.listener.onReadyForSpeech(Bundle())
    verify(channel.events.last() == ("notifyStatus" to "listening"), "Ready follows actual recognizer callback")
    first.listener.onPartialResults(words("drei"))
    var transcript = JSONObject(channel.events.last().second as String)
    verify(transcript.getInt("resultType") == 0, "Partial result retains partial schema")
    val beforeBuffer = channel.events.size
    first.listener.onBufferReceived(byteArrayOf(1, 2, 3))
    verify(channel.events.size == beforeBuffer, "Raw samples are neither forwarded nor retained")
    verify(call("stop").value == true && first.stopCalls == 1, "Stop asks the current recognizer for a final")
    verify(!first.destroyed, "Stop leaves time for the real final result")
    first.listener.onResults(words("ich meinte dreizehn", -1f))
    transcript = JSONObject(channel.events.last { it.first == "textRecognition" }.second as String)
    verify(transcript.getInt("resultType") == 2, "Native final retains final schema")
    verify(transcript.getJSONArray("alternates").getJSONObject(0).getString("recognizedWords") == "ich meinte dreizehn",
        "Actual final self-correction reaches Dart")
    verify(transcript.getJSONArray("alternates").getJSONObject(0).getDouble("confidence") == -1.0,
        "Unknown confidence remains unknown")
    verify(first.destroyed && channel.events.last() == ("notifyStatus" to "done"), "Final ends capture and marks done")

    verify(call("listen", args).value == true, "Next turn starts without another permission request")
    val second = SpeechRecognizer.created.last()
    val beforeStale = channel.events.size
    first.listener.onPartialResults(words("alte Aufgabe"))
    first.listener.onResults(words("alter Nachlauf"))
    first.listener.onError(SpeechRecognizer.ERROR_NO_MATCH)
    verify(channel.events.size == beforeStale, "Old native object cannot publish into the new turn")
    second.listener.onReadyForSpeech(Bundle())
    second.listener.onPartialResults(words("Warum zuerst zwei"))
    verify(call("cancel").value == true && second.destroyed, "Cancel destroys the exact capture")
    val afterCancel = channel.events.size
    second.listener.onResults(words("alte Antwort"))
    verify(channel.events.size == afterCancel, "Late result after cancel is discarded")

    call("listen", args)
    val background = SpeechRecognizer.created.last()
    bridge.setForeground(false)
    verify(background.destroyed, "Background transition destroys microphone")
    verify(call("listen", args).error != null, "Background cannot start a microphone")
    bridge.setForeground(true)
    activity.permission = false
    verify(call("listen", args).error != null, "Revoked permission checked for every capture")
    activity.permission = true
    call("listen", args)
    val noisy = SpeechRecognizer.created.last()
    noisy.listener.onError(SpeechRecognizer.ERROR_SPEECH_TIMEOUT)
    val failure = JSONObject(channel.events.last { it.first == "notifyError" }.second as String)
    verify(failure.getString("errorMsg") == "error_speech_timeout" && !failure.getBoolean("permanent"),
        "A quiet child is a recoverable no-match, never an invented transcript")
    verify(noisy.destroyed, "Error releases native capture")

    val locales = call("locales")
    val localeProbe = SpeechRecognizer.created.last()
    localeProbe.support!!.onSupportResult(RecognitionSupport(listOf("de_DE", "en-US"), listOf("fr-FR")))
    val names = locales.value as List<*>
    verify(names.size == 2 && names.any { (it as String).startsWith("de-DE:") },
        "Locale query returns installed local languages")
    verify(names.none { (it as String).startsWith("fr-FR:") }, "Downloadable model is not called installed")
    verify(localeProbe.destroyed, "Locale query releases its recognizer")
    val unsupported = call("locales")
    SpeechRecognizer.created.last().support!!.onError(SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE)
    verify(unsupported.value == emptyList<String>() && unsupported.completions == 1,
        "Locale query error answers instead of leaving the channel hanging")
    val timedOut = call("locales")
    val stalled = SpeechRecognizer.created.last()
    Handler.advanceDeadlines()
    verify(timedOut.value == emptyList<String>() && timedOut.completions == 1 && stalled.destroyed,
        "Missing locale callback reaches a bounded false result")
    stalled.support!!.onSupportResult(RecognitionSupport(listOf("de-DE")))
    verify(timedOut.completions == 1, "Late locale result cannot answer twice")
    val localeSupport = call("has_on_device_support", mapOf("localeId" to "de_DE"))
    SpeechRecognizer.created.last().support!!.onSupportResult(RecognitionSupport(listOf("de-DE")))
    verify(localeSupport.value == true, "Platform-interface locale-specific support is answered")

    Build.VERSION.SDK_INT = 31
    verify((call("locales").value as List<*>).first().toString().startsWith("de-DE:"),
        "API31-32 supplies a German candidate without claiming a downloaded model")
    verify(call("has_on_device_support", mapOf("localeId" to "de-DE")).value == false,
        "Unqueryable per-language support stays unconfirmed")
    Build.VERSION.SDK_INT = 30
    verify(call("initialize").value == false, "Pre-on-device Android cannot use the default recognizer")
    Build.VERSION.SDK_INT = 36
    activity.permission = false
    val pending = call("initialize")
    bridge.destroy()
    verify(pending.value == false && pending.completions == 1, "Destroy resolves a waiting permission request")
    verify(channel.handler == null, "Destroy detaches the native handler")
    verify(SpeechRecognizer.defaultCreates == 0, "Entire sequence created zero network-capable recognizers")
    verify(SpeechRecognizer.created.all { it.destroyed }, "Entire sequence leaves no active recognizer")
    println("LUMO_LOCAL_RECOGNITION_PASS checks=$checks platform=synthetic_JVM_boundary no_Android_microphone_claim=true")
}
