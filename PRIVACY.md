# Datenschutz - Lumo Lernen

**Stand:** 28. April 2026
**Verantwortlich:** Heinz Ullmann, 2230 Gänserndorf, Österreich

## Wir sammeln keine personenbezogenen Daten von Kindern

Lumo Lernen ist eine Lern-App für Volksschulkinder. Die App ist konform zum Google Play **Designed for Families**-Programm und zur DSGVO/COPPA.

## Was die App tut

- **Lernfortschritt** wird **nur lokal** auf dem Gerät gespeichert (`shared_preferences`).
- **Foto-Scans** der Hausaufgaben werden **nur lokal** verarbeitet. Die Texterkennung (OCR) läuft on-device über Google ML Kit. Es werden **keine** Bilder an externe Server übertragen.
- **Sprachausgabe** erfolgt durch das Betriebssystem selbst (Android Text-to-Speech). Es wird **kein** Audio aufgenommen oder versendet.
- **Kamera-Zugriff** wird nur dann angefragt, wenn das Kind aktiv eine Aufgabe fotografieren möchte.

## Was die App **NICHT** tut

- ❌ Kein Cloud-Upload, kein Server-Sync
- ❌ Keine Werbung
- ❌ Kein Tracking, keine Analytics, keine SDKs Dritter zur Werbung
- ❌ Keine In-App-Käufe
- ❌ Keine Social-Media-Logins
- ❌ Keine Standorterfassung
- ❌ Keine externen Links ohne Erwachsenen-Freigabe (Parental Gate)

## Berechtigungen

| Berechtigung | Zweck | Pflicht? |
|---|---|---|
| KAMERA | Foto der Hausaufgabe für lokale Texterkennung | Optional (nur bei Scan-Funktion) |
| FOTOS / GALERIE | Bestehendes Foto auswählen für Texterkennung | Optional |
| INTERNET | Nicht benötigt (App läuft komplett offline) | — |

## Kontakt

Bei Fragen oder Anliegen: Heinz Ullmann, 2230 Gänserndorf, Leo-Porsch-Gasse 1/1/7

## Bezug zu Google Play

Lumo Lernen erfüllt die Anforderungen des **"Designed for Families"-Programms**:
- Zielgruppe: Kinder unter 13
- Inhalte: ausschließlich altersgerecht (Lerninhalte 1./2. Klasse)
- Kein Datentransfer an Dritte
- Erwachsenen-Schranke (Parental Gate) vor sensiblen Bereichen
