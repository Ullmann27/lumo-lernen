# Floating Animated Fox Status

Base: 35299467b7c2b9077b00160e4c7dba86c82f3d03
Product SHA: 93e06e1b882b15eb4541deb8180f6929cb1159f3

PASS
- isolated branch
- changed-file scope
- no overlap with active PR 204, 206, 197 or 198 on these files
- floating companion now uses LumoAnimatedFox

SKIP
- flutter analyze
- lumo_free_companion_test.dart
- full Flutter suite
- runtime screenshots

NOT EXECUTED
- physical Fold 7
- physical 60 FPS measurement

Open: run companion tests and full suite, then capture phone, fold and tablet runtime views before integration.
