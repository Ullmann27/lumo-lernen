# Lumo Lernen – Professioneller Weiterentwicklungsplan

## Rolle

Die App wird weiterentwickelt aus der Rolle eines leitenden App-Entwicklungsingenieurs, Senior Flutter Engineers, Produktarchitekten, UX-Strategen, Kinder-App-Sicherheitsexperten, Softwaretesters und Release-Qualitätssicherers.

Ziel ist eine stabile, sichere, schöne und kindgerechte Lern-App, die sich deutlich von gewöhnlichen Lern-Apps im Play Store abhebt.

## Projekt

- App-Name: Lumo Lernen
- Technologie: Flutter / Android
- Zielgruppe: Volksschulkinder in Österreich, Klasse 1 bis 4
- Kernidee: Ein freundlicher, sprechender Lumo-Fuchs begleitet Kinder beim Lernen, erkennt Lernstand, erklärt Aufgaben kindgerecht, motiviert, tröstet, schlägt Übungen vor und macht Lernen emotional, sicher und spielerisch.

## Nicht verhandelbare Grundregel

Die bestehende Lumo-Shell darf nicht zerstört werden.

Immer erhalten bleiben:

1. linke Navigation
2. mittlere Content-Zone
3. rechte Lumo-Bühne mit Fuchs
4. warmes, helles, kindgerechtes Premium-Design
5. gespeichertes Kinderprofil
6. Build-Stabilität

Nicht erlaubt:

- keine kompletten Redesigns
- keine neue App-Struktur
- keine Fullscreen-Seiten, die die Shell ersetzen
- keine kaputten Schnellschüsse
- keine neuen riskanten Pakete ohne Grund
- keine API-Keys direkt in der App
- keine Cloud-KI ohne Elternfreigabe und Datenschutzschicht
- keine Änderung, die den Build bricht
- keine Platzhalter als fertige Funktion verkaufen

## Arbeitsweise

In klaren Phasen arbeiten. Nach jeder Phase prüfen:

1. Code prüfen
2. Build prüfen
3. UI prüfen
4. Logik prüfen
5. Fehler suchen
6. erst dann weiterarbeiten

Wenn ein Fehler auftritt:

- nicht raten
- echten Fehler aus Log lesen
- Ursache finden
- minimal reparieren
- erneut prüfen

Jeder Commit muss nachvollziehbar sein. Ein Commit soll möglichst ein Thema lösen.

## Phase 1 – Build und technische Stabilität sichern

Vor neuen Funktionen prüfen:

1. Läuft GitHub Actions grün?
2. Wird eine APK erzeugt?
3. Funktioniert `flutter pub get`?
4. Funktioniert `flutter analyze` ohne harte Fehler?
5. Funktioniert `flutter build apk --debug`?
6. Funktioniert Onboarding nach Neuinstallation?
7. Funktioniert Profil-Speicherung?
8. Funktioniert TTS?
9. Funktioniert Mikrofon?
10. Funktioniert Scanner oder ist er kontrolliert deaktiviert?

Besonders prüfen:

- `speech_to_text`
- `flutter_tts`
- `image_picker`
- `google_mlkit_text_recognition`
- AndroidManifest-Berechtigungen
- minSdk
- Gradle-Kompatibilität

Wenn der Build rot ist: Keine neuen Features. Erst Build reparieren.

## Phase 2 – Einstellungen und Elternbereich

Pflichtfunktionen:

- Eltern-PIN setzen und ändern
- Kinderprofil anzeigen
- Name, Alter, Klasse anzeigen
- Klasse ändern
- tägliches Lernziel einstellen
- Ton ein/aus
- Stimme ein/aus
- automatisches Vorlesen ein/aus
- Mikrofon erlauben/deaktivieren
- Scanner erlauben/deaktivieren
- Animationen reduzieren
- Schriftgröße normal/groß
- ruhiger Modus
- Lernmodus leicht/normal/herausfordernd
- Profil zurücksetzen
- Datenschutz-Hinweise anzeigen

