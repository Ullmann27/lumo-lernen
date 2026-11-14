# Studio 28462: original API 35 failure

This dated package preserves the actual Android 15 emulator result for host `28462a7547048b75fa114e6f5832248e54c94faa` and native `29080ef8cd1a5b385eeeec97976fbefd31280427`. It does not claim acceptance of a later corrected candidate.

The general tour and the real Learning/Cards probe passed. Connect Four then failed during hub navigation: the probe sought `Vier gewinnt`, while the actual enabled tile exposes `Lumo 4 Gewinnt`. The complete intermediate XML and original image `0006` show the tile fully visible. Scrolling did occur; the earlier probe did not journal its direct ADB swipes. No Connect Four gameplay success, or later Quiz/Memory/English acceptance, is inferred.

The original job log and 24 complete original artifact members are preserved. Selected members were fetched through strict HTTP 206 ranges, fully inflated, CRC checked and SHA256 checked. The 196,404,454-byte complete ZIP was not downloaded; its published SHA256 is metadata, not a locally verified archive digest. Range reports preserve request boundaries and hashes. Raw compressed HTTP ranges are temporary analysis data and are not part of this Git package. One central-directory index is retained; the repeated identical indices are omitted.

Root personally viewed `0006-actual-c4-hub.png` and `failure-actual-screen.png`. The initial attempt to fetch `0006` after its temporary URL expired transferred zero bytes; that failed report is retained alongside the successful refreshed-reference report.

Original run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43626348519
