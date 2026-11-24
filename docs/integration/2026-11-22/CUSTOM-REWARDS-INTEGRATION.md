# Eigene Gutscheine – Integration vom 22. November 2026

## Nachgewiesene Ausgangslücke

Die angehängte `05-lumo_lernen_agent_playready_prototype_app.html` enthielt eine tatsächlich angeschlossene eigene Gutscheinverwaltung: `allVouchers()` (Zeile 317) kombiniert Basis- und eigene Gutscheine; `renderRewards()`/`redeem()` (822–823) zeigen und verbrauchen diese Liste; `deleteCustom()` (832), `renderCustomList()` (834), `addCustomVoucher()` (835) und die Initialisierung (894) verbinden Formular, Speicherung und Bedienung. Die Felder sind Titel, Symbol, Kategorie, Sternpreis und Mindestlevel. Die vergleichbare HTML-09-Fassung bestätigt diesen Pfad.

Der Flutter-Ausgangsstand `f19f8311b0967d8dc5ff375d50260df1ab191068` zeigte dagegen nur `RewardCatalog.all`: 33 feste Einträge, mit echter Navigation und Einlösung, jedoch ohne Datenmodell oder Editor für eigene Gutscheine. Eine dokumentierte Abschaffung dieser Funktion wurde nicht gefunden. Der frühere Eltern-PIN ist ausdrücklich durch `docs/PIN_FREI_2026-10-03.md` und Commit `d7b1e3ff` abgelöst; er wurde nicht zurückgebracht.

## Tatsächlicher Einstieg und Verhalten

- Elternbereich: `SettingsContent` → `CustomRewardsCard` → `CustomRewardsScreen` → Formular.
- Kind: Profil/Belohnungen → `LumoSection.rewards` → `RewardShopContent` → eigene Familiengutscheine, zusätzlich zum unveränderten 33er-Katalog.
- Formular: Titel, eigenes Symbol, alle acht historischen Kategorien, frei gewählter Sternpreis, Mindestlevel und optionale gemeinsame Vereinbarung.
- Bearbeiten behält die stabile Gutschein-ID und legt eine neue Revision an. Deaktivieren beendet das Angebot für neue Auswahl; ältere Definitionen und Einlösungen bleiben erhalten. Reaktivieren ist möglich.
- Der eigene Sternpreis muss 1–999999, das Mindestlevel 1–25000 sein. Die Freischaltung verwendet den vorhandenen aktuellen Wallet-Level (`XP ~/ 400 + 1`), nicht die andere XP-Kurve des HTML-Prototyps.
- Jede eigene Einlösung zeigt weiterhin die bestehende ausdrückliche Erwachsenenbestätigung mit Titel und Preis. Abbrechen und Profilwechsel buchen nichts.
- Bereits geöffnete Bestätigungen behalten ihren unveränderlichen Titel und Preis, auch wenn parallel die Definition bearbeitet oder deaktiviert wird. Die tatsächlich bestätigte Revision erscheint in der gespeicherten Historie.

Die Kategorie „Lumo“ ist eine Kategorie frei formulierter gemeinsamer Gutscheine. Sie erzeugt keine erfundene automatische 3D-Inventarwirkung. Der gesonderte historische Zimmer-Shop wird separat unter `LUMO-ROOM-INTEGRATION.md` behandelt.

## Speicher- und Transaktionsvertrag

`RewardShopProfile` liegt unter `lumo.reward_shop.profile.<sha256(studentId)>`. Die Identität wird vor dem ersten asynchronen Schritt festgehalten. Namen und Klassenstufen bestimmen keine neuen Gutschein-Eigentümer. Historische `lumo.reward_shop.local_<name>_<grade>`-Daten bleiben bestehen. Laden und Profil lesen sie ausschließlich für das lokale Profil (`lease.logStudentId == 'self'`); ein ausgewähltes Schulkind A/B bekommt diese nicht zuordenbare Alt-Historie nicht angezeigt.

Der Profilstore behält Definitionen, ältere Revisionen und bestätigte, noch abzuschließende Einlösungen. Höchstens 100 Definitionen, 5000 Revisionen und 100 gleichzeitig wartende Einlösungen begrenzen den Speicher; das Erreichen dieser Grenzen verwirft keine vorhandenen Daten.

