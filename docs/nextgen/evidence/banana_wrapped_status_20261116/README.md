# Read the actual wrapped Banane completion status

The complete immutable-2031 replay at QA `51a3bfdedf4d6a745fb574ae9186c1094eb11abf` (workflow `43806736020`) failed after showing the third native syllable. Its original PNG and unfiltered OCR show the full sentence split into adjacent lines: `Banane: Ba - na - ne. Das Wort hat 3` / `Silben.`. The original failure and all 3,356 archive entries remain retained separately in `../ci-2031-replay-banana-reader-failure/`.

The current candidate's reader dispatch now includes exactly the complete nonexact label `Das Wort hat 3 Silben` in its existing wrapped-phrase path. The same-frame algorithm, full-word requirement, same-variant constraint, geometry, ambiguity rejection, PNG-hash check, ten attempts, 225-second frame budget and two-second retry delay are unchanged. Exact matching, other labels, controls, task logic, historical readers, original tour and APK bytes remain unchanged.

The fixture copies the real last failed observation and reference result byte for byte. The added runtime-dispatch test first reproduced the original error with the prior source (`red-reader.log`, exit 1). With the one-line dispatch change, all 15 current-reader tests pass (`green-reader.log`, exit 0). These are recorded-image host tests; they do not turn the failed Android run into a pass and do not replace a fresh complete Android replay.
