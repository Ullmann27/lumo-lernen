package dev.ullmann.lumo
import android.content.Context
import io.flutter.plugin.common.MethodChannel
class LumoOfflineSpeechBridge(context:Context) {
 fun synthesize(text:String,style:String,approved:Boolean,result:MethodChannel.Result){
  calls++;defaultCalls++;lastWord=null;lastText=text;pending=result
 }
 fun synthesizeEnglishLesson(word:String,text:String,style:String,approved:Boolean,result:MethodChannel.Result){
  calls++;englishCalls++;lastWord=word;lastText=text;pending=result
 }
 fun cancel(){};fun release(){};fun destroy(){}
 companion object {
  var calls=0;var defaultCalls=0;var englishCalls=0
  var pending:MethodChannel.Result?=null;var lastWord:String?=null;var lastText:String?=null
 }
}
object LumoOfflineSpeechEngine {
 const val PROFILE="test-platform-not-Android"
 const val PRESET="F2"
 const val SAMPLE_RATE=44100
}
