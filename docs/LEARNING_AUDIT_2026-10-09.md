# Lumo Lernen – Übernahme der sechs Prüfstränge (9.10.2026)

**Basis:** `lumo-lernen` Commit `b04bee5d1796e0664e2637b3bac41be9f75fa900`, Godot-Pin `de91cc966f7a8b5d43b04e0dd9d67b0e28dbe09b`.  
**Unabhängige Nachprüfung:** Code- und CI-Befunde. Die von Claude angekündigten sechs separaten Prüferberichte waren in dieser Übergabe **nicht vorhanden**; ihre Ergebnisse werden hier nicht erfunden.  
**Statuskonvention:** `CODE CONFIRMED` = im Quellcode belegt; `CI PASS` = von Actions bereits ausgeführter Schritt; `NOT EXECUTED` = nicht eigens gemessen; `OPEN` = verbleibendes Risiko.

## 1. Lehrplan Österreich 1.–4. Schulstufe – teilweise abgedeckt

- `CODE CONFIRMED`: `PrimaryCurriculumSupport.forGrade` trennt mathematische/digitale Übungen, praktische Aktivitäten und schulisch verwaltete Fächer. `test/curriculum_coverage_contract_test.dart` prüft alle vier Jahrgänge strukturell.
- Offizielle Grundlage: RIS [SchOG § 10](https://www.ris.bka.gv.at/NormDokument.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009265&Paragraf=10) und [Lehrplan der Volksschule](https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275). Die Anlage A des 2023 erneuerten Lehrplans gilt in der **4. Schulstufe seit 1.9.2026**.
- `OPEN`: Ein Fächername oder eine vorhandene Unit beweist noch nicht die vollständige fachliche/semesterweise Kompetenzabdeckung. Fachlich geprüfte Beispielaufgaben je Kompetenz und Schulstufe sowie manuelle Pädagogikfreigabe fehlen.

## 2. Aufgabenqualität – bestätigter Fehler korrigiert

- `CODE CONFIRMED`: Das alte `CognitiveProfileGenerator._choice` hat Duplikate entfernt und bei zu wenigen Antwortmöglichkeiten `—4—` usw. erfunden.
- Reparatur: Für Zahlen-, Wort- und Merkaufgaben werden fachlich passende zusätzliche **Ablenker** bereitgestellt. Ein allgemeiner Generator erzeugt keine Platzhalter mehr und bricht bei weniger als vier verschiedenen echten Antworten mit genauer Aufgaben-ID ab.
- `test/cognitive_profile_test.dart` sichert 4 Schulstufen × 50 = **200** deterministische Denkprofil-Fragen ab, prüft vier verschiedene Auswahlmöglichkeiten, verbietet Platzhalter, prüft numerische Antworten und das Format der Merkaufgaben.
- Weitere Bestandstests: `test/math_content_quality_test.dart`, `test/german_linguistic_quality_test.dart`, `test/task_quality_math_test.dart`, `test/iq/iq_puzzle_generator_test.dart`. **Kein unabhängiger vollständiger Generator-Fuzz-Lauf mit Tausenden zufälligen Aufgaben in dieser Übernahme ausgeführt**.
- `OPEN`: Zusätzlich unabhängig die Richtigkeit der Lösungen und die **Eindeutigkeit der Aufgabenstellung** prüfen; bloße Duplikatfreiheit reicht nicht.

## 3. IQ-/Denktest – ausdrücklich nicht normiert

- `CODE CONFIRMED`: Der neue `IqTestSession` führt 24 Rätsel in sechs Bereichen durch, gibt Denkpunkte und keine IQ-Zahl aus; `test/iq/iq_test_screen_test.dart` enthält vollständige Widget-Tests und Responsive-Fälle.
- Ungenaue Werbe-Bezeichnungen „IQ-Test für Kinder“ auf Startseite, Karte und Semantik wurden zu „Denk-Abenteuer“ präzisiert. Das alte `Lumo Denkprofil · 50` bleibt weiterhin erreichbar.
- `OPEN`: Keine repräsentative Normstichprobe, keine testpsychologische Validierung, keine Diagnostik. Zwei Denkprofile messen unterschiedliche Bereiche und dürfen nicht als fachlich gleichwertige IQ-Messungen präsentiert werden.

## 4. Grafik / Interaktion – Referenzvergleich offen

- `CODE CONFIRMED`: Flutter-Design verwendet in der Tests-Oberfläche eigene Widgets. Existierende **echte** Screenshot-Belege: `docs/proof/2026-10-08-iq/` für Phone, Fold und Querformat. Im APK-Lauf 37937263563 wurden die bisherigen Grafik-Screenshot-Schritte und das erste native Render-Artefakt erfolgreich abgeschlossen.
- `OPEN`: Hier keine neuen Flutter/Godot-Bilder gerendert; Fold-Hardware, Textskalierung, Low-end-Geräte, 60 FPS, Stimmen und Referenzvideo-Gleichheit nicht unabhängig bestätigt. Alte Screenshots sind **kein** Beweis für geänderte Versionen. Godot meldet selbst `VISUAL_GAP` gegenüber der Lumo-Referenz.

## 5. Fehler, Profiltrennung und Datenschutz – Blocker

- `CODE CONFIRMED`: `PRIVACY.md` behauptete irreführend „keine Serververbindung“ und „kein Audio“. `LumoAiProxyClient` versendet bei aktivierter KI Nachricht, Klassenstufe, Gesprächsverlauf und Kontext. `AppSettings.aiProxyEnabled` ist standardmäßig `false`. Die Dokumentation wurde auf nachgewiesene Datenflüsse umgestellt.
- `OPEN / HOCH`: `ProgressRepository` verwendet feste Schlüssel `lumo_progress_skills`, `lumo_progress_daily`, `lumo_progress_last`. Auch `CosmosWorld` verwendet globale Schlüssel. Diese Speicherpfade belegen derzeit **keine per-Kind-Isolation**; vor Mehrkindfreigabe End-to-End testen und mittels Namespace/Migration absichern.
- `CODE FIX / TEST PENDING`: Im neuen Änderungsstand verbietet `AppSettings.sanitizeProxyUrl` unverschlüsseltes HTTP zu externen KI-Proxy-Hosts; `localhost`, `127.0.0.1` und `::1` bleiben für lokale Tests zugelassen. Sicherheits-Regressionstests stehen in `test/app_settings_ai_mode_test.dart`. Die produktive Serverkonfiguration und Einwilligungsabläufe sind dennoch offen.
- `NOT EXECUTED`: Kein vollständiges Traffic-Audit und keine juristische Compliance-Zertifizierung.

## 6. Markt und pädagogischer Nutzen – differenzierte Chance

- ANTON bietet bereits umfangreiche Übungen, direktes Feedback, Hilfestellung und teilweise Offline-Nutzung: [anton.app](https://anton.app/de/).
- Khan Academy Kids bietet bereits einen adaptiven, kompetenzorientierten Lernpfad und Fortschrittsberichte: [Khan Academy Kids](https://khankids.zendesk.com/hc/en-us/articles/360048828572-Learn-more-about-the-Learning-Path).
- Die Education Endowment Foundation beschreibt **Mastery Learning** mit klaren Lernzielen, gezielter Nachförderung und überprüfter Beherrschung; die Evidenz ist begrenzt, aber überwiegend positiv: [EEF](https://educationendowmentfoundation.org.uk/education-evidence/teaching-learning-toolkit/mastery-learning/).
- **Empfohlenes Alleinstellungsmerkmal, noch NICHT implementiert:** „Lumo Lernkosmos“ als **sichtbare Kompetenzwelt** nach österreichischem Volksschul-Lehrplan. Jeder Baum bleibt eine Belohnung, erhält aber ein überprüfbares Lernziel (z. B. „Plus bis 20“), einen Kompetenzzustand (neu / üben / sicher / wiederholen) und eine passende Übungsroute. Die vorhandenen `SkillRecord.mastery`, `weaknessScore` und `LearningProfileEngine.topRecommendation()` bieten einen Ausgangspunkt; `CosmosWorld.grantReward` zählt derzeit nur richtig beantwortete Aufgaben. Grundsätzlich Kompetenzfortschritt von Sammelbelohnungen trennen. Vor Freigabe pro Kind isoliert speichern, diagnostische Aussagen vermeiden und Wirksamkeit pädagogisch evaluieren.

## Technischer Abschluss / Verifikation

- Diese Übernahme verändert **keine** Godot-3D-Assets und **keinen** Main-/Release-Branch.
- Die kleinen Reparaturen an Antwortoptionen, Denktest-Labels und Datenschutzdarstellung werden als Review-PR auf Claudes App-Branch angeboten.
- `NOT EXECUTED`: Lokale Flutter-/Dart-Laufzeit in dieser Arbeitsumgebung nicht vorhanden; zusätzliche Tests werden erst als `CI PASS` bezeichnet, wenn die verknüpften GitHub-Actions sie tatsächlich bestanden haben.
- APK 1913: laufender CI-Job `37937263563` mit eigenem Artefakt-Nachweis, **nicht** als fertig oder installierbar ausgeben, solange das Build-Artefakt fehlt. Änderungen dieses PRs sind **nicht** Teil von 1913.