`RewardShopRedemption` enthält Transaktions-ID, Eigentümer, Gutschein-ID, Revision, Titel, Symbol, Vereinbarung, Sternpreis, Mindestlevel, Kategorie und Zeitpunkt. Die gemeinsame `RewardWallet` speichert den Sternabzug und diesen Beleg **in einem Snapshot** in `shopRedemptions`. Neue Gutscheinbelege werden nicht in `gameResultIds` gezählt. Die Preisbuchung verändert weder XP noch bereits verdiente Gesamtsterne.

Der Ablauf ist: ausdrückliche Bestätigung → unveränderlichen ausstehenden Beleg speichern → Wallet atomar abbuchen → Warteliste bereinigen. Bei einem Speicherfehler bleibt derselbe Beleg wiederholbar. Ein identischer Wiederholungsversuch muss eine positive Speicherbestätigung erhalten; er zieht keinen zweiten Preis ab. Die gleiche Transaktions-ID mit verändertem Titel oder Preis wird abgewiesen. Ein lediglich im Preference-Cache sichtbarer Beleg gilt beim Wiederaufnehmen nicht automatisch als dauerhaft bestätigt.

Lesefehler und beschädigte vorhandene Daten werden sichtbar behandelt und nicht durch leere Wallet-/Shopstände überschrieben. Die AppState-Delegatoren prüfen ursprüngliches Profil und aktuelle Auswahl. `RewardShopRepository.flushPendingWrites()` ist im gemeinsamen Backup-Quiesce enthalten.

## Die 40 historischen Basisideen

HTML `baseVouchers()` enthält 40 Basisideen. Die dort beworbenen 140 Einträge entstehen durch automatisch wiederholte „Stufe“-Varianten. Diese Duplikate und ihre andere Preisformel wurden nicht übernommen. Die folgenden 16 konkret benannten Familienideen sind als optionale **Editorvorlagen ohne automatischen Preis** vorhanden. Die Eltern legen ihren aktuellen Sternpreis ausdrücklich fest.

| Historische Idee | Heutige Zuordnung |
|---|---|
| 1 Eis beim Schwimmen | Vorhandene Einträge `eis_essen_gehen` und `schwimmen_gehen`; kein behauptetes automatisches Kombiticket |
| Kakao | Freie Wahl im bestehenden Jausen-/Essensgutschein; konkreter Titel im eigenen Editor möglich |
| Joghurt aussuchen | Bestehende freie Jausenwahl; eigener konkreter Titel möglich |
| Brezel | Bestehende freie Jausenwahl; eigener konkreter Titel möglich |
| Obstbecher | Bestehende freie Jausenwahl; eigener konkreter Titel möglich |
| kleine Sache | Individueller Gutschein im Editor; kein eigener fixer Standardtitel behauptet |
| Sticker | `sticker_aussuchen`, `lieblingssticker` |
| Pixi-Buch | `kleines_buch` |
| Malblock | Bastel-/Malangebot und eigener konkreter Gutschein; kein identischer Standardtitel behauptet |
| Buntstifte | Bastel-/Malangebot und eigener konkreter Gutschein; kein identischer Standardtitel behauptet |
| Spielplatz | `extra_spielplatz`, `spielplatz_gross` |
| Mini-Ausflug | Sinngemäß vorhandene Eltern-/Familienausflüge; eigener kleiner Ausflug frei bepreisbar |
| Picknick | Neue belegte Editorvorlage |
| Schatzsuche | Neue belegte Editorvorlage |
| Seifenblasen | Neue belegte Editorvorlage |
| Schwimmen | `schwimmen_gehen` |
| Ballspiel | Neue belegte Editorvorlage |
| Roller | Neue belegte Editorvorlage |
| Radfahren | Neue belegte Editorvorlage |
| Klettern | Neue belegte Editorvorlage |
| Filmabend | `lieblings_film`, `kinoabend_zuhause` |
| Hörgeschichte | Neue belegte Editorvorlage |
| Kinderlied | Neue belegte Editorvorlage |
| Mini-Kino | `kinoabend_zuhause`, `kino_ausflug` |
| Puppenspiel | Neue belegte Editorvorlage |
| Basteln | `kleines_basteln`, `bastelset` |
| Knete | Neue belegte Editorvorlage |
| Malen | `gemeinsam_malen` |
| Papierflieger | Neue belegte Editorvorlage |
| Wasserfarben | Neue belegte Editorvorlage |
| Brettspiel | Neue belegte Editorvorlage |
| Kuschelrunde | Neue belegte Editorvorlage |
| Extra Geschichte | `gute_nacht_geschichte` |
| Puzzle | Neue belegte Editorvorlage |
| Mama/Papa-Zeit | Vorhandene Familienzeit-/Elternausflüge; konkrete gemeinsame Zeit frei formulierbar |
| Fuchs-Schal | Historischer Lumo-Gutscheintitel ohne Inventarbuchung in `redeem()`; separater Zimmer-Shop |
| Sternkrone | Historischer Lumo-Gutscheintitel ohne angeschlossene Inventarbuchung; keine erfundene Krone ergänzt |
| Pflanze | Historischer Lumo-Gutscheintitel; echte Pflanze gehörte zum separaten `SHOP`/`buyItem()`-Pfad |
| Mini-Drache | Historischer Lumo-Gutscheintitel ohne angeschlossene Drachen-Inventarwirkung; kein Modell erfunden |
| Sternenteppich | Historischer Lumo-Gutscheintitel; tatsächliche Dekoration gehört zum separaten Zimmer-Shop |

