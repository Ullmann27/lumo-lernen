"""Run the real Java speech adapter against explicit ONNX boundary doubles.

No weights, synthesis service, Android player or compiler download is used.
The generated PCM is a synthetic contract fixture, never recorded speech.
"""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "tools/auto_install/LumoOfflineSpeechEngine.java"
GERMAN_PROBE = ROOT / "scripts/voice/LumoOfflineSpeechEngineProbe.java"

STUBS = {
    "ai/onnxruntime/OrtException.java": r'''
package ai.onnxruntime;
public class OrtException extends Exception {
    public OrtException(String message) { super(message); }
}
''',
    "ai/onnxruntime/OnnxTensor.java": r'''
package ai.onnxruntime;
import java.nio.FloatBuffer;
import java.nio.LongBuffer;
public final class OnnxTensor implements AutoCloseable {
    public static int live;
    public final float[] floats;
    public final long[] longs;
    private boolean closed;
    private OnnxTensor(float[] f, long[] l) { floats=f; longs=l; live++; }
    public static OnnxTensor createTensor(OrtEnvironment e, FloatBuffer f, long[] shape)
        throws OrtException {
        float[] a=new float[f.remaining()]; f.duplicate().get(a);
        return new OnnxTensor(a,null);
    }
    public static OnnxTensor createTensor(OrtEnvironment e, LongBuffer f, long[] shape)
        throws OrtException {
        long[] a=new long[f.remaining()]; f.duplicate().get(a);
        return new OnnxTensor(null,a);
    }
    public static OnnxTensor createTensor(OrtEnvironment e, float[] f) throws OrtException {
        return new OnnxTensor(f.clone(),null);
    }
    public FloatBuffer getFloatBuffer() { return FloatBuffer.wrap(floats); }
    public void close() { if(!closed) { closed=true; live--; } }
}
''',
    "ai/onnxruntime/OrtEnvironment.java": r'''
package ai.onnxruntime;
public final class OrtEnvironment {
    private static final OrtEnvironment INSTANCE=new OrtEnvironment();
    public static OrtEnvironment getEnvironment() { return INSTANCE; }
    public OrtSession createSession(String path, OrtSession.SessionOptions options)
        throws OrtException { return new OrtSession(path); }
}
''',
    "ai/onnxruntime/OrtSession.java": r'''
package ai.onnxruntime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
public final class OrtSession implements AutoCloseable {
    public static final List<String> prepared=new ArrayList<>();
    public static int completed;
    public static final List<Float> dpIdentities=new ArrayList<>();
    public static final List<Float> ttlIdentities=new ArrayList<>();
    private final String path;
    public OrtSession(String path) { this.path=path; }
    public static void reset() {
        prepared.clear(); completed=0; dpIdentities.clear(); ttlIdentities.clear();
    }
    public Result run(Map<String,OnnxTensor> input, RunOptions options) throws OrtException {
        if(options.terminated) throw new OrtException("Synthetic terminated inference");
        float[] values;
        if(path.contains("duration_predictor")) {
            StringBuilder text=new StringBuilder();
            for(long token:input.get("text_ids").longs) text.append((char)token);
            prepared.add(text.toString());
            dpIdentities.add(input.get("style_dp").floats[0]);
            values=new float[]{0.196f};
        } else if(path.contains("text_encoder")) {
            ttlIdentities.add(input.get("style_ttl").floats[0]);
            values=new float[]{1.0f};
        } else if(path.contains("vector_estimator")) {
            values=input.get("noisy_latent").floats.clone();
        } else if(path.contains("vocoder")) {
            values=new float[44100];
            Arrays.fill(values,(++completed)*0.05f);
        } else throw new OrtException("Unknown synthetic boundary");
        return new Result(OnnxTensor.createTensor(OrtEnvironment.getEnvironment(),values));
    }
    public void close() throws OrtException {}
    public static final class Result implements AutoCloseable {
        private final OnnxTensor value;
        Result(OnnxTensor value) { this.value=value; }
        public Object get(int index) { if(index!=0) throw new IndexOutOfBoundsException(); return value; }
        public void close() { value.close(); }
    }
    public static final class RunOptions implements AutoCloseable {
        public boolean terminated;
        public void setTerminate(boolean value) throws OrtException { terminated=value; }
        public void close() {}
    }
    public static final class SessionOptions implements AutoCloseable {
        public enum ExecutionMode { SEQUENTIAL }
        public enum OptLevel { ALL_OPT }
        public void setIntraOpNumThreads(int n) {}
        public void setInterOpNumThreads(int n) {}
        public void setExecutionMode(ExecutionMode value) {}
        public void setOptimizationLevel(OptLevel value) {}
        public void setCPUArenaAllocator(boolean value) {}
        public void close() {}
    }
}
''',
}

