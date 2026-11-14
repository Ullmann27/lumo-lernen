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

/** Memory/Quiz surface using the existing tested visibility lease. */
class TableGameActivity : GodotActivity() {
    @Volatile private var returning = false
    @Volatile private var active = false
    @Volatile private var options = "{}"
    @Volatile private var gameName = ""
    @Volatile private var sessionToken = ""
    @Volatile private var authority: IBinder? = null
    private var binding = false
    private val handler = Handler(Looper.getMainLooper())
    private fun token(): String = sessionToken
    private fun game(): String = gameName
    private val lease = ConnectFourVisibleLease(
        schedule = { task, delay -> handler.postDelayed(task, delay) },
        cancel = { handler.removeCallbacks(it) },
        pulse = { desired ->
            val visible = desired && active && binding && !returning &&
                TableAuthorityService.available(authority, token(), game())
            val saved = TableGamesBridge.pulse(filesDir, token(), game(), visible)
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
        try {
            val parsed = org.json.JSONObject(options)
            gameName = parsed.optString("game")
            sessionToken = parsed.optString("tableToken")
        } catch (_: Exception) { gameName = ""; sessionToken = "" }
        super.onCreate(state)
    }
    override fun onStart() {
        super.onStart()
        if (returning || binding) return
        if (!Regex("[a-f0-9]{32}").matches(token()) || game() !in setOf("memory", "quiz")) { returnToApp(); return }
        binding = true
        val bound = try { bindService(Intent(this, TableAuthorityService::class.java)
            .putExtra("tableToken", token()).putExtra("tableGame", game()), connection, Context.BIND_AUTO_CREATE) }
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
        if (!TableAuthorityService.available(remote, token(), game())) {
            runOnUiThread { if (authority === remote) { release(); returnToApp() } }
            return "{}"
        }
        return TableGamesBridge.state(filesDir, token(), game())
    }
    fun submit(payload: String): Boolean = active && !returning &&
        TableAuthorityService.available(authority, token(), game()) &&
        TableGamesBridge.submit(filesDir, token(), game(), payload)

    @Synchronized fun returnToApp(): Boolean {
        if (returning) return true
        val session = try {
            val raw = org.json.JSONObject(options)
            intent.getStringExtra(GameEventStore.CALLER_RETURN_SESSION)?.takeIf {
                raw.optString("game") == game() && game() in setOf("memory", "quiz") && raw.optString("sessionId") == it &&
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
    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> = setOf(TableGamesHostPlugin(engine, this))
    override fun onGodotForceQuit(instance: Godot) { returnToApp() }
    override fun onGodotRestartRequested(instance: Godot) { returnToApp() }
}

class TableGamesHostPlugin(engine: Godot, private val host: TableGameActivity) : GodotPlugin(engine) {
    override fun getPluginName(): String = "LumoHost"
    @UsedByGodot fun getLaunchOptions(): String = host.launchOptions()
    @UsedByGodot fun getTableState(): String = host.state()
    @UsedByGodot fun submitTableAction(payload: String): Boolean = host.submit(payload)
    @UsedByGodot fun returnToApp(destination: String, payload: String): Boolean = host.returnToApp()
    // Only the profile-bound Dart controller may commit Memory/Quiz rewards.
    @UsedByGodot fun reward(payload: String): Boolean = false
}
