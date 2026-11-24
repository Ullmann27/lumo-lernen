from pathlib import Path
import ast,hashlib,json,subprocess,os
root=Path('/workspace/scratch/909ddb52fe7b/garage-probe-repair-1e22')
gitroot=Path('/workspace/scratch/909ddb52fe7b/lumo-upstream057-review')
fixture=root/'tools/android_qa/tests/fixtures/kart-scroll-1e22'
originals={'android':Path('/workspace/scratch/909ddb52fe7b/android-artifacts-1e22/failures/14119041396/originals/main'),'update':Path('/workspace/scratch/909ddb52fe7b/android-artifacts-1e22/failures/14118638414/originals')}
def functions(txt):
 return {n.name:ast.get_source_segment(txt,n) for n in ast.parse(txt).body if isinstance(n,(ast.FunctionDef,ast.ClassDef))}
checks={}
for path in ['tools/android_qa/kart_garage_evidence.py','.github/probes/modernization_android_tour.py']:
 raw=(root/path).read_bytes(); now=functions(raw.decode())
 before=functions(subprocess.check_output(['git','show','057a4e8d067872c4f3514b126aa04c3706d2e5b5:'+path],cwd=gitroot,text=True,env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'}))
 checks[path]={'git_blob':hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest(),'sha256':hashlib.sha256(raw).hexdigest(),'old_functions':len(before),'unchanged_functions':[k for k in before if before[k]==now.get(k)],'changed_functions':[k for k in before if before[k]!=now.get(k)],'added_functions':[k for k in now if k not in before]}
provenance=json.loads((fixture/'provenance.json').read_text()); comparison=[]
for name,series in provenance['series'].items():
 for entry in series['files']:
  new=(fixture/name/entry['file']).read_bytes(); old=(originals[name]/entry['file']).read_bytes()
  assert new==old,(name,entry['file'],'original differs')
  assert len(new)==entry['bytes'] and hashlib.sha256(new).hexdigest()==entry['sha256']
  comparison.append({'series':name,**entry,'actual_download_bytes_equal':True})
report={'validation':'Independent read-only source and original-byte review; no test rerun or Android execution.','source':checks,'original_fixture_files':len(comparison),'original_fixture_bytes_equal':True,'originals':comparison,
'conclusion':'No concrete false-positive or wiring blocker found. Full text then exact original TSV word spans precede the unique current five-bar geometry. The geometry authorizes only a bounded scroll, never a kart identity or selected-race success.',
'preserved_boundaries':['Current PNG SHA256/bytes/dimensions before pixel scan and digest before ADB input.','Karts/workshop/footer and left-side bounds; finite in-image OCR coordinates.','Whole unique five-row same-color/same-pitch block; missing/partial/ambiguous blocks rejected.','Two current stable observations of same anchor kind/caption/bounds and gesture; five-gesture limit, 150-second budget and 650ms swipe remain.','Target still requires exact caption and real touch; saved new-race identity, requested vehicle/driver/mode/track and physical progress remain unchanged.','The actual Android inertia and complete tour remain unproven until the unchanged-APK diagnostic executes.']}
print(json.dumps(report,indent=2))
