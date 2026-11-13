# Android 37 installed-package metadata correction

The original diagnostic at source `fbb9a28e76a08455fc796ed1915a7c5a2ef8226f` installed the actual `x86_64-37.0_r08.zip`, then stopped because the helper treated the image-bundled `Pkg.Revision=7` as the installed package revision. The actual `package.xml` identifies the expected `system-images;android-37.0;google_apis;x86_64` package at revision 8. Both original files are retained unchanged as provenance-bound test fixtures. The earlier failure evidence is unchanged.

The correction reads exactly one installed package descriptor with the expected path, normalizes its numeric revision components, and requires image revision 8. It continues recording the complete original properties, including revision 7. Before the original keyevent and App Tour, the helper compares both the normalized installed descriptor and the complete properties with the preparation record. Actual revision or property changes still fail.

The new fixture reproduces the original error with the old helper. The corrected focused suite passed 12 tests, with no skips, in 0.114 seconds. Raw red and green logs and exact source hashes are attached. The green log contains an intentional negative-case FAIL JSON proving rejection before framework acceptance; it is not an Android failure or success report.

No target, GPU, partition, SDK/Release or framework readiness rule changed. The diagnostic and final candidate have identical corrected helper, tests and fixture bytes. Workflow and framework/action helpers retain their previously reviewed hashes. No new Android execution is claimed by this patch.
