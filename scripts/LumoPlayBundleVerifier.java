import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.CodeSigner;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Set;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/** Verify upload-key possession and every AAB payload entry through public JDK APIs. */
public final class LumoPlayBundleVerifier {
    private static final String FAMILY_CERT =
        "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702";

    private static final class CheckFailed extends RuntimeException {
        CheckFailed(String message) { super(message); }
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new CheckFailed(message);
    }

    private static String variable(String name) {
        String value = System.getenv(name);
        require(value != null && !value.isEmpty(), "Missing required Play signing input: " + name);
        return value;
    }

    private static String certificateDigest(X509Certificate certificate) throws Exception {
        certificate.checkValidity();
        return HexFormat.of().formatHex(
            MessageDigest.getInstance("SHA-256").digest(certificate.getEncoded()));
    }

    private static void preflight() throws Exception {
        Path path = Path.of(variable("LUMO_PLAY_STORE_FILE"));
        require(path.isAbsolute() && Files.isRegularFile(path),
            "Play upload keystore must be an existing absolute file");
        String alias = variable("LUMO_PLAY_KEY_ALIAS");
        require(!alias.equalsIgnoreCase("androiddebugkey"),
            "The standard Android debug alias cannot sign a Play release");
        char[] storePassword = variable("LUMO_PLAY_STORE_PASSWORD").toCharArray();
        char[] keyPassword = variable("LUMO_PLAY_KEY_PASSWORD").toCharArray();
        try {
            KeyStore store = KeyStore.getInstance(path.toFile(), storePassword);
            require(store.entryInstanceOf(alias, KeyStore.PrivateKeyEntry.class),
                "The configured upload alias is not a private-key entry");
            require(store.getKey(alias, keyPassword) instanceof PrivateKey,
                "The configured upload private key cannot be read");
            require(store.getCertificate(alias) instanceof X509Certificate,
                "The upload alias has no X.509 signing certificate");
            String digest = certificateDigest((X509Certificate) store.getCertificate(alias));
            require(!digest.equals(FAMILY_CERT),
                "The public family test certificate cannot sign a Play release");
            System.out.println("{\"uploadCertificateSha256\":\"" + digest
                + "\",\"privateKeyReadable\":true,\"javaFeature\":"
                + Runtime.version().feature() + "}");
        } finally {
            Arrays.fill(storePassword, '\0');
            Arrays.fill(keyPassword, '\0');
        }
    }

    private static boolean signatureMetadata(String name) {
        String upper = name.toUpperCase(Locale.ROOT);
        if (!upper.startsWith("META-INF/")) return false;
        String leaf = upper.substring("META-INF/".length());
        if (leaf.contains("/")) return false;
        return leaf.equals("MANIFEST.MF") || leaf.endsWith(".SF")
            || leaf.endsWith(".RSA") || leaf.endsWith(".DSA")
            || leaf.endsWith(".EC") || leaf.startsWith("SIG-");
    }

    private static void verify(Path path, String expected) throws Exception {
        require(expected.matches("[0-9a-f]{64}") && !expected.equals(FAMILY_CERT),
            "Expected a non-family SHA-256 upload certificate");
        require(Files.isRegularFile(path), "Bundle file is missing");
        long verified = 0;
        Set<String> seen = new HashSet<>();
        byte[] buffer = new byte[64 * 1024];
        try (JarFile archive = new JarFile(path.toFile(), true)) {
            require(archive.getManifest() != null, "Bundle has no JAR signing manifest");
            var entries = archive.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                require(seen.add(entry.getName()), "Bundle contains duplicate archive entries");
                if (entry.isDirectory()) continue;
                // JarEntry.getCodeSigners is populated only after complete consumption.
                try (InputStream input = archive.getInputStream(entry)) {
                    while (input.read(buffer) != -1) { }
                }
                if (signatureMetadata(entry.getName())) continue;
                CodeSigner[] signers = entry.getCodeSigners();
                require(signers != null && signers.length == 1,
                    "Bundle contains an unsigned or ambiguously signed payload entry");
                var certificates = signers[0].getSignerCertPath().getCertificates();
                require(!certificates.isEmpty()
                    && certificates.get(0) instanceof X509Certificate,
                    "Bundle payload signer has no X.509 certificate");
                require(certificateDigest((X509Certificate) certificates.get(0)).equals(expected),
                    "Bundle payload signer differs from the configured upload certificate");
                verified++;
            }
        }
        require(verified > 0, "Bundle contains no verified payload entries");
        System.out.println("{\"uploadCertificateSha256\":\"" + expected
            + "\",\"verifiedEntries\":" + verified + "}");
    }

    public static void main(String[] arguments) {
        try {
            require(Runtime.version().feature() >= 17, "JDK 17 or later is required");
            if (arguments.length == 1 && arguments[0].equals("preflight")) {
                preflight();
            } else if (arguments.length == 3 && arguments[0].equals("verify")) {
                verify(Path.of(arguments[1]), arguments[2]);
            } else {
                throw new CheckFailed("Expected preflight or verify BUNDLE CERT_SHA256");
            }
        } catch (CheckFailed error) {
            System.err.println(error.getMessage());
            System.exit(1);
        } catch (Exception error) {
            // Provider errors can include file paths or credential diagnostics.
            System.err.println("Play signing verification failed (" +
                error.getClass().getSimpleName() + ")");
            System.exit(1);
        }
    }
}
