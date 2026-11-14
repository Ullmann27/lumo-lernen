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
import java.security.MessageDigest
import android.content.pm.PackageManager
import android.speech.SpeechRecognizer
import android.util.Log

class MainActivity : FlutterActivity() {
    private var offlineSpeech: LumoOfflineSpeechBridge? = null
    private val installerChannel = "lumo_lernen/installer"
    private val distributionChannel: String by lazy {
        try {
            @Suppress("DEPRECATION")
            val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            info.metaData?.getString("dev.ullmann.lumo.DISTRIBUTION") ?: "unavailable"
        } catch (_: Exception) { "unavailable" }
    }
    private var pendingGame: MethodChannel.Result? = null
    private var pendingCallerReturnSession: String? = null
    private val gameRequest = 8201
    private fun engineProcessRunning(pid: Int? = null): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return manager.runningAppProcesses?.any {
            it.processName == "$packageName:lumo_game" && (pid == null || it.pid == pid)
        } == true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CardsTableBridge.attach(flutterEngine.dartExecutor.binaryMessenger, filesDir)
        ConnectFourBridge.attach(flutterEngine.dartExecutor.binaryMessenger, filesDir)
        offlineSpeech = LumoOfflineSpeechBridge(applicationContext).also {
            it.attach(flutterEngine)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumo_lernen/diagnostics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "onDeviceSpeechAvailable" -> result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                            SpeechRecognizer.isOnDeviceRecognitionAvailable(this))
                    "runtimeIdentity" -> {
                        try {
                            @Suppress("DEPRECATION")
                            val info = packageManager.getPackageInfo(packageName,
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                                    PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES)
                            @Suppress("DEPRECATION")
                            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                                info.signingInfo?.apkContentsSigners else info.signatures
                            val certificate = signatures?.firstOrNull()?.toByteArray()
                            val sha = certificate?.let {
                                MessageDigest.getInstance("SHA-256").digest(it)
                                    .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
                            }
                            @Suppress("DEPRECATION")
                            val version = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                                info.longVersionCode else info.versionCode.toLong()
                            result.success(mapOf("package" to packageName, "versionCode" to version,
                                "versionName" to info.versionName, "certificateSha256" to sha,
                                "androidApi" to Build.VERSION.SDK_INT))
                        } catch (_: Exception) {
                            result.error("identity", "App-Identität nicht lesbar.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            installerChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "distribution") {
                result.success(distributionChannel)
                return@setMethodCallHandler
            }
            // The manifest is authoritative even if a caller bypasses the Dart UI.
            if (distributionChannel != "family") {
                result.success(false)
                return@setMethodCallHandler
            }
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
                                "kart_records.cfg", "kart_holographic_records.cfg", "progress.cfg",
                                "kart_preferences.cfg", "settings.cfg", "lumo_host_pending_rewards.cfg")) {
                                for (suffix in listOf("", ".tmp")) {
                                    val file = File(filesDir, name + suffix)
                                    if (file.exists() && !file.delete()) throw IllegalStateException("Game reset failed")
                                }
                            }
                            val creativeSave = Regex("(lumo_(build|puzzle|rhythm|treasure)_[A-Za-z0-9_-]+\\.(json|cfg)|kart_workshop_[A-Za-z0-9_-]+\\.cfg)(\\.tmp)?")
                            for (file in filesDir.listFiles().orEmpty()) {
                                if (file.isFile && creativeSave.matches(file.name) && !file.delete()) {
                                    throw IllegalStateException("Creative game reset failed")
                                }
                            }
                            result.success(true)
                        } catch (error: Exception) { result.error("storage", "Spielstände konnten nicht zurückgesetzt werden.", null) }
                    }
                    "pendingGameEvents" -> {
                        try { result.success(GameEventStore.pending(this,
                            pendingCallerReturnSession.takeIf { pendingGame != null })) }
                        catch (error: Exception) { result.error("storage", "Spielstände konnten nicht gelesen werden.", null) }
                    }
                    "acknowledgeGameEvents" -> {
                        try {
                            GameEventStore.acknowledge(this,
                                call.argument<List<String>>("resultIds") ?: emptyList(),
                                call.argument<String>("destination"),
                                pendingCallerReturnSession.takeIf { pendingGame != null })
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
                        val game = if (requested in setOf("kart", "jump", "puzzle", "build", "rhythm", "treasure", "learning", "cards", "connect_four")) requested!! else "kart"
                        val options = JSONObject()
                            .put("game", game)
                            .put("grade", (call.argument<Int>("grade") ?: 1).coerceIn(1, 4))
                            .put("subject", call.argument<String>("subject")?.takeIf { it in setOf("Mathematik", "Deutsch", "Sachunterricht", "Logik") } ?: "Mathematik")
                            .put("sessionId", UUID.randomUUID().toString())
                            .put("stars", (call.argument<Int>("stars") ?: 0).coerceAtLeast(0))
                            .put("lifetimeStars", (call.argument<Int>("lifetimeStars") ?: 0).coerceAtLeast(0))
                            .put("childKey", call.argument<String>("childKey")?.takeIf { it.matches(Regex("[A-Za-z0-9_-]{1,80}")) } ?: "standalone")
                        if (game == "learning") {
                            val learning = call.argument<Map<String, Any?>>("learning")
                            if (learning == null || learning["kind"] !in setOf("bridge_ten", "addition", "subtract_ten", "equal_groups", "equal_sharing", "bridge_hundred", "fraction_parts", "syllables", "plant_parts")) {
                                result.error("invalid_learning", "Die Lernansicht ist nicht verfügbar.", null)
                                return@setMethodCallHandler
                            }
                            options.put("learning", JSONObject(learning))
                        }
                        if (game in setOf("learning", "build")) {
                            options.put("learningVoiceEnabled", call.argument<Boolean>("learningVoiceEnabled") == true)
                                .put("localVoiceLicenseAccepted", call.argument<Boolean>("localVoiceLicenseAccepted") == true)
                                .put("learningAutoRead", call.argument<Boolean>("learningAutoRead") == true)
                                .put("learningVoiceRate", (call.argument<Number>("learningVoiceRate")?.toDouble()
                                    ?.takeIf { it.isFinite() } ?: 1.0).coerceIn(0.70, 1.60))
                            // Release Flutter's local inference model before the
                            // isolated lesson or village owns the same original voice.
                            offlineSpeech?.release()
                        }
                        if (game == "cards") {
                            val token = call.argument<String>("cardsToken")
                            if (token == null || !token.matches(Regex("[a-f0-9]{32}"))) {
                                result.error("invalid_cards", "Der Kartentisch konnte nicht geöffnet werden.", null)
                                return@setMethodCallHandler
                            }
                            options.put("cardsToken", token)
                        }
                        if (game == "connect_four") {
                            val token = call.argument<String>("connectFourToken")
                            if (token == null || !ConnectFourBridge.hasAuthority(token)) {
                                result.error("invalid_connect_four", "Deine Vier-Gewinnt-Runde ist nicht verfügbar.", null)
                                return@setMethodCallHandler
                            }
                            options.put("connectFourToken", token)
                        }
                        options.put("reduceAnimations", call.argument<Boolean>("reduceAnimations") ?: false)
                        val callerSession = options.getString("sessionId")
                            .takeIf { game in setOf("learning", "cards", "connect_four") }
                        val intent = Intent(this, if (game == "connect_four") ConnectFourGameActivity::class.java else LumoGameActivity::class.java)
                            .putExtra("lumoLaunchOptions", options.toString())
                            .putExtra(GameEventStore.CALLER_RETURN_SESSION, callerSession)
                        if (callerSession != null) GameEventStore.beginCallerReturn(this)
                        pendingGame = result
                        pendingCallerReturnSession = callerSession
                        startActivityForResult(intent, gameRequest)
                    } catch (e: Exception) {
                        pendingGame = null
                        pendingCallerReturnSession = null
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
            // A recreated host has no live Dart caller. Its durable return is
            // intentionally left for EmbeddedGameService's normal navigation.
            val callback = pendingGame ?: return
            val callerSession = pendingCallerReturnSession
            val returnedSession = data?.getStringExtra(GameEventStore.CALLER_RETURN_SESSION)
            if (returnedSession != null && returnedSession != callerSession) {
                Log.w("LumoHost", "Ignoring a return from another launch session")
                return
            }
            val destination = if (data?.getStringExtra("destination") == "learn") "learn" else "games"
            val callerOwned = resultCode == RESULT_OK && callerSession != null && returnedSession == callerSession
            val pid = data?.getIntExtra("gamePid", -1)?.takeIf { it > 0 }
            // Engine globals need a fresh process. Do not enable another launch while
            // the previous engine's delayed shutdown can still kill that process.
            fun completeWhenStopped(attempt: Int) {
                if (isDestroyed || pendingGame !== callback || pendingCallerReturnSession != callerSession) return
                if (engineProcessRunning(pid) && attempt < 100) {
                    Handler(Looper.getMainLooper()).postDelayed({ completeWhenStopped(attempt + 1) }, 100)
                } else {
                    if (callerOwned) {
                        try {
                            GameEventStore.completeCallerReturn(this, destination, callerSession!!)
                        } catch (error: Exception) {
                            // Keep the owner and fallback until the atomic commit
                            // succeeds. Never unlock into a stale generic return.
                            Log.e("LumoHost", "Could not commit caller return; retrying", error)
                            Handler(Looper.getMainLooper()).postDelayed({ completeWhenStopped(attempt) }, 1000)
                            return
                        }
                    }
                    callback.success(mapOf("destination" to destination))
                    pendingGame = null
                    pendingCallerReturnSession = null
                }
            }
            completeWhenStopped(0)
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_BACKGROUND) {
            offlineSpeech?.release()
        }
    }

    override fun onDestroy() {
        // Do not let an old Activity's delayed completion consume the fallback
        // belonging to a recreated host that no longer owns the Dart call.
        pendingGame = null
        pendingCallerReturnSession = null
        CardsTableBridge.detach()
        ConnectFourBridge.detach()
        offlineSpeech?.destroy()
        offlineSpeech = null
        super.onDestroy()
    }
}
