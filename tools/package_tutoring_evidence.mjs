// Preserve genuine Flutter frames and exact source evidence. This is not an
// Android build, hardware recording, speech sample or frame-rate measurement.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  copyFileSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = new Map();
for (let index = 2; index < process.argv.length; index += 2) {
  args.set(process.argv[index], process.argv[index + 1]);
}
const required = (key) => {
  const value = args.get(`--${key}`);
  if (!value) throw new Error(`Missing --${key}`);
  return value;
};
const source = required("source-commit");
const before = resolve(required("before"));
const after = resolve(required("after"));
const reference = resolve(required("reference"));
const output = resolve(required("output"));
const git = (...parameters) =>
  execFileSync("git", ["-C", root, ...parameters], {
    maxBuffer: 16 * 1024 * 1024,
  });
if (!/^[a-f0-9]{40}$/.test(source)) throw new Error("Full real source SHA required");
git("cat-file", "-e", `${source}^{commit}`);
mkdirSync(output, { recursive: true });
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sourcePaths = [
  "lib/core/progress_repository.dart",
  "lib/core/progress_recommendation_service.dart",
  "lib/domain/tutoring/guided_lesson_catalog.dart",
  "lib/features/sections/section_content.dart",
  "lib/features/tutoring/tutoring_flow_card.dart",
  "test/progress_repository_corruption_test.dart",
  "test/progress_recommendation_service_test.dart",
  "test/tutoring/tutoring_flow_connection_test.dart",
  ".github/workflows/lumo-change-review.yml",
  "scripts/tests/test_change_review_evidence.py",
];
const sourceFiles = sourcePaths.map((path) => {
  const bytes = readFileSync(join(root, path));
  if (!bytes.equals(git("show", `${source}:${path}`))) {
    throw new Error(`Uncommitted product or test input: ${path}`);
  }
  return { path, bytes: bytes.length, sha256: hash(bytes), matchesCommit: true };
});
const baseline = "9b8b7c86b4b4137c625d2e4fa727a9669a4962f5";
const protectedFiles = [
  "lib/core/lumo_voice.dart",
  "lib/core/lumo_sulafat_client.dart",
  "lib/core/app_settings.dart",
  "config/godot-source.json",
  "pubspec.yaml",
].map((path) => {
  const bytes = git("show", `${source}:${path}`);
  if (!bytes.equals(git("show", `${baseline}:${path}`))) {
    throw new Error(`Protected existing input changed: ${path}`);
  }
  return { path, sha256: hash(bytes), unchangedFromBaseline: true };
});
const files = [];
const save = (path, name, kind) => {
  const bytes = readFileSync(path);
  const target = join(output, name);
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(path, target);
  const png = name.endsWith(".png");
  if (png && bytes.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") {
    throw new Error(`Invalid captured PNG: ${path}`);
  }
  files.push({
    file: name,
    kind,
    bytes: bytes.length,
    sha256: hash(bytes),
    ...(png
      ? { pngPixels: [bytes.readUInt32BE(16), bytes.readUInt32BE(20)] }
      : {}),
  });
};
for (const [directory, kind] of [
  [before, "before"],
  [after, "after"],
]) {
  for (const name of readdirSync(directory).sort()) {
    if (name.endsWith(".png")) {
      save(join(directory, name), `${kind}/${name}`, `actual_${kind}_flutter_frame`);
    }
  }
}
if (files.filter((file) => file.kind === "actual_before_flutter_frame").length !== 2 ||
    files.filter((file) => file.kind === "actual_after_flutter_frame").length !== 6) {
  throw new Error("Expected two genuine baseline and six actual final UI frames");
}
save(reference, "original-reference/51024.jpg", "user_original_design_reference");
for (const [name, fold] of [["phone-360x800", false], ["fold-target", true]]) {
  const target = join(output, "comparisons",
    `Lumo-Nachhilfe-${name}-Vorher-Originalreferenz-Nachher.png`);
  mkdirSync(dirname(target), { recursive: true });
  execFileSync("python3", ["-c",
    "from pathlib import Path; import sys; " +
    "from tools.package_learning_adventure_evidence import comparison; " +
    "comparison(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3])," +
    "Path(sys.argv[4]),'Lumos Lernweg | '+sys.argv[5],sys.argv[6]=='true'," +
    "footer_lines=('Vollständige echte UI-Frames; nur proportional skaliert.'," +
    "'Vorher: echte bisherige Nachhilfe. Referenz: originaler Plus-bis-10-Designstandard.'))",
    join(before, `${name}-actual-tutoring-card.png`),
    join(after, `${name}-actual-tutoring-card.png`),
    reference, target, fold ? "Fold-Zielviewport" : "Smartphone",
    String(fold),
  ], { cwd: root });
}
let fullSuite = { status: "not_added", claim: "No full-suite success inferred" };
const ciResult = args.get("--ci-result");
const ciLog = args.get("--ci-log");
if (Boolean(ciResult) !== Boolean(ciLog)) {
  throw new Error("--ci-result and --ci-log must be supplied together");
}
if (ciResult) {
  const result = JSON.parse(readFileSync(resolve(ciResult), "utf8"));
  const bytes = readFileSync(resolve(ciLog));
  const log = bytes.toString("utf8");
  const count = /\+(\d+)\s+~(\d+): All tests passed!/.exec(log);
  if (result.headSha !== source || result.status !== "completed" ||
      result.conclusion !== "success" || !count ||
      !result.jobs?.some((job) => job.name ===
        "Flutter analysis and complete test suite" && job.conclusion === "success")) {
    throw new Error("Actual successful full CI of this exact source is required");
  }
  fullSuite = {
    status: "completed",
    conclusion: "success",
    sourceCommit: result.headSha,
    runUrl: result.url,
    passed: Number(count[1]),
    skipped: Number(count[2]),
    failed: 0,
    analysisErrors: (log.match(/\serror • /g) || []).length,
    analysisWarnings: (log.match(/\swarning • /g) || []).length,
    existingAnalysisInfos: (log.match(/\sinfo • /g) || []).length,
    actualJobLogSha256: hash(bytes),
  };
}
const evidence = {
  sourceCommit: source,
  baselineCommit: baseline,
  runtime: "Flutter 3.44.9 / Linux widget test renderer",
  capturePixelRatio: 1,
  capturedFictionalAnswers: { correct: 1, incorrect: 4, total: 5 },
  afterStates: ["actual tutoring card", "actual reason after tap", "actual course after tap"],
  foldLogicalViewport: [2176 / 2.25, 1812 / 2.25],
  physicalAndroidRecording: false,
  physicalSamsungRecording: false,
  newApkBuilt: false,
  audibleSpeechTest: false,
  fpsMeasured: false,
  fullSuite,
  sourceFiles,
  protectedFiles,
  files,
  limitations: [
    "Pictures use the real app widgets but are not Android screenshots.",
    "New tutoring changes are not present in the separately tested APK 1929.",
    "No external pedagogical, commercial voice-license or Google Play approval.",
    "Comparison original is a design reference, not an identical tutoring task.",
  ],
};
writeFileSync(join(output, "EVIDENCE.json"),
  JSON.stringify(evidence, null, 2) + "\n");
console.log(JSON.stringify({
  sourceCommit: source, originalUiFrames: files.filter((file) =>
    file.kind.endsWith("_flutter_frame")).length,
  comparisons: 2, fullSuite,
}, null, 2));
