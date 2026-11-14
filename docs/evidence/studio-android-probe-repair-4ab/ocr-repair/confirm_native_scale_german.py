from pathlib import Path
import os,subprocess,time,csv,json,re,unicodedata
from PIL import Image
root=Path('/workspace/scratch/5987865ae883');q=root/'qa/ocr-original-scale-4ab';d=q/'native-scale-german-confirmation';d.mkdir(exist_ok=False)
env={**os.environ,'TESSDATA_PREFIX':'/workspace/scratch/e0abce7d2838/qa/host-a31c0070/tessdata','OMP_THREAD_LIMIT':'1'}
rows=[]
for api,index in [(35,0),(35,7),(37,0),(37,6)]:
 p=root/f'qa/studio-final-4ab96666/api{api}/selected-originals/nextgen/learning-move-1-{index}.png'
 with Image.open(p) as original: rgb=original.convert('RGB')
 for name,im in [('raw',rgb),('contrast',rgb.convert('L').point(lambda v:0 if v>=170 else 255))]:
  prefix=d/f'api{api}-{index}-{name}-1x';im.save(prefix.with_suffix('.png'));cmd=['tesseract',str(prefix.with_suffix('.png')),str(prefix),'--psm','11','-l','deu+eng','tsv'];t=time.monotonic();r=subprocess.run(cmd,capture_output=True,text=True,timeout=15,env=env)
  groups={}
  with prefix.with_suffix('.tsv').open() as s:
   for w in csv.DictReader(s,delimiter='\t',quoting=csv.QUOTE_NONE):
    if w.get('text','').strip() and float(w['conf'])>=15:groups.setdefault(tuple(w[k] for k in ('page_num','block_num','par_num','line_num')),[]).append(w)
  texts=[' '.join(w['text'] for w in sorted(ws,key=lambda w:int(w['left']))) for ws in groups.values()]
  norm=lambda t:re.sub('[^a-z0-9]','',unicodedata.normalize('NFKD',t).encode('ascii','ignore').decode().lower())
  matches=[t for t in texts if 'einobjektzeigen' in norm(t)]
  rows.append({'api':api,'frame':index,'variant':name+'-1x','command':cmd,'exit':r.returncode,'seconds':time.monotonic()-t,'stderr':r.stderr,'matching_lines':matches,'observed_lines':texts})
(d/'experiment.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n');print(json.dumps([{k:r[k] for k in ['api','frame','variant','exit','seconds','matching_lines']} for r in rows]))
