# Parallel integration merge with 803a kept frozen

The integration ref advanced from `729585db3f49ecff7f0632439f90edb882f09454` to `2b586530db4f2cb20c28f426e2549342316151bf` while candidate `803a4e960ffb804a46b6d09417731c031f00f680` was in its full acceptance run. The merged source is preserved at `d14924407f7d63339693eb8a53ecddef0a64d602`, tree `6da1ec046903048db00315eed44da61f0189523e`, with both real parents. The live candidate branch was not changed.

A genuine `git merge-tree --write-tree` operation found exactly one conflict in `lib/features/learning/widgets/lumo_shape_trace_canvas.dart`. The selected integration blob keeps the candidate's ink handling unchanged and adds only a stable widget key and an unmodifiable outer stroke-list snapshot for painter comparison. Every other changed path was a direct merge or already byte-identical. The original input SHA values and complete selection are in `root-merge-review.json`.

On the isolated committed merged source, **19 diagnostic test methods passed**, shell syntax passed, and source/index identity remained unchanged. These tests retain rejection of actual original GMS ANRs, unrequested exits, changed process/inode, changed log prefixes, and forged renderer invocation. Their raw log is included. This does not represent an Android device execution.

Targeted Flutter tests were **not started**: all 99 cached external dependency directories referenced by the existing package configuration were absent after the environment reset. The Flutter SDK remains present. The actual 803a CI results must not be attributed to this new source tree. A full acceptance run of this merged tree remains required before delivery from it.

The review timestamp in the first checkpoint was transcribed as 09:31:00Z; this follow-up corrects it to the actual clock read at 09:29:48Z. The original commit remains unchanged.
