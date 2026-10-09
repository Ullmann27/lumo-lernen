import re, sys, os
from pathlib import Path
root = Path('/home/user/lumo-lernen')
lib = root/'lib'
pkg = 'lumo_lernen'
files = {p.relative_to(root).as_posix() for p in lib.rglob('*.dart')}
pat = re.compile(r"""^\s*(?:import|export|part)\s+(?:deferred\s+)?['"]([^'"]+)['"]""", re.M)
def targets(f):
    text = (root/f).read_text(encoding='utf-8', errors='replace')
    # conditional imports: also capture "if (...) 'path'" alternatives
    out = []
    for m in re.finditer(r"""(?:import|export|part)\s+['"]([^'"]+)['"]([^;]*);""", text):
        out.append(m.group(1))
        for alt in re.findall(r"""['"]([^'"]+\.dart)['"]""", m.group(2)):
            out.append(alt)
    res = []
    for t in out:
        if t.startswith('dart:'): continue
        if t.startswith(f'package:{pkg}/'):
            p = 'lib/' + t[len(f'package:{pkg}/'):]
        elif t.startswith('package:'):
            continue
        else:
            p = os.path.normpath(os.path.join(os.path.dirname(f), t)).replace('\\','/')
        if p in files: res.append(p)
    return res
seen = set(); stack = ['lib/main.dart']
while stack:
    f = stack.pop()
    if f in seen: continue
    seen.add(f)
    stack.extend(targets(f))
dead = sorted(files - seen)
print('lib files:', len(files), 'reachable:', len(seen), 'unreachable:', len(dead))
for d in dead: print(' ', d)
