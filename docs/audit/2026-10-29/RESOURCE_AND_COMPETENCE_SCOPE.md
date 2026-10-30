# Lokale Ressourcen und Grenzen des Kompetenzkatalogs

Geprüfte Ausgangsbasis: 9fdfc3f17e640ade0912411167d4af2f73be8720.
Vorhanden: TutorCoordinationEngine, TaskHintService, LumoTutorEngine,
ErrorDetective, LearningJourney, ProgressRepository, GuidedLessonCatalog,
LumoVoice, LumoOfflineVoiceClient und LumoSpeechListener mit on-device-Prüfung.
Keine neue kostenpflichtige API, kein Modell-Download und kein automatischer
Mikrofonzugriff sind für die neue Engine erforderlich.

Die Engine ist deterministisch. Nichtverstehen ist eine beobachtete Rückmeldung,
kein diagnostiziertes Defizit. Fehlende Voraussetzungen werden als ungeprüft
angezeigt; vorliegende Unit-Antworten sind zunächst Beobachtungen. Eine
konzeptspezifische Bestätigung benötigt einen zum Ziel passenden Prozessbeleg.

Der Katalog enthält 14 Lernziele mit gerichteten Voraussetzungen. Er verknüpft
nur tatsächliche Aufgaben des aktuellen App-Curriculums. Die vollständige
Produktionsreferenz dieses Meilensteins ist Zehner/Einer. Weitere Ziele haben
Übungslinks und Planungsvoraussetzungen; eine Verknüpfung allein beweist nicht,
dass ein Kind den gesamten Lösungsweg beherrscht.

Deutsch/Lesen/Rechtschreibung/Sachunterricht werden in der Aufgabenlandkarte
geführt. Textstellen- und Tokenreihenfolge-Regeln sind getestet; die vollständigen
passenden Unterseiten und Transferszenen sind noch nicht integriert. Schreibtrainer,
Wort-Diktat-Selbsteinschätzung, Journal und Kart-Implementierungen werden erhalten.

Synthetische Vergleichsbank: tatsächliche alte Koordinationslogik aus 9fdfc3f1
in test/intelligence/legacy_tutor_9fdf.dart, mit angepassten Imports/Formatierung.
Zehn deterministische Fälle; Ergebnisse stehen im erzeugten
synthetic-trajectories.json. Drei Änderungen, sieben unveränderte boolesche
Entscheidungsergebnisse; keine schlechtere Entscheidung innerhalb dieser
begrenzten Fallauswahl. Unterschiede an der alten booleschen API sind keine
Behauptung, dass die alte Flutter-Oberfläche unmögliche Würfelzahlen zuließ.
Dies ist keine Wirksamkeitsstudie mit Kindern und keine klinische Validierung.

Die gerenderten Aufnahmen stammen aus produktiven Flutter-Widgets mit echten
Eingaben und lokal gespeicherter synthetischer Evidenz. Sie sind keine Mockups;
sie belegen weder physische Fold7-Bildrate noch lokale Spracheingabe auf dem
Zielgerät. Build 2000 bleibt unverändert erhalten; Build 2002 wurde nach
bestandener Android-Tour und echtem 2000-Update veröffentlicht. Siehe den
[aktuellen Nachweis](../2026-10-30/RELEASE_2002_VERIFICATION.md).
