# Lumos Zimmer – belegte Alt-Funktionen integriert

Stand: 22. November 2026. Der Integrationsauftrag umfasst den tatsächlich bedienbaren Zimmerpfad aus dem gelieferten HTML-Prototyp. Die Übernahme ist ein eigenes lokales Flutter-Modul. Die vorhandene Originalfigur, die gemeinsame Wallet und die aktuellen Kinderprofile bleiben maßgeblich.

## Nachgewiesene Quelle und Umfang

Quelle: `05-lumo_lernen_agent_playready_prototype_app.html`, SHA-256 `d3f679e808199467124a4726150700266c80600f92ebd1b231071fd71ef91f24` aus den 19 bereitgestellten Projektdateien.

| Alter ausführbarer Pfad | Beleg im HTML | Aktueller Anschluss |
| --- | --- | --- |
| Anfangsausstattung blauer Schal | `def()`, Zeile 263: `room.owned/equipped` | `LumoRoomProfile` beginnt mit `scarf_blue`; kein Sternabzug. |
| Gegenstand kaufen | `SHOP`, Zeile 311; `buyItem()`, Zeile 825 | Preisbestätigung → `LumoRoomSession.buy` → dauerhafter Kaufauftrag → gemeinsame atomare Wallet. |
| Gegenstand ausrüsten | `equipItem()`, Zeile 826 | Separater Ausrüsten-Knopf; Schals ersetzen einander, Dekorationen ergänzen das Zimmer, das Thema wechselt. |
| Tatsächlich sichtbare Ausstattung | `renderRoom()`, Zeile 827 und die vier DOM-Elemente in Zeile 180 | `LumoRoomPreview` zeigt die gekauften und ausgerüsteten Elemente sowie die konkrete Schalfarbe. |
| Lumo loben | `petLumo()`, Zeile 828 | +5 Sterne; höchstens einmal pro fünf Minuten und Kinderprofil, mit dauerhaftem Zeitpunkt und Beleg. |
| Fuchs-Snack | `feedLumo()`, Zeile 829 | Nach Preisbestätigung -10 Sterne und +20 XP in derselben Wallet-Transaktion. |
| Tanzpause | `danceLumo()`, Zeile 830 | Bestehende Lumo-Feieranimation und passende sichtbare/sprachliche Reaktion; keine Währung. |

Die ursprünglichen Demo-Anfangswerte von 160 Sternen/160 XP werden nicht erneut vergeben. Die frühere globale HTML-Variable `lastPet` wird an das stabile aktuelle Kinderprofil gebunden. Eine dokumentierte frühere Ersetzung des Zimmerpfads durch Kart, Siedlung oder Kosmos war nicht nachweisbar; die neue Integration übernimmt ihn deshalb ausdrücklich.

## Vollständiger ursprünglicher Zimmerkatalog

| ID | Originalname | Sterne | Art |
| --- | --- | ---: | --- |
| `plant` | Lumo-Pflanze | 80 | Dekoration |
| `rug` | Sternenteppich | 120 | Dekoration |
| `pet` | Mini-Haustier | 180 | Dekoration/Pfotensymbol |
| `star` | Sternlampe | 220 | Dekoration |
| `scarf_blue` | Blauer Schal | 0 | Standardschal |
| `scarf_green` | Grüner Schal | 160 | Schal |
| `scarf_rose` | Rosa Schal | 160 | Schal |
| `room_space` | Sternenraum | 300 | Zimmerthema |

Die Preise und acht IDs stammen aus dem Original. Es gibt keine erfundenen Preisstufen, neuen 3D-Modelle oder automatischen Familiengutscheine. Der virtuelle Kauf benötigt eine klare Sternpreisbestätigung. Die vorhandene Erwachsenenbestätigung für reale Familiengutscheine bleibt bei deren Einlösung; für das Zimmer wird kein neuer PIN eingeführt.

## Erreichbarer Einstieg und Darstellung

`lib/features/home/home_content.dart` bindet `LumoRoomCard(appState: appState)` hinter der Elternaufgabenkarte ein. Der Button „Zimmer öffnen“ öffnet `LumoRoomScreen`; die Einstiegsverdrahtung wurde durch Root integriert.

