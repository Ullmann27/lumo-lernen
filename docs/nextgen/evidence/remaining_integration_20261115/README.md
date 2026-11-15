# Joined remaining learning routes

Environment: installed Flutter 3.44.9 / Dart 3.12.2, Linux widget-test runtime. These tests invoke the existing Android MethodChannel through a controlled test double. They do not prove a device, actual speech recognition or a rendered native scene.

- `mini_game_routes_initial.log`: 6/6 passed. All five existing mini-game entry screens complete every task, confirm answers explicitly, retain exact original wallet amounts, save once and reopen without a duplicate reward. Wrong answers remain on the current task; Stop discards a proposal.
- `remaining_native_joined.log`: 35/35 passed over the new native-boundary checks and existing CrossGrade, Photo, Story and MiniGame flows. The four actual entry buttons invoke `launch3D`, publish assistance before entry, preserve scope through native pause/return, and retain an ungraded candidate. Stop, stale confirmation callbacks, backgrounding and original domain/storage behavior are checked.

The first joined candidate exposed a real CrossGrade race: the interactive workspace announced the new explanation after rendering, and its owner published the step on the next frame. The launcher could otherwise capture the preceding step. The caller now waits for both frames and ignores hidden workspace updates during its native activity. MiniGame native return resumes its presentation clock while ordinary application pause remains paused. Photo and Story retain the exact owner context through their own native activity.

Earlier attempts are not acceptance evidence: the first new fixture was interrupted because an app instance was created in the test clock but awaited from runAsync; the fixture now creates it in runAsync. Android platform override cleanup was moved before Flutter's invariant check. No production assertion was removed to make these pass. One additional safe narrowing after the recorded 35-test run rejects case-normalized duplicate answer choices; final CI must validate the exact source commit again.

The initial C5 combined candidate had 44 passing tests and five failing entries (four obsolete MiniGame UI assumptions and one mismatched screenshot-helper call). The MiniGame tests now operate the actual persisted task deck and current controls. The screenshot-helper correction is in the separate conversation/quiz integration.

The 18 protected writing/journal sources were independently compared byte-for-byte with Flutter base 6f4a8c4753f4d06d0b392da0789b8162b2faa71b and remained unchanged. This is source/storage verification, not a physical-device upgrade result.
