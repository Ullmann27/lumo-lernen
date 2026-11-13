package dev.ullmann.lumo

import android.app.Activity
import android.content.Intent
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.os.IBinder
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.enableEdgeToEdge
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotActivity
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/** Main-looper owner of the visible Cards lease; independent of render frames. */
internal class CardsLifecycleHeartbeat(
    private val schedule: (Runnable, Long) -> Unit,
    private val cancel: (Runnable) -> Unit,
    private val pulse: (Boolean) -> Boolean,
    private val unavailable: () -> Unit
) {
    private var generation = 0L
    private var running = false
    private var closed = false
    private var pending: Runnable? = null

    fun start() {
        if (closed) return
        generation++
        pending?.let(cancel)
        pending = null
        running = true
        beat(generation)
    }

    private fun beat(lease: Long) {
        if (!running || closed || lease != generation) return
        pending = null
        if (!pulse(true)) {
            stop()
            unavailable()
            return
        }
        if (!running || closed || lease != generation) return
        val next = Runnable { beat(lease) }
        pending = next
        schedule(next, 500)
    }

    fun stop() {
        generation++
        running = false
        pending?.let(cancel)
        pending = null
        pulse(false)
    }

    fun close() {
        closed = true
        stop()
    }
}

/** Godot is part of this APK. Its engine has an isolated process for repeatable launches. */
class LumoGameActivity : GodotActivity() {
    @Volatile private var returning = false
    private var cardsEdgeToEdge = false
    @Volatile private var launchOptions = "{}"
    @Volatile private var learningSpeech: LumoLearningSpeech? = null
    @Volatile private var cardsActive = false
    private fun cardsToken(): String = try { org.json.JSONObject(launchOptions).optString("cardsToken", "") } catch (_: Exception) { "" }
    @Volatile private var cardsAuthority: IBinder? = null
    private var cardsBindingRequested = false
    private val cardsBindingHandler = Handler(Looper.getMainLooper())
    private val cardsHeartbeat = CardsLifecycleHeartbeat(
        schedule = { task, delay -> cardsBindingHandler.postDelayed(task, delay) },
        cancel = { task -> cardsBindingHandler.removeCallbacks(task) },
        pulse = { active -> writeCardsLifecycle(active) },
        unavailable = {
            releaseCardsAuthority()
            returnToLearningApp("games")
        }
    )
    private val cardsBindingTimeout = Runnable {
        // Older supported Android releases do not deliver onNullBinding.
        // A dead/unavailable host must return to Flutter instead of trapping
        // the child on a table whose authoritative rules cannot answer.
        if (cardsBindingRequested && cardsAuthority == null) {
            releaseCardsAuthority()
            returnToLearningApp("games")
        }
    }
    private val cardsConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            if (!cardsBindingRequested) return
            cardsBindingHandler.removeCallbacks(cardsBindingTimeout)
            cardsAuthority = service
            if (cardsActive && !returning) cardsHeartbeat.start()
        }
        override fun onServiceDisconnected(name: ComponentName) {
            cardsAuthority = null
            cardsHeartbeat.stop()
            if (cardsBindingRequested) returnToLearningApp("games")
        }
        override fun onNullBinding(name: ComponentName) {
            releaseCardsAuthority()
            returnToLearningApp("games")
        }
        override fun onBindingDied(name: ComponentName) {
            releaseCardsAuthority()
            returnToLearningApp("games")
        }
    }

    private fun writeCardsLifecycle(active: Boolean): Boolean {
        val token = cardsToken()
        if (!Regex("[a-f0-9]{32}").matches(token)) return false
        val available = active && cardsActive && cardsBindingRequested && !returning &&
            CardsAuthorityService.available(cardsAuthority, token)
        val written = CardsTableBridge.pulse(filesDir, token, available)
        return written && (!active || available)
    }

    fun cardsAuthorityAvailable(): Boolean {
        if (returning) return false
        val authority = cardsAuthority ?: return false
        val available = CardsAuthorityService.available(authority, cardsToken())
        if (!available) runOnUiThread {
            if (cardsAuthority === authority) {
                releaseCardsAuthority()
                returnToLearningApp("games")
            }
        }
        return available && cardsAuthority === authority
    }

    override fun onStart() {
        super.onStart()
        val token = cardsToken()
        if (returning || !Regex("[a-f0-9]{32}").matches(token) || cardsBindingRequested) return
        cardsBindingRequested = true
        val accepted = try {
            bindService(Intent(this, CardsAuthorityService::class.java).putExtra("cardsToken", token),
                cardsConnection, Context.BIND_AUTO_CREATE)
        } catch (_: Exception) { false }
        if (!accepted) {
            releaseCardsAuthority()
            returnToLearningApp("games")
        } else if (cardsBindingRequested && cardsAuthority == null) {
            cardsBindingHandler.postDelayed(cardsBindingTimeout, 5000)
        }
    }

    private fun releaseCardsAuthority() {
        cardsHeartbeat.stop()
        cardsBindingHandler.removeCallbacks(cardsBindingTimeout)
        cardsAuthority = null
        if (cardsBindingRequested) {
            cardsBindingRequested = false
            try { unbindService(cardsConnection) } catch (_: Exception) { }
        }
    }

    override fun onStop() {
        cardsActive = false
        releaseCardsAuthority()
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        updateCardsWindowAppearance()
        cardsActive = true
        if (cardsAuthority != null && !returning) cardsHeartbeat.start()
        learningSpeech?.setActive(true)
    }

    override fun onPause() {
        cardsActive = false
        cardsHeartbeat.stop()
        learningSpeech?.setActive(false)
        super.onPause()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        launchOptions = intent.getStringExtra("lumoLaunchOptions") ?: "{}"
        val options = try { org.json.JSONObject(launchOptions) } catch (_: Exception) { org.json.JSONObject() }
        cardsEdgeToEdge = options.optString("game") == "cards"
        if (cardsEdgeToEdge) enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        if (options.optString("game") in setOf("learning", "build")) {
            learningSpeech = LumoLearningSpeech(applicationContext, options)
        }
    }

    private fun updateCardsWindowAppearance() {
        if (!cardsEdgeToEdge) return
        val engine = getGodot() ?: return
        // Godot 4.6.3's exported GodotApp performs this on resume and main-loop
        // start. Embedded GodotActivity does not. Keep the full Cards viewport
        // while exposing actual system-bar/cutout insets to its native header.
        engine.enableImmersiveMode(engine.isInImmersiveMode(), true)
        engine.enableEdgeToEdge(engine.isInEdgeToEdgeMode(), true)
        engine.setSystemBarsAppearance()
    }

    override fun onGodotMainLoopStarted() {
        super.onGodotMainLoopStarted()
        if (cardsEdgeToEdge) runOnUiThread { updateCardsWindowAppearance() }
    }

    override fun onDestroy() {
        cardsActive = false
        cardsHeartbeat.close()
        releaseCardsAuthority()
        learningSpeech?.destroy()
        learningSpeech = null
        super.onDestroy()
    }

    fun speakLearning(payload: String): Boolean = learningSpeech?.speak(payload) ?: false
    fun learningSpeechStatus(): String = learningSpeech?.status() ?: "{}"
    fun stopLearningSpeech() { learningSpeech?.stop() }

    override fun getCommandLine(): MutableList<String> = ArrayList(super.getCommandLine()).apply {
        addAll(listOf("--main-pack", "res://lumo_game.pck", "--rendering-method", "gl_compatibility"))
        if (cardsEdgeToEdge) add("--edge_to_edge")
    }

    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> = setOf(LumoHostPlugin(engine, this))

    fun options(): String = launchOptions

    private fun callerReturnSession(): String? = try {
        val options = org.json.JSONObject(launchOptions)
        intent.getStringExtra(GameEventStore.CALLER_RETURN_SESSION)?.takeIf {
            options.optString("game") in setOf("learning", "cards") &&
                options.optString("sessionId") == it && GameEventStore.validCallerSession(it)
        }
    } catch (_: Exception) { null }

    @Synchronized
    fun returnToLearningApp(destination: String): Boolean {
        if (returning) return true
        val target = if (destination == "learn") "learn" else "games"
        val callerSession = callerReturnSession()
        try {
            GameEventStore.recordReturn(this, target, callerSession)
        } catch (error: Exception) {
            Log.e("LumoHost", "Could not save game return; keep result open", error)
            return false
        }
        returning = true
        learningSpeech?.stop()
        runOnUiThread {
            cardsActive = false
            cardsHeartbeat.close()
            releaseCardsAuthority()
            setResult(Activity.RESULT_OK, Intent().putExtra("destination", target)
                .putExtra("gamePid", android.os.Process.myPid())
                .putExtra(GameEventStore.CALLER_RETURN_SESSION, callerSession))
            finish()
            // Android receives finish/result first. Kill only :lumo_game, never Flutter.
            Handler(Looper.getMainLooper()).postDelayed({
                android.os.Process.killProcess(android.os.Process.myPid())
            }, 500)
        }
        return true
    }

    private fun returnDestination(): String = try {
        if (org.json.JSONObject(launchOptions).optString("game") == "learning") "learn" else "games"
    } catch (_: Exception) { "games" }
    override fun onGodotForceQuit(instance: Godot) { returnToLearningApp(returnDestination()) }
    override fun onGodotRestartRequested(instance: Godot) { returnToLearningApp(returnDestination()) }
}

