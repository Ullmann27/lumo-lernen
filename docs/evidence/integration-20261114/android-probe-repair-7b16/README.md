# Android probe repair checkpoint for Host 7b16f2f5

This isolated source checkpoint is based on the exact tree of published Host
`7b16f2f5ab16f3d913ee170aefd9807c87216260`, Native
`17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`. It contains two observed
probe repairs and their actual original fixtures. It changes no app source,
APK, version, native pin, release permission or production branch.

## Driver-card observation

The API35 and update jobs in run `43540111465` both failed at the visible
Lumo driver card. Original OCR TSV word boxes distinguish the caption from
the fox icon; all existing anchor, confidence, ambiguity, fresh-frame and
subsequent race identity checks remain. Both original failures replayed
before the patch; the final focused suite passes 34 tests, with zero skips.
The 14 TSV files retain original empty final fields and therefore trailing
tabs deliberately. Original PNGs and OCR bytes are unchanged.

## Android17 readiness observation

The API37 originals use `systemReady` and omit legacy window-freeze and
credential-security fields. The observer now reads the actual current
InputDispatcher state, rejects disabled/frozen/ambiguous input and any ANR
history, and never treats an absent credential-security field as permission
to unlock. The existing 120-second readiness deadline and ten-second,
three-sample stability gate remain. The focused suite passes 29 tests.
Positive supplemental input dumps are explicitly synthetic; the original
failed job contains no input dump and cannot be reclassified as READY.

## Actual acceptance remains open

The original build and compile jobs succeeded. API35, API37 and update jobs
failed. API37 recorded a real Google Play services SIM_STATE_CHANGED ANR
before APK installation, independently of the parser defect. The current
Creative job was still running when this checkpoint was prepared.

These local tests and two independent reviews authorize a fresh isolated
Android diagnostic, not device acceptance or APK release. The next run must
retain the exact original APK identity and bind the repaired probe source
separately. A renderer experiment must retain strict ANR observation across
framework readiness, installation and the whole tour.

The source-freeze and handoff files preserve their original local path
references. The compact evidence copied here is byte-identical to those
records; it does not claim to include every file of the original Actions
archives. Original job/run/artifact IDs and hashes remain in the handoffs.
