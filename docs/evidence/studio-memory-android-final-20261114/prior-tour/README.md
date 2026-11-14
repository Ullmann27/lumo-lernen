# Exact ordinary-tour prerequisite for the Memory Android reader

This follow-up adds the 18 actual HARD_STEPS and the three exact display step names from the unchanged modernization tour. All 21 must occur exactly once, pass, and refer to the same actual APK/API. The new pure countercase includes missing, duplicate, unknown, failed and cross-binary/runtime reports. The actual prior inline predicate accepted the duplicate report; the new reader rejects it.

Only the tour constant, check_tour function and its call in AndroidProbe.run changed. Twelve prior top-level functions and sixteen other methods are AST-identical, including every touch, state, save, lifecycle, pixel and deadline operation. The original 24-case package, its first fixture-setup errors, and its real pixel replay remain preserved separately. The new targeted suite passed 25 cases with zero skips. No Android execution occurred.

source-upload-manifest.json is the complete seven-file integration list, reusing five already-confirmed original fixture blobs and the two newly confirmed source blobs. The common C4 helper remains unchanged. The invocation, native sparse paths and 600-second limit remain exactly as documented in the original package README.
