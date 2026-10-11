import dev.ullmann.lumo.LumoOfflineSpeechEngine;
import java.io.File;
import java.io.FileOutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CancellationException;

/** Real JVM inference, not an Android audio player or an acoustic device test. */
public final class LumoOfflineSpeechEngineProbe {
    private static int checks;
    private static void check(boolean value, String label) {
        checks++;
        if (!value) throw new AssertionError(label);
    }
    private static String escaped(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"")
            .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
    private static void units() throws Exception {
        check(LumoOfflineSpeechEngine.prepareGerman("Hallo!")
            .equals("<de>Hallo!</de>"), "German language tag");
        check(LumoOfflineSpeechEngine.prepareGerman("Sch\u00f6n, \u00c4pfel")
            .equals("<de>Scho\u0308n, A\u0308pfel.</de>"), "German diacritics");
        check(LumoOfflineSpeechEngine.prepareGerman("Lumo \ud83c\udf1f")
            .equals("<de>Lumo.</de>"), "Decorative emoji removed");
        check(LumoOfflineSpeechEngine.prepareGerman("Schau   nochmal !")
            .equals("<de>Schau nochmal!</de>"), "Punctuation normalization");
        check(LumoOfflineSpeechEngine.prepareGerman("Ist Haus ein Verb?")
            .equals("<de>Ist Haus ein Werb?</de>"), "German voiced Verb pronunciation aid");
        check(LumoOfflineSpeechEngine.speedFor("comfort") <
            LumoOfflineSpeechEngine.speedFor("celebrate"), "Event pacing, same preset");
        for (String invalid : new String[]{"", "x".repeat(221)}) {
            boolean refused = false;
            try { LumoOfflineSpeechEngine.prepareGerman(invalid); }
            catch (IllegalArgumentException expected) { refused = true; }
            check(refused, "Input bound");
        }
        for (float invalid : new float[]{Float.NaN, Float.POSITIVE_INFINITY, 0}) {
            boolean refused = false;
            try {
                float[] values = new float[4410];
                java.util.Arrays.fill(values, invalid);
                LumoOfflineSpeechEngine.pcmWave(values);
            } catch (java.io.IOException expected) { refused = true; }
            check(refused, "Invalid/silent PCM refused");
        }
    }

    public static void main(String[] args) throws Exception {
        units();
        if (args.length == 1 && "--unit-only".equals(args[0])) {
            System.out.println("PASS local voice Java guards: " + checks);
            return;
        }
        if (args.length != 3) throw new IllegalArgumentException("model-dir input.tsv output-dir");
        File output = new File(args[2]);
        if (!output.isDirectory() && !output.mkdirs()) throw new IllegalStateException("output");
        StringBuilder catalog = new StringBuilder(
            "{\"variant\":\"lumo-free-supertonic-de-v1\",\"voice\":\"Lumo Frei / F2 / JVM actual inference\","
            + "\"audio_extension\":\"wav\",\"clips\":{");
        int count = 0;
        try (LumoOfflineSpeechEngine engine = new LumoOfflineSpeechEngine(new File(args[0]))) {
            boolean cancelled = false;
            try { engine.synthesize("Hallo!", "greeting", () -> true); }
            catch (CancellationException expected) { cancelled = true; }
            check(cancelled, "Cancelled request produces no audio");
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                new FileInputStream(args[1]), StandardCharsets.UTF_8))) {
                for (String line; (line = reader.readLine()) != null;) {
                    String[] parts = line.split("\t", 2);
                    if (parts.length != 2) throw new IllegalArgumentException("TSV shape");
                    long start = System.nanoTime();
                    byte[] wave = engine.synthesize(parts[1], parts[0], () -> false);
                    long elapsed = (System.nanoTime() - start) / 1_000_000;
                    String id = String.format("jvm_%03d", ++count);
                    try (FileOutputStream file = new FileOutputStream(new File(output, id + ".wav"))) {
                        file.write(wave);
                    }
                    check(wave.length >= 44 + 8820, "Actual nonempty WAV");
                    if (count > 1) catalog.append(",");
                    catalog.append("\"").append(id).append("\":{\"id\":\"").append(id)
                        .append("\",\"text\":\"").append(escaped(parts[1]))
                        .append("\",\"style\":\"").append(escaped(parts[0]))
                        .append("\",\"synthesis_ms\":").append(elapsed)
                        .append(",\"bytes\":").append(wave.length).append("}");
                    System.out.println("Actual F2 JVM speech " + id + ": " + wave.length
                        + " bytes; " + elapsed + " ms");
                }
            }
        }
        catalog.append("}}");
        try (FileOutputStream file = new FileOutputStream(new File(output, "catalog.json"))) {
            file.write(catalog.toString().getBytes(StandardCharsets.UTF_8));
        }
        System.out.println("PASS local voice JVM inference: " + count
            + " actual generated WAVs; " + checks + " guards. NOT Android playback.");
    }
}
