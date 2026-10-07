# Lumo Lernen – Reparatur- und Übergabebericht

Stand: 7. Oktober 2026. Lieferfassung: **0.10.10+1602**.

Die Reparatur-APK ist erstellt. Die vorgesehenen sechs Android-Prüffälle wurden mit dieser exakten Datei bestanden: fünf Spiele unter Android 15 und zusätzlich Kart unter Android 16. Die Online-KI bleibt wegen erschöpften Provider-Kontingents eingeschränkt.

## Behobene Probleme

- Die zuvor getrennten App- und Kart-Verbesserungen sind zusammengeführt. Die neue Startseite, Lumo-Bilder, blauen Lernkacheln und getrennte Hilfsleiste bleiben gemeinsam mit der aktuellen Kart-Vorschau und den nativen Welten erhalten.
- Die Beschriftung „Belohnungen“ bleibt auch in der schmalen Navigation vollständig innerhalb ihrer Fläche. Die korrigierte Darstellung wurde gerendert und geprüft.
- Deaktivierte Kart-Aktionen haben lesbare Beschriftungen. Ein leeres Item löst keine Aktion aus; ein vorhandenes Schild wird tatsächlich eingesetzt und verbraucht. Mehrfingersteuerung, Loslassen außerhalb, Pause und zehn Bildschirmgrößen sind Bestandteil der nativen Regression.
- Der Build liest die App-Version aus einer gemeinsamen Quelle. Ein veralteter Build-Override darf keine APK mit niedrigerer Versionsnummer erzeugen. Version 1602 liegt über den bisherigen parallelen Kandidaten 1504 und 1601.
- Die Vorbereitung der Prüfrechner erhält begrenzte Download-Wartezeiten und ein eigenes Acht-Minuten-Limit. Der ursprüngliche Schatzsuche-Job hatte während der Paketvorbereitung bis zum globalen Zeitlimit gewartet; auf dem ergänzenden Prüfrechner bestand der Spieltest.
- Der vollständige Folgeauftrag für Opus liegt im Repository und im Projektgespräch. Die Einstiegsdateien `CLAUDE.md` und `CODEX_START.md` verweisen direkt auf die Übergabe.

## Eindeutiger Quellstand

| Bestandteil | Stand |
|---|---|
| App-Quellstand der APK | `1f9ab5a8fc0d7b5a8fbf2d0b8a35a92d7f8cdf9b` |
| Eingebetteter Godot-Quellstand | `9ade252e67309d18b17d3226e33b0034b91f3495` |
| Version | `0.10.10+1602` |
| Paketkennung | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Signaturzertifikat, SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| APK, SHA-256 | `82865962c7c00413c75bfc2e427a201bb957ab564d8c8eb944f2b798dfbf1511` |
| APK-Dateigröße | 187.064.937 Byte |

Spätere Änderungen an Dokumentation, Prüfwerkzeug und CI-Vorbereitung ändern die ausgelieferte APK nicht. Die oben genannten Quellstände und die APK-Prüfsumme bleiben für diese Lieferung maßgeblich.

## Nachweise

| Prüfung | Ergebnis |
|---|---|
| Flutter-Regressionen | 707 bestanden; 4 bereits deaktivierte Tests übersprungen |
| Python für Build-/Android-Vorbereitung | 9 bestanden |
| Backend | 22 bestanden |
| Erzeugte Lernaufgaben | 40.960 auf Antworten, Optionen und Zahlenbereiche geprüft |
| Android-Prüfwerkzeuge | 185 erfasst; 177 ausgeführt/bestanden, 8 übersprungen |
| Statische App-Analyse | Keine Fehler; 20 Warnungen und 130 Hinweise verbleiben |
| Native Darstellung | Menü, vier Größen, Vorschauen und vier Welten bestanden; 29 Aufnahmen |
| Native Fold-/Menü-/Fahrphysik-Prüfung | Bestanden; zehn Größen, Mehrfingersteuerung, leeres/aktives Item, Loslassen und Pause |
| Signierte APK und Paketprüfung | Bestanden: Paket, Version, stabile Signatur, arm64/x86_64, 16-KiB-Ausrichtung, eingebetteter Quellstand und PCK-Hash; Download zusätzlich per SHA-256 und ZIP-Integrität abgeglichen |
| Android 15: Update von 1400 | Bauwelt, Puzzle, Rhythm Party, Schatzsuche und Kart bestanden |
| Android 16: Update von 1601, Kart und Größenwechsel | Bestanden: Profilerhalt, Offline-Start, fünf Einrichtungsschritte, Telefon/Fold/Cover/640 × 320, Rückkehr und Neustart; Crash-Puffer leer |