## Umgesetzte Dateien

- `lib/domain/rewards/reward_shop.dart`: Definitionen, Revisionen, Belege, Profilstore und Levelprüfung.
- `lib/domain/rewards/custom_reward_templates.dart`: 16 belegte Vorlagen, ohne Preisbehauptung.
- `lib/core/reward_shop_repository.dart`: serialisierte dauerhafte Profilmutation und Wiederaufnahme.
- `lib/core/reward_shop_session.dart`: gemeinsame Profil-, Lade-, Fehler- und Wiederholungsverträge für Editor und Shop.
- `lib/core/reward_wallet_repository.dart`: atomarer Sternabzug mit unveränderlichem Beleg.
- `lib/features/rewards/custom_rewards_card.dart`: erreichbare Elternverwaltung und Formular.
- `lib/features/rewards/reward_shop_content.dart`: Katalog, eigene Kategorien, Freischaltung, Bestätigung, Wiederaufnahme und Historie.
- `lib/widgets/profile_screen.dart`: passende profilgebundene Historie; `parent:`-Aufgabenbelohnungen zählen nicht als gespielte Spiele.
- `SettingsContent`-Einstieg und AppState-Delegatoren wurden im koordinierten Root-/Build-Bereich angeschlossen.

## Tatsächliche lokale Prüfung

Der eigenständige Gutschein-Gate vor der nachfolgenden Zimmererweiterung bestand mit **80/80 Tests, Exit 0, etwa 19 Sekunden**. Darin sind **25 neue** Gutscheinprüfungen: acht Repository-, neun Wallet-/Wiederaufnahme- und acht echte UI-Flows. Gezielte Flutteranalyse der acht Quellen und `test/rewards`: **keine Befunde, Exit 0**. Der gesicherte zugehörige Integrationscheckpoint ist `071f4ecef407e6851c0601c8050e0ac89eadb414`.

Nach der koordinierten Zimmer-/Auszeichnungs-Walleterweiterung wurde derselbe 80er Bestand erneut vollständig geprüft: **25 Gutschein-, 38 Wallet-, sechs State-, fünf Restart- und sechs PIN-frei-Fälle bestanden, jeweils Exit 0**. Zusammen mit den 23 neuen Zimmerfällen waren es **103/103 unterschiedliche grüne Tests** im gemeinsamen Lauf vor dem nachfolgenden Alt-Historien-Nachtrag. Wegen nachgewiesener lokaler Compilerabbrüche beim Vorladen weiterer Dateien liefen die finalen Gates in sechs separaten Prozessen; fehlgeschlagene Sammelaufrufe werden nicht als PASS gezählt. `room-rewards-evidence/games-final-validation.json` enthält sämtliche Befehle, Dateien, UTC-Zeiten, Loghashes und die ausdrücklich erhaltene frühere Fehlversuchsgruppe. Näheres zu diesen Laufzeitgrenzen und zur Zimmerprüfung steht in `LUMO-ROOM-INTEGRATION.md`.

