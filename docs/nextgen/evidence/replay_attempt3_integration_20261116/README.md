# Third complete replay: exact video transfer recovery

The failed second replay and failed first supplemental run are preserved as complete original archives in the neighboring evidence directories. The original numeric correction case genuinely passed; the other recorded failures have not been reclassified.

The shared video-transfer change was supplied as producer `1407c37384ccf26bf6618903049918d3e7bc92e5`, published as `5bcfc870bd7d8e2fa06150958a81898ceaf0e074`, with identical tree `2e09e4e646f535aafe027b815c55d5b725d7e3fc`. Root reviewed the code and tests independently. Only two transfers of the same stopped recording are possible within the previous 90-second total budget. A running recorder, missing/empty or changing remote file, mismatched local hash/size, invalid video or zero duration fails. The UI and recorder run once, original transfer errors/partials remain available, and a task-body exception keeps priority.

Root's integrated seven checker groups pass **205/205** tests. Their unabridged log and source binding are retained here. This includes the owner tests and must not be added to their count. These are host tests, not an Android success. The actual committed source comparison contains only permitted QA/documentation differences from APK source `e05a96a52aaf57e466e79831f15aaffd144284ee`.

The third full-replay QA commit is `e2713c27599b6659a6ad2fd31355effeae9f88c9`, tree `287e12fe434ae314b43d9444a9f0115dd905d306`. The activation record retains the actual observed Actions run and its then-current status. Publication remains blocked until that run and both complete result validators succeed. Supplemental viewport correction remains a separate later check on the same immutable APK.
