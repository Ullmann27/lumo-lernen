import java.io.File;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.HashSet;
import java.util.Set;
import java.util.jar.JarFile;

/** Verify every bundle payload's JAR signature, including unsigned additions. */
class LumoAabCertificateVerifier {
    public static void main(String[] args) throws Exception {
        if (args.length != 2 || !args[1].matches("[0-9a-f]{64}"))
            throw new IllegalArgumentException("Expected AAB path and trusted certificate digest");
        int payloads = 0;
        try (var jar = new JarFile(new File(args[0]), true)) {
            var entries = jar.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                if (entry.isDirectory()) continue;
                // Reading to EOF triggers java.util.jar's cryptographic verification.
                try (var input = jar.getInputStream(entry)) {
                    input.transferTo(java.io.OutputStream.nullOutputStream());
                }
                String name = entry.getName().toUpperCase(java.util.Locale.ROOT);
                if (name.equals("META-INF/MANIFEST.MF") ||
                    name.matches("META-INF/[^/]+\\.(SF|RSA|DSA|EC)")) continue;
                var signers = entry.getCodeSigners();
                if (signers == null || signers.length != 1)
                    throw new IllegalStateException("Bundle payload must have exactly one signer: " + entry.getName());
                var certificate = signers[0].getSignerCertPath().getCertificates().get(0);
                certificate.verify(certificate.getPublicKey());
                String digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                        .digest(certificate.getEncoded()));
                if (!digest.equals(args[1]))
                    throw new IllegalStateException("Unexpected AAB signing certificate: " + digest);
                payloads++;
            }
        }
        if (payloads == 0) throw new IllegalStateException("Bundle contains no signed payload");
        System.out.println("Verified stable AAB signing certificate (SHA-256): " + args[1]);
    }
}
