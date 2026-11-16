# Real resize capture boundary, 2026-11-16

The original 2030 Android run remains **FAIL**. The original MP4 contains exactly one decodable H.264 frame, no positive duration and empty recorder stderr. The existing probe started recording only after the display transition had settled.

The six-file QA component moves the existing recording and a real initial screenshot before the WM mutation, preserving all target WM/PNG, current-task, profile and progress gates. Actual ffprobe metadata is retained before its unchanged positive-duration gate. No new app input, retry, timeout or encoder configuration was added.

The producer ran three targeted host tests: the unchanged 93,539-byte original video still fails the actual recording finalizer; recording and initial capture must precede each existing layout change; wrong target pixels or altered progress still fail and restore the display. RED and the initial harness error are retained. These are recorded-fixture and constructed schedule tests, not a new Android replay.

The video encoder has fixed per-clip dimensions; the target display size remains independently checked with actual WM state and the full-size target PNG. No physical Fold7, new successful transition video or full-tour PASS is claimed here.
