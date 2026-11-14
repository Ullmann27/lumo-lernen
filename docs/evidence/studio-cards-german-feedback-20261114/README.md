# Deutsche Kartenrückmeldungen – isolierte Korrektur

## Tatsächlicher Vorherbefund

Ausgangsquellen sind Host `86445f53af5d573549fc8cf03405261611f3cb7e` und Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Fünfzehn relevante Originaldateien wurden gegen deren veröffentlichte Gitblobs gebunden.

Die zwei vorhandenen Originalaufnahmen wurden einzeln geöffnet und nochmals bytegleich zum jeweiligen Original-ZIP-Mitglied geprüft:

- API35: **„Lumo legt green 2.“**, Aufnahme `12b_cards_persisted_draw_after_visible_idle.png`, SHA-256 `9574b8f97b51fd2380e2b267a195ce5867df32c37a332cdcea0763324eeb5aa1`.
- API37: **„Wirbelwind! Du zieht 1 Karte.“**, gleichnamige Aufnahme im getrennten API37-Artefakt, SHA-256 `3f8bfa78adae6d24dc294d3764b6ece28aa52bf9a33208c40765e33182d50ecc`.

Die vollständigen Originalbilder bleiben in den bestehenden Belegpaketen unter `docs/evidence/studio-final-verification-86445f53/{api35,api37}/selected-originals/nextgen/`. Hier werden keine neuen Bilder erzeugt oder ältere Bilder als korrigierte Laufzeitaufnahme ausgegeben. `original-android-observations.json` bindet die tatsächlichen Artefaktmetadaten, Pfade und Originalmitgliedbytes.

## Ursache und enger Patch

`LumoCardsRules` erzeugt `lastActionMessage`. Bei Zahlkarten verwendete dieser sichtbare Text den maschinellen Farbwert `card.color.name`. Mehrere direkt benachbarte Nachrichten verwendeten unabhängig von der Anrede die dritte Person. `cardsTableView` übermittelt denselben Text als `message`; Native `cards_table.gd` zeigt ihn unverändert an.

Die vorhandene Schnittstelle `LumoCardColor.displayName` bildet die bestehenden Karten bereits korrekt auf **Rot, Gelb, Blau, Grün** ab. Die historischen Enumbezeichner `orange/purple/blue/green` bleiben Save-/Regel-/Protokollwerte.

Es ändern sich ausschließlich zehn sichtbare Nachrichtenausdrücke in `lib/features/games/lumo_cards/lumo_cards_rules.dart` und ein reiner Stringhelfer für die Anrede:

- `Du legst Grün 2.` beziehungsweise `Lumo legt Grün 2.`
- `Du ziehst …` beziehungsweise `Mila/Lumo zieht …`, auch bei den vorhandenen Spezialkarten.
- `Du wählst …` beziehungsweise `Mila/Lumo wählt …`.
- `Du hast …`, `Du bekommst … und darfst …` sowie `für dich` in den unmittelbar betroffenen Ergebnis-/Lernnachrichten.
- Genannte Kinder erhalten ebenso wie genannte Bots die dritte Person; entscheidend ist das tatsächlich angezeigte Pronomen `Du`, nicht der Spielertyp.

Keine Änderung an Kartenanzahl, Karteneffekt, Zufall, Gegnerentscheidung, Punktwert, Reward, Runde, Kindbindung, Speicherformat, Sprachcontroller oder Nativequelle. Die vollständigen Nichtnachrichten-Quellbytes sind nach Entfernen des einzigen reinen Formatierhelfers und Normalisieren ausschließlich der `lastActionMessage`-Argumente identisch; dies ist ein dokumentierter Bytevergleich, keine behauptete AST-Analyse.

## Wirklich ausgeführte Tests

1. Derselbe neue Test auf der unveränderten 86445-Regelquelle: **12 Fälle, 2 PASS, 10 FAIL**, Prozesscode 1, 10,601 s. Die beiden tatsächlichen Bildfehler werden als konkrete Textabweichung reproduziert. Die weiteren Fehler betreffen dieselbe unmittelbar verwendete Sprachbildung; es handelt sich nicht um zehn unabhängige Spielmechanikfehler.
2. Korrigierte isolierte Quelle, neuer Test und vier bestehende Regel-/Sitzungs-/Speicher-/Farbgruppen: **64/64 PASS**, Prozesscode 0, 4,462 s. Keine übersprungenen Tests. Davon zwölf neue Fälle und 52 bestehende Fälle.
3. Die reale Produktionsspeicherfunktion `LumoCardsRound.encode` lieferte in allen **zwölf gemeinsam erreichten Vorher-/Nachherbeobachtungen exakt gleiche gespeicherte Werte**. Der neue Lauf erfasste insgesamt 51 Zustände; der rote Lauf stoppt einige Schleifen bei der ersten falschen Beschriftung, weshalb für die übrigen Zustände keine Vorher-Nachher-Messung behauptet wird.
4. Der neue native View-Vertrag liest die tatsächliche Produktionsfunktion `cardsTableView`: korrigierter deutscher Text erreicht den View, während Karten-ID und `green` im maschinellen Payload gleich bleiben.
5. Die bestehenden Gruppen prüfen weiterhin unter anderem alle Kartenphasen, Kartenerhaltung, dauerhafte ACK-Reihenfolge, Profile/Lebenszyklus, Wiederaufnahme, Speicherung und vorhandene deutsche Farbnamen.

Vollständiger grüner Aufruf:

```text
flutter test --no-pub --reporter=expanded
  test/games/cards_german_feedback_test.dart
  test/lumo_cards_rules_test.dart
  test/lumo_cards_table_session_test.dart
  test/lumo_cards_persistence_test.dart
  test/games/cards_color_consistency_test.dart
```

Der anfängliche isolierte Testaufbau hatte noch keinen Link auf ein vorhandenes Dokument-Asset und scheiterte deshalb vor dem Laden der Tests. Dieses unveränderte Infrastrukturprotokoll bleibt als `initial-staging-asset-error.log` erhalten. Nach Bereitstellung des vorhandenen Assets lief der oben genannte echte Originalgegenfall. Der Vorbereitungsfehler wird nicht als Produktfehler gezählt.

## Quellenfreeze und Einbau

`source-upload-manifest.json` enthält genau zwei zu integrierende Dateien: die isolierte Regeldatei und den neuen Test. Der Source-Diff steht separat unter `patch-against-86445.diff`. Die aktive Host-/Nativequelle und sämtliche eingefrorenen C4-Dateien blieben unverändert.

Das Dokumentmanifest enthält nur kleine Originalprotokolle, Bindungen, den Diff und die vergleichenden Daten. Die beiden Original-PNGs bleiben im bereits erfassten Android-Belegpaket und werden nicht ein zweites Mal kopiert.

**Grenze:** Die Korrektur ist lokal kompiliert und mit den tatsächlichen Produktionsregeln/View-/Savefunktionen geprüft. Sie ist noch kein neuer Android-Build, kein erneuter Androidlauf und keine neue visuelle Rendererabnahme. Der nächste gemeinsame Kandidat muss genau diese integrierten Bytes verwenden.
