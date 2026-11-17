package android.media
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
