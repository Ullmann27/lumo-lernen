"""Synthetic notice ZIP inputs, not license grants or signed APK evidence."""
import hashlib
import json


def fixture(native_source):
    sources = [
        ('host', 'assets/fonts/OFL.txt'),
        ('native', 'assets/fonts/Nunito-LICENSE.txt'),
        ('native', 'assets/characters/lumo_animated/ATTRIBUTION.md'),
        ('native', 'assets/characters/lumo_facial/ATTRIBUTION.md'),
        ('native', 'THIRD_PARTY_NOTICES.md'),
    ]
    entries, originals = [], {}
    for source, path in sources:
        data = f'Synthetic notice fixture: {source}/{path}\n'.encode()
        originals[(source, path)] = data
        entries.append({
            'source': source, 'path': path, 'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
        })
    policy = (json.dumps({'schema': 1, 'notices': entries}, indent=2) + '\n').encode()
    manifest = {
        'schema': 1,
        'policy_sha256': hashlib.sha256(policy).hexdigest(),
        'native_source': native_source,
        'notices': [
            {**entry, 'entry': 'assets/lumo_notices/' + entry['source'] + '/' + entry['path']}
            for entry in sorted(entries, key=lambda entry: (entry['source'], entry['path']))
        ],
    }
    members = {
        'assets/lumo_notices/' + source + '/' + path: data
        for (source, path), data in originals.items()
    }
    members['assets/lumo_notices/manifest.json'] = (
        json.dumps(manifest, indent=2, sort_keys=True) + '\n').encode()
    return policy, members, originals