### Nachtrag: isolierte lokale Alt-Historie

Die abschließende Quellenkontrolle fand noch eine eng begrenzte Anzeigelücke: Die neue Historie war bereits stabil profilgebunden; die alte name/grade-Shopdatei wurde aber zusätzlich bei ausgewählten Schulkindern gelesen. `RewardShopSession.load` und `ProfileScreen._load` begrenzen diese Alt-Daten jetzt ausdrücklich auf `logStudentId == 'self'`. Die Dateien bleiben erhalten, und es wurde keine Walletregel geändert.

`test/rewards/legacy_reward_history_owner_test.dart` besteht mit **2/2 echten UI-Flows, Exit 0**. Shop und Profil wechseln jeweils **A → B → Self → A** und prüfen die tatsächlich sichtbare passende Historie sowie bitgenau unveränderte gespeicherte Legacy- und Wallet-Strings. Der vorhandene `custom_rewards_flow_test.dart` wurde danach erneut geprüft: **8/8 PASS, Exit 0**. Die gezielte Analyse der zwei geänderten Quellen und des neuen Tests ist ohne Befund.

Damit sind **103 ursprüngliche + zwei neue = 105 unterschiedliche Prüfungen** belegt. Die acht nochmals ausgeführten Bestandsfälle werden nicht zusätzlich gezählt. Die enge Korrektur erhielt diesen gezielten Nachlauf; das vollständige 103er Paket wurde deswegen nicht noch einmal ausgeführt. Exakte Aufrufe, Quellhashes, Loghashes und die zwei vorherigen Test-Fixture-Korrekturen stehen in `room-rewards-evidence/games-legacy-history-validation.json`.

### Ursprünglicher 80er Aufruf

```sh
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/rewards/custom_reward_repository_test.dart \
  test/rewards/reward_shop_redemption_test.dart \
  test/rewards/custom_rewards_flow_test.dart \
  test/reward_wallet_transaction_test.dart \
  test/reward_wallet_dedup_confirmation_test.dart \
  test/reward_wallet_queue_zone_test.dart \
  test/state_persistence_regression_test.dart \
  test/restart_regression_test.dart \
  test/pin_free_access_test.dart
```

Die UI-Prüfungen erstellen einen Gutschein über die tatsächlichen Formulare, starten mit erhaltenen Daten neu, brechen eine Bestätigung ab, lösen ein, bearbeiten/deaktivieren und sehen den ursprünglichen Titel/Preis im Shop und Profil. Weitere Fälle wechseln das Profil mitten im Editor oder Dialog, unterbrechen den Sternabzug mit simuliertem Prozessverlust und ändern die Definition während offener Bestätigung. Der schmale Bildschirm wird mit **320×740 und 1,6-facher Schrift** tatsächlich bedient. Fehlgeschlagene Treffer auf Bedienelemente sind im Test fatal.

Die Speicherfehler sind kontrollierte Simulationen der Preference-Grenze, keine behaupteten physischen Android-Datenträgerexperimente. Dieser Bericht allein belegt weder eine installierte neue APK noch Fold7-Laufzeit oder hörbare Android-Sprachausgabe. Diese Nachweise gehören zur gemeinsamen Auslieferung.

Ursprüngliche Logs: `games-custom-rewards-final.log` (SHA-256 `a1a64326dc05fb546558eaecc72488034daac53745b351ee253bf967287ac493`) und `games-custom-rewards-analysis-final.log` (SHA-256 `30d1f5bedc8172bf099d0e0f675c5f0fd725b6f95be01194cad753aa11493dae`). Diese und die Nachtragslogs liegen im Quellpaket unter `room-rewards-evidence/`; die ursprünglichen Laufzeitkopien liegen unter `/tmp/lumo-integration-20261122/`.