class LumoHostPlugin(engine: Godot, private val host: LumoGameActivity) : GodotPlugin(engine) {
    override fun getPluginName(): String = "LumoHost"

    @UsedByGodot
    fun getLaunchOptions(): String = host.options()

    @UsedByGodot
    fun speakLearning(payload: String): Boolean = host.speakLearning(payload)

    @UsedByGodot
    fun getLearningSpeechStatus(): String = host.learningSpeechStatus()

    @UsedByGodot
    fun stopLearningSpeech() { host.stopLearningSpeech() }

    @UsedByGodot
    fun getCardsState(): String {
        // Render stalls must not expire an otherwise visible Android activity.
        // Only the main-looper lifecycle owner writes heartbeats and pause epochs.
        if (!host.cardsAuthorityAvailable()) return "{}"
        val token = try { org.json.JSONObject(host.options()).optString("cardsToken", "") } catch (_: Exception) { "" }
        return CardsTableBridge.state(host.filesDir, token)
    }

    @UsedByGodot
    fun submitCardsAction(payload: String): Boolean {
        val token = try { org.json.JSONObject(host.options()).optString("cardsToken", "") } catch (_: Exception) { "" }
        return CardsTableBridge.submit(host.filesDir, token, payload)
    }

    @UsedByGodot
    fun reward(payload: String): Boolean = try {
        GameEventStore.recordReward(host, payload)
    } catch (error: Exception) {
        Log.e("LumoHost", "Could not save game reward", error)
        false
    }

    @UsedByGodot
    fun returnToApp(destination: String, payload: String): Boolean {
        if (payload.isNotBlank()) {
            try {
                if (org.json.JSONObject(payload).optString("status") == "completed") {
                    if (!reward(payload)) return false
                }
            } catch (error: Exception) {
                Log.e("LumoHost", "Invalid return payload", error)
                return false
            }
        }
        return host.returnToLearningApp(destination)
    }
}
