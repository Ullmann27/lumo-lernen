package dev.ullmann.lumo

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import org.json.JSONObject
import java.io.File

private var checks = 0

private fun verify(condition: Boolean, label: String) {
    checks++
    check(condition) { label }
}

private fun options(voice: Boolean = true, licensed: Boolean = true,
                    optedIn: Boolean = true, mode: String = "settlement") = JSONObject()
    .put("game", "settlement").put("livingVillage", optedIn).put("settlementMode", mode)
    .put("sessionId", "settlement-session").put("childKey", "settlement-child")
    .put("learningVoiceEnabled", voice).put("localVoiceLicenseAccepted", licensed)

private fun request(id: Int) = JSONObject()
    .put("protocolVersion", 1).put("sessionId", "settlement-session")
    .put("taskId", "village-tutorial").put("stepId", "welcome")
    .put("revision", 0).put("cancelEpoch", id).put("id", id)
    .put("text", "Schön, dass du da bist.").put("style", "explain").toString()

private fun close(speech: LumoLearningSpeech) {
    speech.destroy()
    Handler.drain()
}

fun main(args: Array<String>) {
    val clip = File(args.single()).readBytes()
    val speech = LumoLearningSpeech(Context(), options())
    speech.setActive(true)
    Handler.drain()
    val calls = LumoOfflineSpeechBridge.defaultCalls
    val players = MediaPlayer.created
    verify(speech.speak(request(1)), "The explicitly selected licensed village accepts its tutorial speech")
    Handler.drain()
    verify(LumoOfflineSpeechBridge.defaultCalls == calls + 1 &&
        LumoOfflineSpeechBridge.lastWord == null, "Village uses the existing German synthesis path once")
    checkNotNull(LumoOfflineSpeechBridge.pending).success(mapOf("wav" to clip))
    val deadline = System.nanoTime() + 2_000_000_000L
    while (Handler.pending() == 0 && System.nanoTime() < deadline) Thread.sleep(1)
    check(Handler.pending() > 0) { "Village envelope worker did not finish" }
    Handler.drain()
    val player = checkNotNull(MediaPlayer.latest)
    verify(MediaPlayer.created == players + 1 && !player.isPlaying,
        "Village prepares one player without pretending analysis is playback")
    checkNotNull(player.prepared).invoke(player)
    Handler.drain()
    player.currentPosition = 300
    Handler.advance()
    val playing = JSONObject(speech.status())
    verify(playing.optInt("id") == 1 && playing.optString("state") == "playing" &&
        playing.optBoolean("audible") && playing.optInt("positionMs") == 300 &&
        playing.optDouble("envelope") > 0.0, "Village publishes measured articulation for the active utterance")
    speech.setActive(false)
    Handler.drain()
    verify(player.released && JSONObject(speech.status()).optString("state") == "idle",
        "Leaving the village releases playback")
    checkNotNull(player.completed).invoke(player)
    Handler.drain()
    verify(JSONObject(speech.status()).optString("state") == "idle",
        "A late completion cannot replace the paused state")
    val pausedCalls = LumoOfflineSpeechBridge.calls
    speech.speak(request(2))
    Handler.drain()
    verify(LumoOfflineSpeechBridge.calls == pausedCalls, "Paused village cannot start new synthesis")
    speech.setActive(true)
    Handler.drain()
    verify(speech.speak(request(3)), "A resumed village can request a new utterance")
    Handler.drain()
    val late = checkNotNull(LumoOfflineSpeechBridge.pending)
    val created = MediaPlayer.created
    close(speech)
    late.success(mapOf("wav" to clip))
    Handler.drain()
    verify(MediaPlayer.created == created && JSONObject(speech.status()).optString("state") == "idle",
        "Destroyed village cannot create playback from a late synthesis result")

    for (blocked in listOf(options(voice = false), options(licensed = false),
            options(voice = false, licensed = false), options(optedIn = false), options(mode = "build"))) {
        val denied = LumoLearningSpeech(Context(), blocked)
        denied.setActive(true)
        Handler.drain()
        val before = LumoOfflineSpeechBridge.calls
        verify(!denied.speak(request(4)), "Village requires both parent gates and the explicit village selection")
        Handler.drain()
        verify(LumoOfflineSpeechBridge.calls == before, "Refused village requests never begin synthesis")
        close(denied)
    }
    println("LUMO_SETTLEMENT_SPEECH_PASS checks=$checks platform=synthetic_JVM_boundary no_Android_playback_claim=true")
}
