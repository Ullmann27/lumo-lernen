from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'host/tests/platform-fixture'
FILES={
'Context.kt':'''package android.content
import android.media.AudioManager
open class Context(val audioManager: AudioManager = AudioManager()) {
 val applicationContext: Context get()=this
 fun getSystemService(name:String): Any? = if(name==AUDIO_SERVICE) audioManager else null
 companion object { const val AUDIO_SERVICE="audio" }
}
''',
'Handler.kt':'''package android.os
class Looper { companion object { private val main=Looper();fun getMainLooper()=main } }
class Handler(looper:Looper) {
 fun post(task:Runnable):Boolean { synchronized(immediate){immediate.add(task)};return true }
 fun postDelayed(task:Runnable,delay:Long):Boolean { synchronized(delayed){delayed.add(task)};return true }
 fun removeCallbacks(task:Runnable) { synchronized(immediate){immediate.removeAll{it===task}};synchronized(delayed){delayed.removeAll{it===task}} }
 companion object {
  private val immediate=mutableListOf<Runnable>();private val delayed=mutableListOf<Runnable>()
  fun pending():Int=synchronized(immediate){immediate.size}
  fun drain() { var count=0;while(true){val next=synchronized(immediate){if(immediate.isEmpty())null else immediate.removeAt(0)}?:break;check(++count<1000);next.run()} }
  fun advance(){val jobs=synchronized(delayed){val copy=delayed.toList();delayed.clear();copy};synchronized(immediate){immediate.addAll(jobs)};drain()}
 }
}
''',
'Media.kt':'''package android.media
class AudioAttributes { class Builder { fun setUsage(v:Int)=this;fun setContentType(v:Int)=this;fun build()=AudioAttributes() };companion object {const val USAGE_MEDIA=1;const val CONTENT_TYPE_SPEECH=1} }
class AudioManager {var muted=false;var volume=7;fun isStreamMute(stream:Int)=muted;fun getStreamVolume(stream:Int)=volume;companion object {const val STREAM_MUSIC=3} }
abstract class MediaDataSource:AutoCloseable {abstract fun getSize():Long;abstract fun readAt(position:Long,buffer:ByteArray,offset:Int,size:Int):Int}
class PlaybackParams {var rate=1f;fun setSpeed(value:Float):PlaybackParams{rate=value;return this}}
class MediaPlayer {
 var isPlaying=false;var released=false;var currentPosition=20;val duration=100;var playbackParams=PlaybackParams()
 var prepared:((MediaPlayer)->Unit)?=null;var completed:((MediaPlayer)->Unit)?=null;var errored:((MediaPlayer,Int,Int)->Boolean)?=null
 init {latest=this;created++}
 fun setAudioAttributes(value:AudioAttributes){}
 fun setDataSource(value:MediaDataSource){check(value.getSize()>=44)}
 fun setOnPreparedListener(value:(MediaPlayer)->Unit){prepared=value}
 fun setOnCompletionListener(value:(MediaPlayer)->Unit){completed=value}
 fun setOnErrorListener(value:(MediaPlayer,Int,Int)->Boolean){errored=value}
 fun prepareAsync(){}
 fun start(){check(!released);isPlaying=true}
 fun release(){isPlaying=false;released=true}
 companion object {var latest:MediaPlayer?=null;var created=0}
}
''',
'Log.kt':'''package android.util
object Log {fun i(tag:String,message:String):Int=0}
''',
'Channel.kt':'''package io.flutter.plugin.common
class MethodChannel {interface Result {fun success(result:Any?);fun error(code:String,message:String?,details:Any?);fun notImplemented()}}
''',
'Json.kt':'''package org.json
class JSONObject(text:String="{}") {
 private val data=linkedMapOf<String,Any?>()
 init { val regex=Regex("\\\"([^\\\"]+)\\\"\\\\s*:\\\\s*(\\\"[^\\\"]*\\\"|true|false|-?[0-9]+(?:\\\\.[0-9]+)?)");for(m in regex.findAll(text)){val v=m.groupValues[2];data[m.groupValues[1]]=when{v.startsWith("\\\"")->v.substring(1,v.length-1);v=="true"->true;v=="false"->false;v.contains('.') -> v.toDouble();else->v.toInt()}} }
 fun optString(key:String,fallback:String="")=data[key] as? String ?:fallback
 fun optInt(key:String,fallback:Int=0)=(data[key] as? Number)?.toInt()?:fallback
 fun optDouble(key:String,fallback:Double=0.0)=(data[key] as? Number)?.toDouble()?:fallback
 fun optBoolean(key:String,fallback:Boolean=false)=data[key] as? Boolean ?:fallback
 fun put(key:String,value:Any?):JSONObject {data[key]=value;return this}
 override fun toString()=data.entries.joinToString(",","{","}"){"\\\"${it.key}\\\":"+if(it.value is String)"\\\"${it.value}\\\"" else it.value.toString()}
}
''',
'Bridge.kt':'''package dev.ullmann.lumo
import android.content.Context
import io.flutter.plugin.common.MethodChannel
class LumoOfflineSpeechBridge(context:Context) {
 fun synthesize(text:String,style:String,approved:Boolean,result:MethodChannel.Result){calls++;pending=result}
 fun cancel(){};fun release(){};fun destroy(){}
 companion object {var calls=0;var pending:MethodChannel.Result?=null}
}
object LumoOfflineSpeechEngine {const val PROFILE="test-platform-not-Android"}
'''}
ROOT.mkdir(parents=True,exist_ok=True)
for name,text in FILES.items():(ROOT/name).write_text(text)
print('Wrote explicitly synthetic JVM Android API boundary fixture',len(FILES))
