# C4 asynchronous open/close integration plan

**Goal:** A cancelled or failed native C4 opening must not leave authority alive, start polling after cancellation, or race a subsequent opening.

**Architecture:** Preserve the existing real ConnectFourRoundController, private transport, Flutter-first entry, save keys and rewards. Port the bounded opening-generation and closing-future discipline already used by MemoryTableSession to ConnectFourTableSession. Do not change the Android/Godot protocol or claim the user's physical crash is fully diagnosed.

**Tech stack:** Existing Dart/Flutter 3.44.9; existing C4 tests and transport abstraction. No additional package.

**Source:** Host 6f4a8c4753f4d06d0b392da0789b8162b2faa71b, Native d38967f6d39bc20188afe525b0af122d80634029. The target NextGen integration is PR511. Its C4 session blob fd8efe8e114de656b6802e097b96910535d83c39 is identical to this baseline. Keep other teams' learning/voice/fox and Kart/Jungle code untouched.

## Execution
- [ ] Add deterministic delayed-transport tests using the real round controller and an in-memory store; publish before product edits.
- [ ] Execute the new tests against the unchanged production session. Preserve genuine failure logs; compiler/infrastructure errors do not count as reproductions.
- [ ] Guard concurrent opens before the first await, invalidate pending opens on close, clean the exact token after failed/late open, and await the same closing operation.
- [ ] Rerun the identical tests plus existing C4 game/session/route tests and the full Flutter suite.
- [ ] Read back published source; hand the isolated change to PR511 with actual test status and unchanged native pin.

## Tests and failure boundaries
`test/games/connect_four_open_close_race_test.dart` must cover close during settlement, close while native open is held, simultaneous opens, open during a held close, repeated close, lost open acknowledgement, profile revocation, and normal request/ACK operation. Original game and reward assertions remain in existing suites.

Cancellation must be visible immediately in isOpen/canDrop, even while platform cleanup is pending. Cleanup affects this session's token only. A late response must never create a timer. A failed close cannot be represented as confirmed native cleanup; the original transport policy is retained and its limitation remains documented.

## Delivery boundary
No main merge or version/pin/signature change. Targeted transport tests are not Android Binder/device/FPS proof. A joined NextGen build also has unrelated upstream integration failures (including the pattern activity contract); those are tracked on PR511 and must not be hidden by this support repair.
