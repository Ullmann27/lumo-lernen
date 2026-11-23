package dev.ullmann.lumo

import android.content.Intent
import android.app.ActivityManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject
import java.util.UUID
import java.security.MessageDigest
import android.content.pm.PackageManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private var offlineSpeech: LumoOfflineSpeechBridge? = null
    private var localRecognition: LumoLocalRecognition? = null
    private var kartFriends: KartFriendsBridge? = null
    private var localBackup: LumoLocalBackupBridge? = null
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
    private var hostForeground = false
    private var engineCleanupActive = false
    private var pendingStartId: String? = null
    private val startLogTags = listOf("godot", "Godot", "LumoHost", "AndroidRuntime", "DEBUG", "libc")

    /** The start protocol is only a diagnostic aid; it never blocks or fails a start. */
    private fun journal(block: () -> Unit) {
        try { block() } catch (error: Exception) { Log.w("LumoHost", "Start protocol not written", error) }
    }

    private fun requestedScene(call: MethodCall): String =
        call.argument<String>("scene")?.takeIf { it.matches(Regex("[a-z_]{1,24}")) } ?: "unbekannt"

    /**
     * Reads this app's own logcat (both processes share the UID; no permission)
     * on the calling background thread. logcat -d exits by itself; a watchdog
     * ends it after 5 s (minSdk 24, therefore via the reader thread). Returns the filtered lines, newest last.
     */
    private fun readOwnLog(withYear: Boolean = true): List<String> {
        val command = mutableListOf("logcat", "-d", "-v", "threadtime")
        if (withYear) command += listOf("-v", "year")
        command += "-s"
        command += startLogTags.map { "$it:V" }
        val process = ProcessBuilder(command).redirectErrorStream(true).start()
        val lines = ArrayDeque<String>()
        val reader = Thread({
            try {
                process.inputStream.bufferedReader().useLines { all ->
                    for (line in all) synchronized(lines) {
                        lines.addLast(line)
                        if (lines.size > 4000) lines.removeFirst()
                    }
                }
            } catch (_: Exception) {}
        }, "LumoStartLogReader")
        reader.start()
        // minSdk 24: no Process.waitFor(timeout). The reader ends at EOF, i.e.
        // when logcat -d exits; a stuck logcat is destroyed after 5 s.
        reader.join(5000)
        if (reader.isAlive) {
            process.destroy()
            reader.join(1000)
        }
        val result = synchronized(lines) { lines.toList() }
        val failed = try { process.exitValue() != 0 } catch (_: IllegalThreadStateException) { false }
        if (withYear && failed) return readOwnLog(false)
        return result
    }

    private fun refreshLoadTimes(lines: List<String>) {
        journal {
            GameStartJournal.applyLoadTimes(applicationContext, lines.joinToString("\n"),
                System.currentTimeMillis(), java.util.Calendar.getInstance().get(java.util.Calendar.YEAR))
        }
    }

    private fun startProtocolDevice(): Map<String, String> {
        val device = LinkedHashMap<String, String>()
        device["Erstellt"] = java.text.SimpleDateFormat("dd.MM.yyyy HH:mm:ss", java.util.Locale.GERMANY)
            .format(java.util.Date())
        device["Gerät"] = "${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE})"
        device["Android"] = "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
        device["App-Version"] = try {
            @Suppress("DEPRECATION")
            val info = packageManager.getPackageInfo(packageName, 0)
            @Suppress("DEPRECATION")
            val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else info.versionCode.toLong()
            "${info.versionName} ($code)"
        } catch (_: Exception) { "unbekannt" }
        device["Godot-Stand"] = try {
            val source = JSONObject(assets.open("lumo_game_source.json").use { it.readBytes().toString(Charsets.UTF_8) })
            source.optString("revision").ifBlank { "unbekannt" }
        } catch (_: Exception) { "nicht enthalten" }
        device["Arbeitsspeicher"] = try {
            val memory = ActivityManager.MemoryInfo()
            (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memory)
            "${memory.availMem / 1048576} MB frei von ${memory.totalMem / 1048576} MB" +
                if (memory.lowMemory) " (wenig Speicher)" else ""
        } catch (_: Exception) { "unbekannt" }
        device["Speicherplatz"] = "${filesDir.usableSpace / 1048576} MB frei"
        device["Spielprozess läuft"] = if (engineProcessRunning()) "ja" else "nein"
        return device
    }
    private fun engineProcessRunning(pid: Int? = null): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return manager.runningAppProcesses?.any {
            it.processName == "$packageName:lumo_game" && (pid == null || it.pid == pid)
        } == true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // A confirmed import is recovered/applied before Flutter plugins can
        // cache preferences or Dart can write a previous in-memory snapshot.
        LumoLocalBackupBridge.recoverBeforeFlutter(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localBackup = LumoLocalBackupBridge(this) {
            pendingGame == null && !engineCleanupActive && !engineProcessRunning()
        }.also { it.attach(flutterEngine.dartExecutor.binaryMessenger) }
        // Keep the pinned Dart API; replace its native recognition handler
        // after registration so every capture either stays local or fails.
        localRecognition = LumoLocalRecognition(this, flutterEngine.dartExecutor.binaryMessenger)
        CardsTableBridge.attach(flutterEngine.dartExecutor.binaryMessenger, filesDir)
        ConnectFourBridge.attach(flutterEngine.dartExecutor.binaryMessenger, filesDir)
        TableGamesBridge.attach(flutterEngine.dartExecutor.binaryMessenger, filesDir)
        // Geister-Duell: angekommene „Lumo-Geist“-Datei bereithalten (Dart holt sie ab).
        kartFriends = KartFriendsBridge(this).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
            it.handleIntent(intent)
        }
        offlineSpeech = LumoOfflineSpeechBridge(applicationContext).also {
            it.attach(flutterEngine)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumo_lernen/diagnostics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "mediaAudible" -> result.success(try {
                        val manager = getSystemService(AUDIO_SERVICE) as? AudioManager
                        manager != null && !manager.isStreamMute(AudioManager.STREAM_MUSIC) &&
                            manager.getStreamVolume(AudioManager.STREAM_MUSIC) > 0
                    } catch (_: Exception) { false })
                    "onDeviceSpeechAvailable" -> result.success(
                        localRecognition?.onDeviceAvailable() == true)
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
                    "gameStartLog" -> {
                        // Nur Anzeige am Gerät (Elternbereich), nichts wird gesendet.
                        val main = Handler(Looper.getMainLooper())
                        Thread({
                            val lines = try { readOwnLog() } catch (error: Exception) {
                                listOf("Log nicht lesbar: ${error.javaClass.simpleName}")
                            }
                            refreshLoadTimes(lines)
                            val reply = try {
                                mapOf("device" to startProtocolDevice(),
                                    "starts" to GameStartJournal.entries(applicationContext),
                                    "log" to lines.takeLast(400).joinToString("\n"))
                            } catch (error: Exception) { null }
                            main.post {
                                if (reply == null) result.error("start_log", "Das Startprotokoll ist nicht lesbar.", null)
                                else result.success(reply)
                            }
                        }, "LumoStartLog").start()
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
                    // Engine globals need a fresh process: never start into a live
                    // :lumo_game. A leftover engine that outlived its game is ended
                    // first, but only while Flutter is in front and nothing is pending.
                    val scene = requestedScene(call)
                    if (pendingGame != null || engineCleanupActive || localBackup?.blocksGames == true) {
                        journal { GameStartJournal.refused(this, scene, System.currentTimeMillis(), "game_running",
                            if (pendingGame != null) "Start läuft noch" else "Rest wird beendet") }
                        result.error("game_running", "Ein Spiel ist bereits geöffnet.", null)
                        return@setMethodCallHandler
                    }
                    if (!engineProcessRunning()) {
                        launchGame(call, result)
                        return@setMethodCallHandler
                    }
                    if (!hostForeground) {
                        journal { GameStartJournal.refused(this, scene, System.currentTimeMillis(), "game_running",
                            "Spielprozess läuft, App nicht im Vordergrund") }
                        result.error("game_running", "Ein Spiel ist bereits geöffnet.", null)
                        return@setMethodCallHandler
                    }
                    engineCleanupActive = true
                    clearLeftoverEngine { cleared ->
                        engineCleanupActive = false
                        if (cleared && !isDestroyed && pendingGame == null && !engineProcessRunning()) {
                            Log.i("LumoHost", "Leftover game process ended before a new start")
                            launchGame(call, result, "Ein übrig gebliebenes Spiel wurde vorher beendet.")
                        } else {
                            journal { GameStartJournal.refused(this, scene, System.currentTimeMillis(), "game_running",
                                "übrig gebliebener Spielprozess blieb bestehen") }
                            result.error("game_running", "Ein Spiel ist bereits geöffnet.", null)
                        }
                    }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Ends a leftover :lumo_game process (same UID) off the main thread and waits
     * up to ~3 s until it is gone. A visible engine is a real open game (split
     * screen, recreated host) and is never touched. The kill happens while the
     * event-store lock is held, so no durable reward write is cut off.
     */
    private fun clearLeftoverEngine(done: (Boolean) -> Unit) {
        val main = Handler(Looper.getMainLooper())
        val context = applicationContext
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val engineName = "$packageName:lumo_game"
        Thread({
            val cleared = try {
                val killed = GameEventStore.whileNoWriter(context, 1000) {
                    val engines = manager.runningAppProcesses.orEmpty().filter { it.processName == engineName }
                    if (engines.any { it.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE }) {
                        false
                    } else {
                        engines.forEach { android.os.Process.killProcess(it.pid) }
                        true
                    }
                } == true
                var waited = 0
                while (killed && engineProcessRunning() && waited < 3000) {
                    Thread.sleep(100)
                    waited += 100
                }
                killed && !engineProcessRunning()
            } catch (error: Exception) {
                Log.w("LumoHost", "Could not end leftover game process", error)
                false
            }
            main.post { done(cleared) }
        }, "LumoEngineCleanup").start()
    }

    private fun launchGame(call: MethodCall, result: MethodChannel.Result, note: String? = null) {
        val scene = requestedScene(call)
        val refuse = { code: String, message: String ->
            journal { GameStartJournal.refused(this, scene, System.currentTimeMillis(), "refused", code) }
            result.error(code, message, null)
        }
        try {
            assets.open("lumo_game.pck").close()
            val requested = call.argument<String>("scene")
            val villageRequested = call.argument<Boolean>("livingVillage") == true
            if ((requested == "settlement") != villageRequested ||
                (villageRequested && call.argument<String>("settlementMode") != "settlement")) {
                refuse("invalid_village", "Der Dorfmodus wurde nicht sicher ausgewählt.")
                return
            }
            val game = if (requested in setOf("kart", "jump", "run", "skypost", "puzzle", "build", "settlement", "rhythm", "treasure", "learning", "cards", "connect_four", "games", "memory", "quiz", "chess")) requested!! else "kart"
            val options = JSONObject()
                .put("game", game)
                .put("grade", (call.argument<Int>("grade") ?: 1).coerceIn(1, 4))
                .put("subject", call.argument<String>("subject")?.takeIf { it in setOf("Mathematik", "Deutsch", "Sachunterricht", "Englisch", "Logik") } ?: "Mathematik")
                .put("sessionId", UUID.randomUUID().toString())
                .put("stars", (call.argument<Int>("stars") ?: 0).coerceAtLeast(0))
                .put("lifetimeStars", (call.argument<Int>("lifetimeStars") ?: 0).coerceAtLeast(0))
                .put("childKey", call.argument<String>("childKey")?.takeIf { it.matches(Regex("[A-Za-z0-9_-]{1,80}")) } ?: "standalone")
            if (game == "settlement") {
                options.put("livingVillage", true).put("settlementMode", "settlement")
            }
            if (game == "learning") {
                val learning = call.argument<Map<String, Any?>>("learning")
                if (learning == null || learning["kind"] !in setOf(
                    "bridge_ten", "addition", "subtract_ten", "equal_groups", "equal_sharing",
                    "bridge_hundred", "fraction_parts", "syllables", "plant_parts", "english_objects",
                    "pattern", "task_card", "clock", "tutor", "holo_word_problem", "holo_sentence"
                )) {
                    refuse("invalid_learning", "Die Lernansicht ist nicht verfügbar.")
                    return
                }
                val descriptor = JSONObject(learning)
                val scope = descriptor.optJSONObject("scope") ?: JSONObject()
                scope.put("protocolVersion", 1)
                    .put("sessionId", options.getString("sessionId"))
                    .put("taskId", scope.optString("taskId").ifBlank {
                        descriptor.optString("sourceTaskId").ifBlank { "native-" + options.getString("sessionId") }
                    })
                    .put("revision", scope.optLong("revision", 0).coerceAtLeast(0))
                    .put("cancelEpoch", scope.optLong("cancelEpoch", 0).coerceAtLeast(0))
                descriptor.put("scope", scope)
                options.put("learning", descriptor)
                    .put("learningMicrophoneEnabled", call.argument<Boolean>("learningMicrophoneEnabled") == true)
            }
            if (game in setOf("learning", "build", "settlement")) {
                options.put("learningVoiceEnabled", call.argument<Boolean>("learningVoiceEnabled") == true)
                    .put("localVoiceLicenseAccepted", call.argument<Boolean>("localVoiceLicenseAccepted") == true)
                    .put("learningAutoRead", call.argument<Boolean>("learningAutoRead") == true)
                    .put("learningVoiceRate", (call.argument<Number>("learningVoiceRate")?.toDouble()
                        ?.takeIf { it.isFinite() } ?: 1.0).coerceIn(0.70, 1.60))
                // Release Flutter's local inference model before the
                // isolated lesson or village owns the same original voice.
                offlineSpeech?.release()
            }
            // Der Kartentisch führt Regeln, Mitspieler und Spielstand selbst
            // (Sternenstich, Sternenleiter, Lumo-Quartett). Er braucht keine
            // Partie aus der App und deshalb kein Token.
            if (game == "connect_four") {
                val token = call.argument<String>("connectFourToken")
                if (token == null || !ConnectFourBridge.hasAuthority(token)) {
                    refuse("invalid_connect_four", "Deine Vier-Gewinnt-Runde ist nicht verfügbar.")
                    return
                }
                options.put("connectFourToken", token)
            }
            if (game in setOf("memory", "quiz")) {
                val token = call.argument<String>("tableToken")
                if (token == null || !TableGamesBridge.hasAuthority(token, game)) {
                    refuse("invalid_table_game", "Deine Spielrunde ist nicht verfügbar.")
                    return
                }
                options.put("tableToken", token)
            }
            if (game == "kart") {
                // Geister-Duell / WLAN: nur geprüfte Formen; sonst wird das Feld weggelassen.
                options.put("playerName", KartGhostRules.playerName(call.argument<String>("playerName")))
                    .put("friendsLan", call.argument<Boolean>("friendsLan") == true)
                val onlineAllowed = call.argument<Boolean>("friendsOnline") == true
                val rawOnlineEndpoint = call.argument<String>("kartOnlineEndpoint")?.trim().orEmpty()
                val onlineEndpoint = runCatching {
                    val uri = java.net.URI(rawOnlineEndpoint)
                    if (rawOnlineEndpoint.length in 1..2048 && uri.scheme == "wss" &&
                        !uri.host.isNullOrEmpty() && uri.userInfo == null &&
                        uri.rawQuery == null && uri.rawFragment == null &&
                        (uri.port == -1 || uri.port in 1..65535)) {
                        uri.toASCIIString()
                    } else ""
                }.getOrDefault("")
                options.put("friendsOnline", onlineAllowed && onlineEndpoint.isNotEmpty())
                    .put("kartOnlineEndpoint", if (onlineAllowed) onlineEndpoint else "")
                val ghostDuel = call.argument<Boolean>("friendsGhostShare") == true
                options.put("friendsGhostShare", ghostDuel)
                val ghost = call.argument<String>("kartFriendGhost")
                if (ghostDuel && KartGhostRules.isLaunchText(ghost)) {
                    options.put("kartFriendGhost", ghost)
                        .put("kartFriendStart", call.argument<Boolean>("kartFriendStart") == true)
                }
            }
            options.put("reduceAnimations", call.argument<Boolean>("reduceAnimations") ?: false)
            val callerSession = options.getString("sessionId")
                // Der Kartentisch kehrt wie Kart und Lumo Lauf in die Spieleauswahl zurück.
                .takeIf { game in setOf("learning", "connect_four", "memory", "quiz") }
            val activity = when (game) {
                "connect_four" -> ConnectFourGameActivity::class.java
                "memory", "quiz" -> TableGameActivity::class.java
                else -> LumoGameActivity::class.java
            }
            val intent = Intent(this, activity)
                .putExtra("lumoLaunchOptions", options.toString())
                .putExtra(GameEventStore.CALLER_RETURN_SESSION, callerSession)
            if (callerSession != null) GameEventStore.beginCallerReturn(this)
            pendingGame = result
            pendingCallerReturnSession = callerSession
            pendingStartId = null
            journal { pendingStartId = GameStartJournal.begin(this, game, System.currentTimeMillis(), note) }
            startActivityForResult(intent, gameRequest)
        } catch (e: Exception) {
            pendingGame = null
            pendingCallerReturnSession = null
            val failedStart = pendingStartId
            pendingStartId = null
            journal {
                val detail = "${e.javaClass.simpleName}: ${e.message ?: ""}".trimEnd(' ', ':')
                if (failedStart != null) GameStartJournal.finish(this, failedStart, System.currentTimeMillis(), "exception", detail)
                else GameStartJournal.refused(this, scene, System.currentTimeMillis(), "exception", detail)
            }
            result.error("game_unavailable", "Das enthaltene Spiel konnte nicht gestartet werden.", null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        kartFriends?.handleIntent(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (localBackup?.onActivityResult(requestCode, resultCode, data) == true) return
        if (kartFriends?.onActivityResult(requestCode, resultCode, data) == true) return
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
            val startId = pendingStartId
            pendingStartId = null
            if (startId != null) {
                val outcome = when {
                    resultCode == RESULT_OK && data?.hasExtra("destination") == true -> "returned"
                    engineProcessRunning() -> "closed"
                    else -> "process_ended"
                }
                journal { GameStartJournal.finish(this, startId, System.currentTimeMillis(), outcome,
                    if (outcome == "returned") null else "resultCode=$resultCode") }
                // Godot meldet „geladen“ nur als Logzeile [Router] loaded:<szene>.
                Thread({ try { refreshLoadTimes(readOwnLog()) } catch (_: Exception) {} }, "LumoStartLoadTime").start()
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
                    val learningResult = data?.getStringExtra("learningResult")
                    callback.success(
                        if (learningResult != null) mapOf("destination" to destination, "learningResult" to learningResult)
                        else mapOf("destination" to destination)
                    )
                    pendingGame = null
                    pendingCallerReturnSession = null
                }
            }
            completeWhenStopped(0)
        }
    }

    override fun onResume() {
        super.onResume()
        hostForeground = true
        localRecognition?.setForeground(true)
    }

    override fun onPause() {
        hostForeground = false
        localRecognition?.setForeground(false)
        super.onPause()
    }

    override fun onRequestPermissionsResult(requestCode: Int,
        permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        localRecognition?.onRequestPermissionsResult(requestCode, permissions, grantResults)
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
        TableGamesBridge.detach()
        localRecognition?.destroy()
        localRecognition = null
        offlineSpeech?.destroy()
        offlineSpeech = null
        localBackup?.destroy()
        localBackup = null
        super.onDestroy()
    }
}
