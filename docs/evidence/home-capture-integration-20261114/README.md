# Scoped Home capture verification — 14 November 2026

After the atmosphere layout fix at
`69cadb6cad90c653cc044e8d073b06e5906ee97d`, the six-file Home/learning matrix
was attempted with all three capture environment variables enabled. It
completed 13 cases, then stopped producing output while loading the Home
premium-card capture file. The owned attempt was interrupted with exit 130,
before any PNG was produced. It is not an aggregate pass.

One targeted retry of the Home premium-card file in a fresh process passed
all five tests, exit 0, in 10.663 seconds and generated eight real PNGs.
The complete log was recovered from the execution-tool output after the second
environment failure. Its SHA256 exactly matches the original hash recorded
while the environment was still available:
`996cfa8106953bd83d0aed53250260ccb1ffcfcbcb3c11571b37e9e1408643bb`.

The capture manifest preserves the eight observed image hashes, dimensions
and sizes. All eight were checked by the independent QA agent before the
outage. The raw PNG files and complete pre-run source-fingerprint file are
currently inaccessible; this checkpoint does not fabricate replacements.

Six images were actually visually reviewed: both Fold-cover, both phone and
both Fold-open files. The Fold-open learning image shows readable subject
cards. The two Fold-cover images intentionally show the same simplified start
viewport. The phone pair also shows the same start viewport and therefore
does not prove a separate opened-subject capture. On the narrow cover image,
“Belohnungen” wraps with its final “n” alone; the game subtitle and Kart title
are shortened. These are recorded visual limitations, not a passing claim for
every label. The two large-text images were byte-checked but their visual
review was interrupted by the environment failure.

The complete Home/learning matrix, including the 80 module-capture cases with
LUMO_LEARNING_CAPTURE_DIR set, remains required on the final combined source
in CI. These are unretouched Flutter widget-runtime captures, not physical
Android recordings or performance measurements.