Die Vorschau nutzt das vorhandene Originalasset `assets/lumo_design/fox/fox_arms_open.png` im bestehenden `LumoCharacter`. Der Schal liegt als lokale Zeichenebene darüber und bewegt sich mit derselben Figur. Orange-weißer Fuchs, blaue Fliegerbrille und dunkelblaue Jacke bleiben erhalten; das leuchtende L wird nicht verdeckt. Die vier Dekorationen entsprechen dem begrenzten alten CSS-/Symbolpfad. Dies ist eine echte lokale **2D-Zimmervorschau**, kein nachträglich behaupteter Godot-Raum oder neues Figurenmodell.

Die Bedienelemente haben mindestens 48 dp Höhe. Der Inhalt scrollt auf schmalen Bildschirmen; Kauf- und Snack-Dialoge sind scrollbar. Das Lob bleibt während der Sperrzeit als freundliche Reaktion bedienbar, zahlt aber keinen weiteren Bonus. Bei zurückgestellter Uhr bleibt ein gespeicherter späterer Freigabezeitpunkt wirksam.

Sprachreaktionen verwenden `LumoLearningNarration.feedback` und dessen vorhandene Eigentümerprüfung am gemeinsamen Player. Sie verdrängen keine andere Ansage. Profilwechsel, Hintergrundwechsel und Dispose beenden nur eine noch dem Zimmer gehörende Anfrage. Sichtbarer Text bleibt auch ohne verfügbare Sprachausgabe erhalten; die bestehende Stimmenwahl und Freigabe werden verwendet.

## Speicherung, Wiederholung und Profilbindung

- Zimmerdaten liegen unter `lumo.room.profile.<sha256(studentId)>`: ausgerüstete IDs, Thema, dauerhafte erste Kaufangebote und offene Aktionsaufträge.
- Ein Kauf verwendet die deterministische Beleg-ID `shop:<ownerHash>:<hash("lumo-room-v1:<itemId>")>`. Sein erster Preis-/Titel-/Zeitpunkt-Snapshot bleibt bei zwei geöffneten Instanzen, erneutem Tippen und Neustart gleich.
- Die gemeinsame Wallet schreibt Sternabzug und unveränderlichen Kaufbeleg atomar. Der Besitz wird ausschließlich aus passenden bezahlten Belegen für das betreffende Kind abgeleitet; der kostenlose blaue Schal ist die einzige Ausnahme. Ein gespeicherter Ausrüstungsname allein verschafft keinen Gegenstand.
- Lob und Snack erhalten eigene `room:<ownerHash>:<nonce>`-IDs. `roomActions` speichert Aktion, Zeitpunkt und die festen ursprünglichen Beträge mit demselben Wallet-Snapshot. Die Einträge gehen nicht in den Spielezähler ein.
- Ein wiederholter bekannter Beleg wird unverändert erneut gespeichert, bis die Plattform positiv bestätigt. Wiederholung zahlt weder einen zweiten Lobbonus noch zieht sie den Snack-/Kaufpreis erneut ab.
- Ein negativer SharedPreferences-Schreibbescheid führt zum Neuladen des Dart-Caches. Da Android auch bereits veränderte native Speicherdaten zurückliefern kann, reicht das allein nicht: Vor der sichtbaren Ausstattung bestätigt der Session-Ladepfad den Zimmerstand mit `loadConfirmed` und einem aktiven Profil-Guard erneut positiv. Offene Kauf-/Aktions-IDs bleiben für den identischen Retry erhalten.
- Nach Profilwechsel oder während einer Datensicherung verlieren alte Dialoge und noch offene Operationen ihre Berechtigung. Bereits akzeptierte Schreibvorgänge werden durch die vorhandenen Queues abgeschlossen; `LumoRoomRepository.flushPendingWrites()` ist Teil des Backup-Quiesce.
- Die Wallet bleibt wie bisher gemeinsam. Die Zimmerausstattung und der Lob-Cooldown sind profilgebunden. Es werden keine neuen getrennten Sternenkonten behauptet.