Speicherung zuerst mit `shared_preferences`. Keine neue Datenbank ohne zwingenden Grund.

## Phase 3 – Lernprofil und adaptive Intelligenz

Erfassen:

- richtige Antworten pro Fach
- falsche Antworten pro Fach
- Fehler pro Thema
- gelöste Aufgaben
- Sterne
- XP
- Level
- Tagesziel-Fortschritt
- letzte Übung
- bevorzugtes Fach
- schwierige Themen
- Streak

Services:

- `learning_profile_engine.dart`
- `progress_repository.dart`
- `weakness_detection_engine.dart`
- `recommendation_engine.dart`

Regeln:

- Nach jeder Antwort Profil aktualisieren
- Nach 3 Fehlern in einem Thema: Thema als Schwäche markieren
- Nach 5 richtigen Antworten: Schwierigkeit leicht erhöhen
- Bei mehreren Fehlern: Lumo erklärt ruhiger und einfacher
- Empfehlungen immer kindgerecht formulieren

## Phase 4 – Tagesziel, Streak und Missionen

Missionen müssen echten Fortschritt speichern.

Bausteine:

- Tagesziel: 3/5/10/15 Aufgaben
- Fortschritt: 0 von X erledigt
- Streak: Tage hintereinander gelernt
- Tagesbelohnung
- Mission abgeschlossen
- Mission teilweise abgeschlossen
- neue Tagesmissionen

Missionstypen:

- 3 Aufgaben lösen
- 5 Minuten lernen
- 3 richtige Mathe-Aufgaben
- 2 Deutsch-Aufgaben
- Scanner einmal verwenden
- Lumo eine Frage stellen
- Schularbeit-Mini-Test abschließen

## Phase 5 – Belohnungen und Badges

Belohnungen:

- Start-Star
- Mathe-Mut
- Lesefuchs
- Englisch-Held
- Sachforscher
- 7-Tage-Streak
- 100-XP-Badge
- Schularbeit-Training
- Scanner-Helfer
- Lumo-Freund
- Fehler-Mut-Badge

Jede Belohnung braucht Name, Symbol, Freischaltbedingung, Status und kindgerechte Erklärung.

## Phase 6 – Test und Schularbeit

Test-Modus:

- 5 oder 10 Aufgaben
- sofortiges Feedback optional
- Ergebnis am Ende
- richtige/falsche Antworten
- Fachauswertung
- Wiederholungsvorschlag

Schularbeit-Modus:

- 10 bis 20 Aufgaben
- gemischte Aufgaben
- keine sofortige Lösung, wenn Prüfungsmodus aktiv
- Ergebnis am Ende
- freundliche Note/Einschätzung
- Schwächenanalyse
- Wiederholungsplan

## Phase 7 – Lumo-KI und Sprachmodus

Erweitern:

- Chatverlauf
- Spracheingabe sichtbar
- Mikrofonstatus: „Ich höre zu“
- erkannter Text wird angezeigt
- Antwort wird gespeichert
- Button „Lumo nochmal sprechen lassen“
- Button „Passende Übung starten“
- Frust-Erkennung
- sichere Antwortgrenzen

Lumo darf erklären, motivieren, beruhigen und passende Übungen starten. Lumo darf keine gefährlichen Ratschläge geben, keine privaten Daten erfragen und keine offenen Internetantworten erfinden.

Cloud-KI erst später mit Elternfreigabe, Backend, Datenschutz und Inhaltsfilter.

## Phase 8 – Stimme

Verbessern:

- Stimmeinstellungen im Elternbereich
- Sprechtempo einstellbar
- Pitch einstellbar
- Voice-Test-Button
- automatische beste Stimme anzeigen
- Status: welche Stimme wird genutzt?
- unterschiedliche Sprechstile für Lob, Trost und Erklärung

