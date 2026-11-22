# Enger Abgleich der ursprünglichen HTML-Funktionen

## Umfang und Beweisgrenze

Quellenprüfung am 22.11.2026 während der Integration von 2067. Verglichen wurden die vom Nutzer bereitgestellten Dateien `05-lumo_lernen_agent_playready_prototype_app.html` und `09-lumo_lernen_menu_pro_app.html` mit den tatsächlich erreichbaren Flutter-Einstiegen. Diese Prüfung ist ein statischer Anschlussnachweis, kein neuer Android-Lauf und keine Behauptung vollständiger Gleichheit aller alten Oberflächen.

## Bestätigte Lücken vor ihrem jeweiligen Anschluss

### Auszeichnungen und Sterne

HTML05 `claimAchievement` (Zeile 646) und `renderAchievements` (831), entsprechend HTML09 (278/309), prüfen Freischaltung und bereits erfolgtes Einlösen, speichern die Claim-ID und erhöhen `st.stars` um den Auszeichnungsbonus.

Im untersuchten Flutter-Stand zeigte `LumoAppShell._onAchievementUnlock` (`lib/app/app_shell.dart`, ursprünglich 199–277) Burst und Snackbar mit `+rewardStars`, rief aber keine Wallet-Methode auf. `AchievementsWallScreen` zeigte denselben Bonus. Die übrigen Verwendungen von `rewardStars` waren die Katalogdefinitionen; ein Claim-/Claimed-Speicher fehlte. `AchievementTracker` und `AchievementRepository` verwendeten globale Schlüssel `lumo.achievements.unlocked` und `lumo.achievements.counters`, mit best-effort gespeicherten Änderungen. Im gesamten `lib` fand sich neben dem Tracker selbst kein externer `recordEvent`-Aufruf; lediglich der aktuelle Walletsaldo wurde als `starsTotal` synchronisiert.

Das ist eine funktionale Lücke, kein bloß abweichendes Design. Der koordinierte Folgeauftrag bindet Auszeichnungen an ein Profil und bucht den Bonus mit einer dauerhaften, idempotenten Wallet-Quittung. Vorhandene globale Alt-Badges dürfen dabei nicht ungeprüft einem beliebigen Kind zugerechnet werden. Dieser Bericht nimmt das Ergebnis dieses parallelen Folgeauftrags nicht vorweg.

### Eigene Aufgabe aus Text starten

HTML05 `Recognizer.parse` (702–724), `recognizeNow` und `recognizeStart` (725–742) bilden einen vollständigen Ablauf: Text eingeben, konkret erkannte Aufgabe ansehen, dieselbe Aufgabe zum Bearbeiten starten. Unterstützt waren einfache ganzzahlige Addition/Subtraktion/Multiplikation, bestimmte Anfangsbuchstabenformulierungen und Zahlenreihen. Der alte Parser akzeptierte manche mehrdeutigen Eingaben zu großzügig; seine Implementierung ist deshalb keine ungeprüfte Vorlage für heutige Validierung.

Der heutige `lib/widgets/scan_screen.dart` bietet Kamera und Galerie und übergibt ML-Kit-Text an `onTextDetected`; er enthält keine entsprechende freie Texteingabe. `LumoPhotoLessonScreen._onTextDetected` analysiert Fach/Thema. `PhotoLessonPractice.generate` (`lib/features/photo_lesson/photo_lesson_practice.dart`) erzeugt daraus fünf neue Curriculum-Aufgaben. Es übernimmt nicht den konkret eingegebenen Ausdruck als identische Übungsaufgabe.

`LumoAgentContent._ask` übergibt Text an `LumoConversationController.ask` und zeigt/spricht dessen Antwort. Der vorhandene Dialog-Intent-Parser steuert die bereits aktuelle Lernaufgabe. Auch dieser Weg startet keine aus dem eingegebenen Ausdruck neu erkannte Aufgabe. Eine bloße Foto-Lektion oder Dialogantwort ist daher kein gleichwertiger Ersatz für den alten Startablauf.

## Tatsächlich vorhandene Anschlüsse

| Alter Bereich | Beobachteter heutiger Weg | Aussage |
|---|---|---|
| Lernbericht | `lib/widgets/profile_screen.dart` öffnet `LernberichtScreen`; dessen `_load` lädt das Aufgabenprotokoll für das aktive Schulkind bzw. `self` und berechnet `LearningAnalysis`. | Ein tatsächlicher Daten-/Anzeigeweg ist vorhanden. |
| Elternbericht | `SettingsContent` enthält `ParentReportCard`; `_buildReport` verarbeitet vorhandene Skills und Lesedaten in einem lokalen Bericht. Eine zusätzliche KI-Analyse ist eine eigene optionale Aktion. | Der lokale Bericht ist kein leerer Platzhalter. |
| Geschichten | Home, Deutsch und Lesen öffnen `LumoStoryLibraryScreen`; `_createNew` öffnet `LumoStorySetupScreen`; `_startStory` erzeugt eine Geschichte aus der Auswahl und `_openReader` öffnet `LumoStoryReaderScreen`. | Auswahl, Erzeugung und Leser sind verbunden. |
| Agent | `LumoSection.agent` zeigt `LumoAgentContent`; Text-/Spracheingabe erreicht `LumoConversationController.ask`, die Antwort erscheint im Dialog und kann vorgelesen werden. | Ein echter Gesprächseinstieg ist vorhanden; daraus folgt keine allgemeine freie Aufgaben-Erkennung. |
| Persönlicher Tagesplan | `LumoPersonalDailyTutorPlanner.buildEvidencePlan` nutzt gespeicherte Skill-/Journey-Daten; `HomeContent` übergibt seine Schritte an `LumoPersonalDailyPlanCard`; Taps setzen exakt Fach/Thema und öffnen Übung oder Nachhilfe. | Der Plan führt zu bearbeitbaren Einheiten und ist keine alleinige Textanzeige. |

Für diese fünf vorhandenen Wege wurde im begrenzten Altfunktionsabgleich keine weitere fehlende Einstiegshandlung belegt. Bestehende Datenisolations-/Fehlerfallprüfungen und neue Android-Belege bleiben davon getrennte Nachweise.
