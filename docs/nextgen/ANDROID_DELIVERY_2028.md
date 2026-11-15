# Nachfolgeprüfung 0.13.16 (2028)

## Ausgangslage

Die Vorgängerversion 2027 wurde nicht veröffentlicht. [Der tatsächliche Androidfehler](evidence/lab-conversation-context-failure-20261115/README.md) zeigt den Verlust des Lab-Aufgabenkontexts beim Öffnen des eigenen Gesprächs. Der Fehler wird im Produkt korrigiert; eine neue Versionsnummer allein ist keine Korrektur.

Der Produktstand wird zusätzlich auf die Besitzergrenzen beim Schließen eines Gesprächs geprüft: Ein altes Gespräch darf weder einen neuen Sprechauftrag stoppen noch die neue Aufgabe, deren Abbruchepoche oder deren Gesten verändern. Aktives „Stopp“ muss die eigenen Ton-, Mund- und Gestensignale weiterhin gemeinsam beenden.

## Verbindlicher neuer Buildpfad

Die bestehende Workflowdatei `lumo-nextgen-learning-apk.yml` verwendet weiterhin die vorhandene Flutter-/Godot-Architektur, Paketkennung und Testsignatur. Vor einem Build prüft sie den nativen Quell-Pin, alle 18 geschützten Module und jeden Dateihash der frisch erzeugten Abdeckungsliste.

Die erste Androidtour muss vollständig erfolgreich sein. Erst danach führt `run_lumo_nextgen_current_android.sh` die zusätzlichen nativen Banane-/Musterszenen aus. Deren aktueller Einstieg prüft APK-Hash, Provenienz, Versionsname/-code, Quellen, Workflowkennung und die tatsächlich installierten Bytes. Er bindet sich an den erfolgreichen Originalbericht derselben APK und desselben frischen Emulators. Der bestehende Neustart mit ausschließlich fiktivem Profil erfolgt erst nach diesen Prüfungen.

Der historische 2027-Download-/Replaypfad bleibt auf seine alten Bytes festgelegt. Seine Ergebnisse oder ein separater Diagnoselauf dürfen die neue APK nicht freigeben. Der aktuelle Veröffentlicher verlangt beide vollständigen Lerntouren, die echten Audio-/Figur-/Effekt-Messfenster, die native Silbenwiederholung und den erhaltenen Musterrückweg.

`fullModernizationComplete` bleibt ausdrücklich `false`. Die gemeinsame Aufgabenkarte ist keine individuelle räumliche Fachsimulation jeder inventarisierten Variante. Die native Figur läuft in der vorhandenen separaten Godot-Activity. Physische ARM64-/Fold7-Geräte, echte gesprochene Erkennung, hörbare Qualität, Langzeitbetrieb und 60 FPS sind ohne entsprechende aktuelle Messung nicht nachgewiesen.

## Noch keine Artefaktbehauptung

Diese Datei beschreibt den vorbereiteten Nachfolgepfad. Der neue App-Commit, tatsächliche CI-Ergebnisse, APK-Hash, Dateigröße und der geprüfte direkte Download werden nach dem neuen Build ergänzt. Die alten 2027-Hashes werden nicht als Identität der Nachfolgeversion verwendet. `main` bleibt unverändert.
