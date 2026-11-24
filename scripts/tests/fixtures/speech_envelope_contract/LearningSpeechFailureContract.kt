package dev.ullmann.lumo

import android.content.Context
import android.os.Handler
import android.util.Log
import org.json.JSONObject

private var checks=0
private fun verify(ok:Boolean,label:String){checks++;check(ok){label}}
private fun failures()=Log.entries.filter{it.first=="LumoLearningSpeech" && it.second.startsWith("failed ")}

fun main(){
 val speech=LumoLearningSpeech(Context(),JSONObject("{\"game\":\"learning\",\"learningVoiceEnabled\":true,\"localVoiceLicenseAccepted\":true}"))
 fun start(id:Int){
  verify(speech.speak("{\"id\":$id,\"text\":\"Apfel\",\"style\":\"explain\"}"),"Valid request accepted")
  Handler.drain()
 }
 speech.setActive(true);Handler.drain()
 start(7)
 LumoOfflineSpeechBridge.pending!!.error("local_unavailable","never-log-this-child-text",mapOf("private" to "never-log-this-detail"))
 val first=failures().singleOrNull()
 verify(first!=null,"Current synthesis failure leaves an actual diagnostic")
 val payload=JSONObject(first!!.second.removePrefix("failed "))
 verify(payload.optInt("id")==7 && payload.optInt("generation")>0,"Failure belongs to the actual current playback owner")
 verify(payload.optString("phase")=="synthesis" && payload.optString("code")=="unavailable","Fixed failure phase and code")
 verify(JSONObject(speech.status()).optString("state")=="unavailable","Failure state unchanged")
 verify(Log.entries.none{it.second.contains("never-log-this")},"No source text, error message or arbitrary details logged")
 start(8);val old=LumoOfflineSpeechBridge.pending!!
 start(9);val current=LumoOfflineSpeechBridge.pending!!;val count=failures().size
 old.error("local_unavailable","stale",null)
 verify(failures().size==count && JSONObject(speech.status()).optString("state")=="preparing","Stale error cannot log or fail the new owner")
 speech.stop();Handler.drain();current.error("local_cancelled","stale after stop",null)
 verify(failures().size==count && JSONObject(speech.status()).optString("state")=="idle","Cancelled old callback cannot impersonate a current failure")
 start(10);LumoOfflineSpeechBridge.pending!!.error("untrusted-child-payload","private",null)
 val unknown=JSONObject(failures().last().second.removePrefix("failed "))
 verify(unknown.optInt("id")==10 && unknown.optString("code")=="unavailable","Unknown error code is reduced to a fixed enum")
 verify(Log.entries.none{it.second.contains("untrusted-child-payload")},"Arbitrary error code is not logged")
 start(11);val retired=LumoOfflineSpeechBridge.pending!!;speech.destroy();Handler.drain()
 val destroyedCount=failures().size;retired.error("local_unavailable",null,null)
 verify(failures().size==destroyedCount,"Destroyed owner cannot publish a late failure")
 println("LUMO_SPEECH_FAILURE_PASS checks=$checks platform=synthetic_JVM_boundary no_Android_playback_claim=true")
}
