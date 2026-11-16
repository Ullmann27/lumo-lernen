# Permission reader: actual XML Element regression

Original replay **43781148281**, Android job **133018387128**, artifact
**14188204109**: ZIP **13,415,788 bytes**, SHA-256
`3764ad4df03464c277d7340beaa487eccfc1e64230155ea757164e1083e97a87`.
The unchanged APK source is `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242`,
native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.

## Actual failure and original fixture

`0139-microphone-outcome.xml` is a byte-identical copy of the complete recorded
permission hierarchy, **30,798 bytes**, SHA-256
`3b4d7f4b79585edb0bbeb0e7e7bcdc102cd06e1b797c213dc60b8f34845e6e6b`.
It exposes the visible Lumo Lernen Neu record-audio question and one enabled
“While using the app” button at `(137, 1127, 943, 1281)`.
The original run failed before tapping it: `TypeError: element indices must be
integers` in `observed_microphone_allow`, at `node["package"]`.

The prior pure permission tests incorrectly used dictionaries. The actual
`pr207_android_ui_probe.live_nodes` returns `xml.etree.ElementTree.Element`
objects, whose attributes are read with `.get()`.

## Exact narrow correction and evidence

Only three reader expressions change from `node["package"]` to
`node.get("package")`. The 35-second deadline, permission/app identity,
visibility, ambiguity rejection, deduplication, one-tap policy, fresh transition
requirement and all learning/audio/performance gates remain unchanged.

The new regression executes `LearningProbe.nodes` and the actual unchanged
`pr207_android_ui_probe.live_nodes` function. Only its Android transport returns
the original recorded XML; parsing and Element iteration are the real runtime
code. The fixture is never converted into dictionaries. All 14 earlier synthetic
permission cases now also explicitly use Element nodes.

- `permission-element-red.log`: the new original-parser case fails on the old
  reader from `a6ff8f6dc1c99f9ed962233d5ebdb3adcf4f7f0f` with the exact runtime
  `TypeError` at line 233.
- `permission-element-green.log`: **64/64 PASS** in the complete existing
  `test_nextgen_learning_android_probe.py` module after the three-line fix.
- `manifest.json`: original artifact identity, exact fixture/log/source hashes.

No new Android run, actual permission grant or microphone result is claimed.
The post-dialog app nodes in the unit flow remain explicitly synthetic; the
unchanged APK still requires a complete real replay.

Reproduction:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tools/android_qa/tests/test_nextgen_learning_android_probe.py -v
```
