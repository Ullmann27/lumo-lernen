# Österreichischer Volksschulrahmen 2026 für Lumo Lernen

Stand: 6. Oktober 2026

## Offizielle Grundlage

Lumo richtet den Fächerrahmen für die 1.–4. Schulstufe an den aktuell konsolidierten österreichischen Rechtsgrundlagen aus.

Primärquellen:
- RIS – Lehrplan der Volksschule, geltende Fassung: https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275
- RIS – Schulorganisationsgesetz § 10, geltende Fassung: https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009265

§ 10 SchOG sieht für die 1.–4. Schulstufe als Pflichtgegenstände insbesondere vor:
- Religion
- Deutsch
- Sachunterricht
- Mathematik
- Musik
- Kunst und Gestaltung
- Technik und Design
- Bewegung und Sport

Zusätzlich ist Verkehrs- und Mobilitätsbildung als verbindliche Übung vorgesehen.

Die „Lebende Fremdsprache“ wird in der Grundstufe I (1./2. Schulstufe) als verbindliche Übung und in der Grundstufe II (3./4. Schulstufe) als Pflichtgegenstand geführt.

## Umsetzung in Lumo

Der bestehende lokale Aufgabengenerator unterstützt aktuell besonders gut automatisiert überprüfbare Aufgaben in:
- Mathematik
- Deutsch
- Lesen
- Rechtschreibung
- Schreiben
- Sachunterricht
- Englisch
- Logik

Englisch dient in Lumo als konkrete Ausprägung der „Lebenden Fremdsprache“. Die App darf jedoch nicht behaupten, dass österreichweit ausschließlich Englisch angeboten werden muss.

Für Musik, Kunst und Gestaltung, Technik und Design, Bewegung und Sport sowie Verkehrs- und Mobilitätsbildung sollen keine künstlichen Multiple-Choice-„Schularbeiten“ erzeugt werden, solange dafür kein passendes Aktivitäts-/Projektformat implementiert ist.

## Klassenlogik

### 1.–2. Schulstufe
- Kernaufgaben: Mathematik, Deutsch/Lesen/Schreiben/Rechtschreibung, Sachunterricht.
- Lebende Fremdsprache als kindgerechte Übung: vor allem Hören, Sprechen, elementarer Wortschatz und sehr einfache Alltagssituationen.
- Englisch-Aufgaben in Lumo bleiben deshalb spielerische Übungs-/Lerncheck-Aufgaben.

### 3.–4. Schulstufe
- Mathematik, Deutsch und Sachunterricht werden weiter vertieft.
- Lebende Fremdsprache wird als Pflichtgegenstand berücksichtigt.
- Lumo bietet deshalb zusätzlich einen eigenen Englisch-Lerncheck und ein eigenes adaptives Englisch-Subject.
- Bei Schularbeit/Test werden Aufgaben nur aus den Bereichen erzeugt, die der lokale Generator fachlich und technisch sauber prüfen kann.

## Designregel

Unabhängig vom Fach verwendet jede Aufgabe dieselbe Lumo-Welt:
- dunkelblaues Hologlas statt heller Papierkarten,
- Cyan/Blau als primäre UI-Lichtfarbe,
- Orange/Gold als Belohnungs-/Aktionsakzent,
- Nunito als kindgerechte UI-Schrift,
- Lumo sichtbar als Tutorfigur,
- Fortschritt, Hilfe und Antwortzustände als echte UI-Elemente,
- keine Texte als Teil eines starren Hintergrundbildes,
- responsive für Phone, Fold und Tablet.

Die generierten Referenzbilder definieren die Art Direction. Eingabefelder, Antworten, Aufgaben, Schularbeiten und Navigation bleiben echte Flutter-Widgets, damit Lesbarkeit, Barrierefreiheit, Responsivität und Testbarkeit erhalten bleiben.
