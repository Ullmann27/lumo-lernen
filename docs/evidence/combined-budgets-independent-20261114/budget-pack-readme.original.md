# Outer job budget assessment

Read-only assessment for the separately proposed Root follow-up. No workflow, product, test, ref or active CI run was changed.

The proposed build limit is 120 minutes (currently 90); the proposed Android C4 limit is 80 minutes (currently 65). All per-probe deadlines and acceptance gates must remain unchanged.

Current Host3d reached APK build after 62:32; the Native gate itself took 45:04 and Dream 0:58. The separate current Discovery step took 19:05. An illustrative combination with the older 7:28 APK-to-job-completion tail is 89:05, leaving only 55 seconds under 90 minutes and 30:55 under 120. This is not a measured combined duration.

For Android, the extra 15 minutes corresponds to the newly mandatory 900-second Village probe. No combined Android timing is claimed.

Two existing delivery tests contain literal 90-minute expectations. The review names both; all other assertions and all inner timeouts must stay intact. Original API JSON, actual invocation timing records and existing source contracts are included unchanged. Full source files are identified by bytes, Git blob and SHA256 rather than copied again.
