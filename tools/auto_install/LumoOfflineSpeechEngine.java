package dev.ullmann.lumo;

// Local Supertonic 3 inference adapted from the MIT reference implementation:
// https://github.com/supertone-oss-archive/supertonic/blob/main/java/Helper.java
// Copyright (c) 2025 Supertone Inc. MIT notice is bundled with the application.
// Model weights are separately governed by BigScience Open RAIL-M.
// Changes: German-only bounded input, binary preset verification, deterministic
// seed, cancellable inference, bounded output, closed tensors and CPU threads.

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;
import java.io.File;
import java.io.FileInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.text.Normalizer;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.CancellationException;
import java.util.function.BooleanSupplier;

/** CPU-only German speech. No network, microphone, system TTS or child store. */
public final class LumoOfflineSpeechEngine implements AutoCloseable {
    public static final String PROFILE = "lumo-free-supertonic-de-v1";
    public static final String PRESET = "F2";
    public static final int SPEAKER_ID = 1;
    public static final int SAMPLE_RATE = 44100;
    public static final int STEPS = 8;
    private static final int MAX_TEXT = 220;
    private static final int MAX_SECONDS = 30;
    private static final int LATENT_CHANNELS = 144;
    private static final int CHUNK_SIZE = 3072;
    private final OrtEnvironment env;
    private OrtSession durationSession;
    private OrtSession encoderSession;
    private OrtSession vectorSession;
    private OrtSession vocoderSession;
    private OnnxTensor ttlStyle;
    private OnnxTensor dpStyle;
    private int[] indexer;
    private final Object runLock = new Object();
    private OrtSession.RunOptions activeRun;

