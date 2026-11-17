# LUMO Play-Store Quality Agent Network · 14.11.2026

## Geltung und ehrlicher Ausfuehrungsstatus
Die definierten Agenten sind GitHub-Copilot-kompatible Rollenprofile, die bei tatsaechlicher Agent-Zuweisung genutzt werden koennen. Die Erstellung der Dateien oder Issues startet keine Cloud-Agent-Sitzungen. Ein Agent zaehlt erst als aktiv, wenn GitHub eine echte Session/PR mit Bearbeitungsprotokoll zeigt.

## Team-Hierarchie
Koordinator kontrolliert alle PRs, Eingangstests, Integration und Abnahme. Drei Hauptleiter: Lernen, Godot-3D und Android/Play-Release. Jeder hat exakt drei Spezialauftraege. Jeder Spezialauftrag darf exakt ein Implementierungs- und ein unabhaengiges QA-Review erzeugen. Also 3 + 9 + 18 = maximal 30 Gesamtauftraege bei hoechstens drei gleichzeitig laufenden Coding-Sessions, Tiefe hoechstens drei. Alle weiteren Delegationsversuche werden blockiert. Der Status in agent_tree.json bleibt PLANNED_NOT_RUNNING bis echte Agent-Sessions nachgewiesen sind.

## Inhaltliche Ziele
### Lernaufgaben
- Wirklich ALLE in Flutter/Native registrierten Aufgaben 1–4 inventarisieren, nicht nur die bisher 7.552 geprueften Stichproben aus PR #484 und nicht nur die 192 Browser-Prototypaufgaben.
- Fuer jede Klasse/Fach/Thema/Schwierigkeit: gepruefter fachlicher Inhalt, eindeutige Loesung, drei kontextspezifische Hilfen, kindgerechte Sprache, passendes 3D-Objekt, aktives Feedback und Lernerfolgsnachweis.
- Oesterreichische Volksschul-Lehrplaene und echte didaktische Expertenabnahme; keine Behauptung einer Vollabnahme aus Generator-Stichproben.
- Bewahre die bestehenden Profile, Schreiben/Journal, Speicherstaende und bereits erworbene Kompetenzdaten.

### AAA-wuerdiges eigenstaendiges Erlebnis
- 3D-Lernen als reale Aufgabe mit Interaktion, Animation, raeumlicher Antwort und naechstem Lernschritt; kein Kachelmenue mit passiven Kulissen.
- Original LUMO-Fuchs, eigene Figuren/Grafiken, neue Animationen, eigene Tracks/Items; fremde Nintendo-IP und -Musik niemals uebernehmen.
- Touch mindestens 48 dp, ScreenSafeArea, Fold-Portrait/Querformat, Vorher-/Nachher-Original-PNGs an den exakten Build-SHA gebunden.
- Renderer, RAM, thermische Last und 60fps auf physischem Zielgeraet messen statt als Ziel automatisch als PASS auszugeben.

### Play-Store-Readiness als eigenes Release-Gate
- Aktueller Testzustand: prepare_android.py signiert Release-Test-APKs mit Debug-Keystore. Diese Testsignatur ist kein Play-Produktions-Signing.
- Google Play braucht fuer neue Apps AAB (Android App Bundle), seit 31.08.2026 Target API 36+, geeignete Feature/Asset-Delivery bei grossen Paketen.
- Kinder-/Familienrichtlinien, Datenschutz/Datensicherheit, Altersgruppe, erforderliche Store-Assets, Kompatibilitaet, Barrierefreiheit, Android-App-Updates und Datenmigration nachpruefen.
- Bei neuen persoenlichen Entwicklerkonten ab 13.11.2023 gegebenenfalls 12 geschlossene Tester ueber 14 aufeinanderfolgende Tage. Kontostatus nicht raten.
- Eigene Play-Konsole, Store-Zugang, Produktionsschluessel und personenbezogene Tester-Einwilligung muessen von berechtigter Person eingerichtet werden. Keine Self-Publishing-Pipeline oder Ausgaben ohne Freigabe.

## Ausfuehrungsregeln fuer jeden Delegationsschritt
1. Genaue Repo- und Ausgangs-SHA pruefen, bestehenden uncommitted Code erhalten, eigenen Branch benutzen, main niemals ohne Freigabe mergen.
2. Unterauftrag nur, wenn ausreichend separat pruefbar; Verantwortlicher und Akzeptanzkriterien in Issue festhalten.
3. Implementierungsagent liefert echte Codeaenderung, Regression und Beleg. QA-Agent versucht Gegenbeispiele und prueft echte Frames/Nutzerhandlung.
4. Koordinator integriert nur gruen getestete Teil-Pakete, baut dann selbst exakt gepinnte Flutter/Godot-AAB-/APK-Kandidaten.
5. Die Anwendersicht gilt: Hauptmenue und Spielaufgaben muessen sichtbar und spielbar besser sein; blosse Commits/Tests duerfen nicht als AAA-Fortschritt ausgegeben werden.
6. Stop-the-line bei falschen Aufgaben, Kinder-Datenrisiko, fehlender Unterschrift/Signatur, defektem Game-Return, Crash, offenem Android-Proof oder fehlenden Original-Bildbelegen.

## Nachweisquellen
- https://support.google.com/googleplay/android-developer/answer/11926878 (Target API)
- https://developer.android.com/guide/app-bundle (AAB und grosse Assets)
- https://support.google.com/googleplay/android-developer/answer/9893335 (Families)
- https://support.google.com/googleplay/android-developer/answer/14151465 (Testphase fuer bestimmte Konten)
- https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents (Agentenprofile)
- https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/kick-off-a-task (echte Zuweisung)

Die drei Hauptleiter duerfen weitere begrenzte Unterauftraege entwerfen, aber ohne reale, autorisierte Agent-Laufzeit keine Hintergrundausfuehrung behaupten.
