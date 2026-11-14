package dev.ullmann.lumo
import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import org.json.JSONObject
import java.io.File

private var checks=0
private fun verify(ok:Boolean, label:String){checks++;check(ok){label}}
private fun waitPrepared():MediaPlayer {
 val deadline=System.nanoTime()+2_000_000_000L
 while(Handler.pending()==0 && System.nanoTime()<deadline)Thread.sleep(1)
 Handler.drain();return checkNotNull(MediaPlayer.latest)
}
fun main(args:Array<String>){
 val clip=File(args.single()).readBytes()
 fun options(licensed:Boolean=true)=JSONObject("{\"game\":\"learning\",\"learningVoiceEnabled\":true,\"localVoiceLicenseAccepted\":$licensed,\"learningVoiceRate\":1.3}")
 fun request(id:Int)="{\"id\":$id,\"text\":\"Apfel\",\"style\":\"explain\"}"
 val context=Context();val speech=LumoLearningSpeech(context,options())
 speech.setActive(true);Handler.drain()
 verify(speech.speak(request(1)),"Licensed lesson accepts actual synthesis request")
 Handler.drain();verify(JSONObject(speech.status()).optString("state")=="preparing","Synthesis state is separate from playback")
 verify(JSONObject(speech.status()).optDouble("envelope")==0.0,"Preparing never talks")
 LumoOfflineSpeechBridge.pending!!.success(mapOf("wav" to clip));val player=waitPrepared()
 verify(!player.isPlaying,"Envelope derivation does not start playback")
 player.prepared!!(player);Handler.drain();player.currentPosition=300;Handler.advance()
 val playing=JSONObject(speech.status())
 verify(playing.optString("state")=="playing" && playing.optBoolean("audible"),"Only actual player-start state is audible")
 verify(playing.optInt("positionMs")==300,"Snapshot uses player media position, not elapsed timer")
 verify(playing.optBoolean("envelopeAvailable") && playing.optDouble("envelope")>0.0,"Measured original PCM amplitude is exposed")
 context.audioManager.volume=0;Handler.advance()
 verify(!JSONObject(speech.status()).optBoolean("audible") && JSONObject(speech.status()).optDouble("envelope")==0.0,"Zero media volume closes")
 context.audioManager.volume=7;context.audioManager.muted=true;Handler.advance()
 verify(JSONObject(speech.status()).optDouble("envelope")==0.0,"System stream mute closes")
 context.audioManager.muted=false;player.isPlaying=false;Handler.advance()
 verify(!JSONObject(speech.status()).optBoolean("audible"),"Paused player cannot create articulation")
 player.isPlaying=true;Handler.advance();verify(JSONObject(speech.status()).optBoolean("audible"),"Unmuted active player can resume measured articulation")
 speech.stop();Handler.drain()
 verify(player.released && JSONObject(speech.status()).optString("state")=="idle" && JSONObject(speech.status()).optDouble("envelope")==0.0,"Stop releases playback and closes immediately")
 speech.speak(request(2));Handler.drain();val old=LumoOfflineSpeechBridge.pending!!;val before=MediaPlayer.created
 speech.setActive(false);Handler.drain();old.success(mapOf("wav" to clip));Handler.drain()
 verify(MediaPlayer.created==before && JSONObject(speech.status()).optString("state")=="idle","Late synthesis after Activity pause cannot prepare a player")
 speech.setActive(true);Handler.drain();speech.speak(request(3));Handler.drain();LumoOfflineSpeechBridge.pending!!.success(mapOf("wav" to ByteArray(44)));val invalid=waitPrepared();invalid.prepared!!(invalid);Handler.drain()
 verify(!JSONObject(speech.status()).optBoolean("envelopeAvailable") && JSONObject(speech.status()).optDouble("envelope")==0.0,"Unsupported WAV cannot invent amplitude")
 invalid.completed!!(invalid);Handler.drain()
 verify(JSONObject(speech.status()).optString("state")=="completed" && JSONObject(speech.status()).optDouble("envelope")==0.0,"Completion releases envelope")
 val noLicense=LumoLearningSpeech(context,options(false));noLicense.setActive(true);Handler.drain();val synths=LumoOfflineSpeechBridge.calls
 verify(!noLicense.speak(request(4)) && LumoOfflineSpeechBridge.calls==synths,"No parent license means no synthesis or articulation")
 noLicense.destroy();speech.destroy();Handler.drain();val created=MediaPlayer.created;speech.speak(request(5));Handler.drain()
 verify(MediaPlayer.created==created,"Destroyed owner cannot prepare playback")
 println("LUMO_SPEECH_LIFECYCLE_PASS checks=$checks platform=synthetic_JVM_boundary no_Android_playback_claim=true")
}
