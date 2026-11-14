import hashlib,json,shutil,stat,sys,urllib.request,zipfile
from pathlib import Path,PurePosixPath
root=Path('/workspace/scratch/909ddb52fe7b/android-artifacts-6b3047b7/arm64-14125561696')
root.mkdir(parents=True,exist_ok=True)
archive=root/'original-artifact-14125561696.zip'
if not archive.exists():
 partial=root/'original-artifact-14125561696.zip.partial'
 with urllib.request.urlopen(sys.argv[1],timeout=120) as response, partial.open('xb') as out:
  shutil.copyfileobj(response,out,1024*1024)
 assert partial.stat().st_size==331381619
 with partial.open('rb') as stream: digest=hashlib.file_digest(stream,'sha256').hexdigest()
 assert digest=='4019515f9c9a6dadfdc00b2f504f68f559d5b1855e5bf8676675c9e4a9219de6'
 partial.rename(archive)
with archive.open('rb') as stream: archive_digest=hashlib.file_digest(stream,'sha256').hexdigest()
assert archive.stat().st_size==331381619 and archive_digest=='4019515f9c9a6dadfdc00b2f504f68f559d5b1855e5bf8676675c9e4a9219de6'
members=[]
outroot=root/'originals'
with zipfile.ZipFile(archive) as z:
 infos=z.infolist()
 assert len(infos)==len({i.filename for i in infos})
 for i in infos:
  p=PurePosixPath(i.filename)
  assert not p.is_absolute() and '..' not in p.parts and '\\' not in i.filename
  assert not stat.S_ISLNK(i.external_attr>>16)
 assert z.testzip() is None
 for i in infos:
  if i.is_dir(): continue
  target=outroot/i.filename
  target.parent.mkdir(parents=True,exist_ok=True)
  if not target.exists():
   with z.open(i) as src,target.open('xb') as dst: shutil.copyfileobj(src,dst,1024*1024)
  with target.open('rb') as stream: sha=hashlib.file_digest(stream,'sha256').hexdigest()
  assert target.stat().st_size==i.file_size
  members.append({'path':i.filename,'bytes':i.file_size,'sha256':sha,'zip_crc32':f'{i.CRC:08x}'})
apk=outroot/'Lumo-Lernen-Neu.apk'
expected=json.loads(sys.argv[2])
with apk.open('rb') as stream: apk_hash=hashlib.file_digest(stream,'sha256').hexdigest()
assert apk.stat().st_size==expected['bytes'] and apk_hash==expected['sha256']
facts=json.loads((outroot/'APK-VERIFICATION.json').read_text())
assert facts==expected
provenance=json.loads((outroot/'BUILD-PROVENANCE.json').read_text())
assert all(provenance.get(k)==v for k,v in facts.items())
assert provenance['flutter_source_commit']=='6b3047b7979dfb86d837e74a21b0fd890e4f9e66' and provenance['tracked_source_clean'] is True
godot=json.loads((outroot/'GODOT-SOURCE.json').read_text())
assert godot['revision']=='84789d0c2c6fb4b6ecd2897ce1951b89f958b604'
with zipfile.ZipFile(apk) as z:
 assert z.testzip() is None
 assert len(z.namelist())==len(set(z.namelist()))
 with z.open('assets/lumo_game.pck') as stream: pck_hash=hashlib.file_digest(stream,'sha256').hexdigest()
 pck_bytes=z.getinfo('assets/lumo_game.pck').file_size
 embedded=json.loads(z.read('assets/lumo_game_source.json'))
 assert embedded==facts['godot']
 assert pck_hash==embedded['pck_sha256'] and pck_bytes==embedded['bytes']
 abis=sorted({n.split('/')[1] for n in z.namelist() if n.startswith('lib/') and n.endswith('.so')})
 assert abis==['arm64-v8a']
result={'host_source':'6b3047b7979dfb86d837e74a21b0fd890e4f9e66','host_tree':'8b0c31a26207068c28658e14c6535c39a51cf95b','native_source':godot['revision'],'run_id':43616038272,'run_attempt':1,'job_id':132512734271,'artifact_id':14125561696,'artifact_bytes':archive.stat().st_size,'artifact_sha256':archive_digest,'zip_crc_pass':True,'apk_crc_pass':True,'apk_sha256':apk_hash,'apk_bytes':apk.stat().st_size,'abis':abis,'embedded_pck_sha256':pck_hash,'embedded_pck_bytes':pck_bytes,'original_ci_verification_matches_log':True,'original_provenance_matches_exact_host_and_facts':True,'fresh_local_apksigner_aapt':'NOT_RUN_TOOLS_NOT_INSTALLED','original_members':members}
(root/'local-original-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
