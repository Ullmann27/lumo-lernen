# Pause caption test harness follow-up

Base: published QA7fe0b85dd3b51384efed5c94af0618951574b857.

Only the test import/setup changes. PIL.Image and the actual original PNG decoder are loaded before temporary sys.modules patches. All nine test methods, production sources, OCR rules and fixture bytes remain unchanged.

The historical 19-pass/1-error run is retained verbatim in original-failure/. This source pack has not executed tests. Root must checkpoint it before the separately authorized nine-case rerun and one bound old-source Red replay.
