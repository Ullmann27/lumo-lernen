# Datenschutz und Datenflüsse – Lumo Lernen (Entwicklungsstand)

**Stand:** 15. Oktober 2026 – technische Bestandsaufnahme am Quelltext (Zusammenführung der Fassungen vom 9. Oktober aus beiden Entwicklungssträngen).
**Wichtig:** Diese Datei ersetzt keine rechtliche Datenschutzerklärung, keine DSGVO-Prüfung, keine Prüfung von Auftragsverarbeitern und keine Freigabe für den Play Store.
**Verantwortlich:** Heinz Ullmann, 2230 Gänserndorf, Österreich

Die frühere Fassung vom 28. April 2026 sagte „INTERNET nicht benötigt“ und „kein Datentransfer an Dritte“. Das stimmt für den heutigen Stand nicht mehr.

## Kurzfassung

Lumo Lernen ist eine Lern-App für die Volksschule (1.–4. Schulstufe, Österreich).

- Lernstände, Einstellungen, Kinderprofile, Sterne, Belohnungen, Aufgabenprotokoll und Testergebnisse werden **lokal auf dem Gerät** gespeichert (unter anderem `shared_preferences`).
- Es gibt **kein Konto, keine Anmeldung, keine Werbung, keine In-App-Käufe** und **keine Analyse- oder Absturzmelde-Dienste** (die Pakete in `pubspec.yaml` enthalten keine solchen SDKs).
- Einige Funktionen brauchen das Internet. Sie stehen vollständig unter „Wann die App das Internet nutzt“. Die Online-KI ist in frischen Einstellungen **aus** (`AppSettings.aiProxyEnabled = false`) und nur über den Eltern-Schalter „Lumo-KI-Server erlauben“ einschaltbar. In diesem Text heißt das „Online-KI“.

## Was nur auf dem Gerät passiert

- **Lernfortschritt, Lernbericht, Denk- und Knobel-Test-Ergebnisse, Belohnungen** liegen lokal. Löschen: App-Daten in den Android-Einstellungen löschen.
- **Foto-Lektion:** Texterkennung auf dem Gerät (Google ML Kit, on-device). Fotos werden von der App nicht hochgeladen.
- **Sprachausgabe:** mitgelieferte Sprachclips und Android-Text-to-Speech auf dem Gerät.
- **Lumo Kart** und die übrigen Godot-Spiele speichern Spielstand und Werkstatt lokal.

## Wann die App das Internet nutzt

Die App fordert die Berechtigung `INTERNET` an. Im Quelltext gibt es genau diese Ziele:

| Funktion | Wann | Was wird gesendet | Standard |
|---|---|---|---|
| Lumo-KI über Proxy (`https://lumo-ai-proxy.onrender.com`, in den Einstellungen änderbar) | nur mit eingeschalteter Online-KI und Freigabe für den jeweiligen Bereich | HTTP-POST an `<Proxy>/chat` (`LumoAiProxyClient.ask()`): Frage/Nachricht, bis zu acht letzte Chat-Nachrichten, Schulstufe, Kontext (Fach, Thema oder Einheit). Ein Feld für den Kindernamen wird nicht gesendet; Freitexte können trotzdem Namen enthalten | aus |
| Bilder zum Thema (`https://image.pollinations.ai`) im Lumo-Lehrer | nur mit eingeschalteter Online-KI | ein englisches Themenwort aus einer festen Positivliste plus Stilbeschreibung, Bildgröße, Zufallszahl. Kein freier Kindertext. Der Dienst sieht die IP-Adresse des Geräts | aus |
| Update-Suche (`api.github.com`, `github.com`) | nur nach Tippen auf „Aktualisieren“ in den Einstellungen | anonyme Abfrage der Release-Liste und gegebenenfalls Download der APK; GitHub sieht die IP-Adresse | manuell |

Der URL-Prüfer nimmt für externe KI-Proxy-Hosts nur HTTPS an. Unverschlüsseltes HTTP gilt nur für lokale Tests an `localhost`, `127.0.0.1` oder `::1` (Regressionstests vorhanden).

Mit ausgeschalteter Online-KI und ohne Tippen auf „Aktualisieren“ sendet die App selbst nichts. Ausgenommen ist die Spracherkennung (siehe unten).

## Mikrofon und Kamera

- **Mikrofon:** nur nach Freigabe der Eltern (Standard aus) und Android-Erlaubnis. Die Spracherkennung übernimmt der Erkenner des Geräts (`speech_to_text`). **Je nach Gerät und Systemeinstellung kann dieser Audio an seinen Anbieter senden** (auf vielen Geräten Google). Die App legt selbst keine Tonaufnahmen ab.
- **Kamera:** nur nach Freigabe der Eltern (Scanner, Standard aus) und nur, wenn das Kind aktiv eine Aufgabe fotografiert.

## Elternzugang

Der Elternbereich ist **ohne PIN** erreichbar (bewusste Vorgabe, siehe `docs/PIN_FREI_2026-10-03.md`). Wer das Gerät hält, kann die Einstellungen öffnen. Mikrofon, Kamera und Online-KI sind in frischen Einstellungen aus; das Öffnen des Elternbereichs schaltet nichts ein.

## Berechtigungen (gesetzt in `scripts/prepare_android.py`)

| Berechtigung | Zweck | Pflicht? |
|---|---|---|
| KAMERA | Foto der Hausaufgabe für lokale Texterkennung | optional |
| MIKROFON | Vorlesen und Sprechen mit Lumo (Spracherkennung des Geräts) | optional |
| INTERNET | die drei Funktionen aus der Tabelle oben | nur dafür |
| PAKETE INSTALLIEREN | Installation eines heruntergeladenen Updates nach Tippen auf „Aktualisieren“ | nur dafür |

## Noch nicht abschließend nachgewiesen

- alle möglichen ausgehenden Verbindungen von nativen Plugins, ML Kit und Spracherkennung (Netzwerkmitschnitt auf einem Gerät fehlt);
- Lösch- und Aufbewahrungsfristen des Proxys, Unterauftragsverarbeiter, Hostingstandort, AV-Verträge, Betroffenenrechte und Elternzustimmung;
- korrekte Datentrennung bei mehreren Kinderprofilen auf einem Gerät;
- Einhaltung der einschlägigen DSGVO-, Jugendschutz- und Google-Play-Vorgaben (nicht pauschal behaupten). Kinder unter 14 Jahren: Einwilligung der Erziehungsberechtigten (§ 4 Abs. 4 DSG).

## Kontakt

Heinz Ullmann, 2230 Gänserndorf, Leo-Porsch-Gasse 1/1/7
