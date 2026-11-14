# PR483 console launch: original failure and parser repair

This pack binds QA `7e2ab20f6f323c66a1e02de3550d73ef31b2037e`, tree `b9d21ad6c3fd3588ea1906549afaa516a95874b4`, run `43566692796`, attempt 1.

All three original API37 archives were checked in memory against exact API size and SHA256 before parsing. Every member passed CRC and SHA256 inventory. The full ZIPs are retained only in their original Actions artifacts; the selected files here are unchanged original bytes. No signed transport URL is included.

Actual transcripts contain BEGIN and END:1. Bare CR terminal redraws caused the old parser to stop before those complete LF lines. The narrow patch preserves bytes and offsets, observes LF-only completion and keeps nonzero/duplicate/reordered/foreign acknowledgements rejected. The genuine inner Exit1 is still a failure. Its exact failed command remains unknown because the original start path captured no launch/session files after CONSOLE.start failed.

The original parser reproduces three real negative-subcase failures. The repaired parser passes 15 focused local contracts, with zero skips. Synthetic success-neighbour bytes are explicitly identified and are not device evidence. No emulator was launched, no ANR or identity guard was changed, and no device success is claimed.

Use `handoff.json`, `diagnosis.json`, both unedited raw validation logs and `source-freeze-parser-v1.json`. `compact-evidence.tar.gz` contains every indexed original/source/log file; `archive-roundtrip.json` records complete byte verification. Private signed download URL files were never included.
