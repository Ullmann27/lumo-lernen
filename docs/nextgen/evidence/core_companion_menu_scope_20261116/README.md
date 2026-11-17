# Core: sichtbares Fuchs-Menü und Aufgabenbesitzer

## Zwei echte Fehlergrenzen

Auf dem unveränderten Stand `7c42d6da303ba42de2c7e94707dd187ff3660f1f`
öffnet der reale mobile Dock-Fuchs ein normales Modal. Der Core verliert dadurch
seinen Kontext; das sichtbare Fuchs-Menü schließt sich ohne Auswahl. `red.log`,
`red-test.dart.txt` und `red-provenance.json` erhalten genau diesen Einzel-RED.

Der erste Anschluss bestand 19 gezielte Prüfungen. Eine zusätzliche Prüfung
reproduzierte danach eine enge Schließphase: Menüauswahl, bereits geleerter Bus,
`inactive`→`resumed` vor Abschluss der Route. Die ausstehende Auswahl öffnete
unberechtigt wieder den alten Dialog. `closing-pause-red*` hält diesen tatsächlichen
Zwischenstand getrennt fest. Der monotone Lebenszykluszähler behebt diese Grenze.

## Anschluss

Der optionale Presenter-Transport stammt separat von Conversation (`80b18f6`,
Stilkorrektur `ff2bf66`). Die AppShell bindet mobiles Dock, breiten Fragenknopf
und breites Ideenmenü an den sichtbaren Core. Dialog und Menü teilen denselben
exakten Route-/Task-/Profilbesitzer. Das Menü prüft seine ursprüngliche kanonische
Identität vor dem regulären Schließen. Erst nach `route.completed`, frischer
Veröffentlichung der tatsächlichen aktuellen Aufgabe und dem folgenden Hostframe
kann eine weiterhin gültige Auswahl ausgeführt werden. Stopp, Aufgabenwechsel
und ein zwischenzeitlicher Hintergrundwechsel entwerten die alte Auswahl.
Ein null-Ergebnis startet keinen ungebundenen Standarddialog.

## Nachweis

**20/20 PASS**, keine ausgelassenen Fälle: neun echte AppShell/Core-Fälle und elf
bestehende Core-/Header-/Navigationsprüfungen. Darin liegen mobiler Menü-Frageweg,
breite Fragen- und Hilfeaktionen, Schließen/Rückkehr, Fremdroute, alter Task,
Stopp/null-Abbruch, 430→1000-dp-Layoutwechsel sowie Pause/Resume während des
Menüschließens. Die endgültige Analyse der fünf geänderten/integrierten Dartdateien
meldet keine Probleme. Frühere 1er-/19er-Läufe überlappen; sie werden nicht addiert.

`source.json` bindet die endgültigen Testbytes im damals noch nicht committeten
Arbeitsbaum ausdrücklich an den tatsächlichen Dependency-Head. Die ursprünglichen
Logs bleiben bytegleich. Eine frühere reine Superparameter-Stilinfo ist als
`analyze-initial.log` erhalten. Die Prüfung verwendet echte AppShell-, Aufgaben-
und Controllerlogik mit synthetischem Assettransport/Ersatzfonts. Sie belegt keine
Androidaufnahme, Bildqualität, Mikrofonfunktion oder physische Faltbewegung.
