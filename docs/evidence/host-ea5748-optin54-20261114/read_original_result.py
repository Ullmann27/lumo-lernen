#!/usr/bin/env python3
"""Read the completed original unittest stream; never rerun a method."""
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parent


def identity(data):
    return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),
            'git_blob':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}


def main():
    result=json.loads((ROOT/'runs/result.json').read_bytes())
    raw=(ROOT/'runs/stderr.original').read_bytes()
    expected=json.loads((ROOT/'expected-methods.json').read_bytes())
    records=[]
    pending=None
    for number,line in enumerate(raw.decode('utf-8').splitlines(),1):
        match=re.fullmatch(r'(test_\w+) \(([\w.]+)\) \.\.\.(?: (.*))?',line)
        if match:
            assert pending is None, 'Another method started before the previous original status'
            name,identifier,tail=match.groups()
            assert identifier.endswith('.'+name)
            pending={'id':identifier,'start_line':number,'original_start_line':line,
                     'interleaved_original_lines':[]}
            if tail=='ok':
                pending.update(result='ok',completion_line=number)
                records.append(pending);pending=None
            elif tail:
                pending['interleaved_original_lines'].append({'line':number,'text':tail})
        elif pending is not None:
            if line=='ok':
                pending.update(result='ok',completion_line=number)
                records.append(pending);pending=None
            else:
                pending['interleaved_original_lines'].append({'line':number,'text':line})
    assert pending is None, 'An original method has no success completion'
    ids=[record['id'] for record in records]
    assert len(ids)==len(set(ids))==54 and set(ids)==set(expected)
    assert re.search(r'(?m)^Ran 54 tests in [0-9.]+s$',raw.decode('utf-8'))
    assert re.search(r'\nOK\s*\Z',raw.decode('utf-8'))
    assert result['actual_returncode']==0 and result['outer_timeout'] is False
    assert result['checks']['sources_unchanged'] is True
    assert (ROOT/'inventories/before.json').read_bytes()==(ROOT/'inventories/after.json').read_bytes()
    interleaved=[record for record in records if record['interleaved_original_lines']]
    assert len(interleaved)==1
    assert interleaved[0]['id'].endswith('.CompleteEvidenceTests.test_complete_synthetic_observation_replay')
    assert len(interleaved[0]['interleaved_original_lines'])==2
    assert 'DeprecationWarning: Image.Image.getdata is deprecated' in interleaved[0]['interleaved_original_lines'][0]['text']
    assert interleaved[0]['interleaved_original_lines'][1]['text'].strip()=='sampled = list(image.crop(box).getdata())'
    counts={}
    for identifier in ids:
        module=identifier.rsplit('.',2)[0]
        counts[module]=counts.get(module,0)+1
    report={'status':'PASS','scope':'One completed local synthetic Python contract run; read-only accounting of its unchanged original stream.',
            'actual_test_exit_code':result['actual_returncode'],'test_runs':1,'tests_repeated':False,
            'completed_methods':54,'counts_by_module':counts,'skipped':0,'expected_failures':0,
            'all_expected_ids_completed_once':True,'sources_unchanged':True,'method_original_lines':records,
            'original_stdout':identity((ROOT/'runs/stdout.original').read_bytes()),'original_stderr':identity(raw),
            'original_result':identity((ROOT/'runs/result.json').read_bytes()),
            'outer_recorder_diagnostic':{
                'original_status_preserved':result['status'],
                'reason':'The original one-line accounting regex counted 53: one Pillow warning split a method start and its genuine following ok into separate lines.',
                'correction':'This separate read-only parser binds both original line numbers and all 54 exact method IDs; no test, source or original output was changed.'},
            'no_android_flutter_engine_device_fps_or_release_claim':True}
    data=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
    with (ROOT/'original-result-reconciliation.json').open('xb') as stream:
        stream.write(data)
    assert (ROOT/'original-result-reconciliation.json').read_bytes()==data
    print(json.dumps({'result':identity(data),'completed_methods':54,'counts':counts,
                      'original_test_returncode':result['actual_returncode'],'source_invariance':True}))


if __name__=='__main__':
    main()
