import com.android.apksig.ApkVerifier;
import java.io.File;
import java.security.MessageDigest;
import java.security.cert.X509Certificate;
import java.util.HexFormat;
import java.util.HashSet;
import java.util.Set;

/** Verify APK signatures and inspect DER certificates without parsing CLI text. */
class LumoApkCertificateVerifier {
    private static void add(Set<String> digests, X509Certificate certificate) throws Exception {
        if (certificate == null) throw new IllegalStateException("Missing signing certificate");
        digests.add(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(certificate.getEncoded())));
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2 || !args[1].matches("[0-9a-f]{64}"))
            throw new IllegalArgumentException("Expected APK path and trusted certificate digest");
        ApkVerifier.Result result = new ApkVerifier.Builder(new File(args[0])).build().verify();
        if (!result.isVerified()) throw new IllegalStateException("APK signature verification failed");
        if (result.getSignerCertificates().size() != 1)
            throw new IllegalStateException("APK must have exactly one signer");
        Set<String> digests = new HashSet<>();
        for (var certificate : result.getSignerCertificates()) add(digests, certificate);
        for (var signer : result.getV1SchemeSigners()) add(digests, signer.getCertificate());
        for (var signer : result.getV2SchemeSigners()) add(digests, signer.getCertificate());
        for (var signer : result.getV3SchemeSigners()) add(digests, signer.getCertificate());
        for (var signer : result.getV31SchemeSigners()) add(digests, signer.getCertificate());
        if (!digests.equals(Set.of(args[1])))
            throw new IllegalStateException("APK certificate mismatch; public SHA-256 digests: " + digests);
        System.out.println("Verified stable APK signing certificate (SHA-256): " + args[1]);
    }
}
