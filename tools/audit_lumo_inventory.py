"""Read-only Git/tree inventory. Differences are candidates, not lost features.

Run from lumo-lernen: python tools/audit_lumo_inventory.py ../lumo-godot
Does not fetch, checkout, launch games, build Android or modify product files.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

APP_BASE = 'd7440beaba78992ee36c8f4be1513e6b5006c1f6'
GODOT_BASE = 'ec96515a2e359d21e9591120fc81dfd15116e81e'
OUTPUT = Path('docs/audit/2026-10-13')


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True)


def tree(repo, ref):
    result = {}
    for line in git(repo, 'ls-tree', '-r', ref).splitlines():
        info, path = line.split('\t', 1)
        result[path] = info.split()[2]
    return result


def inventory(repo, base):
    baseline = tree(repo, base)
    branches = []
    for line in git(repo, 'for-each-ref', '--format=%(refname:short) %(objectname)',
                    'refs/remotes/origin').splitlines():
        ref, sha = line.split()
        if ref == 'origin':
            continue
        files = tree(repo, sha)
        missing = {p: h for p, h in files.items() if p not in baseline}
        changed = {p: h for p, h in files.items()
                   if p in baseline and baseline[p] != h}
        ancestor = subprocess.run(['git', '-C', str(repo), 'merge-base',
                                   '--is-ancestor', sha, base],
                                  capture_output=True).returncode == 0
        branches.append({'branch': ref.removeprefix('origin/'), 'sha': sha,
                         'ancestor_of_audited_base': ancestor,
                         'files_absent_from_base': sorted(missing),
                         'different_blobs': sorted(changed)})
    historical = []
    for line in git(repo, 'for-each-ref', '--format=%(refname) %(objectname)',
                    'refs/audit/pr').splitlines():
        ref, sha = line.split()
        files = tree(repo, sha)
        historical.append({'pr': int(ref.rsplit('/', 1)[-1]), 'head_sha': sha,
                           'files_absent_from_base': sorted(p for p in files if p not in baseline),
                           'different_blobs': sorted(p for p, h in files.items()
                                                     if p in baseline and baseline[p] != h)})
    return {'audited_sha': base, 'base_files': baseline, 'branches': branches,
            'historical_pull_request_heads': historical}


def dart_graph():
    files = {str(p): p.read_text() for p in Path('lib').rglob('*.dart')}
    edges = {}
    for path, content in files.items():
        imports = re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)", content)
        dests = []
        for target in imports:
            if target.startswith('package:lumo_lernen/'):
                dest = Path('lib') / target.removeprefix('package:lumo_lernen/')
            elif ':' not in target:
                dest = Path(path).parent / target
            else:
                continue
            dest = Path(__import__('os').path.normpath(dest))
            if str(dest) in files:
                dests.append(str(dest))
        edges[path] = dests
    queue, reached, chains = ['lib/main.dart'], set(), {'lib/main.dart': ['lib/main.dart']}
    while queue:
        current = queue.pop(0)
        if current in reached:
            continue
        reached.add(current)
        for dest in edges.get(current, []):
            if dest not in chains:
                chains[dest] = chains[current] + [dest]
                queue.append(dest)
    return {'warning': 'Import reachability is NOT proof of menu/action reachability.',
            'files': {p: {'import_chain': chains.get(p),
                          'test_references': [str(t) for t in Path('test').rglob('*.dart')
                                              if p.removeprefix('lib/') in t.read_text()]}
                      for p in files}}


def asset_inventory(repo, baseline):
    text_files = [p for p in Path(repo).rglob('*') if p.is_file()
                  and p.suffix in {'.dart', '.gd', '.tscn', '.tres', '.json', '.yaml'}
                  and '.git' not in p.parts]
    content = '\n'.join(p.read_text(errors='replace') for p in text_files)
    return [{'path': p, 'blob': h, 'literal_reference': p in content or 'res://' + p in content,
             'warning': 'No literal reference does not exclude computed registry/dynamic loading.'}
            for p, h in baseline.items() if p.startswith('assets/')]


def main():
    godot = Path(sys.argv[1])
    OUTPUT.mkdir(parents=True, exist_ok=True)
    app = inventory(Path('.'), APP_BASE)
    game = inventory(godot, GODOT_BASE)
    for name, value in [('app-branches', app), ('godot-branches', game),
                        ('dart-import-and-test-index', dart_graph()),
                        ('app-assets', asset_inventory('.', app['base_files'])),
                        ('godot-assets', asset_inventory(godot, game['base_files']))]:
        (OUTPUT / (name + '.json')).write_text(json.dumps(value, indent=2) + '\n')
    summary = {'app_branches': len(app['branches']), 'godot_branches': len(game['branches']),
               'app_pr_heads': len(app['historical_pull_request_heads']),
               'godot_pr_heads': len(game['historical_pull_request_heads']),
               'app_files': len(app['base_files']), 'godot_files': len(game['base_files'])}
    (OUTPUT / 'inventory-summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary))


if __name__ == '__main__':
    main()
