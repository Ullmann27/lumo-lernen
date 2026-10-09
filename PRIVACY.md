# Datenschutz - Lumo Lernen

**Stand:** 9. Oktober 2026 (technische Bestandsaufnahme am Quelltext; vor einer Veröffentlichung im Store rechtlich prüfen lassen)
**Verantwortlich:** Heinz Ullmann, 2230 Gänserndorf, Österreich

Die frühere Fassung vom 28. April 2026 sagte „INTERNET nicht benötigt“ und „kein Datentransfer an Dritte“. Das stimmte für den heutigen Stand nicht mehr und wurde durch diese Fassung ersetzt.

## Kurzfassung

Lumo Lernen ist eine Lern-App für die Volksschule (1.–4. Schulstufe, Österreich).

- Lernstände, Profil, Sterne, Belohnungen, Aufgabenprotokoll und Testergebnisse bleiben **auf dem Gerät**.
- Es gibt **kein Konto, keine Anmeldung, keine Werbung, keine In-App-Käufe** und **keine Analyse- oder Absturzmelde-Dienste** (die eingebundenen Pakete in `pubspec.yaml` enthalten keine solchen SDKs).
- Einige Funktionen brauchen das Internet. Sie stehen vollständig unter „Wann die App das Internet nutzt“. Die Online-KI-Funktionen sind in frischen Einstellungen **aus** und nur über den Schalter „Lumo-KI-Server erlauben“ (Einstellungen, Karte „Lumo-KI Testserver“) einschaltbar. In diesem Text heißt das „Online-KI“.

## Was nur auf dem Gerät passiert

- **Lernfortschritt, Lernbericht, Denk- und Knobel-Test-Ergebnisse, Belohnungen** liegen lokal in `shared_preferences`. Löschen: App-Daten in den Android-Einstellungen löschen oder die App-Daten in den Einstellungen zurücksetzen.
- **Foto-Lektion:** Die Texterkennung läuft auf dem Gerät (Google ML Kit, on-device). Fotos werden nicht hochgeladen.
- **Sprachausgabe:** Android-Text-to-Speech auf dem Gerät und mitgelieferte Sprachclips.
- **Lumo Kart** (3D-Rennspiel) speichert Spielstand und Werkstatt lokal.

## Wann die App das Internet nutzt

Die App fordert die Berechtigung `INTERNET` an. Genutzt wird sie ausschließlich hierfür:

| Funktion | Wann | Was wird gesendet | Standard |
|---|---|---|---|
| Lumo-KI über Proxy (`lumo-ai-proxy.onrender.com`) | nur wenn Eltern „Online-KI“ einschalten | die Anfrage an die KI (Frage des Kindes, Aufgabenkontext) | aus |
| Bilder zum Thema (`image.pollinations.ai`) im Lumo-Lehrer und im Jahreszeiten-Modul | nur wenn „Online-KI“ eingeschaltet ist (ab Version 0.12.7+1914; davor wurden sie ohne Schalter geladen) | ein englisches Themenwort aus einer festen Positivliste plus Stilbeschreibung, Bildgröße, Zufallszahl. Kein freier Kindertext. Dem Dienst ist technisch die IP-Adresse des Geräts bekannt | aus |
| Update-Suche (`api.github.com`, `github.com`) | nur wenn in den Einstellungen „Update“ angetippt wird | anonyme Abfrage der neuesten Version; GitHub sieht die IP-Adresse | manuell |

Mit ausgeschalteter Online-KI und ohne Tippen auf „Update“ verlässt nichts das Gerät. Ausgenommen ist die Spracherkennung (siehe unten).

## Mikrofon und Kamera

- **Mikrofon:** nur nach Freigabe der Eltern (Standard aus) und Android-Erlaubnis. Die Spracherkennung übernimmt der Spracherkenner des Geräts (`speech_to_text`). **Je nach Gerät und Systemeinstellung kann dieser Audio an den Anbieter des Erkenners senden** (auf vielen Geräten Google). Die App legt selbst keine Tonaufnahmen ab.
- **Kamera:** nur nach Freigabe der Eltern (Standard aus) und nur, wenn das Kind aktiv eine Aufgabe fotografiert.

## Elternzugang

Der Elternbereich ist **ohne PIN** erreichbar (bewusste Vorgabe, siehe `docs/PIN_FREI_2026-10-03.md`). Wer das Gerät hält, kann die Einstellungen öffnen. Mikrofon, Kamera und Online-KI sind in frischen Einstellungen aus; das Öffnen des Elternbereichs schaltet nichts ein.

## Berechtigungen

| Berechtigung | Zweck | Pflicht? |
|---|---|---|
| KAMERA | Foto der Hausaufgabe für lokale Texterkennung | optional |
| MIKROFON | Vorlesen und Sprechen mit Lumo (Spracherkennung des Geräts) | optional |
| INTERNET | die drei Funktionen aus der Tabelle oben | nur dafür |
| PAKETE INSTALLIEREN | Installation eines heruntergeladenen Updates nach Tippen auf „Update“ | nur dafür |

## Hinweise für die Veröffentlichung

- Aussagen wie „kein Datentransfer an Dritte“ gelten nur mit ausgeschalteter Online-KI und ohne Update-Suche.
- Dienstleister (Proxy-Host, Bilddienst) sind zu benennen und vertraglich zu prüfen. Kinder unter 14 Jahren: Einwilligung der Erziehungsberechtigten (§ 4 Abs. 4 DSG).
- Diese Datei ist eine technische Beschreibung, keine Rechtsberatung.

## Kontakt

Bei Fragen oder Anliegen: Heinz Ullmann, 2230 Gänserndorf, Leo-Porsch-Gasse 1/1/7
