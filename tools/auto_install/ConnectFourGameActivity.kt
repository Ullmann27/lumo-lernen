package dev.ullmann.lumo

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotActivity
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/** Own main-thread lifecycle lease. A stale callback cannot revive a pause. */
internal class ConnectFourVisibleLease(
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
        generation++; pending?.let(cancel); pending = null
        running = true; beat(generation)
    }
    private fun beat(lease: Long) {
        if (closed || !running || lease != generation) return
        pending = null
        if (!pulse(true)) { stop(); unavailable(); return }
        if (closed || !running || lease != generation) return
        pending = Runnable { beat(lease) }.also { schedule(it, 500) }
    }
    fun stop() {
        generation++; running = false; pending?.let(cancel); pending = null
        pulse(false)
    }
    fun close() { closed = true; stop() }
}

/** Dedicated C4 surface; does not change Cards opcodes, service or Activity. */
class ConnectFourGameActivity : GodotActivity() {
    @Volatile private var returning = false
    @Volatile private var active = false
    @Volatile private var options = "{}"
    @Volatile private var authority: IBinder? = null
    private var binding = false
    private val handler = Handler(Looper.getMainLooper())
    private fun token(): String = try { org.json.JSONObject(options).optString("connectFourToken") } catch (_: Exception) { "" }
    private val lease = ConnectFourVisibleLease(
        schedule = { task, delay -> handler.postDelayed(task, delay) },
        cancel = { handler.removeCallbacks(it) },
        pulse = { desired ->
            val visible = desired && active && binding && !returning &&
                ConnectFourAuthorityService.available(authority, token())
            val saved = ConnectFourBridge.pulse(filesDir, token(), visible)
            saved && (!desired || visible)
        },
        unavailable = { release(); returnToApp() }
    )
    private val timeout = Runnable { if (binding && authority == null) { release(); returnToApp() } }
    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, remote: IBinder) {
            if (!binding || returning) return
            handler.removeCallbacks(timeout); authority = remote
            if (active) lease.start()
        }
        override fun onServiceDisconnected(name: ComponentName) { authority = null; lease.stop(); if (binding) returnToApp() }
        override fun onNullBinding(name: ComponentName) { release(); returnToApp() }
        override fun onBindingDied(name: ComponentName) { release(); returnToApp() }
    }
    override fun onCreate(state: Bundle?) {
        options = intent.getStringExtra("lumoLaunchOptions") ?: "{}"
        super.onCreate(state)
    }
    override fun onStart() {
        super.onStart()
        if (returning || binding) return
        if (!Regex("[a-f0-9]{32}").matches(token())) { returnToApp(); return }
        binding = true
        val bound = try { bindService(Intent(this, ConnectFourAuthorityService::class.java)
            .putExtra("connectFourToken", token()), connection, Context.BIND_AUTO_CREATE) }
            catch (_: Exception) { false }
        if (!bound) { release(); returnToApp() }
        else if (binding && authority == null) handler.postDelayed(timeout, 5000)
    }
    override fun onResume() { super.onResume(); active = true; if (authority != null && !returning) lease.start() }
    override fun onPause() { active = false; lease.stop(); super.onPause() }
    override fun onStop() { active = false; release(); super.onStop() }
    override fun onDestroy() { active = false; lease.close(); release(); super.onDestroy() }
    private fun release() {
        lease.stop(); handler.removeCallbacks(timeout); authority = null
        if (binding) { binding = false; try { unbindService(connection) } catch (_: Exception) {} }
    }
    fun launchOptions(): String = options
    fun state(): String {
        val remote = authority ?: return "{}"
        if (!active || returning) return "{}"
        if (!ConnectFourAuthorityService.available(remote, token())) {
            runOnUiThread { if (authority === remote) { release(); returnToApp() } }
            return "{}"
        }
        return ConnectFourBridge.state(filesDir, token())
    }
    fun submit(payload: String): Boolean = active && !returning &&
        ConnectFourAuthorityService.available(authority, token()) &&
        ConnectFourBridge.submit(filesDir, token(), payload)

    @Synchronized fun returnToApp(): Boolean {
        if (returning) return true
        val session = try {
            val raw = org.json.JSONObject(options)
            intent.getStringExtra(GameEventStore.CALLER_RETURN_SESSION)?.takeIf {
                raw.optString("game") == "connect_four" && raw.optString("sessionId") == it &&
                    GameEventStore.validCallerSession(it)
            }
        } catch (_: Exception) { null }
        try { GameEventStore.recordReturn(this, "games", session) }
        catch (_: Exception) { return false }
        returning = true
        runOnUiThread {
            active = false; lease.close(); release()
            setResult(Activity.RESULT_OK, Intent().putExtra("destination", "games")
                .putExtra("gamePid", android.os.Process.myPid())
                .putExtra(GameEventStore.CALLER_RETURN_SESSION, session))
            finish()
            handler.postDelayed({ android.os.Process.killProcess(android.os.Process.myPid()) }, 500)
        }
        return true
    }
    override fun getCommandLine(): MutableList<String> = ArrayList(super.getCommandLine()).apply {
        addAll(listOf("--main-pack", "res://lumo_game.pck", "--rendering-method", "gl_compatibility"))
    }
    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> = setOf(ConnectFourHostPlugin(engine, this))
    override fun onGodotForceQuit(instance: Godot) { returnToApp() }
    override fun onGodotRestartRequested(instance: Godot) { returnToApp() }
}

class ConnectFourHostPlugin(engine: Godot, private val host: ConnectFourGameActivity) : GodotPlugin(engine) {
    override fun getPluginName(): String = "LumoHost"
    @UsedByGodot fun getLaunchOptions(): String = host.launchOptions()
    @UsedByGodot fun getConnectFourState(): String = host.state()
    @UsedByGodot fun submitConnectFourAction(payload: String): Boolean = host.submit(payload)
    @UsedByGodot fun returnToApp(destination: String, payload: String): Boolean = host.returnToApp()
    // C4 rewards belong exclusively to its Dart controller. Reject renderer awards.
    @UsedByGodot fun reward(payload: String): Boolean = false
}
