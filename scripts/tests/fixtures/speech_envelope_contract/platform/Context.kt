package android.content
import android.media.AudioManager
open class Context(val audioManager: AudioManager = AudioManager()) {
 val applicationContext: Context get()=this
 fun getSystemService(name:String): Any? = if(name==AUDIO_SERVICE) audioManager else null
 companion object { const val AUDIO_SERVICE="audio" }
}
