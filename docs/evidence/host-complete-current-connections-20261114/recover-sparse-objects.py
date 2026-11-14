#!/usr/bin/env python3
"""Rebuild private sparse validation clones from exact published Git objects.

Original checkouts, refs and working files are never changed. Missing excluded
evidence blobs remain explicitly listed until recovered; active source must be
present before checkout or validation.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def git(repo, *args, data=None, check=True):
    return subprocess.run(['git', *args], cwd=repo, input=data,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          check=check).stdout


def object_hash(kind, data):
    return hashlib.sha1(kind.encode()+b' '+str(len(data)).encode()+b'\0'+data).hexdigest()


def write_object(repo, kind, data, expected):
    if object_hash(kind, data) != expected:
        raise ValueError('Original object identity differs: '+expected)
    actual=git(repo, 'hash-object', '-w', '-t', kind, '--stdin', data=data).decode().strip()
    if actual != expected:
        raise ValueError('Git object write identity differs: '+expected)


def import_tree(repo, leaves, expected):
    root={}
    for path, entry in leaves.items():
        node=root
        parts=path.split('/')
        for part in parts[:-1]:
            node=node.setdefault(part,{})
        node[parts[-1]]=entry
    def descend(node):
        records=[]
        for name, value in node.items():
            directory='sha' not in value
            sha=descend(value) if directory else value['sha']
            mode='40000' if directory else value['mode'].lstrip('0')
            order=(name+('/' if directory else '')).encode('utf-8')
            data=mode.encode()+b' '+name.encode('utf-8')+b'\0'+bytes.fromhex(sha)
            records.append((order,data))
        data=b''.join(record for _,record in sorted(records))
        sha=object_hash('tree',data)
        write_object(repo,'tree',data,sha)
        return sha
    actual=descend(root)
    if actual != expected:
        raise ValueError('Complete remote tree identity differs: '+actual)


def import_commit(repo, record):
    if record.get('verification',{}).get('verified'):
        raise ValueError('Signed commit needs its original signature bytes')
    first='tree '+record['tree']['sha']+'\n'
    first+=''.join('parent '+parent['sha']+'\n' for parent in record['parents'])
    matches=[]
    for author_zone in ('+0100','+0000'):
        for committer_zone in ('+0100','+0000'):
            value=first
            for label,zone in (('author',author_zone),('committer',committer_zone)):
                person=record[label]
                epoch=int(datetime.fromisoformat(person['date'].replace('Z','+00:00')).timestamp())
                value+=f"{label} {person['name']} <{person['email']}> {epoch} {zone}\n"
            for ending in ('','\n'):
                data=(value+'\n'+record['message']+ending).encode('utf-8')
                if object_hash('commit',data)==record['sha']:
                    matches.append(data)
    if len(matches)!=1:
        raise ValueError('Exact unsigned original commit bytes not uniquely recovered')
    write_object(repo,'commit',matches[0],record['sha'])


def present(repo, hashes):
    hashes=sorted(set(hashes))
    lines=git(repo,'cat-file','--batch-check=%(objectname) %(objecttype)',
              data=('\n'.join(hashes)+'\n').encode()).decode().splitlines()
    return {sha for sha,line in zip(hashes,lines) if line==sha+' blob'}


def initialize(config,root):
    repo=root/config['name']
    if repo.exists():
        raise FileExistsError(repo)
    subprocess.run(['git','clone','--shared','--no-checkout','--quiet',config['source'],str(repo)],check=True)
    git(repo,'remote','set-url','origin','https://github.com/'+config['repository']+'.git')
    git(repo,'config','core.sparseCheckout','true')
    git(repo,'config','core.sparseCheckoutCone','false')
    source=Path(config['source'])
    pattern_path=git(source,'rev-parse','--git-path','info/sparse-checkout').decode().strip()
    original=Path(pattern_path) if Path(pattern_path).is_absolute() else source/pattern_path
    pattern=(repo/'.git/info/sparse-checkout')
    if original.is_file():
        shutil.copyfile(original,pattern)
    else:
        raise FileNotFoundError('Existing approved sparse patterns are unavailable')
    leaves={}
    for item in git(repo,'ls-tree','-rz','HEAD').split(b'\0'):
        if not item:
            continue
        meta,path=item.split(b'\t',1);mode,kind,sha=meta.decode().split()
        leaves[path.decode()]={'path':path.decode(),'mode':mode,'type':kind,'sha':sha}
    for checkpoint in config['checkpoints']:
        for entry in checkpoint['entries']:
            leaves[entry['path']]=entry
        import_tree(repo,leaves,checkpoint['tree'])
        import_commit(repo,checkpoint['commit'])
    known=present(repo,[e['sha'] for e in leaves.values() if e['type']=='blob'])
    missing=[e for e in leaves.values() if e['type']=='blob' and e['sha'] not in known]
    return {'name':config['name'],'repository':config['repository'],'repo':str(repo),
            'head':config['checkpoints'][-1]['commit']['sha'],
            'tree':config['checkpoints'][-1]['tree'],'missing':missing,
            'leaves':list(leaves.values()),'checkout_performed':False}


def main():
    parser=argparse.ArgumentParser();parser.add_argument('input',type=Path)
    args=parser.parse_args();plan=json.loads(args.input.read_bytes());root=Path(plan['root'])
    results=[]
    for config in plan['configs']:
        result=initialize(config,root);results.append(result)
        (root/(config['name']+'-object-recovery.json')).write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps({'repo':result['repo'],'head':result['head'],'tree':result['tree'],
                          'missing_blobs':len(result['missing']),
                          'missing_active':[e['path'] for e in result['missing'] if not e['path'].startswith('docs/')]}))
    (root/'object-recovery-index.json').write_text(json.dumps(results,indent=2)+'\n')


if __name__=='__main__':
    main()
