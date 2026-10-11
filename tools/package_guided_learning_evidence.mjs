// Reproducible provenance for real Flutter frames. No generated proof images,
// audio-provider calls, screenshots from a nonexistent APK or hardware claims.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  copyFileSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs";
import { resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const options = new Map();
for (let index = 2; index < process.argv.length; index += 2) {
  options.set(process.argv[index], process.argv[index + 1]);
}
const required = (name) => {
  const value = options.get(`--${name}`);
  if (!value) throw new Error(`Missing --${name}`);
  return value;
};
const source = required("source-commit");
const captures = resolve(required("capture-dir"));
const plus = resolve(required("plus-dir"));
const beforeDraft = resolve(required("draft-dir"));
const reference = resolve(required("reference"));
const video = resolve(required("video"));
const output = resolve(required("output"));
const git = (...args) =>
  execFileSync("git", ["-C", root, ...args], { maxBuffer: 16 * 1024 * 1024 });
if (!/^[a-f0-9]{40}$/.test(source)) throw new Error("Actual full source SHA required");
git("cat-file", "-e", `${source}^{commit}`);
mkdirSync(output, { recursive: true });
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sourceFiles = [
  "lib/core/learning_profile_engine.dart",
  "lib/domain/tutoring/guided_lesson_catalog.dart",
  "lib/features/learning_modules/learning_module_progress.dart",
  "lib/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart",
  "lib/features/settings/discovery_settings_card.dart",
  "lib/features/settings/settings_content.dart",
  "lib/features/teacher_mode/lumo_akademie_screen.dart",
  "lib/features/tutoring/guided_learning_hub.dart",
  "lib/features/tutoring/guided_lesson_screen.dart",
  "lib/features/tutoring/guided_math_illustration.dart",
  "lib/widgets/design/lumo_learning_module_frame.dart",
  "scripts/audit_content.dart",
  "test/design/guided_learning_runtime_capture_test.dart",
  "test/design/lumo_companion_runtime_capture_test.dart",
  "test/discovery_progress_test.dart",
  "test/tutoring/guided_lesson_catalog_test.dart",
  "test/tutoring/guided_lesson_runtime_test.dart",
  "test/tutoring/guided_quantity_animation_test.dart",
].map((path) => {
  const bytes = readFileSync(join(root, path));
  const committed = git("show", `${source}:${path}`);
  if (!bytes.equals(committed)) throw new Error(`Uncommitted source: ${path}`);
  return { path, bytes: bytes.length, sha256: hash(bytes), matchesCommit: true };
});
const ciResultPath = options.get("--ci-result");
const ciLogPath = options.get("--ci-log");
if (Boolean(ciResultPath) !== Boolean(ciLogPath)) {
  throw new Error("--ci-result and --ci-log must be provided together");
}
let fullSuite = "Read the exact GitHub CI result separately; not inferred from these targeted tests";
if (ciResultPath) {
  const result = JSON.parse(readFileSync(resolve(ciResultPath), "utf8"));
  const logBytes = readFileSync(resolve(ciLogPath));
  const log = logBytes.toString("utf8");
  const counts = /\+(\d+)\s+~(\d+): All tests passed!/.exec(log);
  if (result.headSha !== source || result.status !== "completed" ||
      result.conclusion !== "success" || !counts) {
    throw new Error("CI evidence must be a completed successful run of the exact source SHA");
  }
  const job = result.jobs?.find((entry) =>
    entry.name === "Flutter analysis and complete test suite");
  if (job?.conclusion !== "success") {
    throw new Error("The complete Flutter job itself must have passed");
  }
  fullSuite = {
    runUrl: result.url,
    jobUrl: job.url,
    sourceCommit: result.headSha,
    status: result.status,
    conclusion: result.conclusion,
    passed: Number(counts[1]),
    skipped: Number(counts[2]),
    failed: 0,
    analysisErrors: (log.match(/\serror • /g) || []).length,
    analysisWarnings: (log.match(/\swarning • /g) || []).length,
    existingAnalysisInfos: (log.match(/\sinfo • /g) || []).length,
    originalLogSha256: hash(logBytes),
    note: "Counts read from the actual completed CI log, not targeted-test totals",
  };
}
const protectedFiles = [
  "lib/core/lumo_voice.dart",
  "lib/core/lumo_sulafat_client.dart",
  "lib/core/app_settings.dart",
  "config/godot-source.json",
  "pubspec.yaml",
].map((path) => {
  const bytes = git("show", `${source}:${path}`);
  const baseline = git("show", `1b1a164c651bf40d46e30e28185c5886a1a142a4:${path}`);
  if (!bytes.equals(baseline)) throw new Error(`Protected input changed: ${path}`);
  return { path, sha256: hash(bytes), unchangedFromStorageMilestone: true };
});
const files = [];
const save = (path, name, kind) => {
  const bytes = readFileSync(path);
  const destination = join(output, name);
  mkdirSync(dirname(destination), { recursive: true });
  copyFileSync(path, destination);
  const png = name.endsWith(".png");
  if (png && bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") {
    throw new Error(`Not a real PNG: ${path}`);
  }
  files.push({
    file: name,
    kind,
    bytes: bytes.length,
    sha256: hash(bytes),
    ...(png ? { pngPixels: [bytes.readUInt32BE(16), bytes.readUInt32BE(20)] } : {}),
  });
};
for (const directory of [
  [captures, "after", "actual_guided_flutter_frame"],
  [plus, "plus-after", "actual_plus_flutter_frame"],
  [beforeDraft, "before-draft", "earlier_uncommitted_runtime_draft_not_apk_1929"],
]) {
  for (const name of readdirSync(directory[0]).sort()) {
    if (name.endsWith(".png")) save(join(directory[0], name), `${directory[1]}/${name}`, directory[2]);
  }
}
const beforePlus = join(
  root,
  "docs/education/2026-10-11-learning-companion/images/phone-360x800-actual-help.png",
);
const oldBlob = git("show",
  "87466a2799b34faed0d26f50758a204b2e557746:docs/education/2026-10-11-learning-companion/images/phone-360x800-actual-help.png");
if (!readFileSync(beforePlus).equals(oldBlob)) throw new Error("Baseline PNG differs from actual Git blob");
save(beforePlus, "before/phone-actual-plus-help.png", "exact_prior_committed_runtime_frame");
save(reference, "original-reference/51024.jpg", "user_original_design_reference");
save(video, "Lumo-Unterricht-echte-Zehneranimation-Fold.mp4", "video_of_actual_flutter_animation_without_audio");
const probe = JSON.parse(execFileSync("ffprobe", [
  "-v", "error", "-show_entries",
  "format=duration:stream=codec_type,width,height,r_frame_rate,nb_frames",
  "-of", "json", video,
]).toString());
if (probe.streams.some((stream) => stream.codec_type === "audio")) {
  throw new Error("This proof must not falsely carry unrelated voice audio");
}
const frameNames = readdirSync(join(captures, "bridge-frames"))
  .filter((name) => /^frame-\d{4}\.png$/.test(name)).sort();
if (frameNames.length !== 64) throw new Error("Expected exactly 64 actual animation frames");
const animationFrameHashes = frameNames.map((name) => ({
  file: name, sha256: hash(readFileSync(join(captures, "bridge-frames", name))),
}));
mkdirSync(join(output, "comparisons"), { recursive: true });
const compare = (before, after, name, title, fold, line1, line2) => {
  // Reuse the established real-frame image compositor; never repaint the app.
  const code = [
    "from pathlib import Path",
    "import sys",
    "from tools.package_learning_adventure_evidence import comparison",
    "comparison(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]),Path(sys.argv[4]),sys.argv[5],sys.argv[6]=='true',footer_lines=(sys.argv[7],sys.argv[8]))",
  ].join("\n");
  const destination = join(output, "comparisons", name);
  execFileSync("python3", ["-c", code, before, after, reference, destination,
    title, String(fold), line1, line2], { cwd: root });
  const bytes = readFileSync(destination);
  files.push({ file: `comparisons/${name}`, kind: "unretouched_runtime_comparison",
    bytes: bytes.length, sha256: hash(bytes),
    pngPixels: [bytes.readUInt32BE(16), bytes.readUInt32BE(20)] });
};
compare(beforePlus, join(plus, "phone-360x800-actual-help.png"),
  "Lumo-Plus-Hilfe-Vorher-Originalreferenz-Nachher.png", "Plus-Hilfe | Smartphone", false,
  "Gesicherter früherer Hilfestand und echter neuer Hilfestand; Aufgaben nicht identisch.",
  "Nur proportionale Skalierung und Randbeschriftung; keine retuschierte Benutzeroberfläche.");
compare(join(beforeDraft, "fold-bridge-first-draft.png"),
  join(captures, "fold-target-actual-bridge_ten-example.png"),
  "Lumo-Unterricht-Vorher-Originalreferenz-Nachher-Fold.png", "Geführter Unterricht | Fold-Zielviewport", true,
  "Vorher: erster lokaler Unterrichtsentwurf, nicht die APK 1929. Nachher: echter neuer Unterricht.",
  "Originalreferenz 51024.jpg ist ein Gestaltungsziel, kein funktionsgleiches Unterrichtsbild.");
const manifest = {
  sourceCommit: source,
  sourceUrl: `https://github.com/Ullmann27/lumo-lernen/commit/${source}`,
  branch: "computer/lumo-learning-companion-discovery-2026-10-11",
  pullRequest: "https://github.com/Ullmann27/lumo-lernen/pull/265",
  previousStorageCommit: "1b1a164c651bf40d46e30e28185c5886a1a142a4",
  previousCompanionCommit: "87466a2799b34faed0d26f50758a204b2e557746",
  runtime: "Flutter 3.44.9 Linux widget-test renderer; original PNG assets, Nunito and actual taps",
  physicalAndroidTest: false,
  physicalSamsungTest: false,
  audibleVoiceAcceptance: false,
  lipsyncImplemented: false,
  deviceFpsMeasured: false,
  apkRebuilt: false,
  screenshots: {
    pixelRatio: 1,
    phoneViewport: [360, 800],
    foldPhysicalTargetViewport: [2176, 1812],
    foldDensity: 2.25,
    foldLogicalViewport: [2176 / 2.25, 1812 / 2.25],
  },
  fixtures: { fictitiousProfilesOnly: true, speechEnabled: false, paidApiCalls: 0 },
  proofTests: {
    finalGuidedDomainStorageInteractionTests: 66,
    realInteractionCases: 14,
    quantityAnimationCases: 34,
    catalogTests: 4,
    storageTests: 14,
    deterministicArithmeticCasesWithinOneTest: 151,
    finalGuidedCaptureCases: 4,
    plusHelpCaptureCases: 2,
    generatedAndGuidedAuditSamples: 40969,
    guidedQuestionStepsInAudit: 9,
    fullSuite,
  },
  sourceFiles,
  protectedFiles,
  files,
  video: {
    ...probe,
    encodedFrameRateNotDeviceFps: 20,
    actualCapturedFrameCount: 64,
    animationFrameHashes,
    note: "Actual authored TweenAnimationBuilder, 50ms test-clock advances; no synthetic motion or voice",
  },
  limitations: [
    "Two actual mathematics introductions, not all subjects or four-grade curriculum completion",
    "First draft screenshots have no committed source SHA and are explicitly not old APK frames",
    "Phone long text remains scrollable; actual large targets and fixed Continue are exercised",
    "Local adult confirmation is not verified adult identity",
    "New guided/discovery UI is not in unchanged APK 1929",
    "No physical hardware, human hearing, new APK, 60 FPS, full external pedagogy or Play approval",
  ],
};
writeFileSync(join(output, "EVIDENCE.json"), JSON.stringify(manifest, null, 2) + "\n");
console.log(JSON.stringify({
  sourceCommit: source, copiedAndHashedFiles: files.length,
  verifiedSourceFiles: sourceFiles.length, unchangedProtectedInputs: protectedFiles.length,
  actualAnimationFrames: animationFrameHashes.length, output,
}, null, 2));
