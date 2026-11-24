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

## Tatsächlicher Build und unveränderliche Wiederholung

Der volle Lauf [43774460935](https://github.com/Ullmann27/lumo-lernen/actions/runs/43774460935) verwendet APK-Quelle `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242` und Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Quellvalidierung und beide Builds sind erfolgreich: 2.884 Fluttertests bestehen, 202 bestehende Tests sind übersprungen; 73 Host-Testmethoden und zwölf native Programme bestehen. Die vollständigen unveränderten Prüfprotokolle stehen in `evidence/ci-2028-validation/` und `evidence/ci-2028-build/`.

Die ARM64-APK umfasst 535.020.882 Byte, SHA-256 `3bc5255101fe28ad62881a8aab478fd02650dc6e92a6abbe0d0d137367f06238`. Die x86-APK umfasst 538.184.315 Byte, SHA-256 `6b3a2f62ea80144b5af397e6353d1a52f2210109531a1edd49a1b22ec2bc4fa9`. Die ARM64-Datei wurde vollständig heruntergeladen und zusätzlich lokal anhand ihrer ursprünglichen Quell-/Versions-/Paket-/Signatur-/ABI-/Alignmentvorgaben geprüft.

Die erste Androidtour scheiterte nach der tatsächlichen korrigierten Lab-Erklärung und Stopp beim Lesen der noch einblendenden Mikrofonberechtigung. Der unveränderte UI-Baum enthält einen unsichtbaren Systemcontainer ohne Höhe; das folgende Bild zeigt den fertigen passenden Audiodialog. Originale liegen in `evidence/ci-2028-permission-transition-failure/`. Dieses FAIL wird nicht ersetzt.

Der neue 2028-Replay ist ausdrücklich von historischem 2027-Replay und frischem Buildpfad getrennt. Er bindet denselben vorhandenen APK-Hash an einen eigenen QA-Commit und einen eigenen Lauf. Erst die komplette neu ausgeführte Originaltour und anschließend die tatsächlichen nativen Banane-/Musterszenen dürfen die unveränderte 2028-ARM64-Datei freigeben. Der gemeinsame Beobachtungsgateblock bleibt erhalten; der reguläre Buildpfad verlangt weiterhin QA-Commit gleich APK-Quellcommit. Replaybefunde werden nicht zum Erfüllen dieses anderen Modus umgeschrieben.

Die separate Veröffentlichung prüft beide Ergebnisse, dieselbe native Pack-Datei, den ursprünglichen erfolgreichen Validate-/Buildjob, dessen tatsächlichen fehlgeschlagenen Androidjob, unveränderte QA-Gates und exakte Artefaktgrößen/-hashes. Eine neue Release- oder Tagüberschreibung ist ausgeschlossen. Nach Veröffentlichung muss die vollständige öffentliche APK ohne Anmeldung abgerufen und ihr Bytehash bestätigt werden. Beim Schreiben dieses Zwischenstands ist der neue Replay noch nicht erfolgreich abgeschlossen und kein direkter Download bestätigt.


## Erster unveränderlicher Replay: XML-Readerfehler

Der tatsächliche neue Lauf [43781148281](https://github.com/Ullmann27/lumo-lernen/actions/runs/43781148281) auf QA-Commit `6f8532940693cbba7059bed4037f9aa6d924bac4` behielt exakt die vorhandenen APK-Bytes und bestätigte zunächst die originalen Build-/Quellbindungen. Seine 123 Checkerprüfungen bestanden. Die vollständige Androidtour scheiterte am inzwischen sichtbar gewordenen Mikrofon-Dialog vor dem Zulassen-Tap: `node["package"]` war für den tatsächlich gelieferten `ET.Element` falsch. Der originale Fehler bleibt FAIL. Alle 177 Originaldateien, das vollständige Log und die Quellbindung sind in `evidence/ci-2028-replay-xml-node-failure/` erhalten. Die drei minimalen Attributkorrekturen sind separat als `842285f1fb7458f72a8491e34ceed922a96fa77a` veröffentlicht; alle 64 Originalprobe-Tests bestehen einschließlich einer Regression durch den echten Parser und das unveränderte Dialog-XML. Die anschließende neue vollständige Androidtour ist weiterhin erforderlich.


## Zweiter Replay: echter blockierter Lab-Rückweg, keine Veröffentlichung

[Lauf 43783036351](https://github.com/Ullmann27/lumo-lernen/actions/runs/43783036351) auf QA `0919f32431ce07491e0e182b3ea12b21aaaf9540` bestand 132 Host-Checker und erreichte die tatsächlich erteilte Mikrofonfreigabe. Das Gerät zeigte eine konkrete Begrenzung für deutsche Erkennung; kein gesprochenes Wort wurde erfolgreich geprüft. Nach Rückkehr aus dem eigenen Gespräch blieb der richtige erste Steintap wirkungslos, Checkpoint moved=0 statt1. Originale: `evidence/ci-2028-replay-bridge-checkpoint-failure/`. Zwei neue gezielte Widgetfälle reproduzieren dieselbe blockierte Wiederbedienbarkeit an unveränderter fc5-Quelle. Der Produktfix erfordert eine neue APK-Version 2029. Kandidat2028 bleibt gebaut, aber nicht veröffentlicht; die vollständige native Referenzabnahme fehlt weiterhin.
