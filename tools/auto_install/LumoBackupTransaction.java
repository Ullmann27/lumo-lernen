package dev.ullmann.lumo;

import java.io.*;
import java.security.MessageDigest;
import java.util.*;

/** Cold-start file transaction. No Flutter engine or native game may be alive. */
public final class LumoBackupTransaction {
    public static final int MAX_FILE = 8 * 1024 * 1024;
    public static final int MAX_NATIVE = 32 * 1024 * 1024;
    public static final int MAX_ARCHIVE = 64 * 1024 * 1024;
    public static final int MAX_PREFS = 16 * 1024 * 1024;
    private static final int MAGIC = 0x4c424b31;
    public interface Preferences {
        byte[] read() throws Exception;
        void write(byte[] bytes) throws Exception;
    }
    /** A test fault models process death, including interruption during rollback. */
    public interface Checkpoint { void reached(String phase) throws Exception; }
    public static final class Snapshot {
        public final byte[] preferences;
        public final Map<String, byte[]> files;
        public Snapshot(byte[] preferences, Map<String, byte[]> files) {
            this.preferences = preferences.clone();
            this.files = new TreeMap<>();
            for (Map.Entry<String, byte[]> entry : files.entrySet()) {
                this.files.put(entry.getKey(), entry.getValue().clone());
            }
        }
    }
    private final File filesRoot;
    private final File stateRoot;
    private final Checkpoint checkpoint;

