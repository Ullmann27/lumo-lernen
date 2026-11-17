package dev.ullmann.lumo

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.Parcel

/** Binds only the currently visible table to its existing Flutter authority. */
class TableAuthorityService : Service() {
    private val status = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code != STATUS) return super.onTransact(code, data, reply, flags)
            data.enforceInterface(DESCRIPTOR)
            val token = data.readString() ?: ""
            val game = data.readString() ?: ""
            reply?.writeNoException()
            reply?.writeInt(if (TableGamesBridge.hasAuthority(token, game)) 1 else 0)
            return true
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        val request = intent ?: return null
        val token = request.getStringExtra("tableToken") ?: return null
        val game = request.getStringExtra("tableGame") ?: return null
        return if (TableGamesBridge.hasAuthority(token, game) &&
            TableGamesBridge.state(filesDir, token, game) != "{}") status else null
    }

    companion object {
        private const val DESCRIPTOR = "dev.ullmann.lumo.TableAuthority"
        private const val STATUS = IBinder.FIRST_CALL_TRANSACTION
        fun available(remote: IBinder?, token: String, game: String): Boolean {
            if (remote == null) return false
            val data = Parcel.obtain(); val reply = Parcel.obtain()
            return try {
                data.writeInterfaceToken(DESCRIPTOR); data.writeString(token); data.writeString(game)
                if (!remote.transact(STATUS, data, reply, 0)) false
                else { reply.readException(); reply.readInt() == 1 }
            } catch (_: Exception) { false }
            finally { data.recycle(); reply.recycle() }
        }
    }
}