CONTRACT = r'''
import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtSession;
import dev.ullmann.lumo.LumoOfflineSpeechEngine;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CancellationException;
import java.util.concurrent.atomic.AtomicInteger;

public final class EnglishLessonSpeechContract {
    private static int checks;
    private static void verify(boolean ok,String label) {
        checks++; if(!ok) throw new AssertionError(label);
    }
    private interface Operation { void run() throws Exception; }
    private static void refuse(Operation action,String label) throws Exception {
        boolean rejected=false;
        try { action.run(); } catch(IOException|IllegalArgumentException expected) { rejected=true; }
        verify(rejected,label);
    }
    private static void cancel(Operation action,String label) throws Exception {
        boolean rejected=false;
        try { action.run(); } catch(CancellationException expected) { rejected=true; }
        verify(rejected,label);
    }
    private static byte[] wave(int frames,float amplitude) throws Exception {
        float[] samples=new float[frames];Arrays.fill(samples,amplitude);
        return LumoOfflineSpeechEngine.pcmWave(samples);
    }
    private static ByteBuffer view(byte[] value) {
        return ByteBuffer.wrap(value).order(ByteOrder.LITTLE_ENDIAN);
    }
    private static Path fixture(Path dir) throws Exception {
        Files.createDirectories(dir);
        ByteBuffer voice=ByteBuffer.allocate(48+10*(12800+128)*4).order(ByteOrder.LITTLE_ENDIAN);
        for(long n:new long[]{10,50,256,10,8,16}) voice.putLong(n);
        for(int count:new int[]{12800,128})
            for(int speaker=0;speaker<10;speaker++)
                for(int n=0;n<count;n++) voice.putFloat(speaker+1);
        Files.write(dir.resolve("voice.bin"),voice.array());
        ByteBuffer index=ByteBuffer.allocate(65536*4).order(ByteOrder.LITTLE_ENDIAN);
        for(int n=0;n<65536;n++) index.putInt(n);
        Files.write(dir.resolve("unicode_indexer.bin"),index.array());
        return dir;
    }
    private static void tags() throws Exception {
        for(String word:new String[]{"book","pen","ruler","ball","car","sun","apple",
            "bag","rubber","school bag","desk","chair","pencil case","paper"}) {
            verify(LumoOfflineSpeechEngine.prepareEnglishWord(word).equals("<en>"+word+".</en>"),word);
        }
        verify(LumoOfflineSpeechEngine.prepareEnglishWord("verb").equals("<en>verb.</en>"),
            "German Verb spelling substitution never enters English");
        for(String bad:new String[]{null,"","Book","<de>book</de>","book\npen","book  pen",
            "book!","x".repeat(25),"äpfel"," book","book "})
            refuse(()->LumoOfflineSpeechEngine.prepareEnglishWord(bad),"Reject unsafe word");
    }
    private static void exactJoin() throws Exception {
        byte[] en=wave(8820,.15f),de=wave(13230,.30f);
        byte[] enOriginal=en.clone(),deOriginal=de.clone();
        byte[] joined=LumoOfflineSpeechEngine.joinLessonWaves(en,de);
        int enBytes=en.length-44,deBytes=de.length-44,gapBytes=22050;
        verify(joined.length==44+enBytes+gapBytes+deBytes,"Full bounded PCM sequence");
        verify(view(joined).getInt(4)==joined.length-8,"RIFF size");
        verify(view(joined).getInt(40)==joined.length-44,"Data size");
        verify(view(joined).getInt(24)==44100&&view(joined).getShort(22)==1&&
            view(joined).getShort(34)==16,"Original mono PCM16 rate");
        verify(Arrays.equals(Arrays.copyOfRange(joined,44,44+enBytes),
            Arrays.copyOfRange(en,44,en.length)),"EN samples unchanged");
        verify(Arrays.equals(Arrays.copyOfRange(joined,44+enBytes+gapBytes,joined.length),
            Arrays.copyOfRange(de,44,de.length)),"DE samples unchanged");
        boolean silence=true;
        for(int i=44+enBytes;i<44+enBytes+gapBytes;i++) silence &= joined[i]==0;
        verify(silence,"Exactly 250 milliseconds of inter-utterance silence");
        verify(Arrays.equals(en,enOriginal)&&Arrays.equals(de,deOriginal),"Input WAVs unchanged");
    }
    private static void malformed() throws Exception {
        byte[] good=wave(4410,.1f);
        for(int offset:new int[]{0,4,8,12,16,20,22,24,28,32,34,36,40}) {
            byte[] broken=good.clone();broken[offset]^=1;
            refuse(()->LumoOfflineSpeechEngine.joinLessonWaves(broken,good),"Bad EN header "+offset);
            refuse(()->LumoOfflineSpeechEngine.joinLessonWaves(good,broken),"Bad DE header "+offset);
        }
        for(byte[] broken:new byte[][]{null,new byte[0],new byte[44],
            Arrays.copyOf(good,good.length-1),Arrays.copyOf(good,good.length+2),
            new byte[44+44100*30*2+2]})
            refuse(()->LumoOfflineSpeechEngine.joinLessonWaves(broken,good),"Malformed length");
    }
    private static void totalBound() throws Exception {
        byte[] en=wave(4410,.1f);
        int maximumDeFrames=30*44100-11025-4410;
        byte[] de=wave(maximumDeFrames,.2f);
        byte[] joined=LumoOfflineSpeechEngine.joinLessonWaves(en,de);
        verify(joined.length==44+30*44100*2,"Exactly 30s accepted");
        verify(joined.length<3*1024*1024,"Existing envelope 3MiB bound retained");
        byte[] over=wave(maximumDeFrames+1,.2f);
        refuse(()->LumoOfflineSpeechEngine.joinLessonWaves(en,over),"One combined frame over 30s rejected");
        byte[] thirty=wave(30*44100,.2f);
        refuse(()->LumoOfflineSpeechEngine.joinLessonWaves(thirty,thirty),"Two individually valid long waves rejected");
    }
    private static void sequence(Path dir) throws Exception {
        OrtSession.reset();
        try(LumoOfflineSpeechEngine engine=new LumoOfflineSpeechEngine(fixture(dir).toFile())) {
            byte[] wav=engine.synthesizeEnglishLesson("book","Tippe auf den Gegenstand.","explain",()->false);
            verify(OrtSession.prepared.equals(List.of("<en>book.</en>","<de>Tippe auf den Gegenstand.</de>")),
                "Actual production inference entry receives EN then unchanged DE");
            verify(OrtSession.dpIdentities.equals(List.of(2f,2f))&&
                OrtSession.ttlIdentities.equals(List.of(2f,2f)),"Both inferences retain speaker index1");
            verify(view(wav).getInt(40)==wav.length-44,"Sequence returns one complete WAV");
            verify(OrtSession.completed==2,"Both inference calls completed");
            engine.synthesizeEnglishLesson("book","Tippe auf den Gegenstand.","explain",()->false);
            verify(OrtSession.completed==4,"No text-only or cross-language audio-result cache");
            engine.synthesize("book","explain",()->false);
            verify(OrtSession.prepared.get(4).equals("<de>book.</de>"),"Old German public entry remains DE");
        }
        verify(OnnxTensor.live==0,"Production tensor owners close through both segments");
    }
    private static void cancellation(Path dir,String mode) throws Exception {
        OrtSession.reset();
        try(LumoOfflineSpeechEngine engine=new LumoOfflineSpeechEngine(fixture(dir).toFile())) {
            AtomicInteger visits=new AtomicInteger();
            if(mode.equals("before")) {
                cancel(()->engine.synthesizeEnglishLesson("book","Ein Buch.","explain",()->true),"Before EN");
                verify(OrtSession.prepared.isEmpty(),"No inference after initial cancellation");
            } else if(mode.equals("between")) {
                cancel(()->engine.synthesizeEnglishLesson("book","Ein Buch.","explain",
                    ()->OrtSession.completed==1&&visits.incrementAndGet()>=2),"Between EN and DE");
                verify(OrtSession.prepared.equals(List.of("<en>book.</en>")),"DE never starts after cancellation");
            } else if(mode.equals("before-join")) {
                cancel(()->engine.synthesizeEnglishLesson("book","Ein Buch.","explain",
                    ()->OrtSession.completed==2&&visits.incrementAndGet()>=2),"After DE before join");
                verify(OrtSession.completed==2,"Both finished, cancelled combined result not returned");
            } else if(mode.equals("after-join")) {
                cancel(()->engine.synthesizeEnglishLesson("book","Ein Buch.","explain",
                    ()->OrtSession.completed==2&&visits.incrementAndGet()>=3),"Cancellation before return");
                verify(visits.get()==3,"Final cancellation barrier executed");
            } else if(mode.equals("thread")) {
                Thread.currentThread().interrupt();
                try { cancel(()->engine.synthesizeEnglishLesson("book","Ein Buch.","explain",()->false),"Interrupted worker"); }
                finally { Thread.interrupted(); }
                verify(OrtSession.prepared.isEmpty(),"Interrupted worker cannot start EN");
            } else throw new AssertionError(mode);
        }
        verify(OnnxTensor.live==0,"Cancellation closes every production tensor owner");
    }
    public static void main(String[] args) throws Exception {
        if(args.length!=2) throw new IllegalArgumentException("scenario temporary-model-fixture");
        switch(args[0]) {
            case "tags":tags();break;
            case "join":exactJoin();break;
            case "malformed":malformed();break;
            case "bounds":totalBound();break;
            case "sequence":sequence(Path.of(args[1]));break;
            default:cancellation(Path.of(args[1]),args[0]);
        }
        System.out.println("ENGLISH_LESSON_JAVA_PASS scenario="+args[0]+" checks="+checks+
            " boundary=synthetic_ONNX_no_weights_no_Android_no_audio_claim");
    }
}
'''


class EnglishLessonSpeechJavaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="lumo-english-speech-java-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        cls.java = shutil.which("java")
        if not cls.java:
            raise RuntimeError("Java compiler/runtime required; no dependency download is performed")
        javac = shutil.which("javac")
        compiler = [javac] if javac else [cls.java, "-m", "jdk.compiler/com.sun.tools.javac.Main"]
        cls.classes = cls.work / "classes"
        cls.classes.mkdir()
        files = []
        for relative, source in {**STUBS, "EnglishLessonSpeechContract.java": CONTRACT}.items():
            path = cls.work / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source)
            files.append(str(path))
        result = subprocess.run(
            [*compiler, "-source", "17", "-target", "17", "-d", str(cls.classes), str(ENGINE),
             str(GERMAN_PROBE), *files], capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        if result.stdout or result.stderr:
            print(result.stdout + result.stderr)
        print("Compiled complete production Java source bytes SHA256=" +
              hashlib.sha256(ENGINE.read_bytes()).hexdigest())

    def scenario(self, name):
        result = subprocess.run(
            [self.java, "-cp", str(self.classes), "EnglishLessonSpeechContract", name,
             str(self.work / ("fixture-" + name))],
            capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("ENGLISH_LESSON_JAVA_PASS scenario=" + name, result.stdout)
        print(result.stdout.strip())

    def test_existing_german_engine_contract(self):
        result = subprocess.run(
            [self.java, "-cp", str(self.classes), "LumoOfflineSpeechEngineProbe", "--unit-only"],
            capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS local voice Java guards: 11", result.stdout)
        print(result.stdout.strip())

    def test_english_word_tags_and_input_bound(self): self.scenario("tags")
    def test_join_preserves_pcm_and_exact_gap(self): self.scenario("join")
    def test_malformed_wave_formats_refused(self): self.scenario("malformed")
    def test_total_envelope_duration_bound(self): self.scenario("bounds")
    def test_language_order_identity_and_no_result_cache(self): self.scenario("sequence")
    def test_cancel_before_first_inference(self): self.scenario("before")
    def test_cancel_between_inferences(self): self.scenario("between")
    def test_cancel_before_join(self): self.scenario("before-join")
    def test_cancel_after_join_before_return(self): self.scenario("after-join")
    def test_interrupted_worker_never_starts_inference(self): self.scenario("thread")


if __name__ == "__main__":
    unittest.main()
