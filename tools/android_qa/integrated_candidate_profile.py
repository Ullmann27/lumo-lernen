"""Explicit 2021 execution scope; importing this module never changes old gates.

The historical 2020 entry points retain their original default. Only the new
2021 commands enter this scope, which binds a separate workflow, branch and
artifact family and restores every shared verifier setting on exit.
"""
from contextlib import contextmanager
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
VERSION_CODE = 2021
WORKFLOW = '.github/workflows/lumo-integrated-2021.yml'
BRANCH = 'integration/lumo-complete-apk-20261114-7a1'
PREFIX = 'lumo-integrated-2021'
AUTHORITY_STEPS = {
    'english': ('Exercise English meshes with actual host producer output',),
    'quiz': ('Play all twenty Quiz questions through the real Dart and Godot processes',),
    'memory': ('Reject inconsistent Memory pair evidence',
               'Render the actual Memory geometry and touch layouts',
               'Play Memory through the actual Dart and Godot processes'),
}


def _name(value):
    return (value.replace('lumo-connect-four-2020', PREFIX)
            .replace('.github/workflows/lumo-connect-four-2020.yml', WORKFLOW)
            .replace('update-2020-from-2017', 'update-2021-from-2017')
            .replace('in-place 2020 upgrade', 'in-place 2021 upgrade')
            .replace('UPDATE-2020-RESULT.json', 'UPDATE-2021-RESULT.json'))


@contextmanager
def candidate_scope(*, delivery=False, complete=False):
    import connect_four_android_evidence as c4
    changes = [(c4, {
        'VERSION_CODE': VERSION_CODE, 'WORKFLOW': WORKFLOW,
        'BRANCH': BRANCH, 'ACCEPTED_BRANCHES': frozenset((BRANCH,)),
        'ALLOWED_BRANCHES': frozenset((BRANCH,)),
        'CANDIDATE': PREFIX + '-candidate',
        'NATIVE_ENTRY_LABEL': 'In 3D weiterspielen',
    })]
    if complete or delivery:
        sys.path.insert(0, str(ROOT / 'scripts'))
        import verify_connect_four_candidate as candidate
        from integrated_candidate_evidence import verify_activities
        changes.append((candidate, {'ADDITIONAL_CHECK': verify_activities}))
    if delivery:
        import verify_connect_four_delivery as bundle
        required = {_name(key): tuple(_name(step) for step in steps)
                    for key, steps in bundle.REQUIRED_STEPS.items()}
        for activity, steps in AUTHORITY_STEPS.items():
            required[f'Nextgen {activity} actual authority'] = (
                'Resolve the exact candidate Host and configured Native commits',
                'Record exact sources and import the complete original native project',
                'Exercise the actual authority for this activity', *steps,
                'Verify both tracked source trees remain unchanged',
            )
        artifacts = tuple(_name(name) for name in bundle.ARTIFACT_NAMES)
        artifacts += tuple(PREFIX + '-nextgen-authority-' + activity
                           for activity in AUTHORITY_STEPS)
        changes.append((bundle, {
            'VERSION_CODE': VERSION_CODE, 'WORKFLOW': WORKFLOW,
            'BRANCH': BRANCH, 'ACCEPTED_BRANCHES': frozenset((BRANCH,)),
            'BUNDLE_ARTIFACT': PREFIX + '-delivery-bundle',
            'LEARNING_AUDIT_ARTIFACT': PREFIX + '-learning-curriculum-audit',
            'LEARNING_AUDIT_SOURCES': tuple(
                WORKFLOW if path == '.github/workflows/lumo-connect-four-2020.yml' else path
                for path in bundle.LEARNING_AUDIT_SOURCES),
            'DELIVERY_ASSETS': {_name(name) for name in bundle.DELIVERY_ASSETS},
            'ARTIFACT_NAMES': artifacts, 'REQUIRED_STEPS': required,
        }))
    original = [(module, {name: getattr(module, name) for name in values})
                for module, values in changes]
    try:
        for module, values in changes:
            for name, value in values.items():
                setattr(module, name, value)
        yield
    finally:
        for module, values in reversed(original):
            for name, value in values.items():
                setattr(module, name, value)
