# Additional runtime cases on immutable APK 2031

This integration adds an independent Android workflow for four requested edge cases. It installs the already built, byte-verified `0.13.19+2031` x86 APK in a new emulator and creates a fictional profile through the real UI. It does not replace the complete original/reference replay, change the product, write private preferences or authorize publication. Its results must remain `release_eligible=false`.

## Exact component handoffs

| Component | Producer commit | Published API commit | Identical tree |
| --- | --- | --- | --- |
| Numeric correction and fresh active Flutter switch, including the separate capture-age fix | `ececc0f7f782a76c584c2c87fd1ce192d3dc7648` | `d05419d986d523d0905bb1016afeee6b10346c67` | `4f2d40dab8765d91dd905a6baa6f5746906b179f` |
| Native Banane slower playback and direct stop during current native playback | `9f9aa391e61720feb920bc908f448b6daf70a9e7` | `09f483b32d2308da9e14b4e53222c1849fff586e` | `fb4e0bcbde23eb4c87cdf2fdc442168593ab302d` |

The branches are `qa/lumo-2031-lab-runtime-cases-20261116` and `qa/lumo-2031-native-runtime-cases-20261116`. Original producer handoffs, including the superseded first numeric producer `9cfa4b0760403ac4b489bea440d3ea6040e09dc0`, are retained unchanged. Root verified the complete final 13-file manifests of each component against the committed blobs and integrated files. The source review also confirms byte equality of the 31 publisher-bound files and the four added original Banane fixtures against full-replay QA `c2518e4bad105fcc3d867ae54a5fc93744e03842`.

## Independent reviews and actual validation

`/root/learning` reviewed the final native helper without changing files or rerunning tests. It found no concrete blocker: current PID and a new, uncompleted playback ID are checked before and after OCR and again before the single direct stop; an expired observation, foreign ID or completion prevents input. At least five seconds without a new segment or completion of the stopped ID, a visible idle voice button and preservation of the model/data are required. The slower case requires the observed panel shortcut and four new ordered playback segments.

`/root/conversation` reviewed the final numeric/switch helper, including the separately reproduced and fixed slow-capture defect, plus Root's workflow and configuration. It found no concrete blocker. The 9+7 numeric grading, separate attempt identifiers, correction assistance and persisted journey counts agree with APK source `e05a96a52aaf57e466e79831f15aaffd144284ee`. Auto-read is changed and restored through visible settings. The complete capture-to-requested-touch interval is bounded by the existing one-second budget; input delivery is not claimed to be measured. The workflow has read-only permissions and no publication action.

Root ran the actual integrated seven workflow checker groups, including both new component modules, and retained all output in `integrated-199-host-gates.log`. The actual case configuration, native function imports, CLI and complete committed source boundary were also checked. The 199 host tests are neither additional Android executions nor a pass for the still-pending four cases. Owner test counts overlap this integrated count and must not be added to it.

## Scope of the four requested cases

1. Build the real 8+5 demonstration, proceed to the actual assessed 9+7 recall task, submit 15, then submit 16. Compare the two separate persisted attempts, supported correction and unchanged older records.
2. Build Banane, preserve explicit syllable replay by temporarily disabling automatic prose narration through the actual setting, then switch to unanswered Rakete while a fresh hierarchy simultaneously exposes an active syllable and enabled Next. Restore auto-read through the UI before native cases.
3. Open the real native Banane scene and use the observed question-panel `Langsamer` shortcut; require four new ordered MediaPlayer start/completion pairs and unchanged task/model on return.
4. Prepare the checked native why-two explanation, start a new replay, observe its current active identity and directly press `Stimme stoppen`, without opening the question menu during that playback.

Finite UI and MediaPlayer observations do not establish recognized speech, acoustic pronunciation/speed, physical-device rendering, atomic Android event delivery, or simultaneous millisecond-level audio/mouth/gesture stopping. Missed playback and slow observation fail closed. The complete original/reference replay remains an independent prerequisite for the existing APK publisher.
