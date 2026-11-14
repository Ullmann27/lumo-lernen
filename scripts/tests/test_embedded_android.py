import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('embedded', ROOT / 'scripts/prepare_embedded_games.py')
embedded = importlib.util.module_from_spec(spec)
spec.loader.exec_module(embedded)


class EmbeddedAndroidTest(unittest.TestCase):
    def test_same_package_private_engine_repeatable_preparation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            main = root / 'android/app/src/main'
            main.mkdir(parents=True)
            manifest = main / 'AndroidManifest.xml'
            manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><activity android:name=".MainActivity" android:exported="true" /></application><queries><package android:name="dev.ullmann.lumo3d" /></queries></manifest>')
            gradle = root / 'android/app/build.gradle.kts'
            gradle.write_text('android { namespace = "dev.ullmann.lumo.lumo_lernen"\n defaultConfig { applicationId = "dev.ullmann.lumo.lumo_lernen.coachpreview" } }')
            templates = root / 'tools/auto_install'
            templates.mkdir(parents=True)
            for filename in ('GameEventStore.kt', 'LumoGameActivity.kt', 'CardsTableBridge.kt', 'CardsAuthorityService.kt', 'CardsAuthorityRegistry.java'):
                (templates / filename).write_text((ROOT / 'tools/auto_install' / filename).read_text())
            # Upgrade a host already prepared by the old script. Existing app
            # rules and its reflected plugin rule must survive the JNI fix.
            rules = root / 'android/app/proguard-rules.pro'
            original_rules = ('# Existing application rules\n'
                              '-keep class example.CustomBridge { *; }\n'
                              '-keep class dev.ullmann.lumo.lumo_lernen.LumoHostPlugin { *; }\n')
            rules.write_text(original_rules)
            embedded.prepare(root)
            first_manifest, first_gradle, first_rules = manifest.read_bytes(), gradle.read_bytes(), rules.read_bytes()
            embedded.prepare(root)
            self.assertEqual(first_manifest, manifest.read_bytes())
            self.assertEqual(first_gradle, gradle.read_bytes())
            self.assertEqual(first_rules, rules.read_bytes())
            self.assertTrue(rules.read_text().startswith(original_rules))
            self.assertEqual(rules.read_text().count('-keep class org.godotengine.godot.** { *; }'), 1)
            self.assertEqual(rules.read_text().count('-keep class dev.ullmann.lumo.lumo_lernen.LumoHostPlugin { *; }'), 1)
            self.assertEqual(rules.read_text().count(
                '-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }'), 1)
            doc = ET.parse(manifest).getroot()
            attr = lambda name: '{http://schemas.android.com/apk/res/android}' + name
            activities = doc.findall('application/activity')
            self.assertEqual(len(activities), 2)
            engine = activities[1]
            self.assertEqual(engine.get(attr('exported')), 'false')
            self.assertEqual(engine.get(attr('process')), ':lumo_game')
            self.assertEqual(engine.get(attr('resizeableActivity')), 'true')
            services = doc.findall('application/service')
            self.assertEqual(len(services), 1)
            self.assertEqual(services[0].get(attr('name')), 'dev.ullmann.lumo.lumo_lernen.CardsAuthorityService')
            self.assertEqual(services[0].get(attr('exported')), 'false')
            self.assertIsNone(services[0].get(attr('process')), 'Authority must share the Dart main process')
            self.assertFalse(doc.findall('uses-permission'), 'No new background/wake/network permissions')
            service_file = main / 'kotlin/dev/ullmann/lumo/lumo_lernen/CardsAuthorityService.kt'
            self.assertTrue(service_file.is_file())
            self.assertIn('package dev.ullmann.lumo.lumo_lernen', service_file.read_text())
            registry_file = main / 'java/dev/ullmann/lumo/lumo_lernen/CardsAuthorityRegistry.java'
            self.assertTrue(registry_file.is_file())
            self.assertTrue(registry_file.read_text().startswith('package dev.ullmann.lumo.lumo_lernen;\n'))
            self.assertFalse(doc.findall('queries/package'))
            renderer = [entry for entry in doc.findall('application/meta-data')
                        if entry.get(attr('name')) == 'io.flutter.embedding.android.EnableImpeller']
            self.assertEqual(len(renderer), 1)
            self.assertEqual(renderer[0].get(attr('value')), 'false')
            self.assertIn('org.godotengine:godot:4.6.3.stable', gradle.read_text())
            self.assertIn('.coachpreview', gradle.read_text())
            self.assertIn('noCompress += "pck"', gradle.read_text())
            self.assertIn('if (project.findProperty("split-per-abi") != "true") {', gradle.read_text())
            self.assertIn('abiFilters.addAll(listOf("arm64-v8a", "x86_64"))', gradle.read_text())
            self.assertNotIn('ndk { abiFilters.clear(); abiFilters.addAll', gradle.read_text())
            self.assertIn('android.applicationVariants.configureEach {', gradle.read_text())
            self.assertIn('apkOutput.versionCodeOverride = flutter.versionCode', gradle.read_text())
            self.assertEqual(gradle.read_text().count('apkOutput.versionCodeOverride = flutter.versionCode'), 1)
            self.assertNotIn('afterEvaluate {', gradle.read_text())
            self.assertNotIn('androidComponents {', gradle.read_text())
            self.assertIn('tasks.register("verifyLumoSplitVersionCodes")', gradle.read_text())
            self.assertIn('apkOutput.versionCodeOverride == expected', gradle.read_text())


