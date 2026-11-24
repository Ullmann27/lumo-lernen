from pathlib import Path
import ast
import hashlib
import json
import subprocess

BASE_SHA = "6b3047b7979dfb86d837e74a21b0fd890e4f9e66"
BASE = Path("/workspace/scratch/909ddb52fe7b/lumo-upstream057-review")
PATCH = Path("/workspace/scratch/909ddb52fe7b/village-return-repair-6b")
OUT = Path(__file__).parent
PROBE = ".github/probes/lumo_village_android_probe.py"
TEST = "tools/android_qa/tests/test_village_android_evidence.py"
EXPECTED = {
    PROBE: "3e601644198f0b8c62fdaebcf783e3f631974bb1",
    TEST: "d21f941b2f5cff410f8e4cd7ae23fbbbf894743a",
}
def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def original(path):
    return subprocess.check_output(["git", "-C", str(BASE), "show", BASE_SHA+":"+path])
def methods(data):
    root=ast.parse(data.decode())
    return {f"{c.name}.{f.name}": ast.dump(f, include_attributes=False)
            for c in root.body if isinstance(c, ast.ClassDef)
            for f in c.body if isinstance(f, ast.FunctionDef)}
sources = []
for path in [PROBE, TEST]:
    old, new = original(path), (PATCH/path).read_bytes()
    assert blob(new) == EXPECTED[path], path
    sources.append({"path":path, "original_blob":blob(old), "reviewed_blob":blob(new),
                    "reviewed_sha256":hashlib.sha256(new).hexdigest()})
before, after = methods(original(PROBE)), methods((PATCH/PROBE).read_bytes())
changed = [k for k in before if before[k] != after.get(k)]
added = sorted(set(after)-set(before))
assert changed == ["VillageProbe.remaining", "VillageProbe.visible_return"]
assert added == ["VillageProbe.observe_flutter_return"]
assert not set(before)-set(after)
old_test, new_test = methods(original(TEST)), methods((PATCH/TEST).read_bytes())
old_tests = {k:v for k,v in old_test.items() if ".test_" in k}
new_tests = {k:v for k,v in new_test.items() if ".test_" in k}
assert len(old_tests) == 34 and len(new_tests) == 43
assert all(new_tests[k] == v for k,v in old_tests.items())
suffix_original = original(PROBE).decode().split("    def run(self):", 1)[1]
suffix_patch = (PATCH/PROBE).read_text().split("    def run(self):", 1)[1]
assert suffix_original == suffix_patch
unchanged = [
    "tools/android_qa/village_android_evidence.py",
    ".github/probes/flutter_surface_readiness.py",
    ".github/probes/creative_android_probe.py",
    ".github/probes/lumo_connect_four_android_probe.py",
    "scripts/probes/pr207_android_ui_probe.py",
]
helpers = []
for path in unchanged:
    before_bytes, after_bytes = original(path), (PATCH/path).read_bytes()
    assert before_bytes == after_bytes
    helpers.append({"path":path, "unchanged_blob":blob(before_bytes)})
result = {
    "schema":1, "kind":"Read-only source delta inspection; not a test/build/device run",
    "base_commit":BASE_SHA,
    "reviewed_checkpoint":"a7e06055f70929e918d48a1397bf656c1880adb4",
    "sources":sources, "changed_methods":changed, "new_methods":added,
    "removed_methods":[], "run_and_main_suffix_byte_identical":True,
    "old_test_methods":len(old_tests), "total_test_methods":len(new_tests),
    "old_tests_ast_identical":True, "added_tests":sorted(set(new_tests)-set(old_tests)),
    "unchanged_helpers":helpers,
}
(OUT/"source-delta-check.json").write_text(json.dumps(result, indent=2)+"\n")
print(json.dumps(result, indent=2))
