# Build 2082: executed Flutter evidence

The isolated GitHub Actions run completed successfully on 25 November 2026.
It executed the integrated application source at **f346db8e21bbc7ee7202a444b866bb1f862d85cb**,
tree **e594c39970de46d7ed397f4d6368f33f8fee889e**.

## Result

- Flutter **3.44.9 stable**, Dart **3.12.2**.
- Locked dependencies resolved with `flutter pub get --enforce-lockfile`.
- Full-project analysis completed with exit status 0: **0 errors, 5 warnings, 299 infos**.
  The specified `--no-fatal-infos --no-fatal-warnings` flags were retained.
- **114 tests passed across all 16 selected files**; no failed tests.
- Test command used the expanded reporter, a 60-second timeout, and concurrency 2.
- The workflow had read-only repository permissions and did not build or publish an APK.

## Reproducible source and run identity

- [Run 45561984220](https://github.com/Ullmann27/lumo-lernen/actions/runs/45561984220)
- Job: `139027621354`
- Trigger: actual push to `qa/lumo-intelligence-2082-focus-20261125`
- Workflow commit: `d176ec8c38668bd35bcd1af096260f627d3c74cd`
- Workflow: `.github/workflows/lumo-2082-focused-qa.yml`
- Workflow blob: `d2e2611e45fe7acbba02d8fa91d2bf98333ada18`
- Started: 2026-11-25 06:37:29 UTC; finished: 06:39:27 UTC.

The workflow commit adds only the isolated QA configuration. Its checkout step
explicitly selects the source commit above. The provenance step checks the
actual checkout SHA and records its tree and all application/test/lockfile blobs.
This distinction is intentional: GitHub's run head identifies the workflow,
while `SOURCE-COMMIT.txt` identifies the application actually analyzed and tested.

## Original artifact

- Artifact: `LUMO-2082-FOCUSED-45561984220`
- ID: `14998332164`
- ZIP size: **45,922 bytes**
- ZIP SHA-256: `f6f3923709fb9b2888567a12ed8af5339b229ce206fb48279312c4e4a416782f`
- Retained by Actions until: 2026-12-25 06:39:18 UTC.

The ZIP was downloaded and its SHA-256 was verified. The seven text files in
this directory are the unchanged contents of that artifact. They are also
saved here so the evidence remains available after Actions retention expires.

## Selected tests

- `test/domain/adaptive_practice_plan_test.dart`
- `test/domain/learning_chart_data_test.dart`
- `test/domain/assignment_evidence_2082_test.dart`
- `test/domain/school_model_test.dart`
- `test/parents/live_learning_analytics_test.dart`
- `test/features/teacher_flow_test.dart`
- `test/features/assignment_evidence_2082_widget_test.dart`
- `test/tutoring/intelligence_2082_daily_plan_test.dart`
- `test/tutoring/intelligence_2082_language_tutor_test.dart`
- `test/features/lumo_coach_profile_guard_2082_test.dart`
- `test/domain/learning_analysis_independent_evidence_test.dart`
- `test/features/learning_analysis_evidence_view_test.dart`
- `test/domain/learning_analysis_extended_test.dart`
- `test/domain/school_analysis_test.dart`
- `test/learning_loop_restart_scenario_test.dart`
- `test/features/report_screen_test.dart`

The expanded reporter interleaves concurrent files and may display another
currently active test's name on a completed test's progress line. The terminal
result is `00:09 +114: All tests passed!`; the source manifest fixes the exact
test definitions that ran.

## Scope

These results verify the named integrated Flutter source. Android packaging,
native-game tests, device behavior and publication are separate checks. Later
source changes require their own applicable verification.