# Compile the real embedded Activity against small observable JVM adapters.
# These adapters model call boundaries, not Android rendering or actual insets.
# The clean-source AAR compilation and exact-source Android run remain required.
class EmbeddedCardsWindowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import hashlib
        import os
        import shutil
        import subprocess
        import urllib.request
        from scripts.tests.test_game_return_contract import JSON_URL, JSON_SHA256

        cls.os = os
        cls.subprocess = subprocess
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-cards-window-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(configured) if configured.is_file() else shutil.which('java')
        if not cls.java:
            raise RuntimeError('A JDK is required for the embedded Activity regression')
        gradle = shutil.which('gradle')
        candidates = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                      Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        if gradle:
            candidates.append(Path(gradle).resolve().parents[1] / 'lib')
        libraries = next((p for p in candidates if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        if libraries is None:
            raise RuntimeError('Set LUMO_KOTLIN_LIB_DIR or use the verified Gradle installation on PATH')
        supplied = os.environ.get('LUMO_TEST_JSON_JAR')
        if supplied:
            data = Path(supplied).read_bytes()
        else:
            with urllib.request.urlopen(JSON_URL, timeout=60) as response:
                data = response.read()
        if hashlib.sha256(data).hexdigest() != JSON_SHA256:
            raise RuntimeError('The existing test-only JSON dependency digest changed')
        json_jar = cls.work / 'json.jar'
        json_jar.write_bytes(data)
        sources = []
        for name, source in WINDOW_ADAPTERS.items():
            path = cls.work / name
            path.write_text(source)
            sources.append(str(path))
        classes = cls.work / 'classes'
        classes.mkdir()
        stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
        cls.classpath = os.pathsep.join(map(str, [classes, json_jar, stdlib]))
        cls.run_checked([cls.java, '-cp', os.pathsep.join(map(str, libraries.glob('*.jar'))),
                         'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                         '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(classes),
                         str(ROOT / 'tools/auto_install/LumoGameActivity.kt'), *sources])

    @classmethod
    def run_checked(cls, arguments):
        result = cls.subprocess.run(arguments, capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def scenario(self, name):
        result = self.run_checked([self.java, '-cp', self.classpath,
                                   'dev.ullmann.lumo.CardsWindowRegression', name])
        self.assertIn('CARDS_WINDOW_CALLS_PASS ' + name, result.stdout)
        print(result.stdout.strip())

    def test_cards_initializes_real_start_flags_and_resume_window_calls(self):
        self.scenario('cards')

    def test_cards_waits_for_engine_and_dispatches_main_loop_window_calls_on_ui_thread(self):
        self.scenario('delayed-engine')

    def test_other_games_keep_their_original_arguments_and_window_lifecycle(self):
        self.scenario('non-cards')

    def test_cards_window_hook_keeps_live_authority_pause_resume_and_stop_guards(self):
        self.scenario('authority')


WINDOW_ADAPTERS = {
    'AndroidActivity.kt': r'''
package android.app
open class Activity : android.content.Context() {
    companion object { const val RESULT_OK = -1 }
    var intent = android.content.Intent()
    fun setResult(code: Int, intent: android.content.Intent) {}
    fun finish() {}
    fun runOnUiThread(action: Runnable) { org.godotengine.godot.Calls.ui.add(action) }
}
''',
    'AndroidContext.kt': r'''
package android.content
import android.os.IBinder
import org.godotengine.godot.Calls
open class Context {
    companion object { const val BIND_AUTO_CREATE = 1 }
    val filesDir = java.io.File(".")
    val applicationContext: Context get() = this
    var connection: ServiceConnection? = null
    fun bindService(intent: Intent, service: ServiceConnection, flags: Int): Boolean {
        connection = service
        Calls.events.add("bind")
        return true
    }
    fun unbindService(service: ServiceConnection) { Calls.events.add("unbind") }
}
class Intent() {
    constructor(context: Context, cls: Class<*>) : this()
    private val extras = mutableMapOf<String, Any?>()
    fun getStringExtra(key: String): String? = extras[key] as? String
    fun putExtra(key: String, value: String?): Intent { extras[key] = value; return this }
    fun putExtra(key: String, value: Int): Intent { extras[key] = value; return this }
}
class ComponentName
interface ServiceConnection {
    fun onServiceConnected(name: ComponentName, service: IBinder)
    fun onServiceDisconnected(name: ComponentName)
    fun onNullBinding(name: ComponentName)
    fun onBindingDied(name: ComponentName)
}
''',
    'AndroidOs.kt': r'''
package android.os
interface IBinder
class Bundle
class Looper { companion object { fun getMainLooper() = Looper() } }
class Handler(looper: Looper) {
    fun removeCallbacks(action: Runnable) {}
    fun postDelayed(action: Runnable, delay: Long): Boolean = true
}
object Process {
    fun myPid(): Int = 1
    fun killProcess(pid: Int) {}
}
''',
    'AndroidLog.kt': r'''
package android.util
object Log { fun e(tag: String, message: String, error: Throwable): Int = 0 }
''',
    'AndroidEdgeToEdge.kt': r'''
package androidx.activity
fun org.godotengine.godot.GodotActivity.enableEdgeToEdge() {
    org.godotengine.godot.Calls.events.add("android-edge")
}
''',
    'Godot.kt': r'''
package org.godotengine.godot
import android.os.Bundle
import org.godotengine.godot.plugin.GodotPlugin
object Calls {
    val events = mutableListOf<String>()
    val ui = mutableListOf<Runnable>()
    fun reset() { events.clear(); ui.clear() }
    fun dispatch() { val pending=ui.toList(); ui.clear(); pending.forEach { it.run() } }
    fun window() = events.filter { it.startsWith("immersive:") || it.startsWith("edge:") || it == "bars" }
}
class Godot {
    var edge = false
    var immersive = false
    fun isInEdgeToEdgeMode() = edge
    fun isInImmersiveMode() = immersive
    fun enableEdgeToEdge(value: Boolean, override: Boolean) { edge=value; Calls.events.add("edge:"+value+":"+override) }
    fun enableImmersiveMode(value: Boolean, override: Boolean) { immersive=value; Calls.events.add("immersive:"+value+":"+override) }
    fun setSystemBarsAppearance() { Calls.events.add("bars") }
}
open class GodotActivity : android.app.Activity() {
    var engine: Godot? = Godot()
    val inheritedArguments = mutableListOf("--existing-host-argument")
    var startedArguments: List<String> = emptyList()
    open fun onCreate(saved: Bundle?) {
        Calls.events.add("super:create")
        startedArguments = getCommandLine().toList()
        engine?.edge = "--edge_to_edge" in startedArguments
    }
    open fun onStart() { Calls.events.add("super:start") }
    open fun onStop() { Calls.events.add("super:stop") }
    open fun onResume() { Calls.events.add("super:resume") }
    open fun onPause() { Calls.events.add("super:pause") }
    open fun onDestroy() { Calls.events.add("super:destroy") }
    open fun onGodotMainLoopStarted() { Calls.events.add("super:main-loop") }
    open fun getCommandLine(): MutableList<String> = inheritedArguments
    open fun getHostPlugins(engine: Godot): Set<GodotPlugin> = emptySet()
    fun getGodot(): Godot? = engine
    open fun onGodotForceQuit(instance: Godot) {}
    open fun onGodotRestartRequested(instance: Godot) {}
}
''',
    'GodotPlugin.kt': r'''
package org.godotengine.godot.plugin
open class GodotPlugin(engine: org.godotengine.godot.Godot) { open fun getPluginName() = "" }
annotation class UsedByGodot
''',
    'HostDependencies.kt': r'''
package dev.ullmann.lumo
import android.content.Context
import android.os.IBinder
import org.godotengine.godot.Calls
class CardsAuthorityService {
    companion object { fun available(binder: IBinder?, token: String) = binder != null && token.length == 32 }
}
object CardsTableBridge {
    fun pulse(directory: java.io.File, token: String, active: Boolean): Boolean {
        Calls.events.add("pulse:"+active)
        return true
    }
    fun state(directory: java.io.File, token: String) = "{}"
    fun submit(directory: java.io.File, token: String, payload: String) = true
}
class LumoLearningSpeech(context: Context, options: org.json.JSONObject) {
    init { Calls.events.add("speech:create") }
    fun setActive(active: Boolean) { Calls.events.add("speech:active:"+active) }
    fun destroy() { Calls.events.add("speech:destroy") }
    fun speak(payload: String) = true
    fun status() = "{}"
    fun stop() {}
}
object GameEventStore {
    const val CALLER_RETURN_SESSION = "callerReturnSession"
    fun validCallerSession(value: String) = true
    fun recordReturn(context: Context, target: String, session: String?) {}
    fun recordReward(context: Context, payload: String) = true
}
''',
    'CardsWindowRegression.kt': r'''
package dev.ullmann.lumo
import android.content.ComponentName
import android.content.Intent
import android.os.IBinder
import org.godotengine.godot.Calls
import org.godotengine.godot.Godot
object CardsWindowRegression {
    private val originalArguments = listOf("--existing-host-argument", "--main-pack", "res://lumo_game.pck",
                                           "--rendering-method", "gl_compatibility")
    private val windowCalls = listOf("immersive:false:true", "edge:true:true", "bars")
    private val cards = """{"game":"cards","cardsToken":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}"""
    private fun launch(raw: String): LumoGameActivity {
        Calls.reset()
        val activity=LumoGameActivity()
        activity.intent=Intent().putExtra("lumoLaunchOptions", raw)
        activity.onCreate(null)
        return activity
    }
    @JvmStatic fun main(args: Array<String>) {
        when (args[0]) {
            "cards" -> {
                val activity=launch(cards)
                check(Calls.events.take(2)==listOf("android-edge","super:create")) { "Cards window initialization must precede Godot creation" }
                check(activity.startedArguments==originalArguments+listOf("--edge_to_edge")) { "Cards must expose actual insets while keeping its full viewport" }
                repeat(2) { check(activity.getCommandLine()==activity.startedArguments) }
                check(activity.inheritedArguments==listOf("--existing-host-argument")) { "Mutated inherited launch arguments" }
                activity.onResume()
                check(Calls.window()==windowCalls) { "Missing or incorrect Cards resume initialization" }
                check(Calls.events.indexOf("super:resume")<Calls.events.indexOf("immersive:false:true"))
                activity.onGodotMainLoopStarted()
                check(Calls.window()==windowCalls && Calls.ui.size==1) { "Main-loop callback must dispatch to the UI thread" }
                Calls.dispatch()
                check(Calls.window()==windowCalls+windowCalls)
                activity.onPause(); activity.onResume()
                check(Calls.window()==windowCalls+windowCalls+windowCalls) { "Resume must reapply current engine flags" }
                check(activity.engine?.immersive==false && activity.engine?.edge==true)
            }
            "delayed-engine" -> {
                val activity=launch(cards)
                activity.onStart()
                check("bind" in Calls.events)
                activity.engine=null
                activity.onResume()
                check(Calls.window().isEmpty()) { "Engine not available yet" }
                check("pulse:true" !in Calls.events) { "Missing authority must not start an active Cards lease" }
                activity.connection!!.onServiceConnected(ComponentName(), object : IBinder {})
                check(activity.engine==null && Calls.window().isEmpty()) { "Authority binding must not invent an engine" }
                check(Calls.events.last()=="pulse:true") { "Live authority must renew Cards even before the engine is available" }
                activity.engine=Godot().apply { edge=true }
                activity.onGodotMainLoopStarted()
                check(Calls.window().isEmpty())
                Calls.dispatch()
                check(Calls.window()==windowCalls) { "Main-loop start must recover the late engine" }
            }
            "non-cards" -> {
                for (raw in listOf("""{"game":"kart"}""", """{"game":"learning"}""",
                                   """{"game":"build"}""", """{"game":"jump"}""", "{}", "malformed")) {
                    val activity=launch(raw)
                    check(activity.startedArguments==originalArguments) { "Changed non-Cards arguments: "+raw }
                    check(activity.getCommandLine()==originalArguments)
                    activity.onResume(); activity.onGodotMainLoopStarted(); activity.onPause()
                    check("android-edge" !in Calls.events && Calls.window().isEmpty() && Calls.ui.isEmpty()) { "Changed non-Cards window lifecycle: "+raw }
                    check(Calls.events.count { it=="super:resume" }==1 && Calls.events.count { it=="super:main-loop" }==1)
                    val speech=raw.contains("learning") || raw.contains("build")
                    check(("speech:create" in Calls.events)==speech)
                    if (speech) check(Calls.events.filter { it.startsWith("speech:") }==
                        listOf("speech:create","speech:active:true","speech:active:false")) { "Changed speech lifecycle" }
                }
            }
            "authority" -> {
                val activity=launch(cards)
                activity.onStart()
                check("bind" in Calls.events)
                activity.connection!!.onServiceConnected(ComponentName(), object : IBinder {})
                activity.onResume()
                check(Calls.events.last()=="pulse:true") { "Live authority must remain active after window initialization" }
                activity.onPause()
                check(Calls.events.takeLast(2)==listOf("pulse:false","super:pause"))
                activity.onResume()
                check(Calls.events.last()=="pulse:true")
                activity.onStop()
                check(Calls.events.takeLast(3)==listOf("pulse:false","unbind","super:stop")) { "Window hook bypassed authority release" }
            }
            else -> error("Unknown window regression")
        }
        println("CARDS_WINDOW_CALLS_PASS "+args[0]+" (JVM boundary adapters; no Android pixels or measured insets)")
    }
}
''',
}


if __name__ == '__main__':
    unittest.main()
