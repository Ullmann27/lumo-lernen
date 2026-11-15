package android.media
class AudioAttributes { class Builder { fun setUsage(v:Int)=this;fun setContentType(v:Int)=this;fun build()=AudioAttributes() };companion object {const val USAGE_MEDIA=1;const val CONTENT_TYPE_SPEECH=1} }
class AudioFocusRequest(val listener:AudioManager.OnAudioFocusChangeListener?,val pauseOnDuck:Boolean) {
 class Builder(val gain:Int) {
  private var listener:AudioManager.OnAudioFocusChangeListener?=null
  private var pause=false
  fun setAudioAttributes(value:AudioAttributes)=this
  fun setWillPauseWhenDucked(value:Boolean)=apply{pause=value}
  fun setAcceptsDelayedFocusGain(value:Boolean)=this
  fun setOnAudioFocusChangeListener(value:AudioManager.OnAudioFocusChangeListener,handler:android.os.Handler)=apply{listener=value}
  fun build()=AudioFocusRequest(listener,pause)
 }
}
class AudioManager {
 fun interface OnAudioFocusChangeListener {fun onAudioFocusChange(change:Int)}
 var muted=false;var volume=7
 var focusResult=AUDIOFOCUS_REQUEST_GRANTED
 var requested=0;var abandoned=0;var legacyRequests=0
 var listener:OnAudioFocusChangeListener?=null
 var lastRequest:AudioFocusRequest?=null
 fun isStreamMute(stream:Int)=muted
 fun getStreamVolume(stream:Int)=volume
 fun requestAudioFocus(request:AudioFocusRequest):Int{requested++;lastRequest=request;listener=request.listener;return focusResult}
 fun requestAudioFocus(value:OnAudioFocusChangeListener,stream:Int,gain:Int):Int{requested++;legacyRequests++;listener=value;return focusResult}
 fun abandonAudioFocusRequest(request:AudioFocusRequest):Int{abandoned++;return 1}
 fun abandonAudioFocus(value:OnAudioFocusChangeListener):Int{abandoned++;return 1}
 companion object {const val STREAM_MUSIC=3;const val AUDIOFOCUS_GAIN_TRANSIENT=2;const val AUDIOFOCUS_REQUEST_GRANTED=1;const val AUDIOFOCUS_LOSS=-1;const val AUDIOFOCUS_LOSS_TRANSIENT=-2;const val AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK=-3;const val AUDIOFOCUS_GAIN=1}
}
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
