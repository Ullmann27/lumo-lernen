package dev.ullmann.lumo

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

private var checks = 0
private fun verify(ok: Boolean, label: String) { checks++; check(ok) { label } }
private val meanings = linkedMapOf(
    "book" to "Buch", "pen" to "Kugelschreiber", "ruler" to "Lineal",
    "ball" to "Ball", "car" to "Auto", "sun" to "Sonne", "apple" to "Apfel",
    "bag" to "Tasche", "rubber" to "Radiergummi", "school bag" to "Schultasche",
    "desk" to "Schreibtisch", "chair" to "Sessel", "pencil case" to "Federpennal",
    "paper" to "Papier"
)
private fun options(word: String = "book", meaning: String = meanings[word] ?: "unknown",
    objects: List<Any?> = listOf(word) + meanings.keys.filter { it != word }.take(2),
    licensed: Boolean = true, enabled: Boolean = true): JSONObject = JSONObject()
    .put("game", "learning").put("learningVoiceEnabled", enabled)
    .put("localVoiceLicenseAccepted", licensed).put("learningVoiceRate", 1.0)
    .put("learning", JSONObject().put("kind", "english_objects").put("word", word)
        .put("meaning", meaning).put("objects", JSONArray(objects)))
private fun request(id: Int): String =
    "{\"id\":$id,\"text\":\"Tippe auf den Gegenstand.\",\"style\":\"explain\",\"englishWord\":\"paper\",\"language\":\"fr\"}"
private fun reply(clip: ByteArray, word: String = "book", language: String = "en-de") = mapOf(
    "wav" to clip, "englishWord" to word, "language" to language, "local" to true,
    "profile" to LumoOfflineSpeechEngine.PROFILE, "preset" to LumoOfflineSpeechEngine.PRESET,
    "sampleRate" to LumoOfflineSpeechEngine.SAMPLE_RATE
)
private fun prepared(): MediaPlayer {
    val deadline = System.nanoTime() + 2_000_000_000L
    while (Handler.pending() == 0 && System.nanoTime() < deadline) Thread.sleep(1)
    Handler.drain()
    return checkNotNull(MediaPlayer.latest)
}
private fun active(options: JSONObject): LumoLearningSpeech {
    val speech = LumoLearningSpeech(Context(), options)
    speech.setActive(true); Handler.drain(); return speech
}
private fun close(speech: LumoLearningSpeech) { speech.destroy(); Handler.drain() }

