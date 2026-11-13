# LUMO Studio: current source and execution record

## Verified baseline and ownership

On 13 November 2026 the GitHub connector and a fresh fetch both identified
`Ullmann27/lumo-lernen#461` at `3c712129fef8f144d8946fad567b9ed11c628a60`
and `Ullmann27/lumo-godot#157` at
`ada5ed81ad62339f15289da62670c0a4f9f7f2b9`. The older PRs 459/156 are
ancestors, not the source for new development. The ongoing 2018 release work
and the previous shared working copies are preserved.

This development uses a separate `chatgpt/lumo-studio-20261113` branch in each
repository. Main is not an integration destination. Three actual agents own
learning, original-character animation and puzzle/exploration respectively.
Root owns the Blender learning atelier, integration and acceptance. Shared
character APIs are consumed by the learning world; their implementations have
one owner. Source checkpoints are not quality or release approval.

## Observed capability matrix

| Capability | Classification | Observed tool or constraint |
| --- | --- | --- |
| Godot scenes, GDScript, shaders and meshes | directly implementable | Godot 4.6.3, current source and original assets available |
| Blender geometry and skeletal authoring | implementable with available tools | Blender 4.3.2 available; scripted actual geometry/animation export and CPU rendering |
| Flutter integration and tests | directly implementable | Flutter 3.44.9 / Dart 3.12.2 available in the existing toolchain |
| Native logic, collision and input regression | directly implementable | Real Godot execution, isolated application-data directories |
| Godot raster captures | implementable with available tools | GitHub X11/Mesa acceptance; local Xorg has no usable listening socket |
| Signed Android build and emulator | implementable with available tools | Existing immutable-source CI and Android/provenance gates; fresh candidate must pass |
| Target Fold7/Android 17 FPS, temperature and latency | currently blocked | No physical target device attached; software rendering is not a device measurement |
| Original face lip/eyelid articulation | currently blocked on asset work | Original inspected mesh has no facial morphs or jaw/eye/lid bones; body gestures do not prove facial animation |
| Game Development Studio CLI | currently unavailable | `game-dev` executable absent; explicitly requested native Blender/Godot tools remain available |
| Remote source preservation | directly implementable | GitHub connector creates blobs/trees/commits and expected-SHA ref updates; CLI push has no authentication |

The existing autosave script's read-only check was run in both workspaces.
Its automatic CLI-push watcher is unsuitable for this connection. Explicit
connector checkpoints preserve the owner-authorized files without staging
another agent's incomplete changes or changing a shared branch.

## Actual inherited product inventory

The detailed 2018 inventory remains in `docs/NEXTGEN_AUDIT_20261113.md`.
It lists the 20 Academy topics, seven previous native teaching concepts,
all ten games portals and additional games (including dice race, card
adventure and learning minigames). Existing writing, journal, children,
reading and evidence storage are retained. Their previous test counts are
historical evidence and will not be reported as new Studio tests.

## New development boundaries

* Learning: current multiplication, division and fraction tasks must generate
  mathematically exact native payloads; equal sharing is a genuine object
  interaction. A visit remains assistance, not independent mastery.
* Character: original 65-bone rest-space corrections and Blender-authored
  movement clips must run on the actual original actor. Preserve source GLB.
* Puzzle: rotation must affect geometry, snap eligibility, touch interaction
  and optional additive save state; legacy position-only puzzles still load.
* Atelier: Blender-authored architectural geometry must be loaded by the
  productive teaching scene, with measured mesh/material bounds and original
  lanterns retained. No image-generation output counts as renderer evidence.

## Acceptance status

Implementation and current-source tests are in progress. No Studio APK,
complete master-request acceptance, native raster approval or Fold7 result is
claimed by this initial record. Actual test logs, hashes, commits and any
blocked steps will be appended after execution.
