#!/usr/bin/env python3
"""Read current original artifacts through exact committed pure readers; never launch a game."""
from pathlib import Path
import hashlib, importlib.util, json, sys, time
import PIL
BASE=Path('/workspace/scratch/2708c7907f28/runtime-1375-original-14115597521')
ORIGINAL=BASE/'original'
RUNTIME=ORIGINAL/'runtime'
HELPER=Path('/workspace/scratch/2708c7907f28/lumo-host-current/scripts/run_connect_four_runtime.py')
def identity(data):
 return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}
def file_record(path): return identity(path.read_bytes())
index=json.loads((BASE/'archive-index.json').read_text())
initial={}
for entry in index['members']:
 current=file_record(ORIGINAL/entry['path'])
 assert current=={k:entry[k] for k in ('bytes','sha256','git_blob')},entry['path']
 initial[entry['path']]=current
helper_before=file_record(HELPER)
assert helper_before['git_blob']=='36d93ed0908705e339346bf5ef451cf047b641b5'
expected=json.loads((BASE/'expected-immutable-sources.json').read_text())
source_bytes=(RUNTIME/'source-before.json').read_bytes()
assert source_bytes==(RUNTIME/'source-after.json').read_bytes()
snap=json.loads(source_bytes)
bindings={}
for role in ('host','native'):
 assert snap[role]['head']==expected[role]['head']
 got={row['path']:row for row in snap[role]['files']}
 want={row['path']:row for row in expected[role]['files']}
 assert len(got)==len(snap[role]['files']) and set(got)==set(want)
 for path,record in got.items():
  assert {k:record[k] for k in ('path','mode','git_blob','bytes')}==want[path],path
 bindings[role]={'head':snap[role]['head'],'tree':expected[role]['tree'],'file_count':len(got),'exact_path_mode_blob_size_match':True}
assert bindings['host']['head']=='1375da193af0152af64f91d86577aa9768cd50db'
assert bindings['native']['head']=='e2d15dbc5f3709306decb139eeb70a1cf30c0b73'
spec=importlib.util.spec_from_file_location('approved_1375_runtime_reader',HELPER)
reader=importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
gate=json.loads((RUNTIME/'runtime-gate.json').read_text())
assert gate['passed'] is True and gate['exit_codes']=={'dart':0,'godot':0}
session=json.loads((RUNTIME/'session.json').read_text())
assert gate['session']==session
start=time.monotonic()
fresh_log=reader.validate_native_log(RUNTIME/'original-godot.log')
fresh_results=reader.validate_results(RUNTIME,session)
elapsed=time.monotonic()-start
assert fresh_log==gate['original_godot_log']
assert fresh_results==gate['results']
native=json.loads((RUNTIME/'native-result.json').read_text())
dart=json.loads((RUNTIME/'dart-result.json').read_text())
states=[x['state'] for x in dart['events'] if x.get('kind')=='state']
assert states[-1]==native['final_state']
assert json.loads((RUNTIME/'closed.json').read_text())['token']==session['token']
for path,ident in initial.items(): assert file_record(ORIGINAL/path)==ident,path
assert file_record(HELPER)==helper_before
report={
 'schema':1,'kind':'current_runtime_original_readonly_verification',
 'host':'1375da193af0152af64f91d86577aa9768cd50db','host_tree':'ebaf259b92a4c7923782e195c3a932112ce81027',
 'native':'e2d15dbc5f3709306decb139eeb70a1cf30c0b73','native_tree':'ea0f73ae6aad8792a963cadaa483c290a2f2a62e',
 'run_id':43599456596,'run_attempt':1,'job_id':132460874104,'artifact_id':14115597521,
 'python':sys.version,'pillow':PIL.__version__,'performed':True,'passed':True,
 'scope':'Original JSON/log/image/source-metadata verification only. No renderer, engine, Flutter test or new game run.',
 'archive':index['archive'],'archive_file_count':index['file_count'],'all_original_hashes_unchanged':True,
 'source_bindings':bindings,'source_snapshots_byte_equal':True,'source_snapshot':identity(source_bytes),
 'helper':{'path':'scripts/run_connect_four_runtime.py',**helper_before},
 'actual_pure_calls':['validate_native_log(runtime/original-godot.log)','validate_results(runtime, original_session)'],
 'fresh_result_equals_original':True,'fresh_native_log_equals_original':True,
 'original_process_exit_codes':gate['exit_codes'],'native_checks':native['checks'],'native_errors':native['errors'],
 'frame_count':fresh_results['frames'],'validated_png_count':len(fresh_results['images']),
 'observed_moving_frames':fresh_results['observed_moving_frames'],'observed_winning_frames':fresh_results['observed_winning_frames'],
 'recording_format_fps':24,'measured_device_fps':False,'inputs':len(native['inputs']),'touched_targets':len(native['targets']),
 'touched_target_labels':[x['label'] for x in native['targets']],
 'dart_event_count':len(dart['events']),'last_dart_state_equals_native_final':True,
 'final_ack':native['final_state']['ack'],'final_revision':native['final_state']['revision'],'final_exit':native['final_state']['exit'],
 'stars':dart['stars'],'xp':dart['xp'],'reopened_same_round':dart['reopened_same_round'],
 'preferences_backend':dart['preferences_backend'],'single_player_human_and_bot_observed':dart['single_player_human_and_bot_observed'],
 'reader_elapsed_seconds':elapsed,
 'limitations':['Source metadata was compared against the exact immutable remote Git trees, not presented as a new complete source checkout.',
 'Original CI used local file transport, test SharedPreferences, desktop llvmpipe and declared Android-style insets; this is not an Android/device-FPS acceptance.',
 '24 is the configured recording format, not measured rendering throughput.',
 'The small landscape standard capture does not newly demonstrate scrolling to and activating restart/mode in the won modal. The separate R3 interaction proof is not transferred.',
 'No complete main workflow success or APK/Play release approval is implied.']
}
with (BASE/'original-review.json').open('x') as f: f.write(json.dumps(report,indent=2)+'\n')
with (BASE/'fresh-runtime-results.json').open('x') as f: f.write(json.dumps(fresh_results,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('performed','passed','source_bindings','native_checks','native_errors','frame_count','validated_png_count','original_process_exit_codes','all_original_hashes_unchanged','final_ack','final_revision','recording_format_fps','measured_device_fps','reader_elapsed_seconds')},indent=2))

