# Lumo – kombinierter Runtime-Kandidat 1902

Status: VISUAL_GAP / NOT FINISHED. Kein APK-Erfolg ohne tatsächliche Build-,
Installations- und Ablaufbelege. Dieser Folgebranch verbindet die aktuellen
Referenz-/Kamera- und Runtime-/Kontakt-/Speicherarbeiten; die älteren Branches
bleiben unverändert erhalten.

## Aktuelle Integrationsbasis

| Ebene | Verifizierter Stand |
| --- | --- |
| App Runtime-BASE | `9f56cb8df00925988c84fccab5fbb8eaf2821d3c` (PR 215) |
| App übernommener Referenz-Head | `c857aa929b41a747159b3081c250bc63cf9708ff` (PR 214), Kamera-/Prüferänderung `84ce0e3` |
| Godot Runtime-BASE | `649e7dc7e90ad3affe94721012d39140522e717e` (PR 28) |
| Godot übernommener Referenz-Head | `b6889d1ec767ec008acf5ee93bd73637653cf73d` (PR 27), Kamerafix `30dc99b` |
| Freier Integrationsbranch in beiden Repositories | `codex/lumo-integrated-runtime-2026-10-08` |
| Gemeinsame Kandidatenversion | `0.12.1+1902`; tatsächliche APK noch PENDING |
| Tatsächlicher Godot-Exportpin | `9f17cd2f7af652917a0c1290e506e1211a08fb3f`, Tree `a499de6134b451e26830c4013542b60a4022fabd`; tatsächlicher APK-PCK noch PENDING |

Beide Seiten werden mit ihren echten Eltern per Merge erhalten. Die App hatte
zwei Konflikte: Pin und Version. Der Pin darf nur den neuen kombinierten
Godot-Commit bezeichnen. 1902 vermeidet die Mehrdeutigkeit der beiden getrennten
1901-Kandidaten. Paketkennung und vorhandene Signatur bleiben erhalten.

## Enthaltene Reparaturen und Integrationsziel

Die Runtimearbeit erhält bewegten Hand-/Lenkrad- und Ärmel-/Handkontakt,
Prismenverbrauch nach Grafik-Rebuild und Speicher-Rückkehr, begrenzte sichtbare
Gegnerzustände, Flug-Reset ohne falschen Landungsturbo, Launcher-Lebenszyklusschutz
und fachpassende Foto-Lektionen. Im Kart-Rennen gibt es keine Lernfragen.

Die neue Kamerakorrektur erhält das vollständige Heck samt Rädern im Stillstand.
Breite Cover-Displays verkleinern das vertikale FOV nicht unter seinen Basiswert.
Der Kamera- und Pause-Prüfer enthalten die dazugehörigen neuen Anforderungen;
neun vollständige Mesh-Bounds benötigen drei Prozent Rand. Der bestehende
Android-Prüfer wartet auf die tatsächlich sichtbare RUNDE-Anzeige. Der zusätzliche
vollständige Zwei-Runden-/Ergebnis-/ACK-/Offline-Prüfer bleibt erhalten.

Der integrierte APK-Workflow ist für den neuen Branch aktiviert. Er führt die
bestehenden Flutter-, Inhalts-, Native-, Build- und Android-Prüfungen erneut aus.
Die getrennte Oberfläche-QA muss vor ihrem Start auf diese tatsächliche neue
APK-Provenienz und Build1902 umgestellt werden; ältere 1901-Ergebnisse gelten
nicht automatisch für den kombinierten Stand.

## Vorherige Fehlernachweise

Lauf37788488965 hatte750 Flutter-PASS/4SKIP, wurde aber vor dem APK-Bau korrekt
wegen vier GLES3-Texture-ERRORs im Continuity-Prüfer gestoppt. Ein vollständig
gerendertes Menü vor dem Grafikcallback und abgeschlossene Renderarbeit vor
Szenenfreigabe beheben diesen Test-Lebenszyklusfehler. Alle48 Gameplay-Assertions,
fünf Szenarien und das strenge ERROR-/Exitcode-Gate bleiben identisch. Zwei
strenge GL-Läufe und ein Headless-Lauf wurden auf649e7dc bestätigt. Der
1901-Folgelauf37793715220 ist davon und vom1902-Kandidaten getrennt.

Die neuen integrierten Prüfzahlen, Screenshots, exakten RESULT-SHAs, PRs,
APK-/PCK-/Zertifikathashes und Original-Android-Ergebnisse sind nach dem realen
Abschluss im kuratierten Lieferbericht anzugeben. Kein grüner Marker allein
ersetzt einen sauberen Prozessausgang oder eine tatsächlich installierte APK.

## Verbleibende Abnahmegrenzen

Referenzgleichheit von Gesicht, Fell, Materialien und Gesamtwelt ist noch offen.
Physisches Fold, ARM-Geräte-CPU/GPU, Speicher-/Wärme-Soak und Touchlatenz sind
NOT EXECUTED. Die konkrete YouTube-Referenz war nicht als Videoframes zugänglich;
kein Bild-für-Bild-Vergleich ist behauptet. Die hochgeladenen älteren Quellen
enthielten keine fertigen Produktionsmodelle. Weitere Flug-/Gegner-/Kamerafälle
und der separat geclaimte Shop-Speicherfehler bleiben im Runtimebericht benannt.

Keine Main-Übernahme, Release-Veröffentlichung oder fremde Architekturablösung.
