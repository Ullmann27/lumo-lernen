# Memory, Vier Gewinnt und Quizshow: kleinster belastbarer 3D-Anschluss

Stand: 14.11.2026. **Lesende Integrationsanalyse, keine Implementierung und keine neue Testabnahme.** Der laufende Android-Kandidat bleibt unverändert.

Die 20 maßgeblichen Hostdateien wurden vor der Analyse mit den tatsächlichen Gitblobs beziehungsweise Rohbytes von `Ullmann27/lumo-lernen@4ab96666f954baf258422d6ed277fc297b7ddeef` verglichen; alle stimmen überein. Die einzelnen Pfade und SHA-256 stehen in `source-binding.json`. Native Ausgangsquelle ist der bereits abgenommene Stand `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Es wurden keine neuen Spiele, Testläufe, Rendererbilder oder Android-Ergebnisse erzeugt.

## 1. Tatsächlicher Bestand und notwendige Trennung

| Spiel | Bestehende Regelautorität | Tatsächlicher Speicherstand | Kleinste notwendige Anpassung |
|---|---|---|---|
| Memory | `lib/domain/games/memory_board.dart` mischt die Paare. Aufdecken, Zugwechsel, Lumo-Gedächtnis, Verzögerungen und Rundenergebnis liegen noch in `_LumoMemoryScreenState` in `lib/features/games/memory/lumo_memory_game.dart`. | `lumo.memory.stats.v1.<sha256(studentId)>` speichert `difficulty` und `best`. Die laufende Kartenverteilung, offene Karten und Lumo-Gedächtnis werden in diesem Pfad nicht gespeichert. Der alte ungebundene Schlüssel `lumo_memory_v2` wird ausdrücklich nicht übernommen. | Die vorhandenen Zustandsübergänge in einen gemeinsamen Dart-Controller herauslösen. Flutter und Godot bedienen dann denselben Controller. Die Native-Seite darf kein zweites Memory-Regelwerk erhalten. |
| Vier Gewinnt | `lib/features/games/connect_four/connect_four_engine.dart`: `drop`, `at`, `validColumns`, `findWinningLine`, `chooseLumoColumn`. Drei vorhandene Botstufen einschließlich begrenzter Suche; Regeln liegen bereits außerhalb der Widgets. | Im produktiven `lumo_connect_four_game.dart` liegt die Partie nur in `_game`; dort gibt es keine vollständige Spielstandsserialisierung. | Den bestehenden `_place`-/Bot-/Pausenablauf in einen schmalen Sitzungscontroller verschieben. Die Engine und ihre Botentscheidung wiederverwenden. |
| Quizshow | `lib/domain/quiz/quiz_show.dart`: `QuizShowEngine.start/selectAnswer/reveal/nextQuestion/useJoker`. `quiz_question_bank.dart` liefert die vorhandenen 20 schulstufengerechten Fragen. | `QuizShowContent` hält `_state`, Kategorie und die laufende Antwortverriegelung im Widget. Im gelesenen Pfad wird keine komplette Quizrunde gespeichert. | Die vorhandene Engine weiterverwenden; nur Auswahl, Verriegelungszeit, Audio und Ergebnisbuchung aus dem Widget in eine Sitzung auslagern. Fragen und richtige Antworten bleiben in Dart. |

Die aktuellen Spielwelt-Routen sind ausdrücklich Flutter-Routen: `SpielweltRoutes` nennt `LumoMemoryScreen`, `LumoConnectFourScreen` und `QuizShowContent`. Ein neuer Eintrag in Godot allein macht deshalb keines dieser drei Spiele in der App erreichbar.

## 2. Den bestehenden Cards-Kanal gezielt wiederverwenden

Das tragfähige Muster ist bereits in `lib/features/games/lumo_cards/lumo_cards_table_session.dart` vorhanden:

- Ein Dart-Controller bleibt alleinige Regelautorität. Der Renderer erhält eine öffentliche Ansicht; verdeckte Informationen bleiben im Host.
- Eine Sitzung verwendet ein zufälliges Token, monotone `revision` und `sequence`, sowie `ack`. Der Host akzeptiert nur die aktuelle veröffentlichte Revision, eine gültige Profilfreigabe und einen aktiven Vordergrund.
- `pump()` speichert die akzeptierte Änderung vor dem ACK. Schreibfehler pausieren die Sitzung; wiederholte Eingaben dürfen die Aktion nicht erneut anwenden.
- `CardsTableBridge.kt` verwendet begrenzte atomare Dateien und eine prozessübergreifende Dateisperre. `CardsAuthorityService`/`CardsAuthorityRegistry` binden den weiterhin laufenden Dart-Host. `LumoGameActivity.kt` liefert den vom Renderpoll unabhängigen Lifecycle-Heartbeat. Das bestehende 2.500-ms-Dart-Limit und die explizite Wiederaufnahme bleiben maßgeblich.
- Beim Öffnen entfernt der Cards-Screen seinen Flutter-Pausenbeobachter vor dem Aktivitätswechsel. Nach der Native-Rückkehr bleibt dieselbe Dart-Runde verfügbar. Dieser Übergang ist auch für die drei neuen Spiele erforderlich: Ein zweiter gleichzeitig aktiver Flutter-Lifecycle-Beobachter würde den Hostcontroller beim Öffnen von Godot erneut pausieren.

**Der unveränderte Cards-Kanal kann heute keine Memory-/Spalten-/Quizaktionen übertragen.** Seine Kotlin-Whitelist enthält ausschließlich `play/draw/color/answer/handover/pause/resume/call`; Launcher, MainActivity, Godot-Boot und SceneRouter kennen die drei neuen Native-Szenen noch nicht. Ein Missbrauch von `cardsToken` oder von `answer` für fremde Spiele wäre keine saubere Integration.

Der kleinste gemeinsame Anschluss ist deshalb ein additiver Brettspielkanal mit ausdrücklich drei erlaubten Spielarten, der dieselben geprüften Transport- und Lifecycle-Grundfunktionen nutzt. Bestehendes Cards-Verhalten wird beim Herauslösen dieser Grundfunktionen durch seine bisherigen Verträge erhalten. Kein allgemeines Skript- oder Dateizugriffsprotokoll ist erforderlich.

## 3. Konkreter Vertrag für die erste Umsetzung

Die folgenden Bezeichnungen sind **vorgeschlagene neue Schnittstellen**, keine Behauptung vorhandener APIs:

`BoardSessionAdapter` besitzt genau fünf Aufgaben: `publicView`, `accept(action)`, `pause/resume`, `snapshot`, `restore`. Die Sitzung hält den vor dem ersten Await erfassten `LearningProfileLease`. Vor Verarbeitung, Schreiben und Veröffentlichung werden dessen Gültigkeit, die aktive Auswahl und die Spielberechtigung geprüft.

Der gemeinsame Umschlag enthält `protocol=1`, `game`, `token`, `roundId`, `revision`, `ack`, `phase`, `paused`, `reduceMotion`, `allowedActions`, `view`. Eine Eingabe enthält lediglich dieselbe Identität, die gesehene Revision, eine neue Sequenz sowie eine spielartspezifische Aktion. Native meldet niemals selbst einen Sieg, eine richtige Antwort, Sterne oder einen gespeicherten Fortschritt.

| Spielart | Öffentliche Ansicht | Erlaubte Spielaktionen | Private Hostdaten |
|---|---|---|---|
| `connect_four` | 6×7 öffentliche Steine, Zug, gültige Spalten, letzter angenommener Zug, Gewinnlinie, Modus und Botstufe | `drop(column)`; gemeinsame Pause/Wiederaufnahme/Neustart | Ergebnisbuchung und persistente Eigentümerbindung. Die Botentscheidung kommt ausschließlich aus `chooseLumoColumn`. |
| `memory` | Stabile Feld-IDs, verdeckt/offen/gefunden, Motiv nur bei offenem oder gefundenem Feld, Paarzahlen, Zug und Interaktionsfreigabe | `flip(cellId)`; gemeinsame Aktionen | Ganze Kartenverteilung, Lumo-Gedächtnis, ausstehende Paarprüfung, Botentscheidung und Zufallszustand. Verdeckte Motiv-IDs gehen nicht über die Brücke. |
| `quiz` | Aktuelle Frage, vier Optionen, Auswahl, verborgene Optionen nach Joker, sichtbarer Hinweis/Publikum, Fragenummer, gesicherte Stufe und Verriegelungsphase | `select(index)`, `lock`, `next`, `joker(kind)`; gemeinsame Aktionen | Übrige Fragen, richtige Antwort vor Auflösung, private Auswertung und Auszahlungsidentität. Nach `reveal` wird nur die dann tatsächlich freigegebene Lösung öffentlich. |

Die 3D-Animation zeigt einen bereits autoritativ angenommenen Übergang. Ein Godot-Tween oder ein verspätetes Animationsende darf weder einen Botzug noch eine Antwortauszahlung auslösen. Während einer visuellen Übergangsphase bleiben spielentscheidende Eingaben gesperrt; die maßgebliche verbleibende Zeit liegt in der pausierbaren Dart-Sitzung. Dies erhält die vorhandenen Memory-Verzögerungen und den Vier-Gewinnt-Landungs-/Botablauf, ohne sie vom Software-Renderer abhängig zu machen.

## 4. Daten und Belohnungen: konkrete offene Arbeit

Für Wiederaufnahme nach Prozessende braucht es einen **zusätzlichen**, versionierten Dart-Spielstand, etwa `lumo.board.round.v1.<ownerHash>.<game>.<slot>`, über `LearningStorage`. Der Owner wird aus `captureLearningProfile().studentId` abgeleitet. Bestehende Lernprofile, Memory-Rekorde und Cards-Runden bleiben unverändert. Es gibt keine automatische Zuordnung alter namenbasierter Daten.

Der neue Decoder muss im Releasebetrieb begrenzt und vollständig validieren; Debug-Assertions der vorhandenen Quiz-Engine reichen dafür nicht. Notwendig sind:

- Vier Gewinnt: Modus, Botstufe und gültige Zugfolge; Wiederherstellung kann die vorhandene `drop`-Methode Zug für Zug verwenden und illegale Fortsetzungen nach Spielende ablehnen. Eine bereits ausgewählte, aber noch nicht dargestellte Botaktion darf nicht doppelt ausgeführt werden.
- Memory: Tatsächlich ausgeteilte Paare, offene/gefunden-Markierungen, erster Pick, Zug, Paarzahlen, Lumo-Gedächtnis und ausstehender Übergang. Nur den Seed zu speichern genügt nicht für eine schon laufende Partie. Der spätere Zufallszustand beziehungsweise die bereits angenommene Botentscheidung muss klar definiert sein.
- Quiz: Die konkrete private Fragefolge einschließlich ihrer Version und Inhalte, Index, Auswahl, Joker, aufgelöst/gesichert, verbleibende Verriegelungsphase und Ergebnisstatus. Ein erneuter Abruf der aktuellen QuestionBank darf eine fortgesetzte alte Fragefolge nicht verändern.

**Bestehende Belohnungseigenschaften nicht überbehaupten:** Die drei Screens buchen heute über `appState.addStars`/`addXp`; `RewardWalletRepository` verwendet den globalen Schlüssel `lumo_reward_wallet_v1`. Kindgebundene Memory-Rekorde sind kein Nachweis für eine kindgebundene Wallet. Die bestehende Wallet enthält bereits idempotente Ergebnis-IDs, aber `awardGameResult` akzeptiert höchstens 100 Sterne und 1.000 XP. Die vorhandene Quizshow vergibt 50/200/800/5.000 Sterne. Das ist durch den tatsächlichen Datenfluss belegt, nicht aus einer bloßen Punkteanzeige abgeleitet: `QuizShowEngine.securedStarsAfterIndex` definiert die Stufen, `reveal()` setzt beim Ende `awardedStars`, und `QuizShowContent._resolveAnswer()` ruft beim ersten Spielende ausdrücklich `widget.appState.addStars(next.awardedStars)` auf. Daher darf der Quizadapter weder Werte abschneiden noch pauschal den Rennspiel-Guard erhöhen. Für zusätzliche Wiederaufnahme nach Prozessende benötigt er eine eigene, eng auf die bestehenden autoritativ erreichten Quizstufen begrenzte und nach `roundId` deduplizierte Auszahlung innerhalb der bestehenden Wallet-Transaktion. Ein reiner Darstellungswechsel behält die bisherige Auszahlung unverändert. Alte Walletdaten werden dabei nicht umgeschrieben oder neu verteilt.

Die neue Rundenspeicherung und idempotente Abrechnung sind Voraussetzung für eine behauptete Wiederaufnahme nach Prozessende. Ein nur im Speicher weiterlaufender Dart-Screen reicht dafür nicht. Eine Umstellung der bestehenden globalen Wallet auf Kinderkonten ist eine gesonderte Datenentscheidung und gehört nicht verdeckt in den 3D-Anschluss.

## 5. Exakter Änderungszuschnitt für die Umsetzung

| Ebene | Bestehende Anschlusspunkte | Additive Arbeit |
|---|---|---|
| Flutter-Sitzung | Die drei oben genannten Spiel-Screens und Engines; `lumo_game_pause_scope.dart`; vorhandene `LearningStorage`-/Lease-APIs | Ein gemeinsamer `board_table_session.dart`, ein `board_round_repository.dart`, drei kleine Adapter. Memory-Zuglogik wird herausgelöst; ConnectFour-/Quiz-Engine werden weiterverwendet. |
| App-Einstieg | `lib/features/lumo3d/lumo3d_launcher.dart`, die tatsächlichen Screens, `SpielweltRoutes` | Erreichbarer 3D-Start aus der bestehenden Runde; sichere Rückkehr zur gleichen Runde. Keine Umleitung auf ein anderes Spiel. |
| Android | `tools/auto_install/MainActivity.kt`, `LumoGameActivity.kt`, bestehende Cards-Transport-/Autoritätsklassen | Gemeinsamen beschränkten Mailbox-/Heartbeatkern mit getrennten Spielart-Whitelists verwenden; neue Kanal-/Token-Namen, echte Binderautorität und gleiche Pausengrenzen. Cards bleibt kompatibel. |
| Godot | `scripts/systems/host_bridge.gd`, `scripts/app/app_boot.gd`, `scripts/app/scene_router.gd`, `MobileRuntime` | Drei freigeschaltete produktive Szenen und ein kleiner gemeinsamer Hostclient. Jede Szene sendet echte Touchaktionen und rendert nur die bestätigte öffentliche Ansicht. Gemeinsame gemessene Safe Area und ≥48-dp-Ziele verwenden. |

Die drei Szenen benötigen echte Geometrie und konkrete Interaktionen: Vier Gewinnt mit kollisions-/raybasiert ausgewählter Spalte und bestätigtem Steinfall; Memory mit berührbaren Kartenkörpern und echter Vorder-/Rückseite; Quiz mit räumlicher Bühne und großen, lesbaren Auswahlflächen. Ein gerendertes Studio ohne Verbindung zu den oben genannten Aktionen gilt nicht als Umsetzung.

## 6. Reihenfolge und Abnahme des ersten kleinen Produktionsschritts

**Zuerst Vier Gewinnt vollständig anschließen.** Seine bestehende Regel- und Botengine ist bereits getrennt; damit lassen sich Transport, Speicherung, Unterbrechung und Rückkehr ohne gleichzeitige Memory-Controller-Extraktion belegen. Danach Memory, zuletzt Quiz einschließlich seiner besonderen Auszahlung.

Für den ersten Schritt sind die folgenden Nachweise ausreichend konkret und notwendig; sie wurden in dieser lesenden Analyse nicht erneut ausgeführt:

1. Dieselbe echte Spalteneingabe verändert die bestehende Dart-Engine genau einmal, Godot zeigt die bestätigte Zelle, danach folgt der tatsächlich berechnete Botzug. Volle/falsche Spalten, fremdes Token, alte Revision und doppelte Sequenz verändern nichts.
2. Die ursprünglichen Engine-/Taktik-/Botstufentests bleiben bestehen; dieselben legalen Zugfolgen liefern vor und nach der Controller-Anbindung dasselbe Brett und dieselbe Gewinnlinie.
3. Schreibfehler verhindert ACK und Belohnung; neuer Start lädt dieselbe validierte Eigentümerrunde. Ein Profilwechsel, eine geschlossene Autorität oder Android-Pause verhindert weitere Züge. Ergebnis-Replay vergibt keine zweite Belohnung.
4. Echte Android-Toucheingaben auf Phone/Fold mit gemessener Safe Area bedienen die erwartete Spalte. Screenshot und öffentlicher Zustand stimmen überein. Pause stoppt den Bot, Fortsetzen setzt ihn geordnet fort; Rückkehr zeigt tatsächlich die gleiche Flutter-Partie.

Die vergleichbaren Memory-Verträge kommen aus `test/domain/memory_board_test.dart`, `test/games/memory_profile_storage_test.dart`, `memory_match_feedback_test.dart` und `memory_theme_pack_test.dart`. Für Vier Gewinnt sind `connect_four_engine_test.dart`, `connect_four_tactics_test.dart` und `connect_four_lumo_level_test.dart` vorhanden. Quiz besitzt unter anderem `quiz_show_meister_test.dart`, `quiz_category_lock_lifetime_test.dart` und `quiz_show_live_ladder_lockin_test.dart`. Diese vorhandenen Tests sind Ausgangspunkte; ihre Existenz ersetzt weder neue Integrationsprüfungen noch echte Android-/Rendererbelege.
