#!/usr/bin/env python3
"""Replay only the exact committed Flutter summary parser on original CI data."""
from pathlib import Path
import collections, datetime, hashlib, importlib.util, json, subprocess, sys, time, zipfile
sys.dont_write_bytecode=True
BASE=Path('/workspace/scratch/2708c7907f28/1375-full-flutter-originals')
ORIGINAL=BASE/'original'
REPO=Path('/workspace/scratch/2708c7907f28/lumo-host-current')
READER=REPO/'scripts/run_full_flutter_acceptance.py'
HOST='1375da193af0152af64f91d86577aa9768cd50db'
TREE='ebaf259b92a4c7923782e195c3a932112ce81027'
def identity(data):
 return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}
def file_record(path): return identity(path.read_bytes())
def git(*args): return subprocess.check_output(['git',*args],cwd=REPO,text=True).strip()
assert git('rev-parse','HEAD')==HOST and git('rev-parse','HEAD^{tree}')==TREE
subprocess.run(['git','diff','--exit-code','HEAD','--'],cwd=REPO,check=True)
idx=json.loads((BASE/'ORIGINAL_INDEX.json').read_text())
initial={row['path']:{k:row[k] for k in ('bytes','sha256','git_blob')} for row in idx['members']}
assert len(initial)==len(idx['members'])==idx['file_count']
for name,expected in initial.items(): assert file_record(ORIGINAL/name)==expected,name
before=file_record(READER)
assert before['git_blob']==git('rev-parse',HOST+':scripts/run_full_flutter_acceptance.py')=='8d17cf8175ce13ef1d756526fa13c306c846ac72'
summary=json.loads((ORIGINAL/'acceptance-summary.json').read_text())
events=[]; non_json=0
for line in (ORIGINAL/'flutter-machine.jsonl').read_text().splitlines():
 try: row=json.loads(line)
 except json.JSONDecodeError: non_json+=1; continue
 if isinstance(row,dict): events.append(row)
counts=dict(collections.Counter(e.get('type','<none>') for e in events))
spec=importlib.util.spec_from_file_location('original_flutter_summary_reader',READER)
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
errors=sorted(str(p.relative_to(ORIGINAL)) for p in ORIGINAL.rglob('*.error.txt'))
started=time.monotonic()
fresh=reader.summarize(events,summary['flutter_exit_code'],errors)
elapsed=time.monotonic()-started
for key,value in fresh.items(): assert summary[key]==value,key
assert fresh['status']=='PASS' and summary['runner_errors']==[]
assert summary['scope']==['complete Flutter suite; capture outputs recorded below']
for key,folder in reader.CAPTURE_DIRECTORIES.items():
 assert summary['capture_png_counts'][key]=={'directory':folder,'pngs':sum(1 for _ in (ORIGINAL/folder).rglob('*.png'))},key
for key,name in reader.CAPTURE_FILES.items(): assert summary['capture_file_outputs'][key]=={'path':name,'created':(ORIGINAL/name).is_file()},key
assert summary['rendered_png_count']==sum(1 for _ in ORIGINAL.rglob('*.png'))
starts={e['test']['id']:e['test'] for e in events if e.get('type')=='testStart'}
dones={e['testID']:e for e in events if e.get('type')=='testDone'}
focused=[{'id':i,'name':t['name'],'done':dones.get(i)} for i,t in starts.items() if 'exact' in t['name'].lower() and 'topic' in t['name'].lower()]
assert focused and all(x['done'] and x['done']['result']=='success' and not x['done'].get('skipped') for x in focused)
for name,expected in initial.items(): assert file_record(ORIGINAL/name)==expected,name
assert file_record(READER)==before and git('rev-parse','HEAD')==HOST
subprocess.run(['git','diff','--exit-code','HEAD','--'],cwd=REPO,check=True)
report={'schema':1,'kind':'actual_readonly_original_flutter_parser_replay','recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'performed':True,'passed':True,'host':HOST,'tree':TREE,'run_id':43599456596,'run_attempt':1,'artifact_id':14116675111,'archive':idx['archive'],'original_file_count':idx['file_count'],'all_original_files_unchanged':True,'reader':{'path':'scripts/run_full_flutter_acceptance.py',**before},'actual_reader_call':'summarize(original_events, original_exit_code, actual_error_files)','fresh_summary_fields_equal_original':True,'fresh_summary':fresh,'event_counts':counts,'non_json_lines':non_json,'rendered_png_count':summary['rendered_png_count'],'capture_directory_counts_match':True,'focused_exact_topic_original_results':focused,'final_done_events':[e for e in events if e.get('type')=='done'],'reader_elapsed_seconds':elapsed,'source_and_reader_unchanged':True,'limitations':['Replayed the unchanged committed parser on the original current CI machine log; no new Flutter or application tests were executed.','Archive integrity and PNG counts do not constitute visual approval of all images.','No Android, device-FPS, signed APK or Play approval is inferred.']}
(BASE/'ROOT_READONLY_REPLAY.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
(BASE/'fresh-summary.json').write_text(json.dumps(fresh,indent=2,ensure_ascii=False)+'\n')
with zipfile.ZipFile(BASE/'original-reports-storage.zip','x',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for name in ('acceptance-summary.json','flutter-machine.jsonl'): z.write(ORIGINAL/name,name)
print(json.dumps({k:report[k] for k in ('performed','passed','fresh_summary','event_counts','rendered_png_count','final_done_events','focused_exact_topic_original_results','reader_elapsed_seconds','all_original_files_unchanged')},indent=2))
