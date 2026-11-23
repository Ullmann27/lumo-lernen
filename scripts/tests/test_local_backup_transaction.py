"""Run the actual cold-start transaction on real temporary JVM files.

The injected crash is an Error (process death), not a caught storage exception.
These tests prove recovery ordering, not Android SAF or visual device behavior.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
HARNESS = r'''
package dev.ullmann.lumo;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public final class BackupContract {
    static final class Death extends Error {}
    static final class Prefs implements LumoBackupTransaction.Preferences {
        byte[] value = "old preferences".getBytes();
        boolean failNext;
        public byte[] read() { return value.clone(); }
        public void write(byte[] bytes) throws Exception {
            if (failNext) { failNext = false; throw new IOException("disk failure"); }
            value = bytes.clone();
        }
    }
    static void check(boolean value, String label) {
        if (!value) throw new AssertionError(label);
    }
    static void put(File root, String name, String value) throws Exception {
        File file = new File(root, name); file.getParentFile().mkdirs();
        Files.write(file.toPath(), value.getBytes());
    }
    static String read(File root, String name) throws Exception {
        return new String(Files.readAllBytes(new File(root, name).toPath()));
    }
    static LumoBackupTransaction.Snapshot next() {
        Map<String, byte[]> files = new LinkedHashMap<>();
        files.put("lumo_settlement_p_a_1_garden.json", "{\"phase\":2}".getBytes());
        files.put("kart_geister/Lumo-Geist_Zoey.lumogeist", "{\"version\":1}".getBytes());
        return new LumoBackupTransaction.Snapshot("new preferences".getBytes(), files);
    }
    static void old(File files, Prefs prefs) throws Exception {
        check(new String(prefs.value).equals("old preferences"), "old preferences restored");
        check(read(files, "run_records.cfg").equals("old run"), "old run restored");
        check(!new File(files, "lumo_settlement_p_a_1_garden.json").exists(), "new village removed");
        check(read(files, "engine.pck").equals("unrelated engine"), "engine untouched");
        check(read(files, "lumo_cards_table_v1/token/state.json").equals("live transport"), "authority transport untouched");
    }
    static void fresh(File files, Prefs prefs) throws Exception {
        check(new String(prefs.value).equals("new preferences"), "new preferences installed");
        check(!new File(files, "run_records.cfg").exists(), "absent owned save removed");
        check(read(files, "lumo_settlement_p_a_1_garden.json").equals("{\"phase\":2}"), "new village installed");
        check(read(files, "kart_geister/Lumo-Geist_Zoey.lumogeist").equals("{\"version\":1}"), "ghost subdirectory restored");
        check(read(files, "engine.pck").equals("unrelated engine"), "engine untouched");
    }
    public static void main(String[] args) throws Exception {
        File root = Files.createTempDirectory("lumo-backup-contract-").toFile();
        File files = new File(root, "files"); files.mkdir();
        File state = new File(root, "private"); state.mkdir();
        put(files, "run_records.cfg", "old run");
        put(files, "engine.pck", "unrelated engine");
        put(files, "lumo_cards_table_v1/token/state.json", "live transport");
        Prefs prefs = new Prefs();
        LumoBackupTransaction store = new LumoBackupTransaction(files, state);
        String scenario = args[0];
        if (scenario.equals("roundtrip")) {
            store.apply(next(), prefs); fresh(files, prefs);
            check(store.hasPrevious(), "local previous snapshot retained");
            store.stagePrevious();
            store.apply(store.pendingPrevious(), prefs); old(files, prefs);
            check(!store.pending() && !store.recoveryRequired(), "completed journal cleaned");
        } else if (scenario.equals("stage-cancel")) {
            store.stage("reviewed portable archive".getBytes()); old(files, prefs);
            boolean busy = false;
            try { store.stage("another".getBytes()); } catch (IOException expected) { busy = true; }
            check(busy, "second pending restore refused");
            store.rejectPending(); old(files, prefs);
            check(!store.pending(), "cancelled stage removed");
        } else if (scenario.startsWith("crash:")) {
            String phase = scenario.substring(6);
            store.stage("reviewed archive".getBytes());
            LumoBackupTransaction crashing = new LumoBackupTransaction(files, state, at -> {
                if (at.equals(phase)) throw new Death();
            });
            try { crashing.apply(next(), prefs); throw new AssertionError("crash not reached"); }
            catch (Death expected) {}
            LumoBackupTransaction reboot = new LumoBackupTransaction(files, state);
            boolean recovered = reboot.recover(prefs);
            if (phase.equals("prepared")) {
                check(!recovered && reboot.pending(), "prepared stage has no live changes"); old(files, prefs);
            } else if (phase.equals("committed")) {
                check(recovered, "commit finalized"); fresh(files, prefs);
                check(reboot.status().equals("restored"), "committed result retained");
            } else {
                check(recovered, "interrupted transaction recovered"); old(files, prefs);
                check(reboot.status().equals("rolled_back"), "rollback reported");
                check(!reboot.pending(), "old import cannot replay after rollback");
            }
        } else if (scenario.equals("failed-write")) {
            prefs.failNext = true;
            try { store.apply(next(), prefs); throw new AssertionError("failure swallowed"); }
            catch (IOException expected) {}
            old(files, prefs);
            check(store.status().equals("rolled_back"), "failed preference commit rolled back");
        } else if (scenario.equals("rollback-interrupted")) {
            LumoBackupTransaction first = new LumoBackupTransaction(files, state, at -> {
                if (at.equals("preferences-written")) throw new Death();
            });
            try { first.apply(next(), prefs); } catch (Death expected) {}
            LumoBackupTransaction second = new LumoBackupTransaction(files, state, at -> {
                if (at.equals("rollback-written")) throw new Death();
            });
            try { second.recover(prefs); } catch (Death expected) {}
            check(store.recoveryRequired(), "rollback journal survives its own interruption");
            store.recover(prefs); old(files, prefs);
        } else if (scenario.equals("checksum")) {
            byte[] packed = LumoBackupTransaction.pack(next()); packed[20] ^= 1;
            boolean rejected = false;
            try { LumoBackupTransaction.unpack(packed); } catch (IOException expected) { rejected = true; }
            check(rejected, "damaged rollback pack rejected"); old(files, prefs);
        } else if (scenario.equals("unsafe-paths")) {
            for (String path : new String[]{"../settings.cfg", "/settings.cfg", "kart_geister/../../outside.json",
                "lumo_cards_table_v1/token/state.json", "lumo_game_events.lock", "secret.json"}) {
                check(!LumoBackupTransaction.ownedPath(path), "unsafe path refused: " + path);
            }
            Map<String, byte[]> bad = new HashMap<>(); bad.put("../settings.cfg", new byte[0]);
            try { store.apply(new LumoBackupTransaction.Snapshot(new byte[0], bad), prefs);
                throw new AssertionError("traversal accepted"); } catch (IOException expected) {}
            old(files, prefs);
        } else if (scenario.equals("symlink")) {
            File outside = new File(root, "outside.cfg"); Files.write(outside.toPath(), "outside".getBytes());
            Files.createSymbolicLink(new File(files, "kart_preferences.cfg").toPath(), outside.toPath());
            try { store.apply(next(), prefs); throw new AssertionError("symlink accepted"); }
            catch (IOException expected) {}
            check(read(root, "outside.cfg").equals("outside"), "outside file unchanged"); old(files, prefs);
        } else if (scenario.equals("size-limit")) {
            Map<String, byte[]> large = new HashMap<>();
            large.put("run_records.cfg", new byte[LumoBackupTransaction.MAX_FILE + 1]);
            try { store.apply(new LumoBackupTransaction.Snapshot(new byte[0], large), prefs);
                throw new AssertionError("oversize file accepted"); } catch (IOException expected) {}
            old(files, prefs);
        } else throw new AssertionError("unknown scenario");
        System.out.println("LOCAL_BACKUP_TRANSACTION_PASS " + scenario);
    }
}
'''


class LocalBackupTransactionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        java_home = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin'
        cls.java = str(java_home / 'java') if (java_home / 'java').is_file() else shutil.which('java')
        javac = str(java_home / 'javac') if (java_home / 'javac').is_file() else shutil.which('javac')
        if not javac or not cls.java:
            raise RuntimeError('The real backup transaction requires the existing JDK')
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-backup-jvm-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.classes = Path(cls.temp.name) / 'classes'
        cls.classes.mkdir()
        harness = Path(cls.temp.name) / 'BackupContract.java'
        harness.write_text(HARNESS)
        compiled = subprocess.run([javac, '-d', str(cls.classes),
            str(ROOT / 'tools/auto_install/LumoBackupTransaction.java'), str(harness)],
            capture_output=True, text=True, timeout=60)
        if compiled.returncode:
            raise AssertionError(compiled.stdout + compiled.stderr)

    def scenario(self, name):
        result = subprocess.run([self.java, '-cp', str(self.classes),
            'dev.ullmann.lumo.BackupContract', name], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('LOCAL_BACKUP_TRANSACTION_PASS ' + name, result.stdout)

    def test_roundtrip_and_previous_snapshot(self): self.scenario('roundtrip')
    def test_stage_and_cancel_do_not_change_live_data(self): self.scenario('stage-cancel')
    def test_crash_before_live_mutation(self): self.scenario('crash:prepared')
    def test_crash_after_journal(self): self.scenario('crash:applying')
    def test_crash_during_native_files(self): self.scenario('crash:file-written:kart_geister/Lumo-Geist_Zoey.lumogeist')
    def test_crash_after_preferences(self): self.scenario('crash:preferences-written')
    def test_crash_before_commit(self): self.scenario('crash:data-written')
    def test_crash_after_commit_keeps_restored_data(self): self.scenario('crash:committed')
    def test_failed_commit_rolls_back(self): self.scenario('failed-write')
    def test_interrupted_rollback_retries(self): self.scenario('rollback-interrupted')
    def test_corrupted_previous_snapshot_rejected(self): self.scenario('checksum')
    def test_traversal_authority_and_unknown_paths_refused(self): self.scenario('unsafe-paths')
    def test_symlink_refused_before_mutation(self): self.scenario('symlink')
    def test_size_limit_refused_before_mutation(self): self.scenario('size-limit')


class LocalBackupAndroidCompileTest(unittest.TestCase):
    def test_real_saf_bridge_compiles_against_android_api(self):
        android_roots = [Path(os.environ.get(name, '/nonexistent')) for name in ('ANDROID_HOME', 'ANDROID_SDK_ROOT')]
        configured = Path(os.environ.get('LUMO_ANDROID_API_JAR', '/nonexistent'))
        jars = [configured, *(root / 'platforms/android-36/android.jar' for root in android_roots)]
        android = next((path for path in jars if path.is_file()), None)
        libraries = Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent'))
        java_home = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin'
        java = str(java_home / 'java') if (java_home / 'java').is_file() else shutil.which('java')
        javac = str(java_home / 'javac') if (java_home / 'javac').is_file() else shutil.which('javac')
        if android is None or not list(libraries.glob('kotlin-compiler-embeddable-*.jar')) or not java or not javac:
            self.skipTest(
                'Android API36/JDK/Kotlin compiler toolchain not provisioned; '
                'strict acceptance rejects this skip'
            )
        with tempfile.TemporaryDirectory(prefix='lumo-backup-android-compile-') as directory:
            root = Path(directory)
            classes = root / 'classes'
            classes.mkdir()
            # The transport boundary has no behavior; Android classes come from
            # the real SDK. Transaction, SAF and event-store code are production.
            stubs = {
                'BinaryMessenger.java': 'package io.flutter.plugin.common; public interface BinaryMessenger {}',
                'MethodCall.java': 'package io.flutter.plugin.common; public class MethodCall { public String method; public Object arguments; }',
                'MethodChannel.java': '''package io.flutter.plugin.common;
                  public class MethodChannel {
                    public MethodChannel(BinaryMessenger messenger, String name) {}
                    public interface Result { void success(Object value); void error(String code, String message, Object details); void notImplemented(); }
                    public interface MethodCallHandler { void onMethodCall(MethodCall call, Result result); }
                    public void setMethodCallHandler(MethodCallHandler handler) {}
                  }''',
            }
            for name, source in stubs.items(): (root / name).write_text(source)
            compiled = subprocess.run([javac, '-cp', str(android), '-d', str(classes),
                *map(str, root.glob('*.java')), str(ROOT / 'tools/auto_install/LumoBackupTransaction.java')],
                capture_output=True, text=True, timeout=60)
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
            compiled = subprocess.run([java, '-cp', os.pathsep.join(map(str, sorted(libraries.glob('*.jar')))),
                'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                '-classpath', os.pathsep.join(map(str, (classes, android, stdlib))),
                '-jvm-target', '1.8', '-d', str(classes),
                str(ROOT / 'tools/auto_install/LumoLocalBackupBridge.kt'),
                str(ROOT / 'tools/auto_install/GameEventStore.kt')],
                capture_output=True, text=True, timeout=90)
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            self.assertTrue((classes / 'dev/ullmann/lumo/LumoLocalBackupBridge.class').is_file())


if __name__ == '__main__':
    unittest.main()
