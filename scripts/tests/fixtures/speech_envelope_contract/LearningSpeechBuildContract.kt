package dev.ullmann.lumo

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import org.json.JSONObject
import java.io.File
import kotlin.math.abs

private var checks = 0

private fun verify(condition: Boolean, label: String) {
    checks++
    check(condition) { label }
}

private fun options(
    game: String = "build",
    voice: Boolean = true,
    licensed: Boolean = true,
    rate: Double = 1.3,
) = JSONObject().put("game", game)
    .put("learningVoiceEnabled", voice)
    .put("localVoiceLicenseAccepted", licensed)
    .put("learningVoiceRate", rate)

private fun request(id: Int) = "{\"id\":$id,\"text\":\"Apfel\",\"style\":\"explain\"}"

private fun prepare(speech: LumoLearningSpeech, bytes: ByteArray, id: Int): MediaPlayer {
    val calls = LumoOfflineSpeechBridge.calls
    verify(speech.speak(request(id)), "Licensed active build accepts the original speech request")
    Handler.drain()
    verify(LumoOfflineSpeechBridge.calls == calls + 1, "Build reaches the same local synthesis bridge once")
    val pending = checkNotNull(LumoOfflineSpeechBridge.pending)
    pending.success(mapOf("wav" to bytes))
    val deadline = System.nanoTime() + 2_000_000_000L
    while (Handler.pending() == 0 && System.nanoTime() < deadline) Thread.sleep(1)
    check(Handler.pending() > 0) { "The envelope worker did not complete within the fixture deadline" }
    Handler.drain()
    return checkNotNull(MediaPlayer.latest)
}

fun main(args: Array<String>) {
    val clip = File(args.single()).readBytes()
    for ((rate, expected) in listOf(1.3 to 1.3f, 0.1 to 0.70f, 9.0 to 1.60f)) {
        val context = Context()
        val speech = LumoLearningSpeech(context, options(rate = rate))
        speech.setActive(true)
        Handler.drain()
        val player = prepare(speech, clip, 31)
        verify(!player.isPlaying, "Deriving the build envelope does not start playback")
        checkNotNull(player.prepared).invoke(player)
        Handler.drain()
        player.currentPosition = 300
        Handler.advance()
        val playing = JSONObject(speech.status())
        verify(abs(player.playbackParams.rate - expected) < 0.0001f,
            "The existing playback rate and its bounds are retained for build")
        verify(playing.optInt("id") == 31 && playing.optInt("positionMs") == 300 &&
            playing.optString("state") == "playing" && playing.optBoolean("audible") &&
            playing.optBoolean("envelopeAvailable") && playing.optDouble("envelope") > 0.0,
            "Build exposes the measured PCM at the actual matching playback position")
        speech.setActive(false)
        Handler.drain()
        val idle = JSONObject(speech.status())
        verify(player.released && idle.optString("state") == "idle" &&
            !idle.optBoolean("audible") && idle.optDouble("envelope") == 0.0,
            "Activity pause releases build playback and immediately closes articulation")
        speech.destroy()
        Handler.drain()
    }

    for (game in listOf("learning", "build")) {
        for ((voice, licensed) in listOf(false to true, true to false, false to false)) {
            val speech = LumoLearningSpeech(Context(), options(game, voice, licensed))
            speech.setActive(true)
            Handler.drain()
            val calls = LumoOfflineSpeechBridge.calls
            verify(!speech.speak(request(41)) && LumoOfflineSpeechBridge.calls == calls,
                "Both existing consent gates remain required for $game")
            speech.destroy()
            Handler.drain()
        }
    }
    for (game in listOf("kart", "cards", "treasure", "")) {
        val speech = LumoLearningSpeech(Context(), options(game = game))
        speech.setActive(true)
        Handler.drain()
        val calls = LumoOfflineSpeechBridge.calls
        verify(!speech.speak(request(42)) && LumoOfflineSpeechBridge.calls == calls,
            "The learning/build allow-list is not widened to another scene")
        speech.destroy()
        Handler.drain()
    }

    val inactive = LumoLearningSpeech(Context(), options())
    val calls = LumoOfflineSpeechBridge.calls
    inactive.speak(request(51))
    Handler.drain()
    verify(LumoOfflineSpeechBridge.calls == calls, "Inactive build cannot begin local synthesis")
    inactive.setActive(true)
    Handler.drain()
    inactive.speak(request(52))
    Handler.drain()
    val late = checkNotNull(LumoOfflineSpeechBridge.pending)
    val created = MediaPlayer.created
    inactive.setActive(false)
    Handler.drain()
    late.success(mapOf("wav" to clip))
    Handler.drain()
    verify(MediaPlayer.created == created && JSONObject(inactive.status()).optString("state") == "idle",
        "A build synthesis result after pause cannot create a player")
    inactive.destroy()
    Handler.drain()

    println("LUMO_BUILD_SPEECH_PASS checks=$checks platform=synthetic_JVM_boundary no_Android_playback_claim=true")
}
