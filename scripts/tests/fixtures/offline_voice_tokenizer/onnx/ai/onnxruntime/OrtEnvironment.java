package ai.onnxruntime;

/** Synthetic session construction lets the real engine load its real indexer. */
public final class OrtEnvironment {
    public static OrtEnvironment getEnvironment() { return new OrtEnvironment(); }
    public OrtSession createSession(String path, OrtSession.SessionOptions options)
            throws OrtException { return new OrtSession(); }
}
