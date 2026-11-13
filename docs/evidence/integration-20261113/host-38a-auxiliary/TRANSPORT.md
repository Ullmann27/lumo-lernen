# Lossless original Host 38a auxiliary checkpoint

`original-evidence.tar.gz` contains the complete frozen 88-file agent handoff, including all original compressed JSON/job logs, the original failure ZIP and the separate local scroll repair. Every archive member was reread and compared byte-for-byte with its source. The copied README and manifest are also members of the archive. Gzip members additionally match their original decoded byte counts and SHA256 values.

Source: `38a49f7dda404923da3955592ccb213871f2027d`, tree `625b7940d9e8a4ddf32203126721efd97b3e8c2e`. Eight current workflows succeeded; Script-Recovery failed. Eight historical workflows skipped, two replaced Change-Review runs were cancelled. No result is transferred to the later Host source. Main Android run 43497829121 is recorded separately.

Extract into a separate empty directory with `tar -xzf original-evidence.tar.gz`; `archive-index.json` binds every complete original member.
