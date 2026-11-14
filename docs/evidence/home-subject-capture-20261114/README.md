# Home subject-capture visibility repair — 2026-11-14

## Original, independently checked evidence

The preceding Home workflow ran as 43582160985, attempt 1, job 132408996775.
Its actual checkout was ef6a8bc178d72e8ad50f26e044bbb96c839be94c, the PR merge
commit. Its complete tree is 014b2acc4cea5def174f7c51a12902c4aa2c22d6, exactly
the tree of host cf2593cb6dec51b66461c8e5984dfbfdd5091c22.
The run reported 13 passing Home/subject/navigation tests and eight passing
additional world tests. These passes did not establish that every image named
learning-cards actually showed the opened subject cards.

The unchanged original artifact is 14109390016,
lumo-1989-original-learning-cards, 21603858 bytes, ZIP SHA-256
4ad263460a7c5c15f66ade70afb876c3f1886336732c6af64e7398dffe45bbb5.
The adjacent original-artifact-manifest.json records all eight original PNG
dimensions, byte counts and SHA-256 hashes. Original ZIP CRC and every PNG
hash/header were verified; the original pixels were not edited.

Independent visual review found that fold-cover and phone start/learning pairs
were byte-identical, and the large-text pair showed the same start viewport
(the small image difference did not reveal subject cards). Only fold-open
learning-cards showed the opened subject grid. The corrected Belohnungen title
was genuinely visible in the original cover image; this separate product fix
is preserved.

## Narrow repair

Only test/design/home_1989_premium_cards_capture_test.dart changes.
Its exact baseline on cf2593 is blob bd3efcb5fe3567f77e66bcc0f8301222ed194dfe.

The test now scopes scrolling to the real lumo-home-scroll ListView. It scrolls
the real expansion header into hit-testable view, taps it, checks the actual
expanded subject heading, and then scrolls the real first subject card into
view. The positive scroll delta was checked against Flutter 3.44.9's actual
WidgetController.scrollUntilVisible implementation for AxisDirection.down.
The former cover-only duplicate-image return is removed.

Every device must show a hit-testable Mathe card whose complete rectangle
fits inside the actual capture viewport. After rasterization its hit target
must still be visible and its rectangle must be unchanged. Existing real-font
title bounds, complete Belohnungen glyphs, 48dp targets, cover navigation taps,
narrow stacked subject rows and overflow assertions remain.

No product source, visual golden, title, font scale or application state is
substituted. Captures continue through captureLumoBoundary on the real app.

## Validation boundary

The updated Dart file parsed and was formatted with the existing Flutter
3.44.9 / Dart 3.12.2 SDK. App keys, the expansion structure and SDK scrolling
APIs were inspected against the actual sources. This is not an analyzer or
Flutter test result.

No focused Flutter execution is claimed for this repair: the isolated host
checkout is absent after the environment restart and the shared pub cache has
no package directories (99 of 104 paths referenced by an existing app package
configuration are missing). A major local setup was explicitly avoided.
The next combined host CI must execute all four actual Home variants and
produce and review fresh subject-card images. The preceding original PNGs
must not be relabelled as after-fix evidence.
