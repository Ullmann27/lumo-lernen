package dev.ullmann.lumo

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotActivity
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/** Godot is part of this APK. Its engine has an isolated process for repeatable launches. */
class LumoGameActivity : GodotActivity() {
    private var returning = false
    private var launchOptions = "{}"

    override fun onCreate(savedInstanceState: Bundle?) {
        launchOptions = intent.getStringExtra("lumoLaunchOptions") ?: "{}"
        super.onCreate(savedInstanceState)
    }

    override fun getCommandLine(): MutableList<String> = ArrayList(super.getCommandLine()).apply {
        addAll(listOf("--main-pack", "res://lumo_game.pck", "--rendering-method", "gl_compatibility"))
    }

    override fun getHostPlugins(engine: Godot): Set<GodotPlugin> = setOf(LumoHostPlugin(engine, this))

    fun options(): String = launchOptions

    @Synchronized
    fun returnToLearningApp(destination: String): Boolean {
        if (returning) return true
        val target = if (destination == "learn") "learn" else "games"
        try {
            GameEventStore.recordReturn(this, target)
        } catch (error: Exception) {
            Log.e("LumoHost", "Could not save game return; keep result open", error)
            return false
        }
        returning = true
        runOnUiThread {
            setResult(Activity.RESULT_OK, Intent().putExtra("destination", target)
                .putExtra("gamePid", android.os.Process.myPid()))
            finish()
            // Android receives finish/result first. Kill only :lumo_game, never Flutter.
            Handler(Looper.getMainLooper()).postDelayed({
                android.os.Process.killProcess(android.os.Process.myPid())
            }, 500)
        }
        return true
    }

    override fun onGodotForceQuit(instance: Godot) { returnToLearningApp("games") }
    override fun onGodotRestartRequested(instance: Godot) { returnToLearningApp("games") }
}

class LumoHostPlugin(engine: Godot, private val host: LumoGameActivity) : GodotPlugin(engine) {
    override fun getPluginName(): String = "LumoHost"

    @UsedByGodot
    fun getLaunchOptions(): String = host.options()

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
