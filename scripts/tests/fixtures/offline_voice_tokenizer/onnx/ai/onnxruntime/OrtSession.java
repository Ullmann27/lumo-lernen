package ai.onnxruntime;

import java.util.Map;

/** Explicit synthetic boundary, not a model, a WAV or an Android player. */
public final class OrtSession implements AutoCloseable {
    public static int runs;
    public static final class SessionOptions implements AutoCloseable {
        public enum ExecutionMode { SEQUENTIAL }
        public enum OptLevel { ALL_OPT }
        public void setIntraOpNumThreads(int value) {}
        public void setInterOpNumThreads(int value) {}
        public void setExecutionMode(ExecutionMode value) {}
        public void setOptimizationLevel(OptLevel value) {}
        public void setCPUArenaAllocator(boolean value) {}
        public void close() {}
    }
    public static final class RunOptions implements AutoCloseable {
        public void setTerminate(boolean value) throws OrtException {}
        public void close() {}
    }
    public static final class Result implements AutoCloseable {
        public OnnxTensor get(int index) {
            throw new AssertionError("No synthetic inference result");
        }
        public void close() {}
    }
    public Result run(Map<String, OnnxTensor> inputs, RunOptions options)
            throws OrtException {
        runs++;
        throw new AssertionError("Tokenizer contract must cancel before ONNX inference");
    }
    public void close() throws OrtException {}
}
