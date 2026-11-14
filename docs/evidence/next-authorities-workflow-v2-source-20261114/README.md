# Five-group qualification V2: three source-only corrections

Only `.github/workflows/lumo-next-table-authorities.yml` is proposed. V1 remains frozen and byte-identical. `v1-to-v2.patch` is the complete narrow delta; reversing its five replacement hunks reproduces all V1 bytes. `integration.patch` is the complete new-file patch for Root's still uncommitted workflow.

## Corrections

1. Every group obtains its actual Pub resolution with `flutter pub get --enforce-lockfile` in `host-source`. A new observer preserves the full generated Config, optional Graph, and exact committed Lock bytes before and after. It resolves URIs from the actual Config location, requires `lumo_lernen` to target the actual checkout and its `lib`, records all canonical dependency package roots, and rejects any after-change. Platform packages may legitimately lack `lib`; only their actual package root is required. The compiler script stays byte-identical, including its existing internal Pub invocations. Its before-observer requires one extra initial Pub resolution in that group.
2. The focused Flutter machine stream links each original `testStart.test.suiteID` to original `suite.id/path` and matches `testDone.testID`. Every one of the seven requested files must contribute at least one successful visible non-skipped test completion. Names, IDs, original suite objects and both original test events are retained per suite. Duplicate/unknown IDs, unmatched events, all old no-skip/error/timeout/final-done checks and real exit zero remain mandatory. No case count is invented; the existing summarizer is unchanged.
3. Upload requires `always() && steps.prepare.outcome == 'success'` and uses the fixed runner-temp/run/attempt/group evidence path, not a potentially unset environment variable. This prevents an early checkout/setup failure from expanding an empty variable to `/`. Prepared evidence still uploads on every subsequent outcome.

## Preserved boundaries

The trigger, repository restriction, five groups, exact Native ce909/tree e2a374b2, actual Host `github.sha`, verified toolchain, unchanged actual renderer/authority/compiler commands, budgets, strict source/index/mode binding and all old raster/report checks remain unchanged. Existing C4 workflow and both delivery/candidate verifiers remain untouched. This remains separate desktop-pair, compilation and focused Flutter qualification: no APK, Android-device, physical FPS or release approval follows.

`observed-format-only/` contains the actual earlier local 3fac Pub files and the installed package_config parser as read-only format references. Their machine-specific mappings are never copied into the future CI binding. The new observer reads that future job's own real Pub outputs.

`review-only-inline-code/` contains verbatim excerpts only, not extra repository paths. No proposed inline Python, YAML, Dart, Flutter, compiler or Godot command has been imported, linted or executed. Root's source checkpoint and independent reviews precede all qualification runs.
