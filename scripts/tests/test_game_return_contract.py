"""Execute the production Kotlin event store and validate its Android wiring.

Only Android Context/AtomicFile have small filesystem-backed JVM adapters.
GameEventStore and JSON parsing are real production code; this is not an
Android lifecycle/device test. The separate Flutter origin and Android gates
exercise those boundaries. The test-only org.json JAR is digest pinned.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import urllib.request


ROOT = Path(__file__).resolve().parents[2]
JSON_URL = 'https://repo.maven.apache.org/maven2/org/json/json/20240303/json-20240303.jar'
JSON_SHA256 = '3cf6cd6892e32e2b4c1c39e0f52f5248a2f5b37646fdfbb79a66b46b618414ed'
CONTEXT = '''package android.content;
public abstract class Context { public abstract java.io.File getFilesDir(); }
'''
ATOMIC_FILE = '''package android.util;
import java.io.*;
import java.nio.file.*;
public final class AtomicFile {
  private final File base;
  public static boolean failNextWrite = false;
  public AtomicFile(File file) { base = file; }
  public File getBaseFile() { return base; }
  public FileInputStream openRead() throws IOException { return new FileInputStream(base); }
  public FileOutputStream startWrite() throws IOException {
    if (failNextWrite) { failNextWrite = false; throw new IOException("injected storage failure"); }
    return new FileOutputStream(new File(base.getPath() + ".new"));
  }
  public void finishWrite(FileOutputStream stream) throws IOException {
    stream.close();
    Files.move(Paths.get(base.getPath() + ".new"), base.toPath(), StandardCopyOption.REPLACE_EXISTING);
  }
  public void failWrite(FileOutputStream stream) throws IOException {
    stream.close(); Files.deleteIfExists(Paths.get(base.getPath() + ".new"));
  }
}
'''
HARNESS = r'''
package dev.ullmann.lumo
import android.content.Context
import android.util.AtomicFile
import java.io.File
import org.json.JSONObject

object ReturnRegression {
    private const val OWNER = "11111111-1111-4111-8111-111111111111"
    private const val OTHER = "22222222-2222-4222-8222-222222222222"
    private fun check(value: Boolean, reason: String) {
        if (!value) throw AssertionError(reason)
    }
    @JvmStatic fun main(args: Array<String>) {
        val directory = File(args[1]).apply { mkdirs() }
        val context = object : Context() { override fun getFilesDir(): File = directory }
        val file = File(directory, "lumo_game_events.json")
        fun disk() = JSONObject(GameEventStore.pending(context))
        fun reward(id: String) {
            GameEventStore.recordReward(context, JSONObject().put("resultId", id)
                .put("status", "completed").put("game", "jump").put("stars", 2).put("xp", 5).toString())
        }
        fun count() = disk().getJSONArray("results").length()
        when (args[0]) {
            "result-before-resume", "resume-before-result" -> {
                reward("earned-before-native")
                GameEventStore.beginCallerReturn(context)
                GameEventStore.recordReturn(context, "learn", OWNER)
                if (args[0] == "resume-before-result") {
                    val warm = JSONObject(GameEventStore.pending(context, OWNER))
                    check(!warm.has("destination") && !warm.has(GameEventStore.CALLER_RETURN_SESSION), "warm resume would pop origin")
                    check(warm.getJSONArray("results").length() == 1, "mask removed earned reward")
                    check(disk().getString("destination") == "learn", "read destroyed cold fallback")
                    GameEventStore.acknowledge(context, emptyList(), null, OWNER)
                    check(disk().has("destination") && count() == 1, "masked ACK lost return/reward")
                }
                check(GameEventStore.completeCallerReturn(context, "learn", OWNER), "matching return not committed")
                check(!disk().has("destination") && count() == 1, "completed caller deleted reward or retained navigation")
                check(!GameEventStore.completeCallerReturn(context, "learn", OWNER), "duplicate completion consumed again")
            }
            "cold-recreated" -> {
                reward("retained")
                GameEventStore.recordReturn(context, "games", OWNER)
                check(!JSONObject(GameEventStore.pending(context, OWNER)).has("destination"), "live mask missing")
                check(disk().getString("destination") == "games", "recreated host lost fallback")
                GameEventStore.acknowledge(context, emptyList(), "games")
                check(!disk().has("destination") && !disk().has(GameEventStore.CALLER_RETURN_SESSION), "cold fallback not acknowledged")
                check(count() == 1, "cold navigation consumed rewards")
            }
            "legacy-2017" -> {
                file.writeText("""{"results":[],"destination":"games"}""")
                check(JSONObject(GameEventStore.pending(context, "")).getString("destination") == "games", "empty owner masked legacy navigation")
                check(!GameEventStore.completeCallerReturn(context, "games", ""), "empty owner consumed legacy navigation")
                check(JSONObject(GameEventStore.pending(context, OWNER)).getString("destination") == "games", "legacy return was masked")
                GameEventStore.acknowledge(context, emptyList(), "games", OWNER)
                check(!disk().has("destination"), "legacy destination no longer acknowledges")
                GameEventStore.recordReturn(context, "learn", OWNER)
                GameEventStore.recordReturn(context, "games")
                check(!disk().has(GameEventStore.CALLER_RETURN_SESSION), "Kart inherited old caller ownership")
                check(JSONObject(GameEventStore.pending(context, OWNER)).getString("destination") == "games", "Kart stopped navigating")
            }
            "foreign-stale-and-destination" -> {
                GameEventStore.recordReturn(context, "learn", OWNER)
                val original = file.readBytes()
                check(JSONObject(GameEventStore.pending(context, OTHER)).getString("destination") == "learn", "unknown owner masked navigation")
                check(!GameEventStore.completeCallerReturn(context, "learn", OTHER), "foreign session consumed return")
                check(!GameEventStore.completeCallerReturn(context, "games", OWNER), "wrong destination consumed return")
                check(file.readBytes().contentEquals(original), "rejected completion rewrote bytes")
                GameEventStore.recordReturn(context, "games", OTHER)
                check(!GameEventStore.completeCallerReturn(context, "learn", OWNER), "stale callback consumed newer return")
                check(disk().getString(GameEventStore.CALLER_RETURN_SESSION) == OTHER, "newer session lost")
            }
            "stale-ack-and-rewards" -> {
                reward("first"); reward("second"); reward("first")
                GameEventStore.recordReturn(context, "learn", OWNER)
                GameEventStore.acknowledge(context, listOf("first"), "learn", OWNER)
                check(disk().getString(GameEventStore.CALLER_RETURN_SESSION) == OWNER, "old same-destination ACK cleared live return")
                check(count() == 1 && disk().getJSONArray("results").getJSONObject(0).getString("resultId") == "second", "reward ACK changed retained reward")
                GameEventStore.recordReturn(context, "learn", OTHER)
                GameEventStore.acknowledge(context, emptyList(), "learn", OWNER)
                check(disk().getString(GameEventStore.CALLER_RETURN_SESSION) == OTHER, "stale ACK cleared newer caller")
                check(!GameEventStore.completeCallerReturn(context, "learn", OWNER), "stale completion cleared newer caller")
                check(count() == 1, "navigation touched reward")
            }
            "new-launch-stale-navigation" -> {
                reward("already-earned")
                GameEventStore.recordReturn(context, "learn", OTHER)
                val rewards = disk().getJSONArray("results").toString()
                GameEventStore.beginCallerReturn(context)
                check(!disk().has("destination") && !disk().has(GameEventStore.CALLER_RETURN_SESSION), "old navigation leaks into fresh origin")
                check(disk().getJSONArray("results").toString() == rewards, "new launch changed old rewards")
                GameEventStore.recordReturn(context, "games", OWNER)
                check(disk().getString("destination") == "games", "new return not durable")
            }
            "storage-failure-and-reset" -> {
                reward("durable")
                GameEventStore.recordReturn(context, "learn", OWNER)
                val original = file.readBytes()
                AtomicFile.failNextWrite = true
                var failed = false
                try { GameEventStore.completeCallerReturn(context, "learn", OWNER) }
                catch (_: java.io.IOException) { failed = true }
                check(failed && file.readBytes().contentEquals(original), "failed commit lost fallback/reward")
                check(GameEventStore.completeCallerReturn(context, "learn", OWNER), "commit retry failed")
                check(count() == 1, "retry lost reward")
                GameEventStore.clear(context)
                check(count() == 0 && !disk().has("destination"), "explicit reset regressed")
            }
            "invalid-session" -> {
                reward("untouched")
                val original = file.readBytes()
                for (invalid in listOf("", "legacy", "../other", OWNER.uppercase().replace('1', 'A'))) {
                    var rejected = false
                    try { GameEventStore.recordReturn(context, "learn", invalid) }
                    catch (_: IllegalArgumentException) { rejected = true }
                    check(rejected && file.readBytes().contentEquals(original), "invalid session mutated event store")
                }
            }
            else -> throw AssertionError("unknown scenario")
        }
        println("GAME_RETURN_STORE_PASS " + args[0])
    }
}
'''


class GameReturnStoreTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-native-return-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(configured) if configured.is_file() else shutil.which('java')
        if not cls.java:
            raise RuntimeError('A JDK is required for the production Kotlin return-store test')
        gradle = shutil.which('gradle')
        candidates = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                      Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        if gradle:
            candidates.append(Path(gradle).resolve().parents[1] / 'lib')
        libraries = next((p for p in candidates if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        if libraries is None:
            raise RuntimeError('Set LUMO_KOTLIN_LIB_DIR or use the verified Gradle installation on PATH')
        cls.json_jar = cls.work / 'json-20240303.jar'
        supplied = os.environ.get('LUMO_TEST_JSON_JAR')
        if supplied:
            data = Path(supplied).read_bytes()
        else:
            with urllib.request.urlopen(JSON_URL, timeout=60) as response:
                data = response.read()
        if hashlib.sha256(data).hexdigest() != JSON_SHA256:
            raise RuntimeError('The test-only JSON dependency digest changed')
        cls.json_jar.write_bytes(data)
        cls.classes = cls.work / 'classes'
        cls.classes.mkdir()
        java_sources = []
        for name, text in [('Context.java', CONTEXT), ('AtomicFile.java', ATOMIC_FILE)]:
            path = cls.work / name
            path.write_text(text)
            java_sources.append(str(path))
        cls.run_checked([cls.java, '--module', 'jdk.compiler/com.sun.tools.javac.Main',
                         '-source', '8', '-target', '8', '-Xlint:-options', '-d', str(cls.classes), *java_sources])
        harness = cls.work / 'ReturnRegression.kt'
        harness.write_text(HARNESS)
        stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
        cls.classpath = os.pathsep.join(map(str, [cls.classes, cls.json_jar, stdlib]))
        cls.run_checked([cls.java, '-cp', os.pathsep.join(map(str, libraries.glob('*.jar'))),
                         'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                         '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(cls.classes),
                         str(ROOT / 'tools/auto_install/GameEventStore.kt'), str(harness)])

    @classmethod
    def run_checked(cls, command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def scenario(self, name):
        result = self.run_checked([self.java, '-cp', self.classpath, 'dev.ullmann.lumo.ReturnRegression',
                                   name, str(self.work / name)])
        self.assertIn('GAME_RETURN_STORE_PASS ' + name, result.stdout)
        print(result.stdout.strip())

    def test_result_before_resume(self): self.scenario('result-before-resume')
    def test_resume_before_result(self): self.scenario('resume-before-result')
    def test_cold_recreated_host_preserves_fallback(self): self.scenario('cold-recreated')
    def test_2017_events_and_legacy_kart(self): self.scenario('legacy-2017')
    def test_foreign_stale_and_wrong_destination(self): self.scenario('foreign-stale-and-destination')
    def test_stale_ack_keeps_return_and_unacknowledged_rewards(self): self.scenario('stale-ack-and-rewards')
    def test_new_launch_supersedes_only_stale_navigation(self): self.scenario('new-launch-stale-navigation')
    def test_failed_commit_retains_fallback_and_explicit_reset_still_works(self): self.scenario('storage-failure-and-reset')
    def test_invalid_session_never_writes(self): self.scenario('invalid-session')


class GameReturnWiringTest(unittest.TestCase):
    def test_validated_private_launch_owns_learning_cards_and_separate_connect_four(self):
        text = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        launch = text.split('"launch3D" -> {', 1)[1].split('override fun onActivityResult', 1)[0]
        self.assertIn('.takeIf { game in setOf("learning", "cards", "connect_four") }', launch)
        self.assertLess(launch.index('"invalid_connect_four"'), launch.index('GameEventStore.beginCallerReturn'))
        self.assertLess(launch.index('"invalid_cards"'), launch.index('GameEventStore.beginCallerReturn'))
        self.assertLess(launch.index('GameEventStore.beginCallerReturn'), launch.index('pendingGame = result'))
        self.assertLess(launch.index('pendingCallerReturnSession = callerSession'), launch.index('startActivityForResult'))
        self.assertIn('pendingCallerReturnSession.takeIf { pendingGame != null }', text)

    def test_native_persists_fallback_before_return_and_retains_process_shutdown(self):
        text = (ROOT / 'tools/auto_install/LumoGameActivity.kt').read_text()
        returning = text.split('fun returnToLearningApp(destination:', 1)[1]
        self.assertIn('options.optString("sessionId") == it && GameEventStore.validCallerSession(it)', text)
        self.assertLess(returning.index('GameEventStore.recordReturn(this, target, callerSession)'), returning.index('setResult('))
        self.assertIn('.putExtra(GameEventStore.CALLER_RETURN_SESSION, callerSession)', returning)
        self.assertLess(returning.index('finish()'), returning.index('android.os.Process.killProcess'))

    def test_completion_is_live_session_bound_and_commit_precedes_success_and_unlock(self):
        text = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        returned = text.split('override fun onActivityResult', 1)[1].split('override fun onTrimMemory', 1)[0]
        self.assertIn('val callback = pendingGame ?: return', returned)
        self.assertIn('returnedSession != null && returnedSession != callerSession', returned)
        self.assertIn('isDestroyed || pendingGame !== callback || pendingCallerReturnSession != callerSession', returned)
        self.assertIn('engineProcessRunning(pid) && attempt < 100', returned)
        self.assertLess(returned.index('GameEventStore.completeCallerReturn'), returned.index('callback.success'))
        self.assertLess(returned.index('callback.success'), returned.index('pendingGame = null'))
        self.assertIn('postDelayed({ completeWhenStopped(attempt) }, 1000)', returned)
        destroyed = text.split('override fun onDestroy()', 1)[1]
        self.assertLess(destroyed.index('pendingGame = null'), destroyed.index('super.onDestroy()'))


if __name__ == '__main__':
    unittest.main()
