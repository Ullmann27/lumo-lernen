package dev.ullmann.lumo

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.Parcel

/** Keeps only the visible C4 controller process bound, never a background game. */
class ConnectFourAuthorityService : Service() {
    private val status = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code != STATUS) return super.onTransact(code, data, reply, flags)
            data.enforceInterface(DESCRIPTOR)
            reply?.writeNoException()
            reply?.writeInt(if (ConnectFourBridge.hasAuthority(data.readString() ?: "")) 1 else 0)
            return true
        }
    }
    override fun onBind(intent: Intent?): IBinder? {
        val token = intent?.getStringExtra("connectFourToken") ?: return null
        return if (ConnectFourBridge.hasAuthority(token) && ConnectFourBridge.state(filesDir, token) != "{}") status else null
    }
    companion object {
        private const val DESCRIPTOR = "dev.ullmann.lumo.ConnectFourAuthority"
        private const val STATUS = IBinder.FIRST_CALL_TRANSACTION
        fun available(remote: IBinder?, token: String): Boolean {
            if (remote == null) return false
            val data = Parcel.obtain(); val reply = Parcel.obtain()
            return try {
                data.writeInterfaceToken(DESCRIPTOR); data.writeString(token)
                if (!remote.transact(STATUS, data, reply, 0)) false
                else { reply.readException(); reply.readInt() == 1 }
            } catch (_: Exception) { false }
            finally { data.recycle(); reply.recycle() }
        }
    }
}