## Phase 9 – Scanner als Hausaufgaben-Helfer

Flow:

1. Aufgabe fotografieren
2. Text erkennen
3. erkannte Aufgabe anzeigen
4. Kind/Eltern bestätigt
5. Lumo erklärt
6. passende Übung wird gestartet
7. Thema wird im Lernprofil gespeichert

Wenn OCR fehlschlägt: keine roten Fehler, freundlicher Fallback, manuelle Eingabe möglich.

## Phase 10 – Österreichischer Volksschul-Fokus

Einbauen:

- Klasse 1 bis 4
- österreichische Begriffe
- Schularbeit statt Klassenarbeit
- Sachunterricht mit Österreich-Bezug
- Euro/Geld-Aufgaben
- Uhrzeit
- Verkehrsregeln
- Bundesländer später
- altersgerechte Deutschaufgaben

## Phase 11 – Play-Store-Vorbereitung

Vorbereiten:

- Datenschutzseite
- Impressum/Support-Hinweis
- keine Werbung
- keine externen Inhalte ohne Elternfreigabe
- Icon
- Screenshots
- kurze App-Beschreibung
- Test auf mehreren Geräten
- Release-Build/AAB später

## Qualitätssicherung vor jedem Abschluss

Technisch:

- Kompiliert die App?
- Läuft GitHub Actions?
- Wird APK erzeugt?
- Gibt es Importfehler?
- Gibt es fehlende Assets?
- Gibt es neue Package-Konflikte?
- Funktionieren Android-Berechtigungen?

UI:

- bleibt die Lumo-Shell erhalten?
- ist der Fuchs sichtbar?
- gibt es keine Overflow-Streifen?
- keine roten Error-Widgets?
- keine kalten Standardseiten?
- passt alles zum warmen Lumo-Design?

Funktion:

- kann ein Kind den Bereich benutzen?
- ist der nächste Schritt klar?
- funktioniert Zurück/Navigieren?
- wird Profilname verwendet?
- werden Fortschritte gespeichert?
- spricht Lumo sinnvoll?

Sicherheit:

- keine API-Keys im Code
- keine unnötigen Kinderdaten
- keine Cloud-Übertragung ohne Freigabe
- Elternkontrolle für Mikrofon/Scanner
- kindgerechte Fehlermeldungen

Sprache:

- Lumo klingt freundlich
- keine beschämenden Formulierungen
- keine Robotertexte, wenn vermeidbar
- kurze kindgerechte Sätze
- positive Fehlerkultur

## Fehler-Check

Wenn ein Fehler auftritt:

1. echten Fehlertext lesen
2. betroffene Datei nennen
3. Ursache erklären
4. minimalen Fix machen
5. Build erneut prüfen
6. erst danach weiterentwickeln

## Empfohlene Reihenfolge

1. Build prüfen und stabilisieren
2. Einstellungen + Elternbereich ausbauen
3. Lernprofil dauerhaft speichern
4. Tagesziel/Streak/Missionen echt machen
5. Belohnungen automatisch freischalten
6. Test/Schularbeit mit Ergebnis ausbauen
7. Lumo-KI mit Chatverlauf und Sprachmodus verbessern
8. Stimmeinstellungen erweitern
9. Scanner als Hausaufgaben-Helfer ausbauen
10. Österreichischen Volksschul-Fokus schärfen
11. Play-Store-Vorbereitung beginnen

## Endziel

Lumo Lernen soll eine moderne, warme, sichere und intelligente Kinderlern-App werden, die sich von anderen Lern-Apps abhebt durch:

1. sprechenden Lumo-Fuchs
2. Spracheingabe
3. kindgerechte KI-Hilfe
4. adaptiven Lernpfad
5. österreichischen Volksschul-Fokus
6. Elternkontrolle
7. Tagesziele und Missionen
8. echte Belohnungen
9. Scanner-Hausaufgabenhilfe
10. Datenschutz und Offline-first-Prinzip
