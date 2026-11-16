# LUMO learning generation — shared contract v1

Coordinator branch: `integration/lumo-learning-generation-20261115-ea41`.
Verified host baseline: `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`.
Verified native baseline: `d38967f6d39bc20188afe525b0af122d80634029`.
These are the existing integrated family host and its exact Godot pin, before
the separate Dschungelherz work. Neither main branch is an integration target.

## Ownership and delivery

| Responsibility | Branch | Owned files |
| --- | --- | --- |
| Coordinator / Android | integration/lumo-learning-generation-20261115-ea41 | this contract, launcher, native activity descriptor, Android host, build and integration evidence |
| Learning implementation | work/lumo-nextgen-learning-20261115-ea41 | learning/tutoring/section screens, module frame, coverage inventory and their tests; no protected writing/journal internals |
| Conversation | work/lumo-nextgen-voice-20261115-ea41 | core conversation/context/companion logic, companion request bus, new typed session contract, conversation UI and tests |
| Native figure / scene | work/lumo-nextgen-avatar-20261115-ea41 | Godot learning scene, learning activity/contract, teacher actor and native regression/capture tools |

Separate user chats can deliver independent branches against this contract.
The table records this coordinator's actual helper work, not a claim that
external chats have received or approved it. Integration requires exact SHAs.
Kart and jungle files are outside this change. Existing profile, task, reward
and durable storage identities remain authoritative and unchanged.

## Wire envelope (additive version 1)

`protocolVersion: 1` identifies this contract. The shared identity is
`sessionId`, `taskId`, `revision`, `cancelEpoch`; an optional `stepId` identifies
the explanation step. `sessionId` is opaque and local, not a child's name.
`taskId` is the existing domain identity. `revision` changes on a semantic
task/step snapshot change. `cancelEpoch` increases on every interruption.

All asynchronous actions carry the captured identity. A receiver accepts them
only when all identity fields still match. A task change, profile change,
page exit, app interruption or explicit stop invalidates outstanding work.
Within one task, a new explanation does not erase the child's earlier question.
An old response may never modify a new task or restore stopped animation.

Each task can provide `stepId`, `objectIds`, `explanation`, `errorType`,
`answerChoices` and `allowedActions` in its companion context. Object IDs name
renderer-owned objects; positions are resolved by the scene. No model-supplied
world coordinates, reward changes or evaluation result are accepted.

Allowed requests are `explain`, `repeat`, `slower`, `hint`, `highlight`, `point`,
`look`, `stop`, `proposeAnswer`. `proposeAnswer` only fills a visible candidate;
the existing task controller confirms and evaluates it through its normal path.
Uncertain speech and corrections remain visible and editable before scoring.
Only the task engine supplies `correct`, `errorType`, next permitted hint,
progress and rewards. Assessment mode retains existing no-help boundaries.

## Conversation and actual audio

`turnId` scopes one question/answer. `utteranceId` scopes one playback.
Text/subtitles may be ready before audio. Playback exposes real state,
`positionMs`, `durationMs`, `audible`, `envelopeAvailable`, and `envelope`.
Mouth movement uses those real samples, never an invented reading timer.
`mouthTiming: envelope` means amplitude only; absent phoneme/word timestamps
must be represented as unavailable. A speaking label is not playback evidence.

Stop is one semantic operation: invalidate generation and cancelEpoch, cancel
pending inference/recognition, stop audio, close mouth, cancel related gesture,
and clear/neutralize the teaching target. Starting a replacement narration must
not accidentally cancel its newly requested gesture. Resume requires a fresh
current-context utterance; no automatic replay of cancelled audio.

## Required joined examples

1. Eight plus five: `ten_frame`, `addend`, `bridge_two`, `remainder_three`.
   Explain that 10 minus 8 equals 2; move exactly two objects, leave three.
2. Banane: `syllable_0`, `syllable_1`, `syllable_2` for Ba–na–ne. Repeat and
   slower speech preserve the same checked syllable data.
3. Repeating pattern: `pattern_group`, `pattern_next`, indexed pattern objects.
   A hint identifies the group without submitting the child's answer.

## Verification boundary

The coverage inventory must list actual entry routes, including general tasks,
specialist modules, guided lessons, lab, cross-grade practice and reading.
Unreachable or unadapted rows stay open. Tests must cover wrong answer,
misrecognition/correction, stop, task switch, lifecycle interruption and resize.
Desktop/CI renders are labelled as such and are not Fold7 performance evidence.
