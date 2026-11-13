# Lossless current Auxiliary evidence

`original-evidence.tar.gz` retains all 50 original pack files, including
the unchanged manifest, complete job logs, API responses, source/checkout
bindings and original geometry-log ZIP. Every member was reread and compared
byte-for-byte. Archive size: 373,673 bytes; SHA256
`c8a9af30a88a50f638688596a9f4cc47c0ae932856056fa3885939ba94c04102`.

Extract into an empty directory with `tar -xzf original-evidence.tar.gz` to
restore every relative path described by the original README and manifest.
`archive-manifest.json` also binds every member independently. Inner gzip
files preserve the original uncompressed hashes and exact raw log bytes.

This records 13 actual successful auxiliary workflows and 14 complete clean jobs,
including the newly repaired Geometry check. 158 successful steps and the two
explicit complementary matrix skips remain distinct from runtime test results.
No Nextgen, Graphics, Android, APK or final receipt approval is added here.
The previous 90d/cce false-success records retain their own sources and separate
historical corrections. No original record was modified while packaging.
