# Current 2020 Native pin: e536 source → f9d9772

Exactly three existing lines change:
config/godot-source.json revision;
scripts/verify_legacy_release_pin.py APPROVED[2020];
scripts/tests/test_candidate_2011_pin.py CONNECT_FOUR_2020_REVISION.

Full preimages were read from exact Host e53669a2e06d1832cc6844dbe1077d652551fdb8,
Tree 5cf2f3bc7d062d44b12c0b5370c827a07c3002c1. All 50 historical pins,
Godot 4.6.3, repository origin and pubspec 0.13.8+2020 remain unchanged.
The target Native commit/tree is independently bound by its GitHub original:
f9d9772bb932d7ee8702eeb5bca6d98c286f3b98 /
4036a20ab80de78bcdf0d074b585be88c2946492.

The untruncated actual Host tree was checked against 1,120 current text paths
under .github/config/scripts/tools/lib/android plus pubspec files. Every read
was checked by Git blob against that current tree, even when an identical
object came from an older local cache. Only the three allowed selectors contain
the old current pin. The other match is the original Host5ad Village fixture
provenance; it deliberately retains 2281 and is not a current dependency.
Five fixed Native helper blob IDs in the unchanged C4 workflow match the
actual new Native tree. Literal SHA256s in that report are the existing
workflow requirements, not a new helper execution.

After the three-path freeze, exactly one existing suite ran:
24 Candidate + 40 Legacy = 64 PASS, zero failures/errors/skips, exit 0.
All 64 names were checked against the static roster and original stderr.
All execution-view and bound source inventories were identical before/after.
No Git checkout/index was created or modified: tests used the private exact
seven-file source view, and all source/reference bytes are retained separately.
No extra unit suite, actionlint, engine, Android or workflow was run.

PR485 was read open/draft at 5ad with head branch
integration/lumo-c4-connections-20261114. The exact e536 compare was 12 ahead /
0 behind. The C4 workflow is pull_request only, requires the own repository
and exact head branch, and checks out the actual PR head. The preparation
branch does not satisfy those guards. Root owns a later guarded fast-forward,
actual run discovery and all APK/device/release acceptance.

Root subsequently reported c070 and c874 checkpoints with the same three pin
preimages. The source patch remains based on the independently read e536 bytes.
Its source-only overlay tree is only an in-memory calculation, not a published
commit. Root must recheck the three expected old blobs before applying on its
latest parent. All three final blob IDs and full evidence mapping are provided.
