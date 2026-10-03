package dev.ullmann.lumo

import android.content.Intent
import android.app.ActivityManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val installerChannel = "lumo_lernen/installer"
    private var pendingGame: MethodChannel.Result? = null
    private val gameRequest = 8201
    private fun engineProcessRunning(pid: Int? = null): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return manager.runningAppProcesses?.any {
            it.processName == "$packageName:lumo_game" && (pid == null || it.pid == pid)
        } == true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            installerChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canInstall" -> {
                    val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(allowed)
                }
                "requestInstallPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:" + packageName)
                            )
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "install" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        if (!file.exists()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            packageName + ".fileprovider",
                            file
                        )
                        val intent = Intent(Intent.ACTION_VIEW)
                        intent.setDataAndType(uri, "application/vnd.android.package-archive")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumo_lernen/bridge")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearGameEvents" -> {
                        try {
                            if (engineProcessRunning()) throw IllegalStateException("Game still open")
                            GameEventStore.clear(this)
                            // Only Godot's known progress/settings files belong to the reset.
                            for (name in listOf("kart_sonnenhafen_session.cfg", "jump_session.cfg",
                                "kart_records.cfg", "progress.cfg", "kart_preferences.cfg", "settings.cfg")) {
                                for (suffix in listOf("", ".tmp")) {
                                    val file = File(filesDir, name + suffix)
                                    if (file.exists() && !file.delete()) throw IllegalStateException("Game reset failed")
                                }
                            }
                            result.success(true)
                        } catch (error: Exception) { result.error("storage", "Spielstände konnten nicht zurückgesetzt werden.", null) }
                    }
                    "pendingGameEvents" -> {
                        try { result.success(GameEventStore.pending(this)) }
                        catch (error: Exception) { result.error("storage", "Spielstände konnten nicht gelesen werden.", null) }
                    }
                    "acknowledgeGameEvents" -> {
                        try {
                            GameEventStore.acknowledge(this,
                                call.argument<List<String>>("resultIds") ?: emptyList(),
                                call.argument<String>("destination"))
                            result.success(true)
                        } catch (error: Exception) { result.error("storage", "Spielstände konnten nicht bestätigt werden.", null) }
                    }
                    "launch3D" -> {
                    if (pendingGame != null || engineProcessRunning()) {
                        result.error("game_running", "Ein Spiel ist bereits geöffnet.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        assets.open("lumo_game.pck").close()
                        val requested = call.argument<String>("scene")
                        val game = if (requested in setOf("kart", "jump")) requested!! else "kart"
                        val options = JSONObject()
                            .put("game", game)
                            .put("grade", (call.argument<Int>("grade") ?: 1).coerceIn(1, 4))
                            .put("subject", call.argument<String>("subject")?.takeIf { it in setOf("Mathematik", "Deutsch", "Sachunterricht", "Logik") } ?: "Mathematik")
                            .put("sessionId", UUID.randomUUID().toString())
                            .put("stars", (call.argument<Int>("stars") ?: 0).coerceAtLeast(0))
                        val intent = Intent(this, LumoGameActivity::class.java)
                            .putExtra("lumoLaunchOptions", options.toString())
                        pendingGame = result
                        startActivityForResult(intent, gameRequest)
                    } catch (e: Exception) {
                        pendingGame = null
                        result.error("game_unavailable", "Das enthaltene Spiel konnte nicht gestartet werden.", null)
                    }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == gameRequest) {
            val destination = data?.getStringExtra("destination") ?: "games"
            val pid = data?.getIntExtra("gamePid", -1)?.takeIf { it > 0 }
            // Engine globals need a fresh process. Do not enable another launch while
            // the previous engine's delayed shutdown can still kill that process.
            fun completeWhenStopped(attempt: Int) {
                if (engineProcessRunning(pid) && attempt < 100) {
                    Handler(Looper.getMainLooper()).postDelayed({ completeWhenStopped(attempt + 1) }, 100)
                } else {
                    pendingGame?.success(mapOf("destination" to destination))
                    pendingGame = null
                }
            }
            completeWhenStopped(0)
        }
    }
}
