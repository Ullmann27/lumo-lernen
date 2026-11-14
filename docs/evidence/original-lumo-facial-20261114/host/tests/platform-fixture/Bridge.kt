package dev.ullmann.lumo
import android.content.Context
import io.flutter.plugin.common.MethodChannel
class LumoOfflineSpeechBridge(context:Context) {
 fun synthesize(text:String,style:String,approved:Boolean,result:MethodChannel.Result){calls++;pending=result}
 fun cancel(){};fun release(){};fun destroy(){}
 companion object {var calls=0;var pending:MethodChannel.Result?=null}
}
object LumoOfflineSpeechEngine {const val PROFILE="test-platform-not-Android"}
