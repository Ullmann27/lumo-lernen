"""Execute the complete production Activity with a deterministic JVM main looper.

Android/Godot boundary classes are explicit test doubles, not an emulator. The
Activity and its lifecycle scheduler are compiled verbatim; no copied heartbeat
algorithm or network/download dependency is used by this test.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get('LUMO_HEARTBEAT_SOURCE',
                            ROOT / 'tools/auto_install/LumoGameActivity.kt'))


def missing_toolchain(message):
    if os.environ.get('REQUIRE_ALL_TESTS', '').lower() == 'true':
        raise RuntimeError(message)
    raise unittest.SkipTest(message)


STUBS = {
    'Os.kt': r'''
package android.os
class Bundle
interface IBinder
class Looper { companion object { private val main = Looper(); fun getMainLooper() = main } }
object TestLooper {
    data class Entry(val due: Long, val task: Runnable)
    var now = 0L
    val queue = mutableListOf<Entry>()
    fun advance(milliseconds: Long) {
        val until = now + milliseconds
        var count = 0
        while (true) {
            val next = queue.minByOrNull { it.due } ?: break
            if (next.due > until) break
            check(++count < 10000) { "Unbounded scheduling" }
            queue.remove(next); now = next.due; next.task.run()
        }
        now = until
    }
}
class Handler(looper: Looper) {
    fun postDelayed(task: Runnable, delay: Long): Boolean {
        TestLooper.queue.add(TestLooper.Entry(TestLooper.now + delay, task)); return true
    }
    fun removeCallbacks(task: Runnable) { TestLooper.queue.removeAll { it.task === task } }
}
object Process { var kills = 0; fun myPid() = 73; fun killProcess(pid: Int) { kills++ } }
''',
    'Content.kt': r'''
package android.content
import android.os.IBinder
import java.io.File
class ComponentName
interface ServiceConnection {
    fun onServiceConnected(name: ComponentName, service: IBinder)
    fun onServiceDisconnected(name: ComponentName)
    fun onNullBinding(name: ComponentName)
    fun onBindingDied(name: ComponentName)
}
object Hooks { var connection: ServiceConnection? = null; var unbound = 0 }
open class Context {
    companion object { const val BIND_AUTO_CREATE = 1 }
    val filesDir = File(".")
    val applicationContext: Context get() = this
    fun bindService(intent: Intent, connection: ServiceConnection, flags: Int): Boolean {
        Hooks.connection = connection; return true
    }
    fun unbindService(connection: ServiceConnection) { Hooks.unbound++ }
}
class Intent {
    constructor()
    constructor(context: Context, type: Class<*>)
    private val strings = mutableMapOf<String, String>()
    fun getStringExtra(key: String): String? = strings[key]
    fun putExtra(key: String, value: String?): Intent { if (value != null) strings[key] = value; return this }
    fun putExtra(key: String, value: Int): Intent = this
}
''',
    'Activity.kt': r'''
package android.app
import android.content.Context
import android.content.Intent
import android.os.Bundle
open class Activity : Context() {
    companion object { const val RESULT_OK = -1 }
    var intent = Intent()
    var finished = false
    open fun onStart() {}
    open fun onStop() {}
    open fun onResume() {}
    open fun onPause() {}
    open fun onCreate(bundle: Bundle?) {}
    open fun onDestroy() {}
    fun runOnUiThread(action: Runnable) { action.run() }
    fun setResult(code: Int, intent: Intent) {}
    fun finish() { finished = true }
}
''',
    'Log.kt': r'''
package android.util
object Log { fun e(tag: String, text: String, error: Throwable): Int = 0 }
''',
    'Godot.kt': r'''
package org.godotengine.godot
import android.app.Activity
import org.godotengine.godot.plugin.GodotPlugin
class Godot
open class GodotActivity : Activity() {
    open fun getCommandLine(): MutableList<String> = mutableListOf()
    open fun getHostPlugins(engine: Godot): Set<GodotPlugin> = emptySet()
    open fun onGodotForceQuit(instance: Godot) {}
    open fun onGodotRestartRequested(instance: Godot) {}
}
''',
    'Plugin.kt': r'''
package org.godotengine.godot.plugin
import org.godotengine.godot.Godot
annotation class UsedByGodot
open class GodotPlugin(engine: Godot) { open fun getPluginName(): String = "" }
''',
    'Json.kt': r'''
package org.json
class JSONObject(private val raw: String = "{}") {
    fun optString(key: String, fallback: String = ""): String =
        Regex("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"").find(raw)?.groupValues?.get(1) ?: fallback
}
''',
    'Bridge.kt': r'''
package dev.ullmann.lumo
import android.content.Context
import android.os.IBinder
import android.os.TestLooper
import java.io.File
class TestBinder : IBinder { var valid = true }
class CardsAuthorityService {
    companion object {
        fun available(binder: IBinder?, token: String): Boolean =
            binder is TestBinder && binder.valid && token == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
}
object CardsTableBridge {
    data class Pulse(val time: Long, val active: Boolean)
    var open = true
    val pulses = mutableListOf<Pulse>()
    fun pulse(root: File, token: String, active: Boolean): Boolean {
        if (!open || token != "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") return false
        pulses.add(Pulse(TestLooper.now, active)); return true
    }
    fun state(root: File, token: String): String = if (open) "{\"protocol\":1}" else "{}"
    fun submit(root: File, token: String, payload: String): Boolean = open
}
object GameEventStore {
    const val CALLER_RETURN_SESSION = "callerReturnSession"
    var returns = 0
    fun validCallerSession(session: String) = true
    fun recordReturn(context: Context, target: String, caller: String?) { returns++ }
    fun recordReward(context: Context, payload: String) = true
}
class LumoLearningSpeech(context: Context, options: org.json.JSONObject) {
    fun setActive(value: Boolean) {}
    fun destroy() {}
    fun speak(value: String) = true
    fun status() = "{}"
    fun stop() {}
}
''',
}
HARNESS = r'''
package dev.ullmann.lumo
import android.content.ComponentName
import android.content.Hooks
import android.content.Intent
import android.os.Bundle
import android.os.TestLooper
import org.godotengine.godot.Godot

object CardsHeartbeatRegression {
    private fun create(connected: Boolean = true, cards: Boolean = true): Pair<LumoGameActivity, TestBinder> {
        val activity = LumoGameActivity()
        val options = if (cards) "{\"game\":\"cards\",\"cardsToken\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}" else "{\"game\":\"kart\"}"
        activity.intent = Intent().putExtra("lumoLaunchOptions", options)
        activity.onCreate(Bundle()); activity.onStart(); activity.onResume()
        val binder = TestBinder()
        if (connected && cards) Hooks.connection!!.onServiceConnected(ComponentName(), binder)
        return Pair(activity, binder)
    }
    private fun live(): Boolean = CardsTableBridge.pulses.lastOrNull()?.active == true
    private fun noActiveAfter(at: Long) = CardsTableBridge.pulses.none { it.time > at && it.active }
    @JvmStatic fun main(args: Array<String>) {
        when (args[0]) {
            "render-stall" -> {
                create()
                // No native getCardsState or render frame is executed for six seconds.
                repeat(12) {
                    TestLooper.advance(500)
                    check(live()) { "Visible, bound activity must stay active during render stall" }
                    check(TestLooper.now - CardsTableBridge.pulses.last().time < 2500) {
                        "Render stall expired the unchanged 2500-ms authority lease"
                    }
                }
                check(CardsTableBridge.pulses.count { it.active } >= 13)
                check(TestLooper.queue.size == 1) { "Exactly one bounded recurring heartbeat" }
            }
            "pause-and-stale-callback" -> {
                val (activity, _) = create(); TestLooper.advance(500)
                val old = TestLooper.queue.single().task
                activity.onPause(); check(!live())
                val count = CardsTableBridge.pulses.size
                old.run(); TestLooper.advance(4000)
                check(!live() && CardsTableBridge.pulses.size == count)
                check(TestLooper.queue.isEmpty())
                activity.onResume(); check(live())
                val resumed = CardsTableBridge.pulses.size
                old.run(); check(CardsTableBridge.pulses.size == resumed)
                check(TestLooper.queue.size == 1)
            }
            "stop-and-late-binding" -> {
                val (activity, binder) = create(); TestLooper.advance(500)
                val old = TestLooper.queue.single().task
                activity.onStop(); check(!live()); check(Hooks.unbound == 1)
                old.run(); Hooks.connection!!.onServiceConnected(ComponentName(), binder)
                TestLooper.advance(4000); check(noActiveAfter(500))
                check(TestLooper.queue.isEmpty())
            }
            "destroy" -> {
                val (activity, binder) = create(); TestLooper.advance(500)
                val old = TestLooper.queue.single().task
                activity.onDestroy(); check(!live()); check(Hooks.unbound == 1)
                old.run(); Hooks.connection!!.onServiceConnected(ComponentName(), binder)
                activity.onResume(); TestLooper.advance(4000)
                check(noActiveAfter(500) && TestLooper.queue.isEmpty())
            }
            "return" -> {
                val (activity, _) = create(); TestLooper.advance(500)
                val old = TestLooper.queue.single().task
                check(activity.returnToLearningApp("games")); check(activity.finished)
                check(!live() && GameEventStore.returns == 1)
                old.run(); TestLooper.advance(4000); check(noActiveAfter(500))
                check(TestLooper.queue.isEmpty())
            }
            "authority-lost" -> {
                val (activity, binder) = create(); TestLooper.advance(500)
                binder.valid = false; TestLooper.advance(500)
                check(!live() && activity.finished) { "Revoked authority must stop without a renderer poll" }
                TestLooper.advance(4000); check(noActiveAfter(500))
                check(GameEventStore.returns == 1 && TestLooper.queue.isEmpty())
            }
            "missing-authority" -> {
                val (activity, _) = create(connected = false)
                TestLooper.advance(6000)
                check(CardsTableBridge.pulses.none { it.active })
                check(activity.finished && TestLooper.queue.isEmpty())
            }
            "closed-mailbox" -> {
                val (activity, _) = create(); TestLooper.advance(500)
                CardsTableBridge.open = false; TestLooper.advance(500)
                check(activity.finished) { "Closed mailbox must terminate the active lease" }
                TestLooper.advance(4000); check(noActiveAfter(500))
                check(TestLooper.queue.isEmpty())
            }
            "render-read-is-read-only" -> {
                val (activity, _) = create(); TestLooper.advance(500)
                val plugin = LumoHostPlugin(Godot(), activity)
                val before = CardsTableBridge.pulses.size
                repeat(20) { plugin.getCardsState() }
                check(CardsTableBridge.pulses.size == before) { "Render reads must not own lifecycle writes" }
                activity.onPause(); val paused = CardsTableBridge.pulses.size
                repeat(20) { plugin.getCardsState() }
                check(CardsTableBridge.pulses.size == paused && !live())
            }
            "repeated-resume" -> {
                val (activity, _) = create()
                repeat(5) { activity.onResume() }
                check(TestLooper.queue.size == 1)
                TestLooper.advance(3000); check(live() && TestLooper.queue.size == 1)
            }
            "other-game" -> {
                val (activity, _) = create(cards = false)
                TestLooper.advance(6000); check(!activity.finished)
                activity.onPause(); activity.onStop(); activity.onDestroy()
                check(CardsTableBridge.pulses.isEmpty() && TestLooper.queue.isEmpty())
            }
            else -> error("Unknown scenario")
        }
        println("CARDS_LIFECYCLE_HEARTBEAT_PASS " + args[0])
    }
}
'''


class CardsLifecycleHeartbeatTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-cards-heartbeat-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(configured) if configured.is_file() else shutil.which('java')
        if not cls.java:
            missing_toolchain('A JDK is required for the production Activity regression')
        candidates = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                      Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        gradle = shutil.which('gradle')
        if gradle:
            candidates.append(Path(gradle).resolve().parents[1] / 'lib')
        libraries = next((p for p in candidates if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        if libraries is None:
            missing_toolchain('Use the existing validated Gradle installation or LUMO_KOTLIN_LIB_DIR; this test downloads nothing')
        sources = []
        for name, text in {**STUBS, 'CardsHeartbeatRegression.kt': HARNESS}.items():
            path = cls.work / name
            path.write_text(text)
            sources.append(str(path))
        cls.classes = cls.work / 'classes'
        cls.classes.mkdir()
        cls.classpath = os.pathsep.join(map(str, [cls.classes, next(libraries.glob('kotlin-stdlib-*.jar'))]))
        result = subprocess.run([
            cls.java, '-cp', os.pathsep.join(map(str, libraries.glob('*.jar'))),
            'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
            '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(cls.classes),
            str(SOURCE), *sources,
        ], capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        print('Compiled complete production Activity SHA256=' + hashlib.sha256(SOURCE.read_bytes()).hexdigest())

    def scenario(self, name):
        result = subprocess.run([
            self.java, '-cp', self.classpath, 'dev.ullmann.lumo.CardsHeartbeatRegression', name,
        ], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('CARDS_LIFECYCLE_HEARTBEAT_PASS ' + name, result.stdout)
        print(result.stdout.strip())

    def test_render_stall_exceeding_unchanged_lease(self): self.scenario('render-stall')
    def test_pause_and_old_callbacks_never_revive_lease(self): self.scenario('pause-and-stale-callback')
    def test_stop_and_late_service_connection(self): self.scenario('stop-and-late-binding')
    def test_destroy_and_late_callback(self): self.scenario('destroy')
    def test_explicit_return_stops_before_finish(self): self.scenario('return')
    def test_authority_loss_without_render_poll(self): self.scenario('authority-lost')
    def test_missing_authority_keeps_existing_binding_deadline(self): self.scenario('missing-authority')
    def test_closed_mailbox_does_not_renew_lease(self): self.scenario('closed-mailbox')
    def test_render_thread_cannot_write_active_or_inactive_pulse(self): self.scenario('render-read-is-read-only')
    def test_repeated_resume_does_not_duplicate_scheduled_loop(self): self.scenario('repeated-resume')
    def test_other_games_do_not_start_cards_heartbeat(self): self.scenario('other-game')


class CardsHeartbeatDependencyContractTest(unittest.TestCase):
    def test_mandatory_studio_run_cannot_skip_missing_compiler(self):
        with patch.dict(os.environ, {'REQUIRE_ALL_TESTS': 'true'}):
            with self.assertRaisesRegex(RuntimeError, 'compiler missing'):
                missing_toolchain('compiler missing')

    def test_optional_legacy_environment_reports_missing_dependency_as_skip(self):
        with patch.dict(os.environ, {'REQUIRE_ALL_TESTS': 'false'}):
            with self.assertRaisesRegex(unittest.SkipTest, 'compiler missing'):
                missing_toolchain('compiler missing')


if __name__ == '__main__':
    unittest.main()
