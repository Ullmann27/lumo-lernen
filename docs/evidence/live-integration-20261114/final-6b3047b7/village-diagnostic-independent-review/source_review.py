from pathlib import Path
import ast
import copy
import hashlib
import json
import subprocess

ROOT = Path("/workspace/scratch/909ddb52fe7b/lumo-village-return-diagnostic")
OUT = Path(__file__).parent
BASE = "6b3047b7979dfb86d837e74a21b0fd890e4f9e66"
FILES = [
".github/workflows/lumo-village-return-6b-diagnostic.yml",
".github/probes/lumo_6b_roundtrip_diagnostic.py",
"scripts/verify_unchanged_6b_village_diagnostic.py",
"scripts/run_unchanged_6b_village_diagnostic.sh",
"scripts/tests/test_6b_roundtrip_diagnostic.py",
"scripts/tests/test_verify_unchanged_6b_village_diagnostic.py",
".github/probes/lumo_village_android_probe.py",
"tools/android_qa/tests/test_village_android_evidence.py",
]
def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def info(path):
    data=path.read_bytes()
    return {"bytes":len(data), "sha256":hashlib.sha256(data).hexdigest(), "git_blob":blob(data)}
def source(path):
    return subprocess.check_output(["git","-C",str(ROOT),"show",BASE+":"+path]).decode()
def function(text, name, owner=None):
    tree=ast.parse(text)
    nodes=tree.body if owner is None else next(n for n in tree.body if isinstance(n,ast.ClassDef) and n.name==owner).body
    return copy.deepcopy(next(n for n in nodes if isinstance(n,ast.FunctionDef) and n.name==name))
def dump(node):
    return ast.dump(node, include_attributes=False)
def expr(text):
    return ast.parse(text, mode="eval").body
QA = dump(expr("self.args.expected_qa_source"))
APK = dump(expr("self.args.expected_source"))
SOURCE = dump(expr("source"))
IDENTITY = dump(expr("identity['flutter_source_commit']"))
adapter=(ROOT/FILES[1]).read_text()

class NormalizeIdentity(ast.NodeTransformer):
    def __init__(self, kind):
        self.kind=kind
        self.counts={"qa_identity":0,"apk_binding_keyword":0,"apk_identity":0,"scope":0,"print_label":0}
    def visit_Compare(self,node):
        node=self.generic_visit(node)
        if len(node.comparators)==1 and dump(node.left)==SOURCE and dump(node.comparators[0])==QA:
            node.comparators[0]=expr("self.args.expected_source")
            self.counts["qa_identity"]+=1
        if self.kind=="village" and len(node.comparators)==1 and dump(node.left)==IDENTITY and dump(node.comparators[0])==APK:
            node.comparators[0]=expr("source")
            self.counts["apk_identity"]+=1
        return node
    def visit_keyword(self,node):
        node=self.generic_visit(node)
        if node.arg=="source" and dump(node.value)==APK:
            node.value=expr("source")
            self.counts["apk_binding_keyword"]+=1
        return node
    def visit_BoolOp(self,node):
        node=self.generic_visit(node)
        if self.kind=="c4" and isinstance(node.op,ast.And):
            expected=dump(expr("identity['flutter_source_commit'] == self.args.expected_source"))
            values=[v for v in node.values if dump(v)!=expected]
            if len(values)!=len(node.values):
                self.counts["apk_identity"]+=len(node.values)-len(values)
                node.values=values
        return node
    def visit_Constant(self,node):
        old_scope={
          "village":("Diagnostic actual 6b APK Village roundtrip with separately bound QA; no seven-job acceptance","Actual API35 direct Flutter Village roundtrip; no physical ARM64/FPS claim"),
          "c4":("Diagnostic actual 6b APK C4 test with separately bound QA; no seven-job acceptance","Actual API35 C4 candidate test; no release/FPS/API37 claim"),
        }[self.kind]
        if node.value==old_scope[0]:
            node.value=old_scope[1];self.counts["scope"]+=1
        labels={"village":("[DiagnosticVillageAndroid]","[VillageAndroid]"),"c4":("[DiagnosticConnectFourAndroid]","[ConnectFourAndroid]")}[self.kind]
        if node.value==labels[0]:
            node.value=labels[1];self.counts["print_label"]+=1
        return node

parity=[]
for kind,path,owner in [
 ("village",".github/probes/lumo_village_android_probe.py","VillageProbe"),
 ("c4",".github/probes/lumo_connect_four_android_probe.py","Probe"),
]:
    old=function(source(path),"run",owner)
    new=function(adapter,"_"+kind+"_run")
    new.name="run"
    tr=next(n for n in new.body if isinstance(n,ast.Try))
    binding=tr.body.pop(0)
    expected=ast.parse("result['diagnostic_binding'] = require_bound_diagnostic(self.args)").body[0]
    assert dump(binding)==dump(expected)
    normalizer=NormalizeIdentity(kind)
    new=normalizer.visit(new)
    assert normalizer.counts=={"qa_identity":1,"apk_binding_keyword":1,"apk_identity":1,"scope":1,"print_label":1}, normalizer.counts
    assert dump(new)==dump(old), kind
    parity.append({"kind":kind,"original_source":path,"original_blob":blob(source(path).encode()),
                   "whole_function_ast_identical_after_explicit_identity_and_label_adjustments":True,
                   "added_binding_call":"require_bound_diagnostic(self.args)",
                   "normalized_differences":normalizer.counts,
                   "journey_actions_assertions_and_exception_finalization_preserved":True})
inventory=[{"path":p,**info(ROOT/p)} for p in FILES]
assert next(x for x in inventory if x["path"]==".github/probes/lumo_village_android_probe.py")["git_blob"]=="3e601644198f0b8c62fdaebcf783e3f631974bb1"
assert next(x for x in inventory if x["path"]=="tools/android_qa/tests/test_village_android_evidence.py")["git_blob"]=="d21f941b2f5cff410f8e4cd7ae23fbbbf894743a"
existing=[
".github/probes/modernization_android_tour.py",".github/probes/creative_android_probe.py",
".github/probes/lumo_connect_four_android_probe.py","tools/android_qa/connect_four_android_evidence.py",
"tools/android_qa/village_android_evidence.py",
]
for p in existing:
    assert (ROOT/p).read_bytes()==source(p).encode(),p
result={"schema":1,"kind":"Read-only source review, not a test run","base_commit":BASE,
        "reviewed_sources":inventory,"adapter_ast_parity":parity,
        "unchanged_production_journeys_and_verifiers":[{"path":p,"git_blob":blob(source(p).encode())} for p in existing]}
(OUT/"static-source-review.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result,indent=2))