Im selben koordinierten Wallet-Anschluss wurden `achievementClaims` und `earnedStarsByOwner` ergänzt. Neue positive tatsächliche Gutschriften können ihrem ursprünglich angenommenen Kinderprofil zugeordnet werden; alte nicht zuordenbare Gesamtbeträge bleiben unzugeordnet. Eine Ausgabe reduziert diesen historischen Zähler nicht. Claim-Freischaltung, Wand und deren eigene Tests sind im separaten Bericht `ACHIEVEMENTS-INTEGRATION.md` dokumentiert. Die AppState-Delegatoren und die Erfassung des ursprünglichen Owners gehören zum Build-Agent-Anschluss.

## Dateien

| Bereich | Dateien |
| --- | --- |
| Katalog, Belege und Profilmodell | `lib/domain/room/lumo_room.dart` |
| Persistenz und aktuelle Profil-Session | `lib/core/lumo_room_repository.dart`, `lib/core/lumo_room_session.dart` |
| Einstieg, Bildschirm, echte Vorschau | `lib/features/room/lumo_room_screen.dart` |
| Gemeinsame atomare Wallet | `lib/core/reward_wallet_repository.dart` |
| Koordinierte Root-/Build-Anschlüsse | `lib/features/home/home_content.dart`, `lib/app/app_state.dart` |
| Transaktionen und Speichergrenzen | `test/room/lumo_room_wallet_test.dart` |
| Echte Bedienung und Bildbelege | `test/room/lumo_room_flow_test.dart` |

Der vorhandene Profil-Spielezähler schließt `parent:`- und `recognized:`-Ergebnisfamilien aus; alle bisherigen Spiel-IDs bleiben unverändert. Der Gutschein-UI-Test prüft einen echten Spielbeleg zusammen mit beiden nichtspielerischen Familien und erwartet weiterhin genau ein gespieltes Spiel.

## Ausgeführte Prüfungen

Die gemeinsame Zimmer-/Gutschein-/Walletprüfung bestand mit **103/103 unterschiedlichen Tests**, auf sechs vollständig beendete Prozesse verteilt, jeweils **Exit 0**. Der Zimmeranteil enthält 17 Repository-/Walletfälle und sechs echte Widget-Flows. Die gezielte Dart-Analyse der Zimmerquellen, Wallet, Room-/Gutschein-Tests und zehn angepassten Bestands-Test-Fakes meldete **keine Befunde**.

Der anschließend im Gutscheinbericht dokumentierte enge Alt-Historien-Nachtrag ergänzt **zwei neue bestandene UI-Prüfungen** für Shop und Profil sowie acht erneut bestandene vorhandene Gutschein-Flows. Das ergibt **105 unterschiedliche grüne Fälle**, ohne die acht Wiederholungen doppelt zu zählen. Der Zimmercode wurde dafür nicht verändert; die gezielte Prüfung steht in `room-rewards-evidence/games-legacy-history-validation.json` und `CUSTOM-REWARDS-INTEGRATION.md`.

| Endgültiger Teilaufruf | Ergebnis | Dauer einschließlich Start |
| --- | ---: | ---: |
| Beide Room-Testdateien | 23/23 | 8,8 s |
| Drei eigene Gutschein-Testdateien | 25/25 | 12,3 s |
| Wallet-Transaction, Dedup-Confirmation und Queue-Zone | 38/38 | 2,6 s |
| `state_persistence_regression_test.dart` | 6/6 | 6,3 s |
| `restart_regression_test.dart` | 5/5 | 2,6 s |
| `pin_free_access_test.dart` | 6/6 | 3,1 s |

Diese finalen Aufrufe liefen am 22. November 2026 zwischen **19:46:32 und 19:48:45 UTC**. `room-rewards-evidence/games-final-validation.json` enthält Dateilisten, exakte CLI, Zeitpunkte, Exitcodes und SHA-256 für jedes Log. Die zuvor fehlgeschlagene Sammelgruppe ist darin als durch die drei erfolgreichen Einzelaufrufe ersetzt gekennzeichnet und bleibt als Evidenz erhalten.

```sh
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/room/lumo_room_wallet_test.dart \
  test/room/lumo_room_flow_test.dart

flutter test --no-pub --concurrency=1 --reporter expanded \
  test/reward_wallet_dedup_confirmation_test.dart
```

