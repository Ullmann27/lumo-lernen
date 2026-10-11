# Execution ledger: docs/superpowers/plans/2026-10-11-lumo-production.md

Base: 0dc3b1f30d7d885cc0c9914d1f557fad8655d762; branch sol/lumo-active-companion-2026-10-11; existing isolated worktree /workspace/lumo-android-1930.

Ruling: companion summaries will derive from canonical profile progress rather than create a second set of persisted answer counters. Unowned legacy companion bytes stay untouched. This prevents new duplication/migration ambiguity; old global aggregate counts are not attributed to any child.

Pre-flight: Task 1 owns profile UI refresh; Task 2 carries profileGeneration/taskId into proposal lifecycle. Neither changes LearningProfileEngine counting or the existing discovery storage boundary.

Task 1: complete — canonical profile snapshot, safe name lookup, A/B/A and delayed old-profile completion. Five focused tests passed (profile-extra-tests.log); original UI contamination reproduced in profile-red.log. Legacy companion bytes unchanged.

Task 2: Ruling: direct Plus portrait uses a separate existing layout — integrate the same offer-only host there as in the shared frame; preserve its original assets. Without it portrait children would never see the proposed help.
Task 2: Ruling: inject a fresh real RewardWalletRepository per widget test — the cached singleton queue belonged to a prior FakeAsync zone. Isolated old test passed; new combined file passes all four after fixture repair, without changing product storage.
