package dev.ullmann.lumo

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.Parcel

/** Bound only while the native Cards activity is visible. The OS can see that
 * its Dart authority in the main process is user-visible work, not cached work.
 * No started/foreground service, wake lock, network or duplicate game engine.
 */
class CardsAuthorityService : Service() {
    private val status = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code == STATUS) {
                data.enforceInterface(DESCRIPTOR)
                val token = data.readString() ?: ""
                reply?.writeNoException()
                reply?.writeInt(if (CardsTableBridge.hasAuthority(token)) 1 else 0)
                return true
            }
            return super.onTransact(code, data, reply, flags)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        val token = intent?.getStringExtra("cardsToken") ?: return null
        if (!Regex("[a-f0-9]{32}").matches(token) || !CardsTableBridge.hasAuthority(token)) return null
        if (CardsTableBridge.state(filesDir, token) == "{}") return null
        return status
    }

    companion object {
        private const val DESCRIPTOR = "dev.ullmann.lumo.CardsAuthority"
        private const val STATUS = IBinder.FIRST_CALL_TRANSACTION

        fun available(remote: IBinder?, token: String): Boolean {
            if (remote == null) return false
            val request = Parcel.obtain()
            val reply = Parcel.obtain()
            return try {
                request.writeInterfaceToken(DESCRIPTOR)
                request.writeString(token)
                if (!remote.transact(STATUS, request, reply, 0)) {
                    false
                } else {
                    reply.readException()
                    reply.readInt() == 1
                }
            } catch (_: Exception) { false }
            finally { request.recycle(); reply.recycle() }
        }
    }
}
