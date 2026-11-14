# Exact 7b16 diagnostic repairs after PR481 and PR482

This source checkpoint preserves the original results: PR481 Jump failed before its first joystick action; Build, Puzzle and Treasure passed. PR482 API35 and the real 2017-to-2019 update passed, while all three API37 jobs failed during logger setup after adb root. Neither old run is relabelled.

## Portrait observer

The two byte-identical PR481 frames show one 186 px outer ring on a 1080 by 1920 screen. The old height-based minimum was 249.6 px, so it rejected that ring. The minimum now uses the shorter screen dimension (140.4 px here), retaining the 65 px absolute minimum, connected cyan ring, circularity, occupancy, ring topology, lower-left region and exactly-one-match rules. The 57.75 px inner ring remains excluded. The seven focused contracts passed locally; the two fixture inputs are original images and resampled images are explicitly synthetic. This is an observer repair, not a fresh Android movement pass.

## Root continuity

The logger is launched only through the held private init-console channel, with the same all-buffer logger body and continuous marker/file/process/ANR gates. The exact console and adbd cgroups must be observed and distinct. Actual launch stdout/stderr are preserved separately from serial background output. Source and independent review are bound in the adjacent JSON files.

83 local supported tests passed with no skips. The three real Unix socket methods failed at the local system call with EPERM and remain mandatory in the full 86-case CI discovery. A fresh workflow must prepare the exact private socket before emulator launch and pass its shell-serial option. Actual emulator capability and survival across adb root remain unproven until that fresh run.

The APK remains Host 7b16 / Native 17f5 / version 0.13.7+2019. This checkpoint changes observation tools only. It is not a new APK, an Android17 acceptance, an audible-speech result or an FPS measurement.