    public LumoBackupTransaction(File filesRoot, File stateRoot) throws IOException {
        this(filesRoot, stateRoot, phase -> {});
    }
    public LumoBackupTransaction(File filesRoot, File stateRoot, Checkpoint checkpoint) throws IOException {
        this.filesRoot = filesRoot.getCanonicalFile();
        this.stateRoot = stateRoot.getCanonicalFile();
        this.checkpoint = checkpoint;
        if (!this.filesRoot.isDirectory() ||
            (!this.stateRoot.isDirectory() && !this.stateRoot.mkdirs())) {
            throw new IOException("Backup directory unavailable");
        }
    }
    public static boolean ownedPath(String path) {
        if (path == null || path.length() > 220 || path.contains("..") || path.contains("\\") ||
            path.chars().anyMatch(c -> c < 32)) return false;
        if (path.startsWith("kart_geister/")) {
            String name = path.substring(13);
            return !name.isEmpty() && !name.contains("/") &&
                (name.endsWith(".lumogeist") || name.endsWith(".json"));
        }
        if (Arrays.asList("settings.cfg", "progress.cfg", "lumo_game_events.json",
            "lumo_host_pending_rewards.cfg", "lumo_soundscape.cfg", "lumo_sternenjagd.cfg").contains(path)) return true;
        return path.matches("(kart|run|skypost|jump)_[A-Za-z0-9_-]{1,180}\\.cfg") ||
            path.matches("lumo_(build|settlement|puzzle|rhythm|treasure|cards|chess|first_run)_[A-Za-z0-9_-]{1,160}\\.(json|cfg)");
    }
    private File target(String path) throws IOException {
        if (!ownedPath(path)) throw new IOException("Unsupported backup path");
        File file = new File(filesRoot, path);
        if (!file.getCanonicalPath().equals(file.getAbsolutePath())) {
            throw new IOException("Symbolic backup path rejected");
        }
        if (!file.getCanonicalPath().startsWith(filesRoot.getPath() + File.separator)) {
            throw new IOException("Backup path escaped storage");
        }
        return file;
    }
    public Map<String, byte[]> captureFiles() throws IOException {
        Map<String, byte[]> result = new TreeMap<>();
        File[] roots = filesRoot.listFiles();
        if (roots == null) throw new IOException("Game directory unreadable");
        for (File file : roots) {
            if (ownedPath(file.getName())) {
                result.put(file.getName(), readLimited(target(file.getName()), MAX_FILE));
            } else if (file.getName().equals("kart_geister")) {
                if (!file.getCanonicalPath().equals(file.getAbsolutePath())) {
                    throw new IOException("Symbolic ghost directory rejected");
                }
                File[] ghosts = file.listFiles();
                if (ghosts == null) throw new IOException("Ghost directory unreadable");
                for (File ghost : ghosts) {
                    String path = "kart_geister/" + ghost.getName();
                    if (ownedPath(path)) result.put(path, readLimited(target(path), MAX_FILE));
                }
            }
        }
        validate(new Snapshot(new byte[0], result));
        return result;
    }
    public static byte[] readLimited(File file, int limit) throws IOException {
        try (InputStream input = new FileInputStream(file)) { return readLimited(input, limit); }
    }
    public static byte[] readLimited(InputStream input, int limit) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[16384];
        int size;
        while ((size = input.read(buffer)) != -1) {
            if (size > limit - output.size()) throw new IOException("Backup size limit exceeded");
            output.write(buffer, 0, size);
        }
        return output.toByteArray();
    }
    public static void validate(Snapshot snapshot) throws IOException {
        if (snapshot.preferences.length > MAX_PREFS || snapshot.files.size() > 1024) {
            throw new IOException("Backup size limit exceeded");
        }
        long total = 0;
        for (Map.Entry<String, byte[]> entry : snapshot.files.entrySet()) {
            if (!ownedPath(entry.getKey()) || entry.getValue().length > MAX_FILE) {
                throw new IOException("Invalid game backup entry");
            }
            total += entry.getValue().length;
        }
        if (total > MAX_NATIVE) throw new IOException("Game backup size limit exceeded");
    }
    public void stage(byte[] archive) throws IOException {
        if (archive.length == 0 || archive.length > MAX_ARCHIVE) throw new IOException("Invalid archive size");
        if (new File(stateRoot, "state").exists() || pending()) throw new IOException("Restore already pending");
        durable(new File(stateRoot, "pending.json"), archive);
    }
    public boolean pending() {
        return new File(stateRoot, "pending.json").isFile() || new File(stateRoot, "pending-previous.pack").isFile();
    }
    public byte[] pendingArchive() throws IOException {
        File file = new File(stateRoot, "pending.json");
        return file.isFile() ? readLimited(file, MAX_ARCHIVE) : null;
    }
    public boolean hasPrevious() { return new File(stateRoot, "previous.pack").isFile(); }
    public void stagePrevious() throws IOException {
        if (pending() || new File(stateRoot, "state").exists()) throw new IOException("Restore already pending");
        byte[] bytes = readLimited(new File(stateRoot, "previous.pack"), MAX_ARCHIVE);
        unpack(bytes);
        durable(new File(stateRoot, "pending-previous.pack"), bytes);
    }
    public Snapshot pendingPrevious() throws IOException {
        File file = new File(stateRoot, "pending-previous.pack");
        return file.isFile() ? unpack(readLimited(file, MAX_ARCHIVE)) : null;
    }
    public String status() throws IOException {
        File file = new File(stateRoot, "result");
        return file.isFile() ? new String(readLimited(file, 1000), "UTF-8") : "none";
    }
    public void rejectPending() throws IOException {
        clearPending();
        durable(new File(stateRoot, "result"), "invalid".getBytes("UTF-8"));
    }
    public boolean recover(Preferences preferences) throws Exception {
        File journal = new File(stateRoot, "state");
        if (!journal.isFile()) return false;
        String state = new String(readLimited(journal, 32), "UTF-8");
        if (state.equals("committed")) {
            finish("restored");
        } else if (state.equals("applying")) {
            Snapshot before = unpack(readLimited(new File(stateRoot, "before.pack"), MAX_ARCHIVE));
            replace(before, preferences);
            checkpoint.reached("rollback-written");
            // A repeated interruption replays the same previous snapshot.
            finish("rolled_back");
        } else { throw new IOException("Unknown restore state; originals retained"); }
        return true;
    }
    public void apply(Snapshot next, Preferences preferences) throws Exception {
        validate(next);
        if (new File(stateRoot, "state").exists()) throw new IOException("Recovery must run first");
        // Resolve every destination before changing any live file.
        for (String path : next.files.keySet()) target(path);
        Snapshot before = new Snapshot(preferences.read(), captureFiles());
        byte[] oldBytes = pack(before);
        byte[] nextBytes = pack(next);
        long required = (long) oldBytes.length * 2 + nextBytes.length + 2 * 1024 * 1024;
        if (stateRoot.getUsableSpace() < required) throw new IOException("Not enough space for rollback");
        durable(new File(stateRoot, "before.pack"), oldBytes);
        durable(new File(stateRoot, "after.pack"), nextBytes);
        checkpoint.reached("prepared");
        durable(new File(stateRoot, "state"), "applying".getBytes("UTF-8"));
        checkpoint.reached("applying");
        try {
            replace(next, preferences);
            checkpoint.reached("data-written");
            durable(new File(stateRoot, "state"), "committed".getBytes("UTF-8"));
            checkpoint.reached("committed");
            finish("restored");
        } catch (Exception error) {
            // If rollback itself fails, leave the journal + both packs intact
            // and refuse Flutter startup. The next cold start retries recovery.
            recover(preferences);
            throw error;
        }
    }
    private void replace(Snapshot snapshot, Preferences preferences) throws Exception {
        validate(snapshot);
        for (String path : snapshot.files.keySet()) target(path);
        Map<String, byte[]> current = captureFiles();
        for (Map.Entry<String, byte[]> entry : snapshot.files.entrySet()) {
            durable(target(entry.getKey()), entry.getValue());
            checkpoint.reached("file-written:" + entry.getKey());
        }
        for (String path : current.keySet()) {
            if (!snapshot.files.containsKey(path) && !target(path).delete()) {
                throw new IOException("Old game file could not be replaced");
            }
        }
        preferences.write(snapshot.preferences);
        checkpoint.reached("preferences-written");
    }
    private void finish(String result) throws IOException {
        byte[] previous = readLimited(new File(stateRoot, "before.pack"), MAX_ARCHIVE);
        unpack(previous);
        durable(new File(stateRoot, "previous.pack"), previous);
        clearPending();
        durable(new File(stateRoot, "result"), result.getBytes("UTF-8"));
        delete(new File(stateRoot, "state"));
        delete(new File(stateRoot, "after.pack"));
        delete(new File(stateRoot, "before.pack"));
    }
    private void clearPending() throws IOException {
        delete(new File(stateRoot, "pending.json"));
        delete(new File(stateRoot, "pending-previous.pack"));
    }
    private static void delete(File file) throws IOException {
        if (file.exists() && !file.delete()) throw new IOException("Backup cleanup failed");
    }
    private static void durable(File file, byte[] bytes) throws IOException {
        File parent = file.getParentFile();
        if (!parent.isDirectory() && !parent.mkdirs()) throw new IOException("Storage directory unavailable");
        File temporary = new File(parent, file.getName() + ".writing");
        try (FileOutputStream output = new FileOutputStream(temporary)) {
            output.write(bytes);
            output.getFD().sync();
        }
        if (!temporary.renameTo(file)) throw new IOException("Atomic backup rename failed");
    }
    public static byte[] pack(Snapshot snapshot) throws IOException {
        validate(snapshot);
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        DataOutputStream out = new DataOutputStream(bytes);
        out.writeInt(MAGIC);
        out.writeInt(snapshot.preferences.length);
        out.write(snapshot.preferences);
        out.writeInt(snapshot.files.size());
        for (Map.Entry<String, byte[]> entry : snapshot.files.entrySet()) {
            out.writeUTF(entry.getKey());
            out.writeInt(entry.getValue().length);
            out.write(entry.getValue());
        }
        out.flush();
        byte[] payload = bytes.toByteArray();
        bytes.write(hash(payload));
        return bytes.toByteArray();
    }
    public static Snapshot unpack(byte[] bytes) throws IOException {
        if (bytes.length < 44 || bytes.length > MAX_ARCHIVE) throw new IOException("Invalid rollback pack");
        byte[] payload = Arrays.copyOf(bytes, bytes.length - 32);
        if (!MessageDigest.isEqual(hash(payload), Arrays.copyOfRange(bytes, bytes.length - 32, bytes.length))) {
            throw new IOException("Rollback checksum mismatch");
        }
        DataInputStream in = new DataInputStream(new ByteArrayInputStream(payload));
        if (in.readInt() != MAGIC) throw new IOException("Unknown rollback pack");
        int prefSize = in.readInt();
        if (prefSize < 0 || prefSize > MAX_PREFS || prefSize > in.available()) throw new IOException("Invalid preferences length");
        byte[] prefs = new byte[prefSize]; in.readFully(prefs);
        int count = in.readInt();
        if (count < 0 || count > 1024) throw new IOException("Invalid file count");
        Map<String, byte[]> files = new TreeMap<>();
        for (int n = 0; n < count; n++) {
            String name = in.readUTF();
            int size = in.readInt();
            if (!ownedPath(name) || files.containsKey(name) || size < 0 || size > MAX_FILE || size > in.available()) {
                throw new IOException("Invalid rollback file");
            }
            byte[] content = new byte[size]; in.readFully(content); files.put(name, content);
        }
        if (in.available() != 0) throw new IOException("Unexpected rollback data");
        Snapshot result = new Snapshot(prefs, files); validate(result); return result;
    }
    private static byte[] hash(byte[] bytes) {
        try { return MessageDigest.getInstance("SHA-256").digest(bytes); }
        catch (Exception impossible) { throw new IllegalStateException(impossible); }
    }
}
