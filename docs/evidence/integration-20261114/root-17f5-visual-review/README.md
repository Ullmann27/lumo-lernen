# Root visual review of Native 17f5

The current Nextgen acceptance is tied to commit `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`, workflow run `43532048311`, and original combined artifact `14089423812`. Root directly inspected all 29 selected originals. The existing strict recorder completed successfully after all selected bytes were compared with the successful final archive.

The current Graphics acceptance uses the same Native commit and successful run `43532048253`. Root directly inspected five current original images. The production receipts are `config/nextgen-2019-visual-review.json` and `config/kart-graphics-2019-visual-review.json`; their original images are preserved under the referenced content-addressed paths.

This folder preserves the original per-image observations, original metadata slices, byte bindings, earlier partial records, previous Host receipts and recorder results without rewriting them. `manifest.json` enumerates every copied original and its SHA256. The final Nextgen receipt has SHA256 `b41471c3cb90df69b99228f6da7057851af224528004872215f36332efb1804d`; the final Graphics receipt has SHA256 `355b6878f5d833aed4010fa49c5efb49759bbe9f8e4f185a75ca894ad9c6bf99`.

The observations explicitly retain clipped scroll viewports, ellipsized titles, wrapped counters and background occlusion. Native renderer fixtures and static images establish neither actual Android inputs/insets nor device frame rates. The new Host Android runs, complete upgrade path and Creative gameplay are separate required gates. No APK publication is authorized by these records.