fun main(args: Array<String>) {
    require(args.size == 2)
    val clip = File(args[1]).readBytes() // Declared synthetic PCM fixture, not English speech.
    when (args[0]) {
        "binding" -> {
            for ((word, meaning) in meanings) {
                val speech = active(options(word, meaning))
                val before = LumoOfflineSpeechBridge.englishCalls
                verify(speech.speak(request(1)), "Closed current task accepts $word")
                Handler.drain()
                verify(LumoOfflineSpeechBridge.englishCalls == before + 1 &&
                    LumoOfflineSpeechBridge.lastWord == word,
                    "Host descriptor wins over forged request word/language for $word")
                verify(LumoOfflineSpeechBridge.lastText == "Tippe auf den Gegenstand.",
                    "German explanation is unchanged for $word")
                close(speech)
            }
            val mutable = options()
            val speech = active(mutable)
            mutable.optJSONObject("learning")!!.put("word", "paper").put("meaning", "Papier")
            verify(speech.speak(request(2)), "Captured descriptor remains usable")
            Handler.drain()
            verify(LumoOfflineSpeechBridge.lastWord == "book", "Later options mutation cannot replace captured task")
            close(speech)
        }
        "invalid-descriptor" -> {
            for (bad in listOf(options("dog"), options(meaning = "Papier"),
                options(objects = listOf("book", "book", "pen")),
                options(objects = listOf("pen", "ruler", "paper")),
                options(objects = listOf("book", "pen")),
                options(objects = listOf("book", "pen", 7)),
                options(objects = listOf("book", "pen", "dog")))) {
                val speech = active(bad); val before = LumoOfflineSpeechBridge.calls
                verify(!speech.speak(request(1)), "Invalid closed descriptor refused")
                Handler.drain()
                verify(LumoOfflineSpeechBridge.calls == before, "No synthesis for invalid descriptor")
                close(speech)
            }
        }
        "parent-and-default" -> {
            for (blocked in listOf(options(licensed = false), options(enabled = false))) {
                val speech = active(blocked); val before = LumoOfflineSpeechBridge.calls
                verify(!speech.speak(request(1)), "Parent gate blocks bilingual speech")
                Handler.drain()
                verify(LumoOfflineSpeechBridge.calls == before, "Blocked parent gate starts neither segment")
                close(speech)
            }
            val old = JSONObject().put("game", "learning").put("learningVoiceEnabled", true)
                .put("localVoiceLicenseAccepted", true)
                .put("learning", JSONObject().put("kind", "addition"))
            val speech = active(old); val before = LumoOfflineSpeechBridge.defaultCalls
            verify(speech.speak(request(1)), "Existing non-English lesson remains accepted")
            Handler.drain()
            verify(LumoOfflineSpeechBridge.defaultCalls == before + 1 &&
                LumoOfflineSpeechBridge.lastWord == null, "Old German bridge signature remains selected")
            close(speech)
        }
        "one-player" -> {
            val speech = active(options()); val before = MediaPlayer.created
            verify(speech.speak(request(1)), "Valid bilingual request accepted")
            Handler.drain(); LumoOfflineSpeechBridge.pending!!.success(reply(clip))
            val player = prepared()
            player.duration = 800 // Exact declared duration of this synthetic PCM boundary fixture.
            verify(MediaPlayer.created == before + 1 && !player.isPlaying,
                "Both segments prepare exactly one player; analysis is not playback")
            player.prepared!!(player); Handler.drain(); player.currentPosition = 50; Handler.advance()
            val first = JSONObject(speech.status())
            verify(first.optInt("id") == 1 && first.optInt("positionMs") == 50 &&
                first.optBoolean("audible") && first.optDouble("envelope") > 0.0,
                "First actual player position owns measured synthetic envelope")
            player.currentPosition = 300; Handler.advance()
            verify(JSONObject(speech.status()).optDouble("envelope") == 0.0,
                "PCM pause between segments closes the envelope")
            player.currentPosition = 500; Handler.advance()
            verify(JSONObject(speech.status()).optInt("id") == 1 &&
                JSONObject(speech.status()).optInt("positionMs") == 500 &&
                JSONObject(speech.status()).optDouble("envelope") > 0.0 &&
                MediaPlayer.created == before + 1, "DE segment keeps same player and request generation")
            speech.stop(); Handler.drain()
            verify(player.released && JSONObject(speech.status()).optString("state") == "idle",
                "Stop releases the entire joined sequence")
            close(speech)
        }
        "late-callback" -> {
            val speech = active(options()); speech.speak(request(1)); Handler.drain()
            val old = LumoOfflineSpeechBridge.pending!!; val before = MediaPlayer.created
            speech.setActive(false); Handler.drain(); old.success(reply(clip)); Handler.drain()
            verify(MediaPlayer.created == before && JSONObject(speech.status()).optString("state") == "idle",
                "Late bilingual result after Home/pause cannot start playback")
            speech.setActive(true); Handler.drain(); speech.speak(request(2)); Handler.drain()
            val earlier = LumoOfflineSpeechBridge.pending!!
            speech.speak(request(3)); Handler.drain(); earlier.success(reply(clip)); Handler.drain()
            verify(MediaPlayer.created == before && JSONObject(speech.status()).optInt("id") == 3,
                "Superseded bilingual generation cannot publish a player")
            val last = LumoOfflineSpeechBridge.pending!!; close(speech)
            last.success(reply(clip)); Handler.drain()
            verify(MediaPlayer.created == before, "Late result after return/destroy stays closed")
        }
        "result-identity" -> {
            for (bad in listOf(reply(clip, word = "paper"), reply(clip, language = "de"),
                reply(clip) + ("local" to false), reply(clip) + ("profile" to "other"),
                reply(clip) + ("preset" to "F1"), reply(clip) + ("sampleRate" to 24000))) {
                val speech = active(options()); val before = MediaPlayer.created
                speech.speak(request(1)); Handler.drain(); LumoOfflineSpeechBridge.pending!!.success(bad)
                Handler.drain()
                verify(MediaPlayer.created == before &&
                    JSONObject(speech.status()).optString("state") == "unavailable",
                    "Wrong returned word/language/identity never prepares a player")
                close(speech)
            }
        }
        else -> error("Unknown contract")
    }
    println("ENGLISH_LESSON_LIFECYCLE_PASS scenario=${args[0]} checks=$checks " +
        "platform=synthetic_JVM_boundary no_inference_or_Android_audio_claim=true")
}
