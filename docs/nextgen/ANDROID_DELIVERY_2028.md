# Nachfolgeprüfung 0.13.16 (2028)

## Ausgangslage

Die Vorgängerversion 2027 wurde nicht veröffentlicht. [Der tatsächliche Androidfehler](evidence/lab-conversation-context-failure-20261115/README.md) zeigt den Verlust des Lab-Aufgabenkontexts beim Öffnen des eigenen Gesprächs. Der Fehler wird im Produkt korrigiert; eine neue Versionsnummer allein ist keine Korrektur.

Der Produktstand korrigiert zusätzlich die Besitzergrenzen beim Schließen eines Gesprächs (56/56 gezielte Flutterprüfungen): Ein altes Gespräch darf weder einen neuen Sprechauftrag stoppen noch die neue Aufgabe, deren Abbruchepoche oder deren Gesten verändern. Aktives „Stopp“ muss die eigenen Ton-, Mund- und Gestensignale weiterhin gemeinsam beenden.

Der getrennte Diagnoselauf `43770887936` erreichte außerdem die tatsächliche native Banane-Szene der alten APK. Der Sprachknopf fehlte; 189 gespeicherte Sprachlogs enthalten kein gestartetes/abgeschlossenes `LumoLearningSpeech`-Paar. Die Lernwelt prüfte registrierte Android-Plugin-Methoden mit `Object.has_method`. Der offizielle Godot-Quelltag 4.6.3 enthält für die separate JNI-Methodenregistrierung `has_java_method`. Der neue native Helfer prüft beide tatsächlich verfügbaren Wege und ruft unbekannte Methoden weiterhin nicht auf. Der erste isolierte Helfertest besteht 32 Prüfaussagen. Der anschließende Review korrigiert zusätzlich zwei Stop-Aufrufe in der tatsächlich gerouteten Unterklasse; die erweiterte Prüfung lädt deren echte PackedScene und besteht 43/43 nach zwei reproduzierten Fehlern. Der neue Android-Audionachweis bleibt erforderlich. Der endgültige veröffentlichte Native-Pin ist `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.

Primärquellen: [Godot 4.6.3 JNISingleton](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/api/jni_singleton.h) und [offizieller Hinweis zur Android-Methodenabfrage](https://github.com/godotengine/godot/issues/106436). Die alte Emulatormessung ohne Sprache ist diagnostisch und wird nicht als aktueller Performance-PASS übernommen.

Die Muster-Gesprächsbridge übernimmt die Wiederholungsgruppe jetzt aus dem tatsächlichen Godot-Payload `parameters.patternUnit` und prüft sie gegen die unveränderliche Startsequenz und deren kleinste Periode. Nur eine aktuell registrierte `pattern_group` darf als Blick-/Gestenziel erscheinen. Berechtigungen, verspätete Antworten und nullable `stepId` bleiben am bestehenden v1-Vertrag gebunden. Der tatsächliche Produktions-Kotlin-/Java-Test besteht 81 Integrationschecks; die unveränderten 26 Java-Dialogchecks bestehen ebenfalls. Das sind JVM-Prüfungen mit ausdrücklich simulierten Android-Systemklassen, kein Android-Wiedergabebeleg.

## Verbindlicher neuer Buildpfad

Die bestehende Workflowdatei `lumo-nextgen-learning-apk.yml` verwendet weiterhin die vorhandene Flutter-/Godot-Architektur, Paketkennung und Testsignatur. Vor einem Build prüft sie den nativen Quell-Pin, alle 18 geschützten Module und jeden Dateihash der frisch erzeugten Abdeckungsliste.

Die erste Androidtour muss vollständig erfolgreich sein. Erst danach führt `run_lumo_nextgen_current_android.sh` die zusätzlichen nativen Banane-/Musterszenen aus. Deren aktueller Einstieg prüft APK-Hash, Provenienz, Versionsname/-code, Quellen, Workflowkennung und die tatsächlich installierten Bytes. Er bindet sich an den erfolgreichen Originalbericht derselben APK und desselben frischen Emulators. Der bestehende Neustart mit ausschließlich fiktivem Profil erfolgt erst nach diesen Prüfungen.

Die erste Tour enthält nun zusätzlich eine tatsächliche Frage innerhalb der nativen 8+5-Szene. Sie setzt das unbewertete Anschauungsmodell sichtbar zurück, tippt „Warum zuerst zwei?“ in das beobachtete Godot-Eingabefeld und sendet über dessen sichtbaren Knopf. Anschließend müssen zwei automatisch bewegte Objekte, eine aktuelle inhaltliche Erklärung und eine neue Audiowiedergabe erkennbar sein. Manuelle Objektbewegung oder ein gesetztes Antwort-/Bewertungsergebnis ersetzt diese Prüfung nicht.

Der historische 2027-Download-/Replaypfad bleibt auf seine alten Bytes festgelegt. Seine Ergebnisse oder ein separater Diagnoselauf dürfen die neue APK nicht freigeben. Der aktuelle Veröffentlicher verlangt beide vollständigen Lerntouren, die echten Audio-/Figur-/Effekt-Messfenster, die native Silbenwiederholung und den erhaltenen Musterrückweg.

`fullModernizationComplete` bleibt ausdrücklich `false`. Die gemeinsame Aufgabenkarte ist keine individuelle räumliche Fachsimulation jeder inventarisierten Variante. Die native Figur läuft in der vorhandenen separaten Godot-Activity. Physische ARM64-/Fold7-Geräte, echte gesprochene Erkennung, hörbare Qualität, Langzeitbetrieb und 60 FPS sind ohne entsprechende aktuelle Messung nicht nachgewiesen.

## Noch keine Artefaktbehauptung

Diese Datei beschreibt den vorbereiteten Nachfolgepfad. Der neue App-Commit, tatsächliche CI-Ergebnisse, APK-Hash, Dateigröße und der geprüfte direkte Download werden nach dem neuen Build ergänzt. Die alten 2027-Hashes werden nicht als Identität der Nachfolgeversion verwendet. `main` bleibt unverändert.
