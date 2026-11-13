"""Execute the production JVM registry; no Android or mocked registry methods."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
HARNESS = r'''
package dev.ullmann.lumo;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class RegistryRegression {
    private static final String OLD = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String NEW = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    private static void check(boolean value, String reason) {
        if (!value) throw new AssertionError(reason);
    }
    public static void main(String[] args) throws Exception {
        Path mailbox = Paths.get(args[1], "lumo_cards_table_v1", OLD, "state.json");
        Files.createDirectories(mailbox.getParent());
        byte[] saved = ("{\"token\":\"" + OLD + "\",\"revision\":7}").getBytes(StandardCharsets.UTF_8);
        Files.write(mailbox, saved);
        CardsAuthorityRegistry owner = new CardsAuthorityRegistry();
        switch (args[0]) {
            case "stale":
                check(Files.isRegularFile(mailbox), "actual stale state fixture missing");
                check(!owner.hasAuthority(OLD), "a leftover file must not attach Flutter");
                owner.attach();
                check(!owner.hasAuthority(OLD), "engine attachment alone must not revive a session");
                owner.open(NEW);
                check(owner.hasAuthority(NEW), "fresh session should be live");
                check(!owner.hasAuthority(OLD), "fresh session must not admit old token");
                break;
            case "restart":
                owner.attach(); owner.open(OLD);
                check(owner.hasAuthority(OLD), "first process owns live session");
                CardsAuthorityRegistry restarted = new CardsAuthorityRegistry();
                restarted.attach();
                check(!restarted.hasAuthority(OLD), "new process cannot recover authority from disk");
                restarted.open(NEW);
                check(restarted.hasAuthority(NEW), "new controller may open its own session");
                check(!restarted.hasAuthority(OLD), "old binder token remains invalid");
                break;
            case "detach":
                owner.attach(); owner.open(OLD); owner.open(NEW);
                owner.detach();
                check(!owner.hasAuthority(OLD) && !owner.hasAuthority(NEW), "detach revokes every token");
                boolean rejected = false;
                try { owner.open(OLD); } catch (IllegalStateException expected) { rejected = true; }
                check(rejected, "detached engine cannot open sessions");
                owner.attach();
                check(!owner.hasAuthority(OLD) && !owner.hasAuthority(NEW), "reattach cannot restore old authority");
                owner.open(NEW);
                check(owner.hasAuthority(NEW), "fresh controller can open after attach");
                break;
            case "close":
                owner.attach(); owner.open(OLD); owner.open(NEW);
                owner.close(OLD); owner.close(OLD);
                check(Files.isRegularFile(mailbox), "simulate close before file cleanup");
                check(!owner.hasAuthority(OLD), "close revokes authority before cleanup");
                check(owner.hasAuthority(NEW), "closing one session cannot revoke another");
                owner.attach();
                check(!owner.hasAuthority(NEW), "replacement engine revokes previous sessions");
                break;
            case "tokens":
                owner.attach();
                for (String invalid : new String[]{null, "", "../../private", OLD + "a", OLD.toUpperCase()}) {
                    boolean invalidRejected = false;
                    try { owner.open(invalid); } catch (IllegalArgumentException expected) { invalidRejected = true; }
                    check(invalidRejected && !owner.hasAuthority(invalid), "invalid token accepted");
                }
                owner.open(OLD);
                check(!owner.hasAuthority(NEW), "foreign but valid token must be rejected");
                break;
            default: throw new AssertionError("unknown scenario");
        }
        check(java.util.Arrays.equals(saved, Files.readAllBytes(mailbox)), "registry must not alter persisted bytes");
        System.out.println("CARDS_AUTHORITY_REGISTRY_PASS " + args[0]);
    }
}
'''


class CardsAuthorityRegistryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.work = tempfile.TemporaryDirectory(prefix='lumo-cards-authority-')
        cls.root = Path(cls.work.name)
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(configured) if configured.is_file() else shutil.which('java')
        if not cls.java:
            raise RuntimeError('A JDK with java and jdk.compiler is required for the Cards authority regression')
        harness = cls.root / 'RegistryRegression.java'
        harness.write_text(HARNESS)
        cls.classes = cls.root / 'classes'
        cls.classes.mkdir()
        # The installed JDK may expose jdk.compiler without a separate javac
        # wrapper or ct.sym. Compile the production source to Java 8 bytecode;
        # the Android host compilation separately checks the actual platform API.
        compiled = subprocess.run([
            cls.java, '--module', 'jdk.compiler/com.sun.tools.javac.Main',
            '-source', '8', '-target', '8', '-Xlint:-options', '-d', str(cls.classes),
            str(ROOT / 'tools/auto_install/CardsAuthorityRegistry.java'), str(harness),
        ], capture_output=True, text=True, timeout=30)
        if compiled.returncode:
            raise AssertionError(compiled.stdout + compiled.stderr)

    @classmethod
    def tearDownClass(cls):
        cls.work.cleanup()

    def run_scenario(self, name):
        result = subprocess.run([
            self.java, '-cp', str(self.classes), 'dev.ullmann.lumo.RegistryRegression',
            name, str(self.root / name),
        ], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('CARDS_AUTHORITY_REGISTRY_PASS ' + name, result.stdout)

    def test_actual_stale_mailbox_does_not_revive_session(self):
        self.run_scenario('stale')

    def test_restarted_process_requires_new_live_session(self):
        self.run_scenario('restart')

    def test_detach_and_replacement_engine_revoke_old_tokens(self):
        self.run_scenario('detach')

    def test_close_revokes_before_file_cleanup(self):
        self.run_scenario('close')

    def test_invalid_and_foreign_tokens_never_gain_authority(self):
        self.run_scenario('tokens')


if __name__ == '__main__':
    unittest.main()
