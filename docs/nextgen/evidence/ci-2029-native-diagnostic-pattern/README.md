# 2029 native pattern diagnostic: original FAILED evidence

This is a diagnostic-only run of the unchanged existing 2029 APK. It cannot accept or publish 2029 or 2030. The original complete 2029 Android failure remains unchanged.

The exact current screen visibly contains Was / kommt als Nächstes? over two lines. The original native_text reader searches one OCR line at a time, so it did not accept the full question. Later group-hint and proposal gates were not reached; this diagnostic remains FAILED.

Run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43790709991

QA commit: `e04e29437e2c28f40e492191f430cd49ddc456fa`. APK source: `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc`. Native source: `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. API35 x86_64 emulator, Pixel5 profile, llvmpipe software renderer; no physical-device claim.

The entire original artifact ZIP is retained in consecutive parts described by `archive-reassembly.json`; all original members and hashes are in `artifact-verification.json`. `selected-original` contains byte-identical copies for inspection. The complete original job log is losslessly gzipped; its decoded bytes and SHA-256 are recorded in `summary.json`. Native screen recordings contain no audio track.
