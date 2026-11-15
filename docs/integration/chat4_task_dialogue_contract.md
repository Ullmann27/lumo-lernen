# LUMO Chat 4 — Task Dialogue Contract (15 Nov 2026)

Working branch: chatgpt/lumo-chat4-dialogue-20261115
Source branch: delivery/lumo-2023-complete-update-20261115 at 6f4a8c4753f4d06d0b392da0789b8162b2faa71b

## Current implementation

- Existing showLumoConversation opens LumoTaskConversationPanel only for an active lesson task belonging to the current profile and section; the general Lumo chat remains unchanged.
- LumoTaskDialogueEngine uses bounded, deterministic task phrasing. It handles 8+5 ten-frame hints, the verified German syllable spelling of Banane, level-gated repeating circle/triangle patterns, ASR corrections, stop, independent-work, repeat, slower playback and clarification of ambiguous selections. It is NOT an unrestricted local language model.
- LumoConversationController cancels stale tasks and provider responses, holds only four dialogue exchanges in RAM and never changes graded answers, awards or learning progress. Active task questions are not sent to the existing unverified online model.
- LumoTaskConversationPanel uses the existing Android on-device SpeechToText and LumoVoice with half-duplex turn-taking: explicit mic start; microphone closed before own voice begins; listen again after audio completion; stop, slower, repeat and text alternatives.
- No new audio provider, profile database or persistent transcript is introduced.

## Chat 1: integration owner

Keep this branch isolated until reviewed and merged into the agreed candidate. The task owner must publish LumoCompanionTaskContext on lesson opening and clear/update on navigation. Correct task ID and profile generation are mandatory to invalidate outdated dialogue. Do not modify application ID, game pins, existing learning data or signing.

Changed code paths:
- lib/app/lumo_companion_host.dart
- lib/features/agent/lumo_task_conversation_panel.dart
- lib/core/lumo_task_dialogue_engine.dart
- lib/core/lumo_conversation_controller.dart
- test/lumo_task_dialogue_engine_test.dart
- test/lumo_context_conversation_test.dart

## Chat 2: learning authority

The published LumoCompanionTaskContext provides: taskId, subject, unit, prompt, helpLevel, attempts, lastAnswer, previousHelp, localHelp, isExam, answering, ownerSection and profileGeneration. Correct answers and verified visual-object graph are not available to Chat 4. Chat 2 alone retains grading, reward and advancement. ASR correction is not a scored attempt. The first repeating-pattern hint does not disclose its cycle; level 2 is needed for naming the cycle. The 8+5 script uses two remaining ten-frame cells if the published task information supports them. For "die zwei da", Chat 4 asks which objects, until Chat 2 publishes stable visible object IDs.

## Chat 3: avatar cue contract

LumoConversationController.activeCue is ValueNotifier<LumoConversationCue?> with:
- utteranceId: opaque session:revision:round
- taskId: exact current lesson ID
- contextRevision: invalidates old cue on lesson changes
- subtitle: spoken sentence, including an optional syllable segmentation
- focus: semantic target currently "ten-frame", "syllables" or "pattern"

This cue is prepared before the audio operation and removed on interruption. Actual lip animation must check LumoVoice.instance.status == VoiceStatus.speaking and sample LumoVoice.instance.clipMouth. The envelope tracks media playback, not actual phoneme/viseme timing. Validate any focus semantic target against real visible scene objects; otherwise look toward the listener. 3D rig adaptation, gaze and facial motions are Chat 3 integration tasks and are NOT claimed as delivered in this isolated branch.

## Parent/privacy and offline guarantees

On-device STT is requested with onDevice true, but recognition depends on installed offline speech support on the Android device. Existing Lumo Frei clips or parent-authorized local synthesis handle TTS when available. Text and deterministic task help always remain accessible if microphone/network or voice fails. No new paid provider is enabled. No permanent raw recording or transcript database is introduced; history stays in memory and is cleared on scope changes and disposal.

## Reproducible acceptance scenes

1. Rechne 8+5; "Warum zuerst zwei?" explains two free places but not the final answer.
2. "Nein, ich meinte dreizehn" stays an ASR correction, no bad attempt.
3. "Banane": replay/slow matches Ba – na – ne visible segmentation.
4. "Stopp" during speech must stop player, mouth envelope and pending turn.
5. Task switch while waiting cancels outdated response and gaze cue.
6. Kreis-Dreieck-Kreis-Dreieck-Kreis: initial hint compares shapes, upgraded hint names the repeating pair.
7. Multi-turn, mic denied, offline and background; no lost progress or phantom speech.

Flutter tests and physical-device audio/video capture are separate acceptance gates. This branch was written through the GitHub connection and has not itself produced a verified Android recording, APK or proof of installed offline ASR/TTS. The existing 2D Lumo pose used in Flutter is not a verified Godot 3D facial-rig integration.
