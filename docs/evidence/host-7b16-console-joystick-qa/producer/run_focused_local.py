"""Run supported local contracts; do not represent this as the committed CI gate."""
import hashlib
import json
import os
from pathlib import Path
import sys
import unittest

PACK = Path(__file__).resolve().parent
VIEW = PACK / 'test-view'
os.chdir(VIEW)
sys.path.insert(0, str(VIEW))
sys.path.insert(0, str(VIEW / 'tools/android_qa/tests'))
modules = [
    'scripts.tests.test_console_joystick_workflow',
    'scripts.tests.test_verify_unchanged_apk_diagnostic',
    'scripts.tests.test_unchanged_creative_diagnostic',
    'scripts.tests.test_creative_evidence_parts',
    'scripts.tests.test_unchanged_apk_followup',
    'scripts.tests.test_runtime_followup_workflow',
    'scripts.tests.test_studio_creative_android_probe',
    'scripts.tests.test_studio_creative_runtime_repair',
    'scripts.tests.test_studio_creative_7b_repair',
    'scripts.tests.test_studio_joystick_portrait',
]
blocked = 'scripts.tests.test_verify_unchanged_apk_diagnostic.ApkContracts.test_full_preflight_keeps_qa_run_and_apk_source_separate'


def leaves(suite):
    for item in suite:
        if isinstance(item, unittest.TestSuite):
            yield from leaves(item)
        else:
            yield item


tests = list(leaves(unittest.defaultTestLoader.loadTestsFromNames(modules)))
assert sum(t.id() == blocked for t in tests) == 1
before = {str(p.relative_to(PACK)): hashlib.sha256(p.read_bytes()).hexdigest()
          for p in (PACK / 'final-source').rglob('*') if p.is_file()}
selected = [t for t in tests if t.id() != blocked]
print(json.dumps({'collected': len(tests), 'executed': len(selected),
                  'not_executed': [blocked],
                  'reason': 'Original earlier execution failed at strict git show HEAD in the explicitly git-free scratch overlay; unchanged full contract remains mandatory in the new committed CI.',
                  'earlier_error_log': 'validation/focused-contracts.log'}), flush=True)
result = unittest.TextTestRunner(verbosity=2).run(unittest.TestSuite(selected))
after = {str(p.relative_to(PACK)): hashlib.sha256(p.read_bytes()).hexdigest()
         for p in (PACK / 'final-source').rglob('*') if p.is_file()}
report = {'collected': len(tests), 'executed': result.testsRun,
          'failures': len(result.failures), 'errors': len(result.errors),
          'skips': len(result.skipped), 'not_executed': [blocked],
          'source_hashes_before': before, 'source_hashes_after': after,
          'sources_unchanged': before == after,
          'scope': 'Supported local contract subset only, not the complete mandatory committed CI gate or any device acceptance.'}
(PACK / 'validation/final-local-result.json').write_text(json.dumps(report, indent=2) + '\n')
sys.exit(0 if result.wasSuccessful() and not result.skipped and before == after else 1)
