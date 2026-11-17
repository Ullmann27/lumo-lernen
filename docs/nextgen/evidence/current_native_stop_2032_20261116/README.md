# Aktiver nativer Stopp im aktuellen vollständigen Lauf ab 2032

**Stand dieser Übergabe: nur lokale Hostprüfung, kein neuer Android-PASS.**

Basis ist `362b6ac36fb645bb5266205f17c5504a8fbf22a3`. Der Anschluss gehört zum aktuellen Buildpfad; die unveränderlichen 2031-Replays und ihre bestehenden Resultate werden nicht umgewidmet.

## Verhalten

`CurrentCandidateProbe.banana()` führt zuerst den vollständigen bisherigen Banane-Ablauf aus. Nur bei `expected_version >= 2032` folgt `run_current_native_stop`. Erst nach dessen erfolgreicher Rückkehr läuft das bestehende `pattern()` weiter. Fehler in Banane oder Stopp brechen die Tour ab.

Der neue Helper bindet den aktuellen APK-Kandidaten, Flutter-/Native-Quellen, Workflow, den eigenen Helper und die unveränderte importierte Aktionsdatei. Vor der Aktion liest er erneut den tatsächlichen installierten APK-Pfad, die PackageManager-Metadaten und den vollständigen APK-Hash. Die abgeschlossene Banane-Prüfung und das aktuelle synthetische Profil müssen zusammengehören. Vorher und nachher werden Profil, Lern- und Belohnungsdaten verglichen.

Anschließend verwendet er ausschließlich die bestehende Funktion `lumo_nextgen_2031_native_runtime_cases.py::bridge_active_stop`. Diese beobachtet Akademie und offene Werkzeuge frisch, öffnet die geführte Aufgabe „Acht und fünf“, führt die echte Warum-zuerst-zwei-Erklärung aus und verlangt danach eine neue laufende Wiedergabe. Eigener PID, aktuelle Playback-ID, zwei frische stabile Bilder des sichtbaren Stoppknopfs, das 45-Sekunden-Fenster vor Eingabe und das anschließende Ruhefenster bleiben unverändert. Es gibt keinen zusätzlichen Installations-, Reset- oder Wiederholversuch durch den neuen Helper.

Das eigene Resultat `current_native_active_stop` nennt Herkunft, Installation, abgeschlossene Banane, Modell und beobachtete Stoppgrenzen. `prepare_current_learning_release.py::verify_tours` verlangt dieses Resultat ab VersionCode 2032. Die von historischen Replay-Publishern verwendete Funktion `verify_observed_execution` bleibt bytegleich; ebenso die historische Aktionsdatei und deren 2031-Runner/Verifier. Letztere werden vom neuen Helper nicht aufgerufen.

## Nachweise

| Prüfung | Tatsächlicher Stand |
|---|---|
| Ausgangsregression | `b97edebdc8614412e1e67b6098bd48f0e96358a3`: zwei erwartete Fehler, keine unerwarteten Fehler. Der alte aktuelle Publisher akzeptierte das fehlende Stoppresultat, der reale Referenz-Runner ging direkt von Banane zu Muster. |
| Geprüfter Code | `34a0f314f9df4d0ac23a2032bd324b43072542d7`, vor dem Lauf sauberer Worktree. |
| Gezieltes GREEN | 26/26: elf neue Current-Stopp-Prüfer, zwölf vorhandene Current-Prüfer und drei unveränderte DirectStopTiming-Prüfer; kein Skip. |
| Quellgrenzen | `source.json` bindet 15 Quelldateien, darunter elf unveränderte bestehende Abhängigkeiten, sowie die bytegleiche historische gemeinsame Publisherfunktion. |

`red.log` und `green.log` sind die unveränderten lokalen unittest-Ausgaben. Die positiven Prüfdaten sind ausdrücklich synthetisch und werden nicht in einen Android-Ergebnisordner geschrieben. Die vorhandenen Timingtests simulieren Transport, Zeit und Zielbeobachtung; sie beweisen keine tatsächlich erfolgreiche OCR oder Eingabe auf einem Androidgerät.

Ein späterer erfolgreicher Androidlauf muss den Stopp tatsächlich ausführen und die bestehenden vollständigen Original- und Referenztouren weiterhin bestehen. MediaPlayer-Ereignisse und ein endliches Ruhefenster belegen weiterhin weder akustische Stille noch Mund-/Gestenstopp oder eine millisekundengenaue Reaktion. Keine Aussage zur vollständigen Modernisierung, zu physischem Fold-Verhalten oder zu 60 FPS wird hinzugefügt.
