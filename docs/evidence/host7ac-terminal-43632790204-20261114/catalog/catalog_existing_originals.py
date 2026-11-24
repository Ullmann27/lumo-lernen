from pathlib import Path
import datetime, hashlib, json, re, zipfile
OUT=Path('/tmp/host7ac-terminal-publication-catalog-20261114')
OUT.mkdir(exist_ok=False)
T=Path('/tmp/host7ac-c4-run43632790204-evidence-20261114/terminal-20261114T195750Z')
F=Path('/tmp/host7ac-full-flutter-originals-20261114')
C=Path('/tmp/host7ac-build-contracts-originals-20261114')
H=Path('/tmp/host7ac-c4-host-compile-evidence-20261114')
R=Path('/tmp/host7ac-runtime-native-evidence-20261114/runtime')
RH=Path('/tmp/host7ac-runtime-originals-checkpoint-20261114')
HEAD='7ac736fdbd042769592e88de0f9849632242316d'
NATIVE='f9d9772bb932d7ee8702eeb5bca6d98c286f3b98'
RUN=43632790204
PREFIX='docs/evidence/host7ac-terminal-43632790204-20261114'
def identity(path):
 size=path.stat().st_size
 sha=hashlib.sha256(); git=hashlib.sha1(b'blob '+str(size).encode()+b'\0')
 total=0
 with path.open('rb') as stream:
  for block in iter(lambda:stream.read(1024*1024),b''):
   total+=len(block);sha.update(block);git.update(block)
 assert total==size and path.stat().st_size==size,str(path)
 return {'bytes':size,'sha256':sha.hexdigest(),'git_blob':git.hexdigest()}
def load(path):return json.loads(path.read_text())
run=load(T/'run.original.json');jobs=load(T/'jobs.original.json');artifacts=load(T/'artifacts.original.json')
assert run['id']==RUN and run['head_sha']==HEAD and run['run_attempt']==1
assert run['path']=='.github/workflows/lumo-connect-four-2020.yml'
assert (run['status'],run['conclusion'])==('completed','failure')
expected_jobs={
 'connect-four-runtime':(132562871412,'success'),
 'android-host-compile':(132562871774,'success'),
 'verify-and-build':(132564123163,'failure'),
 'update-2020-from-2017':(132569070277,'skipped'),
 'android-c4':(132569070562,'skipped'),
 'verify-c4-candidate':(132569070664,'skipped'),
 'prepare-c4-delivery':(132569071465,'skipped'),
}
assert len(jobs['jobs'])==7
for job in jobs['jobs']:
 assert (job['id'],job['conclusion'])==expected_jobs[job['name']]
 assert job['status']=='completed' and job['run_attempt']==1 and job['run_id']==RUN
build=next(j for j in jobs['jobs'] if j['name']=='verify-and-build')
failed=[s for s in build['steps'] if s['conclusion']=='failure']
assert len(failed)==1 and failed[0]['number']==20
artifact_by_id={a['id']:a for a in artifacts['artifacts']}
assert len(artifact_by_id)==7
for a in artifacts['artifacts']:
 assert a['workflow_run']['id']==RUN and a['workflow_run']['head_sha']==HEAD
recount=load(F/'machine-inspection/recount.json')
assert recount['counts']=={'visible_success':2686,'hidden_success':583,'paired_test_ids':3269,'failures':0,'skips':0,'error_events':0,'suites':399}
assert recount['done']['event']=={'success':True,'type':'done','time':591081}
assert recount['original_summary_matches'] and recount['unchanged']
runtime=load(RH/'handoff.json');compile=load(H/'handoff.json')
assert runtime['run_id']==RUN and runtime['attempt']==1 and runtime['host']['head']==HEAD and runtime['native']['head']==NATIVE
assert compile['binding']['run']==RUN and compile['binding']['attempt']==1 and compile['binding']['head']==HEAD and compile['binding']['native_sha']==NATIVE
files=[]
def add(path,relative,status,kind='original'):
 row={'source_path':str(path),'repository_path':PREFIX+'/'+relative,'kind':kind,'evidence_status':status,**identity(path)}
 files.append(row);return row
for name in ('run.original.json','jobs.original.json','artifacts.original.json'):
 add(T/name,'terminal/'+name,'Exact complete original terminal API response')
add(T/'raw-manifest.json','terminal/raw-manifest.json','Original terminal collection manifest','collection_manifest')
log_entry=add(T/'job-132564123163.original.log','terminal/job-132564123163.original.log','Once-downloaded complete original terminal build job log')
assert log_entry['sha256']=='1cba4f6f36e86a4f3b6576ded5b283c23dfd8188200902fa020aa995997caa42'
contract_entry=add(C/'originals/build-contracts.log','contracts/build-contracts.original.log','Exact complete failed build-contract stdout/stderr artifact member')
assert contract_entry['sha256']=='b197b423ca3f96a5b5ddd4f55e0df6361c193c27b1c5eef6b131e0299b50b798'
add(C/'zip-members.json','contracts/zip-members.json','Complete original artifact member CRC/SHA index','archive_index')
add(C/'host7ac-build-contracts-14129167785.zip','contracts/artifact-14129167785.original.zip','Original small artifact bytes; API SHA and sole member CRC/SHA verified','original_archive')
for name in ('run.original.json','jobs.original.json','artifacts.original.json'):
 add(F/'api-originals'/name,'flutter/upload-api/'+name,'Exact original API response collected with the finished Flutter artifact; earlier than terminal snapshot')
