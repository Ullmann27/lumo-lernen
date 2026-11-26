"""Execute the production Kotlin event store and validate its Android wiring.

Only Android Context/AtomicFile have small filesystem-backed JVM adapters.
GameEventStore and JSON parsing are real production code; this is not an
Android lifecycle/device test. The separate Flutter origin and Android gates
exercise those boundaries. The test-only org.json JAR is digest pinned.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
if __package__:
    from .jvm_test_dependencies import JSON_SHA256, JSON_URL, prepare_json_jar
else:
    from jvm_test_dependencies import JSON_SHA256, JSON_URL, prepare_json_jar


def world_mission_contract_source():
    """Use the production protocol verbatim in Activity boundary fixtures.

    Those fixtures observe store calls with a test adapter. The complete real
    store and the protocol are compiled together by GameReturnStoreTest below.
    """
    source = (ROOT / 'tools/auto_install/GameEventStore.kt').read_text()
    start = source.index('object WorldMissionContract {')
    end = source.index('/** Durable events shared', start)
    return 'package dev.ullmann.lumo\nimport org.json.JSONObject\n' + source[start:end]


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
            "world-mission-contract" -> {
                fun request() = JSONObject("""{"version":1.0,"id":"school_numbers","requestId":"world-school-0001","subject":"Mathematik","grade":2.0,"returnGame":"world"}""")
                val original = request()
                val clean = WorldMissionContract.request("world", 2, original)
                check(clean != null, "restored Godot integral JSON numbers were rejected")
                check(clean!!.opt("version") == 1 && clean.opt("grade") == 2, "canonical transport must use integer numbers")
                check(clean.getString("requestId") == "world-school-0001", "request identity changed")
                check(WorldMissionContract.request("learning", 2, request()) == null, "another scene opened the World mission")
                check(WorldMissionContract.request("world", 3, request()) == null, "another grade accepted the request")
                for (key in listOf("version", "id", "requestId", "subject", "grade", "returnGame")) {
                    check(WorldMissionContract.request("world", 2, request().apply { remove(key) }) == null, "missing $key accepted")
                }
                for (key in listOf("version", "grade")) {
                    for (bad in listOf(true, "1", "2", 1.25, -1, 0, 5, Long.MAX_VALUE)) {
                        check(WorldMissionContract.request("world", 2, request().put(key, bad)) == null, "invalid numeric $key accepted: $bad")
                    }
                }
                for (bad in listOf("short", "bad request", "x".repeat(161), "../owner")) {
                    check(WorldMissionContract.request("world", 2, request().put("requestId", bad)) == null, "invalid request ID accepted")
                }
                for ((key, value) in listOf("id" to "another_mission", "subject" to "Deutsch", "returnGame" to "kart")) {
                    check(WorldMissionContract.request("world", 2, request().put(key, value)) == null, "foreign $key accepted")
                }
                for (key in listOf("owner", "childKey", "stars", "completed")) {
                    check(WorldMissionContract.request("world", 2, request().put(key, "injected")) == null, "request supplied $key")
                }
                val envelope = JSONObject().put("sessionId", OWNER).put("worldMission", request())
                val payload = envelope.toString()
                check(WorldMissionContract.returnRequest("world", 2, OWNER, payload) != null, "owned request envelope rejected")
                check(WorldMissionContract.returnRequest("world", 2, OTHER, payload) == null, "another launch session claimed a school return")
                check(WorldMissionContract.returnRequest("world", 2, "", payload) == null, "missing caller session accepted")
                check(WorldMissionContract.returnRequest("kart", 2, OWNER, payload) == null, "another game supplied a school envelope")
                check(WorldMissionContract.returnRequest("world", 2, OWNER, "{") == null, "malformed envelope accepted")
                check(WorldMissionContract.returnRequest("world", 2, OWNER, payload.padEnd(2000)) != null, "bounded payload limit rejected")
                check(WorldMissionContract.returnRequest("world", 2, OWNER, payload.padEnd(2001)) == null, "oversized payload accepted")
                for (key in listOf("owner", "childKey", "status", "stars", "xp")) {
                    val injected = JSONObject(payload).put(key, "completed").toString()
                    check(WorldMissionContract.returnRequest("world", 2, OWNER, injected) == null, "envelope supplied $key")
                }
                fun receipt(): MutableMap<String, Any?> = mutableMapOf("version" to 1.0, "missionId" to "school_numbers",
                    "requestId" to "world-school-0001", "subject" to "Mathematik", "grade" to 2.0,
                    "returnGame" to "world", "completed" to true)
                val accepted = WorldMissionContract.receipt("world", 2, receipt())
                check(accepted != null && accepted.opt("version") == 1 && accepted.opt("grade") == 2, "receipt normalization failed")
                check(WorldMissionContract.receipt("kart", 2, receipt()) == null, "receipt crossed game boundary")
                check(WorldMissionContract.receipt("world", 3, receipt()) == null, "receipt crossed grade boundary")
                for (key in receipt().keys) {
                    check(WorldMissionContract.receipt("world", 2, receipt().apply { remove(key) }) == null, "missing receipt $key accepted")
                }
                for (key in listOf("version", "grade")) {
                    for (bad in listOf(true, "1", "2", 1.25, Double.NaN, Double.POSITIVE_INFINITY, Double.NEGATIVE_INFINITY)) {
                        check(WorldMissionContract.receipt("world", 2, receipt().apply { put(key, bad) }) == null, "invalid receipt number accepted")
                    }
                }
                for (bad in listOf(false, "true", 1, null)) {
                    check(WorldMissionContract.receipt("world", 2, receipt().apply { put("completed", bad) }) == null, "unearned completion accepted")
                }
                for (key in listOf("owner", "childKey", "stars", "xp")) {
                    check(WorldMissionContract.receipt("world", 2, receipt().apply { put(key, "injected") }) == null, "receipt supplied $key")
                }
            }
            "world-reward-replay" -> {
                val payload = JSONObject().put("resultId", "world-chapter-one")
                    .put("game", "world").put("status", "completed").put("stars", 6).put("xp", 30).toString()
                check(GameEventStore.recordReward(context, payload), "World reward rejected")
                check(GameEventStore.recordReward(context, payload), "World reward retry rejected")
                check(count() == 1, "World retry duplicated a reward")
                GameEventStore.beginCallerReturn(context)
                GameEventStore.recordReturn(context, "learn", OWNER)
                check(!GameEventStore.completeCallerReturn(context, "learn", OTHER), "foreign World caller consumed return")
                check(GameEventStore.completeCallerReturn(context, "learn", OWNER), "World caller return lost")
                check(count() == 1, "World navigation lost its chapter reward")
            }
            "skypost-replay" -> {
                val source = System.getenv("LUMO_TEST_FLIGHT_RECEIPT")
                val payload = if (source == null) JSONObject().put("resultId", "test-post-flight")
                    .put("game", "skypost").put("status", "completed").put("stars", 5).toString()
                    else File(source).readText()
                check(JSONObject(payload).getString("game") == "skypost", "Sternenpost receipt expected")
                repeat(2) { check(GameEventStore.recordReward(context, payload), "flight not accepted") }
                val pending = disk()
                val receipts = pending.getJSONArray("results")
                check(receipts.length() == 1, "duplicate flight")
                val id = JSONObject(payload).getString("resultId")
                check(receipts.getJSONObject(0).getString("resultId") == id, "flight ID changed")
                System.getenv("LUMO_TEST_FLIGHT_PENDING")?.let { File(it).writeText(pending.toString()) }
                GameEventStore.acknowledge(context, listOf(id), null, null)
                check(count() == 0, "flight not acknowledged")
            }
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
            "start-journal" -> {
                reward("kept-reward")
                val utc = java.util.TimeZone.getTimeZone("UTC")
                val start = 1_795_000_000_000L
                fun stamp(offset: Long): String = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS")
                    .apply { timeZone = utc }.format(java.util.Date(start + offset))
                check(GameStartJournal.lineTime(stamp(1234) + "  4711  4712 I godot   : x", 2026, utc) == start + 1234, "year line time")
                check(GameStartJournal.lineTime(stamp(50).substring(5) + "  4711  4712 I godot   : x", 2026, utc) == start + 50, "threadtime line time")
                check(GameStartJournal.lineTime("1795000000.250  4711  4712 I godot   : x", 2026, utc) == start + 250, "epoch line time")
                val log = listOf(stamp(-60_000) + " 1 2 I godot   : [Router] loaded:run ",
                    stamp(2_000) + " 1 2 I godot   : [Router] loaded:loading ",
                    stamp(10_400) + " 1 2 I godot   : [Router] loaded:run ").joinToString("\n")
                check(GameStartJournal.loadedAfterMs(log, "run", start, start + 60_000, 2026, utc) == Pair(10_400L, "run"), "exact scene load")
                check(GameStartJournal.loadedAfterMs(log, "kart", start, start + 60_000, 2026, utc) == Pair(2_000L, "loading"), "fallback load")
                check(GameStartJournal.loadedAfterMs(log, "run", start + 20_000, start + 60_000, 2026, utc) == null, "old load counted")
                val first = GameStartJournal.begin(context, "run", start)
                GameStartJournal.finish(context, first, start + 30_000, "process_ended", "resultCode=0")
                GameStartJournal.finish(context, first, start + 40_000, "returned")
                var entries = org.json.JSONArray(GameStartJournal.entries(context))
                check(entries.getJSONObject(0).getString("outcome") == "process_ended", "finished twice")
                val open = GameStartJournal.begin(context, "jump", start + 50_000, "Rest beendet")
                GameStartJournal.begin(context, "kart", start + 60_000)
                entries = org.json.JSONArray(GameStartJournal.entries(context))
                check(entries.getJSONObject(1).getString("outcome") == "host_closed" &&
                    entries.getJSONObject(1).getString("id") == open && entries.getJSONObject(1).getString("note") == "Rest beendet", "older open start")
                for (index in 0 until 30) GameStartJournal.refused(context, "quiz", start + 70_000 + index, "game_running", "x".repeat(400))
                entries = org.json.JSONArray(GameStartJournal.entries(context))
                check(entries.length() == GameStartJournal.LIMIT, "journal not limited")
                check(entries.getJSONObject(19).getString("detail").length == 200, "detail not bounded")
                File(directory, "lumo_game_starts.json").writeText("kaputt")
                check(org.json.JSONArray(GameStartJournal.entries(context)).length() == 0, "broken journal not dropped")
                val run = GameStartJournal.begin(context, "run", start)
                GameStartJournal.applyLoadTimes(context, log, start + 60_000, 2026)
                val zoneLog = log.lineSequence().map { line ->
                    val time = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS").apply { timeZone = utc }.parse(line.substring(0, 23)).time
                    java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS").format(java.util.Date(time)) + line.substring(23)
                }.joinToString("\n")
                GameStartJournal.applyLoadTimes(context, zoneLog, start + 60_000, 2026)
                val loaded = org.json.JSONArray(GameStartJournal.entries(context)).getJSONObject(0)
                check(loaded.getString("id") == run && loaded.getLong("loadedAfterMs") == 10_400L && loaded.getString("loadedScene") == "run", "load time not applied")
                check(count() == 1, "start journal touched rewards")
            }
            "free-writer-lock" -> {
                reward("before-cleanup")
                check(GameEventStore.whileNoWriter(context, 300) { "ran" } == "ran", "free lock did not run cleanup")
                reward("after-cleanup")
                check(count() == 2, "cleanup lock lost or blocked a reward")
            }
            "hold-writer-lock" -> {
                GameEventStore.whileNoWriter(context, 1000) {
                    println("WRITER_LOCK_HELD")
                    System.out.flush()
                    Thread.sleep(2500)
                }
            }
            "busy-writer-lock" -> {
                var ran = false
                val started = System.nanoTime()
                check(GameEventStore.whileNoWriter(context, 300) { ran = true } == null, "busy writer lock was not reported")
                check(!ran, "leftover cleanup ran during another process's write")
                check(System.nanoTime() - started < 2_000_000_000L, "busy lock wait exceeded its limit")
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
        cls.json_jar = prepare_json_jar(cls.work / 'json-20240303.jar')
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
        self.scenario_in(name, self.work / name)

    def scenario_in(self, name, folder):
        result = self.run_checked([self.java, '-cp', self.classpath, 'dev.ullmann.lumo.ReturnRegression',
                                   name, str(folder)])
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
    def test_skypost_retry_persists_one_flight(self): self.scenario('skypost-replay')
    def test_world_request_and_receipt_reject_foreign_and_malformed_data(self): self.scenario('world-mission-contract')
    def test_world_reward_retry_and_caller_identity(self): self.scenario('world-reward-replay')

    def test_invalid_session_never_writes(self): self.scenario('invalid-session')
    def test_leftover_cleanup_lock_runs_when_no_writer(self): self.scenario('free-writer-lock')
    def test_start_journal_keeps_twenty_bounded_entries_and_derives_load_time(self): self.scenario('start-journal')

    def test_leftover_cleanup_never_kills_during_another_process_write(self):
        folder = self.work / 'shared-writer-lock'
        holder = subprocess.Popen([self.java, '-cp', self.classpath, 'dev.ullmann.lumo.ReturnRegression',
                                   'hold-writer-lock', str(folder)], stdout=subprocess.PIPE, text=True)
        try:
            self.assertEqual(holder.stdout.readline().strip(), 'WRITER_LOCK_HELD')
            self.scenario_in('busy-writer-lock', folder)
        finally:
            holder.wait(timeout=30)
            holder.stdout.close()


class GameReturnWiringTest(unittest.TestCase):
    def test_validated_private_launch_owns_learning_and_separate_table_games(self):
        text = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        launch = text.split('"launch3D" -> {', 1)[1].split('override fun onActivityResult', 1)[0]
        # The card table (Sternenstich, Sternenleiter, Lumo-Quartett) keeps its
        # own rules and save in the game. It is opened like Kart and Lumo Lauf:
        # no round token from the app and a normal return to the games section.
        self.assertIn('.takeIf { game in setOf("learning", "connect_four", "memory", "quiz", "world") }', launch)
        self.assertNotIn('"invalid_cards"', launch)
        self.assertNotIn('cardsToken', launch)
        self.assertRegex(launch, r'"kart", "jump", "run", "skypost", "puzzle"')
        self.assertLess(launch.index('"invalid_connect_four"'), launch.index('GameEventStore.beginCallerReturn'))
        self.assertLess(launch.index('"invalid_table_game"'), launch.index('GameEventStore.beginCallerReturn'))
        self.assertLess(launch.index('GameEventStore.beginCallerReturn'), launch.index('pendingGame = result'))
        self.assertLess(launch.index('pendingCallerReturnSession = callerSession'), launch.index('startActivityForResult'))
        self.assertIn('pendingCallerReturnSession.takeIf { pendingGame != null }', text)

    def test_world_message_limits_and_owner_free_canonical_transport(self):
        main = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        game = (ROOT / 'tools/auto_install/LumoGameActivity.kt').read_text()
        returning = game.split('fun returnToApp(destination:', 1)[1]
        self.assertLess(returning.index('payload.length > WorldMissionContract.MAX_PAYLOAD_LENGTH'),
                        returning.index('org.json.JSONObject(payload)'))
        self.assertLess(returning.index('WorldMissionContract.returnRequest('), returning.index('if (!reward(payload))'))
        self.assertIn('WorldMissionContract.receipt(game, options.getInt("grade"), receipt)', main)
        self.assertIn('if (callerOwned && destination == "learn")', main)
        self.assertIn('options.optString("game") in setOf("learning", "cards", "world")', game)

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
        self.assertIn('resultCode == RESULT_OK && (it == "learn" || it == "games")', returned)
        self.assertIn('destination != null -> "returned"', returned)
        self.assertIn('val response = destination?.let', returned)
        self.assertLess(returned.index('GameEventStore.completeCallerReturn'), returned.index('callback.success'))
        self.assertLess(returned.index('callback.success'), returned.index('pendingGame = null'))
        self.assertIn('postDelayed({ completeWhenStopped(attempt) }, 1000)', returned)
        destroyed = text.split('override fun onDestroy()', 1)[1]
        self.assertLess(destroyed.index('pendingGame = null'), destroyed.index('super.onDestroy()'))

    def test_leftover_engine_is_ended_off_the_main_thread_before_a_fresh_start(self):
        text = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        handler = text.split('"launch3D" -> {', 1)[1].split('private fun clearLeftoverEngine', 1)[0]
        # Never start into a live engine; pending starts and running cleanups still refuse.
        self.assertLess(handler.index('if (pendingGame != null || engineCleanupActive || localBackup?.blocksGames == true)'),
                        handler.index('if (!engineProcessRunning())'))
        self.assertLess(handler.index('if (!hostForeground)'), handler.index('clearLeftoverEngine {'))
        self.assertIn('cleared && !isDestroyed && pendingGame == null && !engineProcessRunning()', handler)
        self.assertEqual(handler.count('result.error("game_running"'), 3)
        self.assertEqual(handler.count('GameStartJournal.refused(this, scene, System.currentTimeMillis(), "game_running"'), 3)
        cleanup = text.split('private fun clearLeftoverEngine', 1)[1].split('private fun launchGame', 1)[0]
        self.assertIn('Thread({', cleanup)
        self.assertLess(cleanup.index('GameEventStore.whileNoWriter(context, 1000)'),
                        cleanup.index('android.os.Process.killProcess(it.pid)'))
        self.assertLess(cleanup.index('IMPORTANCE_VISIBLE'), cleanup.index('killProcess'))
        self.assertIn('waited < 3000', cleanup)
        self.assertIn('main.post { done(cleared) }', cleanup)
        self.assertNotIn('myPid', cleanup)
        self.assertIn('hostForeground = true', text.split('override fun onResume()', 1)[1].split('override fun onPause()', 1)[0])
        self.assertIn('hostForeground = false', text.split('override fun onPause()', 1)[1].split('override fun onRequestPermissionsResult', 1)[0])
        self.assertIn('Engine globals need a fresh process', text.split('override fun onActivityResult', 1)[1])

    def test_start_protocol_is_local_bounded_and_never_on_the_main_thread(self):
        text = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        log_call = text.split('"gameStartLog" -> {', 1)[1].split('else -> result.notImplemented()', 1)[0]
        self.assertLess(log_call.index('Thread({'), log_call.index('readOwnLog()'))
        self.assertIn('main.post {', log_call)
        self.assertIn('takeLast(400)', log_call)
        reader = text.split('private fun readOwnLog', 1)[1].split('private fun refreshLoadTimes', 1)[0]
        self.assertIn('"logcat", "-d"', reader)
        self.assertIn('reader.join(5000)', reader)
        self.assertIn('process.destroy()', reader)
        # minSdk 24: Process.waitFor(timeout)/isAlive brauchen API 26.
        self.assertNotIn('process.waitFor(', reader)
        self.assertNotIn('process.isAlive', reader)
        self.assertIn('listOf("godot", "Godot", "LumoHost", "AndroidRuntime", "DEBUG", "libc")', text)
        device = text.split('private fun startProtocolDevice', 1)[1].split('override fun configureFlutterEngine', 1)[0]
        for field in ('Build.MODEL', 'Build.VERSION.RELEASE', 'versionName', 'lumo_game_source.json', 'availMem'):
            self.assertIn(field, device)
        launch = text.split('private fun launchGame', 1)[1].split('override fun onActivityResult', 1)[0]
        self.assertLess(launch.index('GameStartJournal.begin(this, game'), launch.index('startActivityForResult'))
        self.assertIn('"exception", detail', launch)
        self.assertEqual(set(re.findall(r'refuse\("(invalid_[a-z_]+)"', launch)), {
            'invalid_village', 'invalid_world_receipt', 'invalid_learning',
            'invalid_connect_four', 'invalid_table_game',
        })
        returned = text.split('override fun onActivityResult', 1)[1].split('override fun onResume', 1)[0]
        self.assertLess(returned.index('GameStartJournal.finish'), returned.index('completeWhenStopped(0)'))
        self.assertIn('Thread({ try { refreshLoadTimes(readOwnLog()) }', returned)
        # Nur eigenes Log lesen: keine neue Berechtigung, kein Netzwerk.
        for name in ('READ_LOGS', 'HttpURLConnection', 'Socket('):
            self.assertNotIn(name, text)


if __name__ == '__main__':
    unittest.main()
