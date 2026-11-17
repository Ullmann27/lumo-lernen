import ai.onnxruntime.OrtSession;
import dev.ullmann.lumo.LumoOfflineSpeechEngine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.concurrent.CancellationException;

/** Runs production prepareGerman + ids with the exact pinned tokenizer table.
 * Only ONNX session/tensor construction is synthetic. A cancellation supplied
 * to the actual public synthesize method must happen after ids and before run.
 * This is neither model inference nor Android playback/acoustic evidence. */
public final class OfflineVoiceTokenizerContract {
    private static int checks;
    private static void check(boolean condition, String message) {
        checks++;
        if (!condition) throw new AssertionError(message);
    }
    private static void accepts(LumoOfflineSpeechEngine engine, String text) throws Exception {
        try {
            engine.synthesize(text, "explain", () -> true);
            throw new AssertionError("Cancelled tokenization must not return synthetic audio");
        } catch (CancellationException expected) {
            checks++;
        }
    }
    public static void main(String[] args) throws Exception {
        Path indexer = Path.of(args[0]);
        byte[] raw = Files.readAllBytes(indexer);
        String hash = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw));
        check(raw.length == 262144 && hash.equals(args[1]), "Exact repository-pinned indexer");
        System.out.println("PINNED_INDEXER sha256=" + hash + " bytes=" + raw.length);
        ByteBuffer table = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN);
        check(table.getInt(0x201e * 4) == -1 && table.getInt('"' * 4) >= 0,
            "Model refuses the original low quote but supports its ASCII equivalent");

        Path models = Path.of(args[2]);
        Files.copy(indexer, models.resolve("unicode_indexer.bin"));
        // Valid shape, zero synthetic styles: no inference is permitted.
        ByteBuffer style = ByteBuffer.allocate(48 + 10 * (50 * 256 + 8 * 16) * 4)
            .order(ByteOrder.LITTLE_ENDIAN);
        for (long dimension : new long[]{10, 50, 256, 10, 8, 16}) style.putLong(dimension);
        Files.write(models.resolve("voice.bin"), style.array());

        try (LumoOfflineSpeechEngine engine = new LumoOfflineSpeechEngine(models.toFile())) {
            String original = "Baue Banane. Als Nächstes kommt die Silbe „Ba“.";
            // The original fails inside the actual ids(), before cancellation.
            accepts(engine, original);
            check(LumoOfflineSpeechEngine.prepareGerman(original).equals(
                "<de>Baue Banane. Als Na\u0308chstes kommt die Silbe \"Ba\".</de>"),
                "Original words and German diacritics remain; only quote typography changes");
            accepts(engine, "Warum zuerst zwei?");
            accepts(engine, "8 plus 5 ist 13.");
            check(LumoOfflineSpeechEngine.prepareGerman("8 plus 5 ist 13.")
                .equals("<de>8 plus 5 ist 13.</de>"), "Numbers and relation remain intact");
            check(LumoOfflineSpeechEngine.prepareGerman("„Ba“ und “na”")
                .equals("<de>\"Ba\" und \"na\"</de>"), "Existing quote normalization remains");
            String unsupported = "8 \u0378 plus 5";
            check(table.getInt(0x0378 * 4) == -1 &&
                LumoOfflineSpeechEngine.prepareGerman(unsupported).contains("\u0378"),
                "An unknown question character is not silently discarded");
            boolean rejected = false;
            try { engine.synthesize(unsupported, "explain", () -> true); }
            catch (IllegalArgumentException expected) {
                rejected = "Unsupported speech character".equals(expected.getMessage());
            }
            check(rejected, "Actual ids still rejects unknown characters before inference");
        }
        check(OrtSession.runs == 0, "No synthetic ONNX execution");
        System.out.println("LUMO_OFFLINE_TOKENIZER_PASS checks=" + checks
            + " production_normalizer_and_ids=true real_pinned_indexer=true"
            + " onnx_boundary=synthetic inference=false Android_playback=false");
    }
}
