"""Compare the actual Godot file readback against the installed host projection."""
from pathlib import Path
import inspect,json,sys
root=Path('/workspace/scratch/5987865ae883/lumo-studio-final-e3d')
sys.path.insert(0,str(root/'tools/android_qa'))
import nextgen_evidence as evidence
fixtures=root/'tools/android_qa/tests/fixtures/cards_safe_area_2019'
layout=json.loads((fixtures/'android35_portrait-playing.layout.json').read_text())
public=json.loads((fixtures/'public-fixture.json').read_text())
if hasattr(evidence,'require_cards_layout'):
    projected=evidence.require_cards_layout(layout,public,width=1080,height=2400,density=2.625,allow_fixture=True)['geometry']
else:
    projected=evidence.cards_projected_faces(1080,2400,2.625,len(public['hand']))
errors=[]
for actual,readback in zip(projected['hand'],layout['hand']):
    errors.extend(abs(a-b) for pa,pb in zip(actual,readback['quad']) for a,b in zip(pa,pb))
maximum=max(errors)
print(json.dumps({'actual_runtime_readback':'android35_portrait-playing.layout.json','projected_hand_max_error_px':maximum,'required_tolerance_px':0.002,'status':'PASS' if maximum<=.002 else 'FAIL'},indent=2))
if maximum>.002:raise SystemExit(1)
