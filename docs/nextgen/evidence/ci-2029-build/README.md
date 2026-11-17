# Actual 2029 signed APK build and byte verification

Run [43785937519](https://github.com/Ullmann27/lumo-lernen/actions/runs/43785937519), job 133037491223: success. APK source `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc`; native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`; version `0.13.17+2029`.

ARM64: 535,021,166 bytes, SHA-256 `bc8fdd9c1f70d7d6e374b5424029e127531525deb4f2dec1e69de4ea8f6ee0c3`. x86_64: 538,184,171 bytes, SHA-256 `01e0c126930b48cb8089f0671ed9238b5dc6ded903e288ad7c1fda452ed3cf0f`. Both contain the same native pack, SHA-256 `9aeb88d1dc52f612ea591c04d7651ccc3eef8b807b33b8b78c2f82b4e4eea303`, 278,589,612 bytes.

Package `dev.ullmann.lumo.lumo_lernen.coachpreview`; preserved test certificate SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Actual verifier results confirm minimum API 24, target API 36, requested ABI, 16 KiB ELF alignment, resource alignment, exact native pin, offline voice assets and original notice hashes. This is test signing, not Play production signing or a physical ARM64 run.

All five original build-proof artifact members are retained unchanged. The original ZIP is 63,014 bytes with SHA-256 `46adb115d52fbbcc2cab9490a34576bc467cef0e9dc66a64de4bf2fdfca3dfbc`. The complete decoded job log is retained losslessly as gzip, with byte/hash/roundtrip verification.

The actual 535,035,272-byte ARM64 artifact ZIP was additionally downloaded in full locally, its GitHub digest confirmed, every APK byte hashed and all archive CRCs verified. Its three original metadata files and exact validation script are retained under local-arm64-byte-check/. No APK was written to disk, and apksigner was not rerun locally; the original CI signature checks remain separately identifiable. This is not the later anonymous public download check.

The Android tour is running at the time this build checkpoint is written. No Android PASS or new public APK URL is asserted here. Historical 2028 artifacts and failed runs remain unchanged.