for name in ('acceptance-summary.json','flutter-machine.jsonl'):
 row=add(F/'originals'/name,'flutter/originals/'+name,'Unchanged original Flutter artifact member; current run only')
 bound=recount['source_originals_after']['originals/'+name]
 assert {k:row[k] for k in ('bytes','sha256','git_blob')}==bound
for name in ('zip-members.json','archive-verification.json'):
 add(F/name,'flutter/'+name,'All 554 original ZIP members were decompressed and CRC/SHA/size checked at original collection','archive_integrity_report')
for name in ('recount.json','suite-results.json','non-protocol-lines.json'):
 add(F/'machine-inspection'/name,'flutter/inspection/'+name,'Existing read-only recount of the original machine stream; not a new test run','derived_original_analysis')
add(F/'recount-program/read_original_machine.py','flutter/read_original_machine.py','Exact program used for the existing read-only recount','read_only_program')
for name in ('review.json','manifest.json'):
 add(Path('/tmp/host7ac-full-flutter-independent-review-20261114')/name,'flutter/independent-review/'+name,'Existing independent original-stream count and binding; no test replay','peer_review')
for name in ('handoff.json','manifest.json'):
 add(RH/name,'runtime/'+name,'Existing peer-frozen current Runtime original pack and exact source binding','peer_handoff')
add(R/'job-132562871412.original.log','runtime/job-132562871412.original.log','Existing once-downloaded complete Runtime job log')
add(R/'runtime-original-replay.json','runtime/runtime-original-replay.json','Existing exact-source pure original replay, not an engine rerun','peer_pure_replay')
for name in ('handoff.json','manifest.json','archive-verification.json'):
 add(H/name,'host-compile/'+name,'Existing peer-frozen current compile evidence and archive integrity','peer_handoff')
add(H/'originals/host-compile-132562871774.original.log','host-compile/job-132562871774.original.log','Existing once-downloaded complete HostCompile job log')
add(H/'originals/artifact-14128952438.original.zip','host-compile/artifact-14128952438.original.zip','Original small six-member compile artifact; API SHA/CRC checked','original_archive')
large=[]
for artifact_id,path in [
 (14128439571,F/'host7ac-full-flutter-14128439571.zip'),
 (14128583501,R/'original-14128583501.zip'),
 (14129167785,C/'host7ac-build-contracts-14129167785.zip'),
 (14128952438,H/'originals/artifact-14128952438.original.zip')]:
 ident=identity(path);meta=artifact_by_id[artifact_id]
 assert ident['bytes']==meta['size_in_bytes'] and 'sha256:'+ident['sha256']==meta['digest']
 large.append({'artifact_id':artifact_id,'name':meta['name'],'path':str(path),**ident,'original_api_digest':meta['digest'],'new_download':False,'include_in_compact_payload':ident['bytes']<1024*1024,'crc_members_checked_at_original_collection':{14128439571:554,14128583501:399,14129167785:1,14128952438:6}[artifact_id]})
small_index=load(C/'zip-members.json')
with zipfile.ZipFile(C/'host7ac-build-contracts-14129167785.zip') as z:
 assert len(z.infolist())==1
 info=z.infolist()[0];data=z.read(info)
 assert info.filename==small_index[0]['path']=='build-contracts.log'
 assert data==(C/'originals/build-contracts.log').read_bytes()
 assert f'{info.CRC:08x}'==small_index[0]['crc32']
contract_lines=(C/'originals/build-contracts.log').read_text().splitlines()
full_lines=(T/'job-132564123163.original.log').read_text().splitlines()
error_title='ERROR: setUpClass (test_speech_envelope_contract.SpeechEnvelopeContractTest)'
def occurrence(lines,text):
 result=[{'line':i+1,'original_text':s} for i,s in enumerate(lines) if text in s]
 assert result,text
 return result
