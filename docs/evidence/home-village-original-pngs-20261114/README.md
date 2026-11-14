# Original Home and Village PNG evidence — 2026-11-14

This dedicated evidence branch preserves ten original PNG files and their
original job logs. Its commit adds evidence only and does not change product
code, test code or workflows.

## Files

- home-original-pngs.tar.gz: four genuinely opened Home learning-card PNGs
  (fold-cover, phone, fold-open, large-text), their manifest, original successful
  Home job log and source map.
- village-original-pngs.tar.gz: six successful Village capture PNGs (fold-cover,
  phone, fold-open, landscape, 640dp and 690dp/text scale 1.2), their manifest,
  original successful Flutter and Kotlin job logs and source map.

The unchanged Home start images are intentionally not duplicated. The full
original Home workflow artifact still contains all eight images. Archive
compression changes no PNG bytes. Both archives were extracted to a fresh
directory and every member compared byte-for-byte to the original input;
every PNG SHA-256 was checked again after extraction. Uploaded Git blob
identities equal the SHA-1 of the exact Git blob headers and original archive
bytes computed before upload.

## Actual source and runs

Home head b5b7f6d9c2c33fd43234fc28fefd1f84f933dcea was executed through PR merge
checkout 58c32b76745325e4b8d5daeeb2049c6f700de3b2. Both trees are
f192095cae6db2b88668b167a0eb92bcda67fa5b. Run 43584516810/1, job 132416045501,
passed 13 Home/navigation tests and eight additional Magic/Mirror/Quest tests.
All four first Mathe cards were hit-testable, entirely within their viewport
and stable through rasterization. The four images were actually viewed and
show the opened subject cards.

Village head c54d9aa3a4dccab6c1cf677c9857abf77df66174 ran as 43583899148/1.
Flutter job 132414202983 passed 27 tests, including all six capture/launch
cases. Kotlin job 132414202800 compiled the actual generated Android bridge
successfully. All six original PNGs are hash-identical to the preceding
cf2593 PNGs, and independent QA actually viewed all six and confirmed the
complete Dorfwirtschaft title without glyph clipping.

The manifests bind source, actual checkout where applicable, run, attempt,
job, original artifact, archive hashes, PNG dimensions and PNG hashes. They
preserve the actual findings; no generated, retouched or relabelled pixels
are used. Natural viewport clipping of lower content remains visible.

This focused evidence does not claim a final combined full-suite pass, an
Android runtime Village return, a final APK or physical-device performance.
Those remain separate integration gates.

## Archive verification

Home archive: 5691799 bytes
SHA-256: fb5dae082a1e69ac5ca2ec18dd3a0f2503e72fa1d2dbcdd135e7dca55e506c75
Git blob: 74ac97492a403609b31fb38f8809330fa5b96b17

Village archive: 3625272 bytes
SHA-256: 6da7b3670b24dfbdf0cb800ce9bcbe48c9739a7025eddd20575c53c9a565688b
Git blob: 2daf4ed0869ea155cf6e9980e903044e73e5a222
