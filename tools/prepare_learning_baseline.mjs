// Reconstruct genuine pre-change widget sources from the recorded product
// commit for a repeatable runtime comparison. Generated tests are temporary;
// they are never imported by lib/, an APK, a user profile or the app router.
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const base = "bef1403ed5d0243f8c6daca2717e998081cab15e";
const root = resolve(import.meta.dirname, "..");
const cache = resolve(root, ".dart_tool/lumo_learning_baseline_1928");
mkdirSync(cache, { recursive: true });
const modules = [
  ["plus_bis_10", "PlusBis10Screen", "plus-bis-10-reference"],
  ["minus_bis_10", "MinusBis10Screen", "minus-bis-10"],
  ["zahlen_bis_10", "ZahlenBis10Screen", "zahlen-bis-10"],
  ["formen", "FormenScreen", "formen"],
  ["uhr_lernen", "UhrLernenScreen", "uhr"],
];
const manifest = { commit: base, sourceKind: "original Git widget source", modules: [] };
for (const [folder, type, label] of modules) {
  const sourcePath = `lib/features/learning_modules/${folder}/${folder}_screen.dart`;
  const original = execFileSync("git", ["-C", root, "show", `${base}:${sourcePath}`],
    { encoding: "utf8" });
  // These modules share the original progress/voice/phrase implementations,
  // which were checked unchanged in the current checkout.
  const importsResolved = original
    .replaceAll("import '../../../", "import 'package:lumo_lernen/")
    .replaceAll("import '../", "import 'package:lumo_lernen/features/learning_modules/");
  writeFileSync(resolve(cache, `${folder}.dart`), importsResolved);
  manifest.modules.push({
    module: label, type, sourcePath,
    originalSha256: createHash("sha256").update(original).digest("hex"),
    mechanicalChanges: "relative import URI resolution only",
  });
}
let test = readFileSync(resolve(root, "test/design/learning_adventure_capture_test.dart"), "utf8");
test = test.replace(
  /^import 'package:lumo_lernen\/features\/learning_modules\/[^']+';\n/gm, "");
test = test.replace("const _boundary", modules.map(([folder]) =>
  `import '../../.dart_tool/lumo_learning_baseline_1928/${folder}.dart';`).join("\n")
  + "\n\nconst _boundary");
const start = test.indexOf("final _modules =");
const end = test.indexOf("const _sizes =", start);
if (start < 0 || end < start) throw Error("Capture map boundaries not found");
test = test.slice(0, start)
  + "final _modules = <String, Widget Function(LumoAppState)>{\n"
  + modules.map(([, type, label]) =>
    `  '${label}': (app) => ${type}(appState: app),`).join("\n")
  + "\n};\n"
  + test.slice(end);
const generated = resolve(root, "test/design/learning_adventure_baseline_1928_test.dart");
writeFileSync(generated, `// Generated original-runtime baseline from ${base}.\n` + test);
writeFileSync(resolve(cache, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
console.log(JSON.stringify({ base, generated, manifest }, null, 2));
