package ai.onnxruntime;

import java.nio.Buffer;
import java.nio.FloatBuffer;

/** No tensor math: inference is forbidden by OrtSession.run below. */
public final class OnnxTensor implements AutoCloseable {
    public static OnnxTensor createTensor(OrtEnvironment env, Buffer data, long[] shape)
            throws OrtException { return new OnnxTensor(); }
    public static OnnxTensor createTensor(OrtEnvironment env, Object data)
            throws OrtException { return new OnnxTensor(); }
    public FloatBuffer getFloatBuffer() {
        throw new AssertionError("Synthetic ONNX boundary cannot provide model output");
    }
    public void close() {}
}