Der UI-Test betätigt den tatsächlichen Einstieg und kauft alle sieben kostenpflichtigen Gegenstände nach Preisbestätigung. Er rüstet sie aus, verwirft zuerst einen Kaufdialog, startet mit gespeicherten Daten neu und wechselt A → B → A. Weitere Fälle prüfen Lob/Snack/Tanz, den kalten Neustart nach unklarer Speicherantwort, einen Profilwechsel während einer offenen Preisbestätigung, 320×740 bei 1,6-facher Schrift und die Eigentümerschaft verspäteter Sprachausgabe. Fehlende Treffer auf Widgets sind im Test fatal. Die Walletfälle prüfen zusätzlich Uhr-Rückstellung, exakte Fünf-Minuten-Grenze, konkurrierende gleiche Käufe, ungekaufte Ausrüstung, manipulierte Aktionsart und positive Wiederbestätigung bei drei simulierten Fehlerarten.

Zwei bereits vorhandene AppState-Dedup-Erwartungen wurden auf die neue Owner-Zuordnung ergänzt: genau die tatsächlich verdienten zwei Sterne gehören dem ursprünglichen Kind. Der übrige vollständige Snapshot- und Disk-/Cache-Vergleich bleibt erhalten. Das ist keine Abschwächung der Abbuchungs- oder Wiederholungsprüfung.

Der erste kombinierte 103er Aufruf bestand die 23 Zimmerfälle, hing anschließend beim Laden einer weiteren Testdatei und wurde mit Exit 130 beendet. Ein nachfolgender großer Bestandsaufruf erreichte die erwähnten zwei alten Owner-Erwartungen und hing später erneut beim Dateiladen (Timeout, Exit 124). Eine weitere 17er Sammelgruppe meldete ausdrücklich „The Dart compiler exited unexpectedly“ während des Vorladens der nächsten Datei; alle sechs bereits laufenden State-Assertions bestanden, der Prozess musste aber in den 90-s-Timeout laufen. Diese Aufrufe werden ausdrücklich **nicht** als bestandene Gesamtgates ausgegeben. Nach Freigabe reproduzierbarer temporärer Caches und der Aufteilung endeten alle oben ausgewiesenen finalen Gruppen erfolgreich. Die früheren Logs bleiben in `room-rewards-evidence/` nachvollziehbar; es erfolgte keine Produktänderung wegen des Compilerabbruchs.

## Visuelle Belege und Aussagegrenzen

Der echte Widgettest lädt das Originalasset, die vorhandenen Nunito-Dateien und MaterialIcons und rendert die Vorschau selbst in PNG. Die erzeugten Bilder wurden vom Agent und unabhängig von Root angesehen: beide Schalfarben, alle vier Dekorationen und der Themenwechsel sind sichtbar; keine Symbol-Ersatzkästchen, kein verdecktes Jacken-L.

Die eigenen Logs, das Ergebnismanifest und beide PNGs sind zusätzlich unter `docs/integration/2026-11-22/room-rewards-evidence/` im Quellpaket enthalten.

| Datei in `room-rewards-evidence/` | SHA-256 |
| --- | --- |
| `lumo-room-starter.png` | `67ef9586c7bb45f4ec07e12150b2d67ecfba4189c391458475a6dc1b2503b0df` |
| `lumo-room-equipped.png` | `a16f74df10a4ee5cefd33c3af3c34609165d47c0513ad2bc9b39fb4badeabcdf` |
| `games-room-first.log` | `d092e351197b0c3d568376cebe5e74b9d5644b6ce8d40cbef717c07e9dfa2434` |

Die Speicherfehlertests modellieren die Plattformgrenze und native Cache-Ungewissheit; sie sind keine Behauptung eines absichtlich erzeugten Android-Datenträgerfehlers. Die PNGs sind Flutter-Testframes. Android-Emulatortour, APK-Provenienz und Gerätetest werden getrennt durch den finalen Build-/Auslieferungspfad belegt; aus diesem Bericht folgt kein bereits bestandener Fold7-Test.
