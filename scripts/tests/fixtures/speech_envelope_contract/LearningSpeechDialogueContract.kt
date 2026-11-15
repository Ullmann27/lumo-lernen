package dev.ullmann.lumo

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import org.json.JSONObject
import java.io.File

private var dialogueChecks = 0
private fun ensure(value: Boolean, message: String) {
    dialogueChecks++
    check(value) { message }
}

private fun scopedRequest(id: Int, revision: Int = 2, task: String = "bridge-ten",
    session: String = "session-1", utterance: String = "utterance-$id") = JSONObject()
    .put("id", id).put("text", "Fülle zuerst die beiden freien Plätze.")
    .put("style", "explain").put("sessionId", session).put("taskId", task)
    .put("turnId", "turn-$id").put("utteranceId", utterance)
    .put("contextRevision", revision).toString()

private fun completeSynthesis(bytes: ByteArray): MediaPlayer {
    val previous = MediaPlayer.latest
    checkNotNull(LumoOfflineSpeechBridge.pending).success(mapOf("wav" to bytes))
    val deadline = System.nanoTime() + 2_000_000_000L
    while (System.nanoTime() < deadline) {
        Handler.drain()
        val next = MediaPlayer.latest
        if (next != null && next !== previous) return next
        Thread.sleep(1)
    }
    error("Actual envelope worker failed to prepare within the fixture deadline")
}

fun main(args: Array<String>) {
    val wave = File(args.single()).readBytes()
    val context = Context()
    val options = JSONObject().put("game", "learning").put("learningVoiceEnabled", true)
        .put("localVoiceLicenseAccepted", true).put("sessionId", "session-1")
    val speech = LumoLearningSpeech(context, options)
    ensure(JSONObject(speech.status()).optInt("scopeVersion") == 1,
        "Existing status advertises the optional scope extension")
    speech.setActive(true)
    Handler.drain()
    ensure(speech.speak(scopedRequest(71)), "Checked scoped request is accepted")
    Handler.drain()
    val preparing = JSONObject(speech.status())
    for ((key, value) in mapOf("sessionId" to "session-1", "taskId" to "bridge-ten",
        "turnId" to "turn-71", "utteranceId" to "utterance-71")) {
        ensure(preparing.optString(key) == value, "Exact $key accompanies synthesis state")
    }
    ensure(preparing.optInt("contextRevision") == 2 && !preparing.optBoolean("audible"),
        "Preparation has the exact revision and does not claim audio")
    val player = completeSynthesis(wave)
    checkNotNull(player.prepared).invoke(player)
    Handler.drain()
    player.currentPosition = 300
    Handler.advance()
    val playing = JSONObject(speech.status())
    ensure(playing.optString("utteranceId") == "utterance-71" &&
        playing.optInt("positionMs") == 300 && playing.optDouble("envelope") > 0,
        "Scope, measured envelope and actual media position share one playback")
    ensure(context.audioManager.requested == 1 &&
        context.audioManager.lastRequest?.pauseOnDuck == true,
        "Speech requests audio focus and does not continue over transient duck interruptions")
    val calls = LumoOfflineSpeechBridge.calls
    for (invalid in listOf(scopedRequest(71), scopedRequest(72, revision = 1),
        scopedRequest(73, task = "syllables"), scopedRequest(74, session = "foreign"),
        scopedRequest(75).replace("\"contextRevision\":2", "\"contextRevision\":2.5"),
        scopedRequest(76).replace("\"contextRevision\":2", "\"contextRevision\":true"),
        scopedRequest(77).replace("\"turnId\":\"turn-77\",", ""))) {
        ensure(!speech.speak(invalid), "Malformed, duplicate or outdated context is rejected")
    }
    Handler.drain()
    ensure(LumoOfflineSpeechBridge.calls == calls && player.isPlaying,
        "Rejected requests neither synthesize nor interrupt the valid playback")
    val oldFocus = checkNotNull(context.audioManager.listener)
    oldFocus.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK)
    Handler.drain()
    val interrupted = JSONObject(speech.status())
    ensure(player.released && interrupted.optString("state") == "interrupted" &&
        !interrupted.optBoolean("audible") && interrupted.optDouble("envelope") == 0.0,
        "Audio interruption releases audio and reports a closed mouth immediately")
    oldFocus.onAudioFocusChange(AudioManager.AUDIOFOCUS_GAIN)
    Handler.drain()
    ensure(MediaPlayer.latest === player && !player.isPlaying,
        "Restored audio focus does not automatically replay a cancelled explanation")
    ensure(speech.speak(scopedRequest(81, revision = 3, task = "syllables")),
        "New task is accepted only with a new context revision")
    Handler.drain()
    val next = completeSynthesis(wave)
    checkNotNull(next.prepared).invoke(next)
    Handler.drain()
    oldFocus.onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS)
    Handler.drain()
    ensure(next.isPlaying && !next.released && JSONObject(speech.status()).optString("taskId") == "syllables",
        "A late interruption callback from the old task cannot stop its successor")
    speech.stop()
    Handler.drain()
    ensure(!next.isPlaying && next.released && context.audioManager.abandoned >= 2,
        "Explicit stop releases both playback and focus")
    context.audioManager.focusResult = 0
    ensure(speech.speak(scopedRequest(82, revision = 3, task = "syllables")),
        "Focus availability is checked when the real audio is ready")
    Handler.drain()
    val denied = completeSynthesis(wave)
    checkNotNull(denied.prepared).invoke(denied)
    Handler.drain()
    ensure(denied.released && !denied.isPlaying && JSONObject(speech.status()).optString("state") == "unavailable",
        "Denied audio focus cannot produce speech or a playing snapshot")
    context.audioManager.focusResult = 1
    Build.VERSION.SDK_INT = 25
    ensure(speech.speak(scopedRequest(83, revision = 3, task = "syllables")),
        "Existing pre-26 Android path remains supported")
    Handler.drain()
    val legacy = completeSynthesis(wave)
    checkNotNull(legacy.prepared).invoke(legacy)
    Handler.drain()
    ensure(context.audioManager.legacyRequests == 1 && legacy.isPlaying,
        "Pre-26 devices use their actual legacy focus API")
    speech.destroy()
    Handler.drain()
    Build.VERSION.SDK_INT = 36
    ensure(legacy.released && !speech.speak(scopedRequest(84)), "Destroyed session rejects new speech")
    println("LUMO_DIALOGUE_SPEECH_PASS checks=$dialogueChecks platform=synthetic_JVM_boundary no_Android_playback_claim=true")
}
