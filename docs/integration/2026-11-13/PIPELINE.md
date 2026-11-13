# LUMO: aktive Integration und Reparatur

Stand: 13. November 2026. Dieses Team arbeitet ausschließlich an der Übernahme bestehender Entwicklungen und an konkret belegten Anschlussfehlern.

## Auftrag und Zuständigkeit

Der Besitzer hat einen Hauptintegrator und drei Helfer beauftragt: Flutter-Anschlüsse, Godot-Anschlüsse und Pipeline-/Integrationsreparaturen. Die anderen Studio- und Spielewelt-Teams entwickeln auf ihren eigenen Zweigen weiter. Es werden keine fremden uncommitteten Arbeitsbäume übernommen oder geändert.

**Aktuelle Besitzerkorrektur: keine geplante Aufgabe.** Die kurz angelegte stündliche Folgeprüfung wurde erfolgreich deaktiviert. Diese Zusammenarbeit findet nur in der aktiven Sitzung statt; dieses Dokument startet keinen Hintergrunddienst. Eine spätere Sitzung muss den echten aktuellen Stand erneut lesen.

Gemeinsamer Sammelpunkt: [Flutter PR #465](https://github.com/Ullmann27/lumo-lernen/pull/465), Zweig `integration/lumo-connections-20261113` in beiden Repositories. Koordination ist auf [Produkt-PR #461](https://github.com/Ullmann27/lumo-lernen/pull/461#issuecomment-6853367123) und [Native-PR #157](https://github.com/Ullmann27/lumo-godot/pull/157#issuecomment-6853367809) veröffentlicht. `status.json` enthält die konkrete Quellenwarteschlange.

## Quellen und tatsächlich geprüfte Integration

Produktbasis ist Flutter `3c712129fef8f144d8946fad567b9ed11c628a60` mit Native-Pin `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` und Godot 4.6.3. Aktuell gesicherte Reparaturen: `aea885f0f07644de2d6057ce32ef2bb5a636cdc3`. Dessen Git-Baum `0a037b2f789dfa1e506edfad161284b5d8d5c5a8` stimmt exakt mit dem lokal geprüften kombinierten Baum überein.

- #463 wurde über den fertigen Folgecommit `f257c787878be5d3d9615d1258aaa8f2f83a945e` aus #464 vollständig übernommen: kollisionsfreie, unveränderliche Bildnachweise und eng begrenzte Logcat-Transportwiederholung. Die tatsächlichen Sprach- und Bildfreigaben bleiben unverändert erforderlich.
- Der historische Build-1999-Updatejob ist auf seinen ursprünglichen Kandidatenzweig begrenzt. Die früher nachgewiesene Prüfung einer 1999-APK gegen die 2018-Versionsdatei entfällt; der historische Jobkörper ist unverändert.
- **318 vollständige Skriptverträge PASS, 0 Fehler, 0 übersprungene Tests**, 43,241 Sekunden. Quellenhashes vor/nach dem Lauf sind gleich. Rohprotokoll und Manifest liegen unter `docs/evidence/integration-20261113/`.
- Unabhängige Zusatzprüfung: 5 Speech-Logcat- und 12 Sprachevidenztests PASS. Actionlint für die zwei betroffenen Workflows PASS. Diese Prüfungen sind keine neue Android-Tour oder APK-Abnahme.

Die tatsächliche Produktabnahme bleibt von diesen Übernahmen getrennt. Auf dem Ausgangsstand waren APK-Bau, Android-Host-Kompilierung und das 2017-zu-2018-Update in Lauf 43405216014 erfolgreich, während die Android-Tour bei der letzten Abfrage noch lief. Der Native-Lauf 43399721309 ist auf ada5ed81 erfolgreich. Vor Produktaufnahme beide Live-Stände neu prüfen; keine veraltete Erfolgsmeldung übertragen.

## Aktuell in Arbeit

Die alte #456 enthält bislang fehlende echte Garage-/Resume-Prüfungen. Der Pipeline-Helfer verbindet ihre wiederverwendbaren Nachweise mit dem aktuellen Spatial-Menü und der bestehenden Android-Tour. Es wird kein alter 2015-Publisher aktiviert. Tatsächliche Kartwahl, neue Rennidentität und Weiterfahrt im selben Rennen müssen aus echten Touches und der vom Spiel geschriebenen Session belegt werden.

Studio hat Host-Checkpoint `a8e09123805b2bf30706c8dd1914b928ae6b24ca` veröffentlicht. Er aktiviert unter anderem `equal_sharing`; diese Route benötigt eine korrespondierende neue Godot-Lieferung. **Den Host nicht allein mit dem alten ada5ed81-Pin als vollständig angeschlossen behandeln.** Die beiden Fachhelfer prüfen deshalb Host und Native gemeinsam. Die Grafik-/Spielraumlieferung ist zusätzlich auf ihren tatsächlich veröffentlichten Stand zu prüfen.

## Übernahmeverfahren in dieser Sitzung

1. Exakten veröffentlichten Quell-SHA, Dateien, Abhängigkeiten und reale Prüfungen lesen. Ein Checkpoint oder offener PR ist noch kein fertiger Gesamtnachweis.
2. Abstammung und Inhalte vergleichen. Bereits portierte alte Dateien nicht über neuere Funktionen schreiben; siehe `flutter_inventory.md` und das entsprechende `godot_inventory.md` im Native-Repository.
3. Disjunkte Übernahmen im eigenen Integrationsbaum zusammenführen, konkrete Konflikte reparieren und die betroffenen bestehenden Prüfungen ausführen. Neue Tests nur zur Reproduktion eines echten Fehlers oder zur Schließung der belegten Anschlusslücke.
4. Native-Quelle, Rendererbelege, Host-Vertrag und Pin als ein zusammengehöriges Paket prüfen. Alte Bildfreigaben werden nicht auf neue Native-SHAs umetikettiert.
5. Änderungen über erwartete Remote-SHAs sichern und zurücklesen. Die lokale Git-Schreibanmeldung ist nicht verfügbar; die bestätigten Checkpoints dieses Teams erfolgen über die autorisierte GitHub-Verbindung. Ein lokaler Commit allein ist keine Remote-Sicherung.
6. Die laufende Produktabnahme nicht durch Aktualisierung ihres Zweigs abbrechen. Nach deren Ende und bei vollständiger Lieferung die konkrete Übernahme mit dem Produktteam abstimmen. Main bleibt geschützt.

Die Inventuren dokumentieren ihren tatsächlichen Umfang. Sie behaupten weder die Prüfung aller historischen Zweige noch einen physischen Fold7-, Leistungs- oder Bildqualitätsnachweis.
