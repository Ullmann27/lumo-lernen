# Console followup targeted validation

Actual committed source: 5676495b331bc5a41d5ff78259f7165cf25d100a; tree f6f7d30eeb8ace2eb546fd2d952834d2bbd68a1f.

One combined unittest invocation contains Workflow 9, original-parser 7 and failure-diagnostic 9 methods. One actionlint invocation checks exactly the four requested workflows. All original stdout/stderr is retained losslessly in the raw logs, with commands, timestamps and exit codes. Source-before/source-after bind all 27 relevant files, exact Git HEAD/tree/branch, index entries and full porcelain status. No source or Git state is changed.

The 86 Console/AF_UNIX cases are not repeated here. This does not establish Android launch, init-console survival or ANR absence. The three historical original END:1 transcripts remain failures in the parser regressions.
