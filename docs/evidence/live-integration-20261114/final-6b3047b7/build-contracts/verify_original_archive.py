import hashlib,json,stat,sys,urllib.request,zipfile
from pathlib import Path,PurePosixPath
root=Path('/workspace/scratch/909ddb52fe7b/android-artifacts-6b3047b7/build-contracts-14122323327')
root.mkdir(parents=True,exist_ok=True)
archive=root/'original-artifact-14122323327.zip'
if not archive.exists():
 with urllib.request.urlopen(sys.argv[1],timeout=120) as response, archive.open('xb') as out:
  while chunk:=response.read(1024*1024): out.write(chunk)
data=archive.read_bytes()
assert len(data)==29488
assert hashlib.sha256(data).hexdigest()=='f334e1d66517c355e41c35ee401a3b3552a3a118db1df4d1feca85ca27463763'
rows=[]
with zipfile.ZipFile(archive) as z:
 names=[i.filename for i in z.infolist()]
 assert len(names)==len(set(names))
 for i in z.infolist():
  p=PurePosixPath(i.filename)
  assert not p.is_absolute() and '..' not in p.parts and '\\' not in i.filename
  assert not stat.S_ISLNK(i.external_attr>>16)
 assert z.testzip() is None
 for i in z.infolist():
  if i.is_dir(): continue
  b=z.read(i)
  target=root/'originals'/i.filename
  target.parent.mkdir(parents=True,exist_ok=True)
  if target.exists(): assert target.read_bytes()==b
  else: target.write_bytes(b)
  rows.append({'path':i.filename,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),'zip_crc32':f'{i.CRC:08x}'})
m={'host_source':'6b3047b7979dfb86d837e74a21b0fd890e4f9e66','host_tree':'8b0c31a26207068c28658e14c6535c39a51cf95b','native_source':'84789d0c2c6fb4b6ecd2897ce1951b89f958b604','run_id':43616038272,'run_attempt':1,'job_id':132512734271,'artifact_id':14122323327,'artifact_bytes':len(data),'artifact_sha256':hashlib.sha256(data).hexdigest(),'zip_crc_pass':True,'original_members':rows}
(root/'archive-verification.json').write_text(json.dumps(m,indent=2)+'\n')
print(json.dumps(m,indent=2))