    public LumoOfflineSpeechEngine(File directory) throws IOException, OrtException {
        env = OrtEnvironment.getEnvironment();
        try (OrtSession.SessionOptions options = new OrtSession.SessionOptions()) {
            options.setIntraOpNumThreads(2);
            options.setInterOpNumThreads(1);
            options.setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL);
            options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT);
            options.setCPUArenaAllocator(false);
            durationSession = env.createSession(
                new File(directory, "duration_predictor.int8.onnx").getPath(), options);
            encoderSession = env.createSession(
                new File(directory, "text_encoder.int8.onnx").getPath(), options);
            vectorSession = env.createSession(
                new File(directory, "vector_estimator.int8.onnx").getPath(), options);
            vocoderSession = env.createSession(
                new File(directory, "vocoder.int8.onnx").getPath(), options);
            loadStyle(new File(directory, "voice.bin"));
            byte[] data = readBinary(new File(directory, "unicode_indexer.bin"), 262144);
            if (data.length != 262144) throw new IOException("Invalid indexer shape");
            ByteBuffer values = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN);
            indexer = new int[data.length / 4];
            for (int i = 0; i < indexer.length; i++) indexer[i] = values.getInt();
        } catch (IOException | OrtException | RuntimeException error) {
            close();
            throw error;
        }
    }

    private void loadStyle(File path) throws IOException, OrtException {
        byte[] raw = readBinary(path, 48 + 10 * (50 * 256 + 8 * 16) * 4);
        if (raw.length != 48 + 10 * (50 * 256 + 8 * 16) * 4) {
            throw new IOException("Invalid preset payload");
        }
        ByteBuffer data = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN);
        long[] expected = {10, 50, 256, 10, 8, 16};
        for (long dimension : expected) {
            if (data.getLong() != dimension) throw new IOException("Invalid preset dimensions");
        }
        float[] ttl = new float[50 * 256];
        float[] dp = new float[8 * 16];
        data.position(48 + SPEAKER_ID * ttl.length * 4);
        for (int i = 0; i < ttl.length; i++) ttl[i] = data.getFloat();
        data.position(48 + 10 * ttl.length * 4 + SPEAKER_ID * dp.length * 4);
        for (int i = 0; i < dp.length; i++) dp[i] = data.getFloat();
        for (float value : ttl) if (!Float.isFinite(value)) throw new IOException("Invalid preset");
        for (float value : dp) if (!Float.isFinite(value)) throw new IOException("Invalid preset");
        ttlStyle = OnnxTensor.createTensor(env, FloatBuffer.wrap(ttl), new long[]{1, 50, 256});
        dpStyle = OnnxTensor.createTensor(env, FloatBuffer.wrap(dp), new long[]{1, 8, 16});
    }

    /** Exact German normalization compatible with the reference language tags. */
    public static String prepareGerman(String input) {
        if (input == null || input.trim().isEmpty() || input.length() > MAX_TEXT) {
            throw new IllegalArgumentException("Empty or oversized speech text");
        }
        String normalized = Normalizer.normalize(input, Normalizer.Form.NFKD)
            .replace('\u2013', '-').replace('\u2014', '-').replace('\u2011', '-')
            .replace('_', ' ').replace('\u201c', '"').replace('\u201d', '"')
            .replace('\u2018', '\'').replace('\u2019', '\'')
            .replace('\u00b4', '\'').replace('`', '\'')
            .replaceAll("[\\[\\]|/#\u2190\u2192]", " ")
            .replaceAll("[\u2665\u2606\u2661\u00a9\\\\]", "")
            .replace("@", " at ");
        StringBuilder clean = new StringBuilder();
        normalized.codePoints().forEach(cp -> {
            boolean emoji = cp > 0xffff || (cp >= 0x2600 && cp <= 0x27bf);
            if (!emoji) clean.appendCodePoint(cp);
        });
        normalized = clean.toString().replaceAll(" +([,.!?;:'])", "$1")
            .replaceAll("\\s+", " ").replaceAll("\"{2,}", "\"")
            .replaceAll("'{2,}", "'").trim();
        if (normalized.isEmpty()) throw new IllegalArgumentException("No speakable text");
        // The German word "Verb" starts with a voiced consonant. This small
        // model-specific spelling hint avoids the observed unvoiced "Färb".
        // It is speech input only; visible text, grading and stored answers
        // remain exactly as supplied by the existing learning logic.
        normalized = normalized.replaceAll("(?i)\\bverb\\b", "Werb");
        if (!normalized.matches("(?s).*[.!?;:,'\")\\]}\u2026]$")) normalized += ".";
        return "<de>" + normalized + "</de>";
    }

    private long[] ids(String prepared) {
        int[] characters = prepared.codePoints().toArray();
        long[] ids = new long[characters.length];
        for (int i = 0; i < characters.length; i++) {
            int cp = characters[i];
            if (cp < 0 || cp >= indexer.length || indexer[cp] < 0) {
                // A typo/unsupported character is never allowed to index -1
                // in an ONNX embedding or silently change a mathematical task.
                throw new IllegalArgumentException("Unsupported speech character");
            }
            ids[i] = indexer[cp];
        }
        return ids;
    }

    public static float speedFor(String style) {
        if ("celebrate".equals(style)) return 1.02f;
        if ("comfort".equals(style)) return .94f;
        if ("question".equals(style)) return .96f;
        return .98f;
    }

    /** SetTerminate acts on native inference; the worker owns tensor disposal. */
    public void cancel() {
        synchronized (runLock) {
            if (activeRun != null) {
                try { activeRun.setTerminate(true); } catch (OrtException ignored) {}
            }
        }
    }

    public byte[] synthesize(String text, String style, BooleanSupplier cancelled)
        throws IOException, OrtException {
        String prepared = prepareGerman(text);
        long[] tokens = ids(prepared);
        float[] mask = new float[tokens.length];
        Arrays.fill(mask, 1);
        OrtSession.RunOptions run = new OrtSession.RunOptions();
        synchronized (runLock) { activeRun = run; }
        try (
            OnnxTensor tokenTensor = OnnxTensor.createTensor(env,
                java.nio.LongBuffer.wrap(tokens), new long[]{1, tokens.length});
            OnnxTensor textMask = OnnxTensor.createTensor(env, FloatBuffer.wrap(mask),
                new long[]{1, 1, tokens.length});
            OnnxTensor totalStep = OnnxTensor.createTensor(env, new float[]{STEPS})
        ) {
            checkCancelled(cancelled);
            Map<String, OnnxTensor> durationInputs = new HashMap<>();
            durationInputs.put("text_ids", tokenTensor);
            durationInputs.put("style_dp", dpStyle);
            durationInputs.put("text_mask", textMask);
            float duration;
            try (OrtSession.Result predicted = durationSession.run(durationInputs, run)) {
                duration = ((OnnxTensor) predicted.get(0))
                    .getFloatBuffer().get(0) / speedFor(style);
            }
            if (!Float.isFinite(duration) || duration < .1f || duration > MAX_SECONDS) {
                throw new IOException("Invalid speech duration");
            }
            int wavLength = (int) (duration * SAMPLE_RATE);
            int latentLength = (wavLength + CHUNK_SIZE - 1) / CHUNK_SIZE;
            float[] latent = new float[LATENT_CHANNELS * latentLength];
            Random random = new Random((PROFILE + prepared).hashCode());
            for (int i = 0; i < latent.length; i++) latent[i] = (float) random.nextGaussian();
            float[] maskValues = new float[latentLength];
            Arrays.fill(maskValues, 1);
            Map<String, OnnxTensor> encoderInputs = new HashMap<>();
            encoderInputs.put("text_ids", tokenTensor);
            encoderInputs.put("style_ttl", ttlStyle);
            encoderInputs.put("text_mask", textMask);
            try (
                OrtSession.Result encoded = encoderSession.run(encoderInputs, run);
                OnnxTensor latentMask = OnnxTensor.createTensor(env,
                    FloatBuffer.wrap(maskValues), new long[]{1, 1, latentLength})
            ) {
                OnnxTensor embedding = (OnnxTensor) encoded.get(0);
                for (int step = 0; step < STEPS; step++) {
                    checkCancelled(cancelled);
                    try (
                        OnnxTensor noisy = OnnxTensor.createTensor(env,
                            FloatBuffer.wrap(latent), new long[]{1, LATENT_CHANNELS, latentLength});
                        OnnxTensor current = OnnxTensor.createTensor(env, new float[]{step})
                    ) {
                        Map<String, OnnxTensor> inputs = new HashMap<>();
                        inputs.put("noisy_latent", noisy);
                        inputs.put("text_emb", embedding);
                        inputs.put("style_ttl", ttlStyle);
                        inputs.put("latent_mask", latentMask);
                        inputs.put("text_mask", textMask);
                        inputs.put("current_step", current);
                        inputs.put("total_step", totalStep);
                        try (OrtSession.Result result = vectorSession.run(inputs, run)) {
                            FloatBuffer values = ((OnnxTensor) result.get(0)).getFloatBuffer();
                            latent = new float[values.remaining()];
                            values.get(latent);
                        }
                    }
                }
                checkCancelled(cancelled);
                try (OnnxTensor finalLatent = OnnxTensor.createTensor(env,
                    FloatBuffer.wrap(latent), new long[]{1, LATENT_CHANNELS, latentLength})) {
                    Map<String, OnnxTensor> inputs = new HashMap<>();
                    inputs.put("latent", finalLatent);
                    try (OrtSession.Result result = vocoderSession.run(inputs, run)) {
                        FloatBuffer values = ((OnnxTensor) result.get(0)).getFloatBuffer();
                        float[] samples = new float[Math.min(wavLength, values.remaining())];
                        values.get(samples);
                        checkCancelled(cancelled);
                        return pcmWave(samples);
                    }
                }
            }
        } finally {
            synchronized (runLock) {
                if (activeRun == run) activeRun = null;
                run.close();
            }
        }
    }

    private static void checkCancelled(BooleanSupplier cancelled) {
        if (cancelled.getAsBoolean() || Thread.currentThread().isInterrupted()) {
            throw new CancellationException("Local speech cancelled");
        }
    }

    private static byte[] readBinary(File file, int expected) throws IOException {
        if (file.length() != expected) throw new IOException("Invalid binary size");
        try (FileInputStream input = new FileInputStream(file);
             ByteArrayOutputStream output = new ByteArrayOutputStream(expected)) {
            byte[] buffer = new byte[16384];
            for (int count; (count = input.read(buffer)) != -1;) {
                output.write(buffer, 0, count);
                if (output.size() > expected) throw new IOException("Oversized binary");
            }
            if (output.size() != expected) throw new IOException("Truncated binary");
            return output.toByteArray();
        }
    }

    /** Real mono PCM, with gentle limiting. It is not a fake completion signal. */
    public static byte[] pcmWave(float[] samples) throws IOException {
        if (samples.length < SAMPLE_RATE / 10 || samples.length > SAMPLE_RATE * MAX_SECONDS) {
            throw new IOException("Invalid speech sample count");
        }
        float peak = 0;
        double power = 0;
        for (float value : samples) {
            if (!Float.isFinite(value)) throw new IOException("Invalid PCM sample");
            peak = Math.max(peak, Math.abs(value));
            power += value * value;
        }
        if (peak < .005 || Math.sqrt(power / samples.length) < .001) {
            throw new IOException("Silent model output");
        }
        float scale = peak > .78f ? .78f / peak : 1f;
        ByteBuffer wav = ByteBuffer.allocate(44 + samples.length * 2)
            .order(ByteOrder.LITTLE_ENDIAN);
        wav.put(new byte[]{'R', 'I', 'F', 'F'}).putInt(36 + samples.length * 2)
            .put(new byte[]{'W', 'A', 'V', 'E', 'f', 'm', 't', ' '})
            .putInt(16).putShort((short) 1).putShort((short) 1)
            .putInt(SAMPLE_RATE).putInt(SAMPLE_RATE * 2)
            .putShort((short) 2).putShort((short) 16)
            .put(new byte[]{'d', 'a', 't', 'a'}).putInt(samples.length * 2);
        for (float value : samples) {
            wav.putShort((short) Math.round(Math.max(-.98f,
                Math.min(.98f, value * scale)) * 32767));
        }
        return wav.array();
    }

    @Override
    public void close() {
        cancel();
        if (ttlStyle != null) { ttlStyle.close(); ttlStyle = null; }
        if (dpStyle != null) { dpStyle.close(); dpStyle = null; }
        for (OrtSession session : new OrtSession[]{
            durationSession, encoderSession, vectorSession, vocoderSession
        }) {
            if (session != null) try { session.close(); } catch (OrtException ignored) {}
        }
        durationSession = encoderSession = vectorSession = vocoderSession = null;
    }
}
