# Flutter-Integrationsinventur vom 13. November 2026

## Auftrag, Quelle und Abdeckung

Dieses Team übernimmt ausschließlich vorhandene Entwicklungen und repariert ihre Integration. Es verändert keine fremden aktiven Arbeitszweige und führt keinen Main-Merge aus.

Geprüfte aktuelle Produktbasis: **`3c712129fef8f144d8946fad567b9ed11c628a60`**, [PR #461](https://github.com/Ullmann27/lumo-lernen/pull/461), Branch `chatgpt/lumo-nextgen-20261113`, Version **0.13.6+2018**, Godot-Pin **`ada5ed81ad62339f15289da62670c0a4f9f7f2b9`**.

Die Live-Abfrage `updated:>=2026-11-10` lieferte **26 PRs**; für alle wurden aktuelle Metadaten und Heads gelesen. Damit ist das angeforderte Zeitfenster von 48–72 Stunden einschließlich des gesamten 10. November abgedeckt. Zusätzlich wurden offene ältere PRs als Kandidatenliste gelesen, sämtliche Branch-Namensseiten bis zur leeren Folgeseite durchlaufen und sechs lose jüngere Reparaturzweige gezielt untersucht. Das ist **keine** Behauptung einer vollständigen inhaltlichen Prüfung jedes historischen Branch-Heads. GitHub-PR-Status allein wurde ausdrücklich nicht als fehlende Integration gewertet.

Historienvergleich: jeweils Quell-HEAD als `base`, Produkt-`3c712129` als `head`. `ahead / behind_by=0` bestätigt den Quellcommit als Vorfahr. Divergente Historien wurden zusätzlich anhand tatsächlicher Dateiinhalte und Git-Blob-Hashes geprüft.

## Bereits durch Commit-Historie enthalten

| PR | Vollständiger geprüfter Quell-HEAD | Nachweis |
|---|---|---|
| [#438](https://github.com/Ullmann27/lumo-lernen/pull/438) | `85afcb0e7fafa7fc85a65aee6a959dd2bf1ec952` | GitHub-Compare: behind_by = 0 |
| [#439](https://github.com/Ullmann27/lumo-lernen/pull/439) | `9c7005221a1d7870e5b661cd161edd538da8203d` | GitHub-Compare: behind_by = 0 |
| [#440](https://github.com/Ullmann27/lumo-lernen/pull/440) | `af044d938f00cffab25bc30bc97dfc625f5b3fc3` | GitHub-Compare: behind_by = 0 |
| [#441](https://github.com/Ullmann27/lumo-lernen/pull/441) | `3e4d8c235fe0834079d9d539fe4883bf9a91b27a` | GitHub-Compare: behind_by = 0 |
| [#442](https://github.com/Ullmann27/lumo-lernen/pull/442) | `0de7afc2d45d5b7eb4ce90c5afa1b92cd4546652` | GitHub-Compare: behind_by = 0 |
| [#443](https://github.com/Ullmann27/lumo-lernen/pull/443) | `0853d3c3d7735e7352003a04c9bd99cb1445ed67` | GitHub-Compare: behind_by = 0 |
| [#444](https://github.com/Ullmann27/lumo-lernen/pull/444) | `cc951ffc085390a20c1149e2798ee9b29a816091` | GitHub-Compare: behind_by = 0 |
| [#445](https://github.com/Ullmann27/lumo-lernen/pull/445) | `550b3fc6a662e10d1658bda54f7ef55ba985c38b` | GitHub-Compare: behind_by = 0 |
| [#446](https://github.com/Ullmann27/lumo-lernen/pull/446) | `d723ea880eec09d896470ed70ef508af38b4839e` | GitHub-Compare: behind_by = 0 |
| [#447](https://github.com/Ullmann27/lumo-lernen/pull/447) | `84f610522db4bc49625773ef6bbf0578da999074` | GitHub-Compare: behind_by = 0 |
| [#448](https://github.com/Ullmann27/lumo-lernen/pull/448) | `550b3fc6a662e10d1658bda54f7ef55ba985c38b` | GitHub-Compare: behind_by = 0 |
| [#449](https://github.com/Ullmann27/lumo-lernen/pull/449) | `84f610522db4bc49625773ef6bbf0578da999074` | Identischer Head zu #447; bereits Vorfahr |
| [#450](https://github.com/Ullmann27/lumo-lernen/pull/450) | `76aa559cb03d968f492b59129c1b7cee057e76e9` | GitHub-Compare: behind_by = 0 |
| [#451](https://github.com/Ullmann27/lumo-lernen/pull/451) | `696db258693465acfc27d051c9c0874710ac9046` | GitHub-Compare: behind_by = 0 |
| [#457](https://github.com/Ullmann27/lumo-lernen/pull/457) | `43f1d7c2b847be757123a59133967e85a58407dd` | GitHub-Compare: behind_by = 0 |
| [#459](https://github.com/Ullmann27/lumo-lernen/pull/459) | `47889f74a651b073965def70743417cf320b1eb9` | GitHub-Compare: behind_by = 0 |

Die noch offenen PRs zu Lernobjekten, Spielebühnen, Memory-Packs, 4-Gewinnt-KI und Quiz-Kategorien sind daher kein Beleg liegengebliebener Produktarbeit. Eine zweite Übernahme würde ältere Stände wieder einführen.

## Divergente Historien: tatsächliche Einordnung

| PR | Vollständiger geprüfter Quell-HEAD | Einordnung |
|---|---|---|
| [#452](https://github.com/Ullmann27/lumo-lernen/pull/452) | `98698f4fc2df0e8e081bc8521cf40f6148cc5577` | Selektiv integriert; Tutor, Darstellung, Sprachsteuerung und Eltern-Reset erhalten. |
| [#453](https://github.com/Ullmann27/lumo-lernen/pull/453) | `9d2971009bf296e42cf65be03b6caddfa5ed79db` | Selektiv integriert; identische Cards-KI und Gegner-Einstellungen, UI inzwischen erweitert. |
| [#454](https://github.com/Ullmann27/lumo-lernen/pull/454) | `d555a44d3a5d7a7bc6ae90ed6bb851a433ceb41a` | Selektiv integriert; Controller, Wallet, Persistenz- und Resume-Tests identisch. |
| [#455](https://github.com/Ullmann27/lumo-lernen/pull/455) | `6fbb1e2ec3eb828ff27897e46745b74f327896ca` | Produktbasis integriert; drei abweichende Folgecommits ändern nur historische STATUS/CONTINUE-Dateien. |
| [#456](https://github.com/Ullmann27/lumo-lernen/pull/456) | `a1d581f0b0b392e0bc4ad7d90fd38d14f8d74095` | Noch getrennte 2015-Garagen-QA; Wiederverwendung der tatsächlichen Auswahlprüfungen wird separat geprüft. |
| [#458](https://github.com/Ullmann27/lumo-lernen/pull/458) | `fe3f75d3abf159e9cc20aab12f240459c80e9b3d` | Historischer isolierter 2016-APK-Workflow, kein fehlender Produktcode. |
| [#460](https://github.com/Ullmann27/lumo-lernen/pull/460) | `1166e9ae5aa59204ea5570bb95cdb262638f7841` | Historischer 2017-Publikationsfix, kein fehlender Produktcode; aktuelles SDK-Setup bereits korrigiert. |
| [#462](https://github.com/Ullmann27/lumo-lernen/pull/462) | `ab3c004cd81a3def70da88b2287d4e73245d47c6` | Zurückgezogener a31-Abnahmeweg; QA-Produktkorrekturen selektiv übernommen, alten Publisher nicht aktivieren. |
| [#463](https://github.com/Ullmann27/lumo-lernen/pull/463) | `b56295f53f08c70079266331039250b96ca7bdbc` | Recorder und Regressionen jetzt gezielt übernommen; Originalquellen unten dokumentiert. |

### Inhaltliche Erhaltung von Tutor und Cards

Auf `3c712129` sind gegenüber #452 byteidentisch: Tutor-Katalog und Evidence-Klasse, mathematische Illustration, Sechs-Phasen-Zehneranimation, Eltern-Evidence-Karte, Tutor-Katalog-/Evidence-/Mengen-/Playback-/Sprach-/Natur-/Eltern-Resettests sowie die ursprüngliche Übergabedokumentation. Die abweichenden Dateien enthalten spätere Änderungen zur unabhängigen Lernbewertung, den nativen 3D-Lernaufruf und bereits integrierte weitere Korrekturen.

Gegenüber #453 sind Cards-Bot-Policy, Gegner-Einstellungen, Strategy-, Controller-Lifecycle- und Session-UI-Tests byteidentisch. Gegenüber #454 sind Cards-Controller, Wallet-Repository, Persistenz- und Resume-Tests sowie Opponent-Capture-Test byteidentisch. Die Rundenspeicherung ergänzt lediglich validierte optionale Pokal-Slots. Die spätere Bildschirmdatei ergänzt nativen Tisch, Pokal, Profil-Grenzen, Darstellung und den korrigierten Verlustbonus; die vorhandene Regelautorität und Wiederaufnahme sind weiterhin angeschlossen.

Beispiele exakt verglichener Git-Blobs:

| Datei | Git-Blob |
|---|---|
| `lib/features/games/lumo_cards/lumo_cards_bot_policy.dart` | `f18191ac1d5d8c7c394ab4adcfb4c8771f0e0d9e` |
| `lib/features/games/lumo_cards/lumo_cards_game_controller.dart` | `6b6b22504cc0ff431cf03d4f3496b296282d24b4` |
| `lib/core/reward_wallet_repository.dart` | `63a3d4c4fe6c5c9249f3531e685cc541646747ee` |
| `test/lumo_cards_persistence_test.dart` | `7b57489e38777b9331bb886f1a16b8da20b3f459` |
| `test/lumo_cards_resume_widget_test.dart` | `191fc9bb71a2b13acb7104783343575a4c4c2ce5` |
| `lib/features/tutoring/guided_ten_frame_animation.dart` | `a721c9b46b6cbcfa92b0793177f932edd48524a8` |
| `test/tutoring/tutor_parent_reset_test.dart` | `0d6ec675d42db738355cb1a66b3431116696d3cd` |

### Lose Reparaturzweige

| Quelle | Befund am aktuellen Produktstand |
|---|---|
| `lumo-2014/cards-loss-reward-20261111`, `74b29f7a29a40fce1c0f17ad73b7fd7221076ba3` | Verlustanzeige von einem Stern vorhanden; `test/lumo_cards_result_reward_test.dart` exakt `b2d283d267ca589b9693cd40b266fcc4ca54b7e9`. |
| `lumo-2014/learning-tip-review-20261110`, `87b12d1c5215a1b7f8308972d8591d486d9bb033` | Sichtbarer erster Tipp und getrennte begleitete Evidence vorhanden; `guided_lesson_runtime_test.dart` exakt `57526c22bf530d38a6290a4013e931ef1add5e7e`. |
| `lumo-2014/quiz-lock-final-20261110`, `e3870b67b5f9d958acd71a266b6a4ca6506c1b10` | Ganze Produktdatei `lib/features/quiz/quiz_show_content.dart` exakt `ca4fa2aa5c8b4328b58cd0a56ddde9f7c43446de`; darin auch die ältere Lifetime-/Generation-Absicherung aus `0d583cea749b6dc0f95a85c7d1ef2481120fe0fd`. |
| `chatgpt/lumo-2018-speech-logcat-recovery-20261113`, `f257c787878be5d3d9615d1258aaa8f2f83a945e` | Genau ein Commit nach `3c712129`; enthält denselben #463-Recorderfix sowie begrenzte Wiederholung ausschließlich für beobachteten adb/logcat-Transportfehler 255. Pipeline-Bot besitzt dessen Prüfung und Integration. |
| `checkpoint/lumo-2018-card-recovery-20261113`, `a6a0de287d1d8e43326fa8f649a56c36367e6f5e` | Zwischencheckpoint ab a31, kein eigenständiger aktueller APK-Kandidat; neueren Produktstand nicht durch diesen Checkpoint ersetzen. |

## Tatsächlich übernommene Recorder-Reparatur

Aus [#463](https://github.com/Ullmann27/lumo-lernen/pull/463) wurde nur die bestehende Reparatur mit ihren Regressionen übernommen. Die beiden Dateien sind bytegleich zum Quellhead `b56295f53f08c70079266331039250b96ca7bdbc`:

- `scripts/record_nextgen_visual_review.py`: Blob `30d602142e9e0b71fa35e9968e22c102dc3d0b95`.
- `scripts/tests/test_nextgen_review_recovery.py`: Blob `31a9fe20b48bc47fc8ec8616a8e3ae313606501f`.

Korrigierte Originalbilder erhalten einen eigenen stabilen Dateinamen mit vollständigem SHA-256. Andere Auswahlreihenfolgen ändern unveränderte Bildpfade nicht. Historische Originalbilder und sämtliche bestehenden Quellen-, Archiv-, Vollständigkeits-, Integritäts- und Veröffentlichungskontrollen bleiben erhalten.

Tatsächlich hier ausgeführt:

| Prüfung | Ergebnis |
|---|---|
| Neue acht Regressionen zuerst gegen unveränderten `3c712129`-Recorder | **1 FAIL, 3 ERROR, 4 PASS**, keine Skips; Kollision und reihenfolgeabhängige Pfade reproduziert. |
| `python3 -m unittest discover -s scripts/tests -p 'test_nextgen*.py' -v` nach Übernahme | **26 PASS**, keine Fehler/Skips; 9,731 Sekunden. |
| `git diff --check` | PASS. |
| Git-Blob-Vergleich beider Dateien mit #463 | Beide exakt identisch. |

Diese Tests verwenden ausdrücklich synthetische Speicher-/Vertragsfixtures. Sie sind keine neuen Rendererbilder, kein Android-Gerätetest und keine APK-Freigabe. Stage/Commit/Push des gemeinsamen Zweigs erfolgen durch den Integrationsleiter.

## Tatsächlich noch getrennte ältere QA

[#456](https://github.com/Ullmann27/lumo-lernen/pull/456) enthält vier Dateien, die gegenüber dem aktuellen Tree noch eigenständig sind:

- `.github/probes/lumo_2015_garage_android_probe.py`
- `.github/workflows/lumo-2015-android-garage-qa.yml`
- `docs/qa/lumo-2015-android-garage.md`
- `scripts/tests/test_lumo_2015_garage_android_probe.py`

Das sind Nachweise/Prüfcode für den historischen 2015-Kandidaten, keine verlorene Spielfunktion. Der damalige Lauf scheiterte laut PR-Handoff vor Emulatorstart. Der Pipeline-Bot prüft gezielt, ob moderne Garage-Auswahlfälle fehlen und welcher Teil sinnvoll übertragbar ist. Der alte versionsgebundene Workflow wird nicht ungeprüft aktiviert.

## Laufende Lieferungen und aktueller Build

Die vorhandenen Arbeitsbereiche anderer Teams wurden ausschließlich gelesen:

- `chatgpt/lumo-studio-20261113` auf `3c712129`: aktive Änderungen an Lernaktivität und Legacy-Aufgabenadapter gesehen.
- `chatgpt/lumo-game-rooms-20261113` und `chatgpt/lumo-cards-cup-20261113` auf `3c712129`: separate Entwicklungsbereiche identifiziert.

Diese lokalen Arbeitsnamen sind keine Behauptung bereits gepushter oder fertiger Lieferung. Vor jeder Übernahme müssen Quellhead, fertiger Umfang und Prüfnachweise erneut gelesen werden.

Der Live-Build [43405216014](https://github.com/Ullmann27/lumo-lernen/actions/runs/43405216014) wurde gelesen: `verify-and-build`, `android-host-compile` und `update-2018-from-2017` waren erfolgreich; `android-tour` war bei dieser Abfrage noch in Arbeit. Dieser Zeitpunkt belegt keinen späteren Gesamtstatus. Weitere Liefer- und Veröffentlichungsschritte bleiben beim zuständigen Integrations-/Releaseleiter.
