# Memory reader fixtures

These are original local Dart/Godot CI observations from Native 9f2e865614262c7176f9fdd987766ff5e45f2551 with Host c0ca5265eb4159e6848317da5f49edabaa75bfa0, Run 43603969762, Memory job 132474493500. They are not Android observations.

Artifact 14117292610 has 3,943,945 bytes and SHA256 4b812683569e29cb00e5f019ed4ebd579459decf8db4f658c46a1355bd677505. The single original ZIP was checked for complete SHA/CRC.

- layout-hidden.json is the exact memory-pair/native/01-memory-real-hidden.layout.json.
- layout-face.json is the exact memory-pair/native/02-memory-real-face.layout.json.
- saved-paused.json is the exact memory-pair/authority/unfinished-reopen-before-round.json.
- public-states.json is a documented JSON selection from the original authority-result.json: states[0].state, states[2].state, states[7].state, states[12].state and requests[0].request. Selection changes JSON formatting but not values; provenance binds the original full-file hash.

Android validation rejects observation_source=platform_fixture by default. Tests explicitly allow it for independent geometry checks. The page transport test marks a synthetic observation as Android to exercise retry ordering, and the bot test adapts a transport identity to omit the original intervening pause/reopen. Neither is an Android execution result.
