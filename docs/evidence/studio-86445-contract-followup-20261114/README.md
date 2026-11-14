# c081 build failure, narrow 86445 correction and complete local contracts

## Exact source and CI status at this snapshot

The previous host `c081cfaaa3e7ddedbca21a46f63dbe4a8cc0d111` failed Studio run **43545886722**, attempt1. Actual Kotlin/Java host compilation succeeded. The original builder log contains **2,514 Flutter tests passed**, followed by **445 build/preservation tests with exactly two assertion failures** in the legacy voice-scroll expectations. Downstream APK build, Android35/37, update, Creative and publisher did not run.

The new host **`86445f53af5d573549fc8cf03405261611f3cb7e`**, tree `2389b97232041bb77307e47ecc0e550772339a4e`, changes only `scripts/tests/test_android_voice_scroll.py`: the two exact call assertions now include the helper's existing `orientation="landscape"` argument. All **4,144 other blobs and modes are unchanged**. An independent review compares the complete test AST after removing just the two added keywords. Native remains `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`; Main was not changed.

New full [Studio run43549076631](https://github.com/Ullmann27/lumo-lernen/actions/runs/43549076631) has started. Its result is still pending at this snapshot. No new accepted APK or physical Fold7 result is inferred.

## Executed local checks

- Original focused test: seven tests, exactly the two expected old assertion failures.
- Corrected focused test: **7/7 PASS, zero skips, 0.063 seconds**.
- Complete Android-probe contracts: **819 PASS, zero skips, 40.953 seconds**; process41.348seconds. German/English OCR models were explicitly selected. These are code/probe contracts, not819 device tours.
- First full build-contract attempt: **425 tests**, two JVM setup errors and one skipped Gradle-mirror test because the existing toolchain was not on PATH. The failing original log remains included.
- The already installed Gradle9.1.0 and Kotlin2.2.0 compiler libraries were located; only process environment variables were supplied. Nothing was installed or downloaded for this repair.
- Full build/preservation suite with that existing toolchain: **445 PASS, zero skips, 74.157 seconds**; process74.396seconds.
- Before the final successful execution, one Root source-hash preflight stopped with a manifest-key error before any test process began. Its exact cause and correction are retained separately; it is not counted as a test run.

All38 reviewed source files retain their hashes across the suites and match the reviewed source manifests. The local working tree carries an older Git HEAD; the local checks are not misrepresented as a clean candidate checkout. The independent full CI uses the exact PR head and must provide its own result.

## Evidence included

Original c081 host-compile logs and five-member archive; original failed builder/Flutter results and source bindings; unchanged red/green logs; independent review; one-file Git tree comparison and published commit checkpoint; both full local groups including the initial failures; and current public readback of the Native803 archive.

The Native803 archive was streamed publicly without authentication and matched locally by bytes and SHA256. Only the duplicate local199,274,727-byte ZIP was removed afterwards; all32 selected original images and61 frozen evidence files remain. GitHub still reports `immutable:false`; current retrievability does not establish permanent immutability. This storage operation grants no additional gameplay or Android acceptance.

The earlier original4ab Android failures and their subsequent diagnostics remain separate, source-bound records. No older failure has been relabeled as successful.
