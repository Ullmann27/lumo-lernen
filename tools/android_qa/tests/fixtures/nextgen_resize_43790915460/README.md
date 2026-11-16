# Original 2030 compact-resize recording failure

The MP4 is copied unchanged from run43790915460 / Android job133056371546,
artifact14192539626. Its exact source and hashes are in manifest.json.
It contains one actual decodable 720x1600 H.264 frame with timestamp0 and no
positive duration. The original recorder stderr was empty.

The probe started recording after WM size/density mutation and its existing
three-second settling delay. The two subsequent visible checks returned FOUND
without gestures; only a static view was captured. The original run remains FAIL.

The regression executes ffprobe on the original bytes and passes those same
bytes through the production recording finalizer using a clearly synthetic adb
transport. The unchanged positive-duration gate must still reject the file.
Separate constructed call-order tests require recording and an initial screenshot
before every WM mutation, preserve the target PNG/WM/profile/task checks, and
verify failure/restoration on changed target pixels or progress. These host
checks do not prove a repaired Android recording or a complete learning tour.
