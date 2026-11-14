# Exact PR502 manifest integration

Host preimage e53669a2e06d1832cc6844dbe1077d652551fdb8, tree 5cf2f3bc7d062d44b12c0b5370c827a07c3002c1. Producer eb59c2f6c35361e50c3d9e474a2c7a366b7a35ab.

Only the two exact producer hunks were applied to the newer host sources. The Table Activity, private Cards/C4/Table authority services, Kotlin/Java templates, R8 rules and build logic were preserved byte for byte outside those hunks. The manifest adds one POST_NOTIFICATIONS declaration before application when absent; no runtime permission request or grant was added.

The existing EmbeddedAndroidTest class ran once against all 12 byte-bound current templates. Its single manifest, service, generation and repeatability case passed, with exit 0 and unchanged 14-file execution inventory. The four unchanged JVM window cases were not rerun. No Android/emulator acceptance is inferred from this unit-level result. The next complete APK build and actual Android/update gates remain mandatory.

All preimages and full producer postimages are retained. The source payload is exact provenance data, not an independently executed product.
