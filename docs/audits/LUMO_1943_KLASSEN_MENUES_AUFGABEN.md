# Lumo 1943 – Klassen, Fächer, Navigation und Aufgaben: Code-Kontrollgang

Basis: geschützter Lumo-1943-Branch, auf Version 1942 aufgebaut. Diese Dokumentation ist ein **Quellcode-Audit**, keine Behauptung über einen vollständigen Live-Test auf einem physischen Fold.

## Lehrplan und Klassenwahl

- Österreichische Volksschule 1.–4.: **Sachunterricht** bleibt eigenes Fach. Natur, Geschichte, Technik und Geografie sind altersgerechte Schwerpunkte.
- **Englisch ist in allen Klassen angeboten**; 1./2. Klasse als lebende Fremdsprache/verbindliche Übung, 3./4. als Pflichtfach. Der lokale Generator nutzt altersgestaffelte Wortlisten.
- Academy-Picker zeigt das ausgewählte Klassencurriculum. Bei Abweichung von der Profilklasse wird eine Erklärung angezeigt. Browsing höherer Klassen öffnet vorbereitendes Entdecken und **ändert weder Profilklasse noch gespeicherte Lernstände**.
- Home-Fächer: Mathe, Deutsch, Sachunterricht, Englisch, Logik und weitere Lernzugänge. Ein gespeichertes Vorjahresthema wird nicht unbemerkt als aktuelle Klassenstufe wieder aufgenommen.

## Durchgegangene Menüs/Einstiege

| Oberfläche | Code-Einstieg | Verifizierbares Verhalten |
|---|---|---|
| Start | `HomeContent` | Fächer-Karten, aktueller Grad, Englisch sichtbar, Klick startet Übung |
| Lernen | `LumoAkademieScreen` | Klassen 1–4, Mathe/Deutsch/Sachunterricht/Englisch je Klasse, Themen |
| Mathe/Deutsch | `LumoAkademieScreen._openTopic` | Vorhandene lokale Übungen; Geschichte öffnet Bibliothek, Aufsatz Schreibcoach |
| Sachunterricht/Englisch | `_openTopic` | Exakte Curriculum-Unit und realer lokaler Aufgaben-Generator; bei höherer Klasse Discovery |
| Übungsansicht | `AppShell` zu `LearningContent` | Richtige Profilklasse, Antworten/Feedback, Hilfe und Sprach-Funktionen aus 1941 |
| Schulaufgaben/Tests | `SectionContent`, `LumoTestsScreen` | Englisch-Lerncheck für alle Grade, gemischte Übung inklusive Englisch |
| Spielen/Lumo Kart | `AppShell` zu `GamesContent` | Eigenes Godot/Kart-System bleibt unverändert eingebettet |
| Geschichten | Story-Einstiege aus Home/Akademie | Bestehende Bibliothek, Klassenfilter und Speicherfunktionen bleiben erhalten |
| Profil/Elternbereich | `ProfileScreen`, `SettingsContent` | Echte Profile und Fortschritte, Update-Kanal und Sprachausgabe aus 1942 |
| Mehr-Menü | Shell/mobile Mehr | Bestehende responsive Navigation unverändert, UI-Regression in CI |
| Lumo-Welt | `LumoWeltScreen` | Inselname **Sachunterricht**; Summen für alte Sachkunde-Daten weiterhin berücksichtigt |
| Kompetenzring | `lumo_design_system.dart` | Bezeichnung Sachunterricht statt Sachkunde, Fortschritt aus echten Skill-Daten |

## Gefundene und reparierte Risiken

1. Englisch-Kachel hatte keine Klassen-Themenliste.
2. Sachkunde und Sachunterricht waren mehrfach inkonsistent; Lehrer-Topic-Kontexte verwendeten noch Sachkunde.
3. Starre Einstiegsmenüs enthielten erste-Klasse-Themen und erfundene Sterne.
4. Grade 3/4 wurden bei einzelnen Akademie-Kacheln auf einen allgemeinen Chat statt zu vorhandenen lokalen Mathe-/Deutsch-Aufgaben geleitet.
5. Beim Home-Einstieg konnte das alte `lastTopic` aus der Vorjahresklasse wiederverwendet werden.
6. Erste vollständige CI scheiterte an einem veralteten Test, der weiterhin `Sachkunde` erwartete. Assertion wurde auf `Sachunterricht` berichtigt.

## Abnahmegrenzen

Automatisierte Widget- und Navigations-Regressionen prüfen die implementierten Klickketten, die vollständige Testsuite und ein separates Inhalts-Audit decken die Aufgabenpools ab. Sie beweisen **nicht**, dass wirklich jeder denkbare Button auf jedem Gerät manuell angetippt wurde. Vor einer Veröffentlichung sind ein frischer Emulator-Lauf mit Screenshots und ein physischer Fold-Test für Cover, ausgeklappten Modus, Voice und Kart nötig. Nicht als erfolgreich gemeldet, solange sie nicht tatsächlich stattgefunden haben.

Keine APK-/Release-Freigabe oder Änderung an `main` ohne ausdrückliche Bestätigung.