failure={
 'first_failed_step':failed[0],
 'setup_error':error_title,
 'complete_contract_log_locations':{'error':occurrence(contract_lines,error_title),'count':occurrence(contract_lines,'Ran 921 tests in 309.572s'),'result':occurrence(contract_lines,'FAILED (errors=1)')},
 'complete_build_log_locations':{'error':occurrence(full_lines,error_title),'count':occurrence(full_lines,'Ran 921 tests in 309.572s'),'result':occurrence(full_lines,'FAILED (errors=1)'),'exit_one':occurrence(full_lines,'Process completed with exit code 1.')},
 'reported_compile_errors':['LumoLearningSpeech.kt:31 optJSONObject','LumoLearningSpeech.kt:103 LumoOfflineSpeechEngine.PRESET','LumoLearningSpeech.kt:104 LumoOfflineSpeechEngine.SAMPLE_RATE','LumoLearningSpeech.kt:138 LumoOfflineSpeechBridge.synthesizeEnglishLesson','LumoLearningSpeech.kt:224 optJSONObject','LumoLearningSpeech.kt:244 type inference'],
 'test_count_claim':'The original states Ran 921 and FAILED(errors=1); no all-pass count is inferred.',
 'repair_scope':'Root owns the separately checkpointed Speech-fixture repair. This catalog preserves the actual failed old source unchanged.'
}
known_verified={x['artifact_id'] for x in large}
catalog={
 'schema':1,'kind':'terminal_original_publication_catalog','created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'repository':'Ullmann27/lumo-lernen','run_id':RUN,'attempt':1,'head':HEAD,'tree':'f7c4f29460cab5a5728acff117d21e2562bd0af2','native':NATIVE,'native_tree':'4036a20ab80de78bcdf0d074b585be88c2946492',
 'workflow':run['path'],'workflow_blob':'05329a8f7ac3d51d95a9151ead0b7e482ae09064',
 'terminal':{'status':'completed','conclusion':'failure','original_snapshot_utc':'2026-11-14T19:57:50Z','run_created_at':run['created_at'],'run_updated_at':run['updated_at'],'job_count':7,'success_jobs':2,'failed_jobs':1,'skipped_jobs':4},
 'jobs':[{k:j.get(k) for k in ('id','name','run_attempt','status','conclusion','started_at','completed_at')} for j in jobs['jobs']],
 'raw_timestamp_policy':'All original skipped-job API timestamps are retained unchanged, including completed_at earlier than started_at in three skipped entries; no duration is inferred for skipped jobs.',
 'failure':failure,
 'flutter':{'stage':next(s for s in build['steps'] if s['number']==13),'counts':recount['counts'],'done':recount['done']['event'],'original_summary_matches':True,'independent_review_sha256':'be4adf6f8b4a706220e54f6c676cb8835fa9540d4c4d968dd52eb381425a63c1','image_limit':'552 PNG members are integrity-indexed, not visually reviewed or PNG-decoded by this collector.'},
 'runtime':{'job_id':132562871412,'artifact_id':14128583501,'status':'success','scope':runtime['scoped_result'],'peer_handoff_path':str(RH/'handoff.json'),'host_scoped_files':458,'native_scoped_files':1295,'source_binding':'Peer frozen exact-tree and before/after source inventories; exact-source pure replay. No new engine invocation in this catalog.'},
 'host_compile':{'job_id':132562871774,'artifact_id':14128952438,'status':'success','actual_result':compile['actual_result'],'peer_handoff_path':str(H/'handoff.json'),'limits':compile['limitations']},
 'not_reached':{'native_52_dream_discovery_steps':[s for s in build['steps'] if s['number'] in (31,32,33)],'apk_build_step':next(s for s in build['steps'] if s['number']==35),'native_build_artifact_present':False,'apk_present':False,'android_or_update_evidence_present':False,'delivery_bundle_present':False,'four_downstream_jobs':'All four were skipped, not failed device tests and not successful acceptance.'},
 'artifacts':[{'id':a['id'],'name':a['name'],'bytes':a['size_in_bytes'],'digest':a['digest'],'evidence_status':'ORIGINAL_ARCHIVE_COLLECTED_AND_BOUND' if a['id'] in known_verified else 'METADATA_ONLY_NOT_DOWNLOADED_BY_THIS_COLLECTOR'} for a in artifacts['artifacts']],
 'publication_files':files,
 'publication_payload_bytes':sum(f['bytes'] for f in files),
 'separate_original_archives':large,
 'existing_peer_technical_archive':{'path':runtime['technical_archive']['path'],**identity(Path(runtime['technical_archive']['path'])),'scope':'Existing peer-produced compact Runtime original/reader pack; not duplicated here'},
 'restrictions':{'remote_downloads_during_catalog':0,'tests_during_catalog':0,'engine_or_device_runs':0,'ci_or_ref_changes':0,'source_changes':0,'terminal_watch_stopped':True,'publication_or_release_authorized_by_this_result':False},
 'overall_claim':'Historical current-run FAILURE remains. Successful substage originals are preserved; neither Android acceptance, release, nor a later repaired-source PASS is claimed.'
}
raw=(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n').encode()
with (OUT/'mapping.json').open('xb') as f:f.write(raw)
failure_raw=(json.dumps(failure,ensure_ascii=False,indent=2)+'\n').encode()
with (OUT/'first-failure.json').open('xb') as f:f.write(failure_raw)
print(json.dumps({'root':str(OUT),'mapping':identity(OUT/'mapping.json'),'first_failure':identity(OUT/'first-failure.json'),'publication_files':len(files),'publication_payload_bytes':catalog['publication_payload_bytes'],'separate_archives':large},ensure_ascii=False,indent=2))