Der [ursprüngliche Build und die Prüfungen](https://github.com/Ullmann27/lumo-lernen/actions/runs/37674457852) enthalten die Protokolle und Originalnachweise. Ein bestandener Test belegt den geprüften Ablauf, keine allgemeine Fehlerfreiheit.

### Korrektur der Android-16-Prüfung

Beim ersten Android-16-Durchlauf blieben nach der Vergrößerung des Displays 1812 × 2176 Pixel im Hochformat aktiv. Alle fünf Aktionstasten wurden erkannt, aber die strikte Erwartung von 2176 × 1812 Pixeln schlug fehl. Update und Profilübernahme waren bereits bestanden.

[Android 16 berücksichtigt feste Ausrichtungswünsche auf großen Displays nicht mehr allgemein](https://developer.android.com/about/versions/16/behavior-changes-16#adaptive-layouts). Der Test hatte eine reine Größenänderung mit einer Gerätedrehung gleichgesetzt. Der korrigierte Ablauf dreht den Emulator ausdrücklich und behält die strikten Prüfungen der tatsächlichen Bildschirmgröße, der sichtbaren Tasten und der Rückkehr zur App bei. Die APK wird dabei unverändert verwendet.

[Ergänzender Android-Prüflauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/37678448599), Prüfwerkzeug-Quellstand `4e46b95db1090f061dec308db7cf0ae6e4d2cb7e`: Schatzsuche bestanden. APK- und Prüfwerkzeug-Quellstände sind in den Ergebnisdateien getrennt dokumentiert. Bei zwei ergänzenden Android-16-Versuchen trat bereits in der alten Ausgangsversion 1601 eine doppelte Testeingabe ("LL" statt "L") auf. Diese Versuche bleiben als fehlgeschlagene Nachweise erhalten.

Der [abschließende Android-16-Lauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/37681087799) verwendet das Prüfwerkzeug `9bcd223e2ddab8d60e79972f49e323c4b0fa9023`. Es tippt auf tatsächlich sichtbare Bildschirmtastatur-Tasten, deren Positionen aus frischen UI-Daten stammen. Der vollständige Profilname wird weiterhin nach jedem Buchstaben und nach dem Update geprüft. Die Anwendung und ihre gespeicherten Daten werden dabei nicht direkt verändert.

**Ergebnis dieses abschließenden Laufs: bestanden.** Android-API 36 wurde auf dem laufenden Emulator ausgelesen; die echte Displaydrehung wurde von `free` auf `lock 1` protokolliert. Die erfasste innere Spielfläche beträgt 2176 × 1812 Pixel. Alle fünf Aktionstasten wurden erkannt; Cover, Kompaktansicht, Rückkehr und vollständiger App-Neustart sind ebenfalls bestanden. Der Crash-Puffer ist leer.

Die einzelnen Android-Spielprüfungen umfassen: Bauziel mit genau 3 Sternen/24 XP und ohne doppelte Vergabe; Puzzle mit gespeichertem 12-Teile-Zustand und einem Hinweis; Rhythmus-Start und Rückkehr; Schatzsuche mit Inventar und erhaltenem Kapitel; Kart mit Menü, Rennstart, Displaywechseln und Rückkehr. Die maschinellen Originalergebnisse liegen im Repository unter `docs/REPAIR_RESULTS_2026-10-07.json`.

## Verbleibende Grenzen

- **Online-KI:** Der Dienst `https://lumo-ai-proxy.onrender.com` ist erreichbar. Eine tatsächliche synthetische Anfrage wurde jedoch mit HTTP 503 und `openai_quota_exceeded` abgewiesen. Der Providerzugang benötigt wieder verfügbares Kontingent. Eine reine Codeänderung kann dies nicht beheben.
- **Statische Hinweise:** Die vorhandenen 20 Warnungen und 130 Hinweise sind nicht als behoben ausgewiesen. Überwiegend betreffen sie ungenutzten Code und Stil; zusätzlich ist eine Rendering-Override-Warnung im bestehenden Jump-Spiel offen.
- **Hardware:** Android-Emulatoren und native Desktop-Renderer ersetzen keine Messung auf dem physischen Fold. Scharnierverhalten, Temperatur, Akku und stabile 60 FPS auf dem Gerät sind nicht bestätigt.
- **Spielumfang:** Die Android-Prüfungen erfassen konkrete Start-, Speicher-, Belohnungs- und Rückkehrabläufe. Sie umfassen keine vollständige Schatzsuche, kein komplett gelöstes Puzzle und keinen vollständig gespielten Rhythmus-Song. Ein Vergleich der gesamten Darstellung mit den Referenzvideos steht ebenfalls aus.
- **Audio und Gestaltung:** Die neue menschlich klingende Cartoon-Lumo-Stimme, modernere Musik, der originalgetreuere Kartfahrer und die vollständigen Intros/Rennsequenzen gehören zum Folgeauftrag. Die Emulatorprüfung läuft ohne hörbare Audioausgabe; sie beweist keine Klangqualität.

## Direkte Übergabe an Opus

1. App-Branch `chatgpt/repair-opus-handoff-2026-10-07` öffnen.
2. `OPUS_NEXT.md` lesen und anschließend `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` vollständig ausführen.
3. Auf dem geprüften Stand weiterarbeiten und vorhandene Reparaturen erhalten.
4. App-Gestaltung, Animation und Stimme zuerst verbessern; anschließend Lumo-Fahrer, Musik, Einfahrt, Intro, Rennablauf und Zieleinlauf fertigstellen.
5. Fortschritte mit echten Screenshots sowie Ton-/Videoaufnahmen belegen und den erneuten gemeinsamen APK-Build prüfen.

[App-PR 213](https://github.com/Ullmann27/lumo-lernen/pull/213) · [Godot-PR 26](https://github.com/Ullmann27/lumo-godot/pull/26) · [Vollständiger Auftrag im Projektgespräch](https://github.com/Ullmann27/lumo-lernen/pull/213#issuecomment-6045212718).

Die Übergabe startet oder weckt keine separate Opus-Sitzung automatisch. Sie ist beim Öffnen des Projektstands unmittelbar auffindbar.
