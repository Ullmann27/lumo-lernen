package dev.ullmann.lumo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Geister-Duell (Lumo Kart) ohne Server: Datei empfangen („Öffnen mit“/„Teilen an“ Lumo
 * oder Android-Dateiauswahl) und eigene Bestfahrt über das Teilen-Menü verschicken.
 * Keine Berechtigung nötig: Dateien kommen als content://-Freigabe des Absenders,
 * versendet wird über den vorhandenen FileProvider (cache-path).
 */
class KartFriendsBridge(private val activity: Activity) {
    companion object {
        const val PICK_REQUEST = 8311
        private const val TAG = "LumoHost"

        /** Aus dem Spiel (eigener Prozess :lumo_game): Teilen-Menü für einen Geist öffnen. */
        fun share(activity: Activity, base64: String, fileName: String, title: String): Boolean {
            val data = try { Base64.decode(base64, Base64.DEFAULT) } catch (_: Exception) { null }
            if (!KartGhostRules.looksLikeGhost(data)) return false
            return try {
                val folder = File(activity.cacheDir, "geister").apply { mkdirs() }
                folder.listFiles()?.forEach { it.delete() }
                val file = File(folder, KartGhostRules.fileName(fileName))
                file.writeBytes(data!!)
                val uri = FileProvider.getUriForFile(activity, activity.packageName + ".fileprovider", file)
                val send = Intent(Intent.ACTION_SEND)
                    .setType(KartGhostRules.MIME)
                    .putExtra(Intent.EXTRA_STREAM, uri)
                    .putExtra(Intent.EXTRA_TEXT, KartGhostRules.shareText(title))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                activity.runOnUiThread {
                    try {
                        activity.startActivity(Intent.createChooser(send, "Lumo-Geist schicken"))
                    } catch (error: Exception) {
                        Log.w(TAG, "Kart ghost share failed", error)
                    }
                }
                true
            } catch (error: Exception) {
                Log.w(TAG, "Kart ghost could not be prepared", error)
                false
            }
        }
    }

    private var incoming: ByteArray? = null
    private var incomingError: String? = null
    private var pendingPick: MethodChannel.Result? = null
    private var readingIncoming = false
    private var waitingTake: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "lumo_lernen/kart_friends").setMethodCallHandler { call, result ->
            when (call.method) {
                "takeIncomingGhost" -> {
                    if (readingIncoming) {
                        // Die Datei wird noch gelesen: antworten, sobald sie da ist.
                        waitingTake?.success(null)
                        waitingTake = result
                        return@setMethodCallHandler
                    }
                    val error = incomingError
                    val data = incoming
                    incoming = null
                    incomingError = null
                    if (error != null) result.error("ghost_invalid", error, null) else result.success(data)
                }
                "pickGhostFile" -> {
                    if (pendingPick != null) {
                        result.error("busy", "Die Dateiauswahl ist schon offen.", null)
                        return@setMethodCallHandler
                    }
                    pendingPick = result
                    try {
                        activity.startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*"),
                            PICK_REQUEST,
                        )
                    } catch (error: Exception) {
                        pendingPick = null
                        result.error("no_picker", "Auf diesem Gerät gibt es keine Dateiauswahl.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** VIEW/SEND an Lumo: Datei im Hintergrund lesen; Dart holt sie mit takeIncomingGhost. */
    fun handleIntent(intent: Intent?): Boolean {
        val uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> @Suppress("DEPRECATION") (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))
            else -> null
        } ?: return false
        // Nur freigegebene Dateien (content://). lumolernen:-Links und alles andere bleiben
        // unberührt beim bisherigen Weg.
        if (uri.scheme != "content") return false
        readingIncoming = true
        read(uri) { data, error ->
            readingIncoming = false
            val waiting = waitingTake
            waitingTake = null
            if (waiting != null) {
                if (error != null) waiting.error("ghost_invalid", error, null) else waiting.success(data)
            } else {
                incoming = data
                incomingError = error
            }
        }
        // Nicht zweimal bei Neuerstellung der Activity verarbeiten.
        intent.action = Intent.ACTION_MAIN
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_REQUEST) return false
        val callback = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            callback.success(null)
            return true
        }
        read(uri) { bytes, error ->
            if (error != null) callback.error("ghost_invalid", error, null) else callback.success(bytes)
        }
        return true
    }

    private fun read(uri: Uri, done: (ByteArray?, String?) -> Unit) {
        Thread({
            val outcome: Pair<ByteArray?, String?> = try {
                val bytes = activity.contentResolver.openInputStream(uri)?.use { KartGhostRules.readLimited(it) }
                when {
                    bytes == null -> null to "Diese Datei ist zu groß für einen Lumo-Geist."
                    !KartGhostRules.looksLikeGhost(bytes) -> null to "Das ist kein Lumo-Geist."
                    else -> bytes to null
                }
            } catch (error: Exception) {
                Log.w(TAG, "Kart ghost could not be read", error)
                null to "Die Datei konnte nicht gelesen werden."
            }
            main.post { done(outcome.first, outcome.second) }
        }, "LumoKartGhostRead").start()
    }
}
