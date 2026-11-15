# Native Banane: tatsächlicher Androidfehler vor dem Capability-Fix

**DIAGNOSTIC_ONLY, nicht releasefähig.** Run [43770887936](https://github.com/Ullmann27/lumo-lernen/actions/runs/43770887936), Job 132986319654, QA `e4b6f0734e718f781c591f933c534ef971b76b0e`. Die unveränderte alte APK stammt aus Flutter `72a7914059d10152604b877cfeaf8bd1d2155810` / Native `ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb`.

Das echte Androidbild zeigt die erreichte Szene „Wörter bauen · Banane“, den Fuchs, die Banane, leere Zielplätze und Silbenbausteine. Der Knopf „Schritt anhören“ fehlt. 189 tatsächliche Sprachlog-Snapshots enthalten kein gestartetes/abgeschlossenes aktuelles `LumoLearningSpeech`-Paar. Der Lauf scheitert vor weiteren Silbenschritten, Fragenpanel und Musterroute. Seine vorherige vollständige Originaltour war nicht bestanden; kein Diagnoseresultat erfüllt die Freigabe.

Der offizielle Godot-Quelltag 4.6.3 bindet `has_java_method`, um die eigene JNI-Methodenliste abzufragen. Die Lernwelt verwendete vor diesen Aufrufen `Object.has_method`. Originalquellen und ihre Gitblob-/SHA-256-Werte liegen bei. Die Laufzeit meldet `4.6.3.stable.official.7d41c59c4`; diese Kurzrevision ließ sich nicht zur gleichen vollständigen Upstream-Revision auflösen. Deshalb wird keine ungesicherte Gleichheit zwischen Quelltag und Laufzeitbinary behauptet. Der Helfer prüft den tatsächlich vorhandenen Reflection-Weg.

Der erste isolierte Fix `464e271167025185e48747c03310f23f6d79a092`, veröffentlicht als `f521fc5887e98562ba89fbfeca3bb466031fdea0`, besteht 32 echte Godot-Prüfaussagen. Er korrigiert die Basisklasse. Ein anschließender Review fand zusätzlich zwei Stop-Guards der gerouteten Unterklasse; deren Folgekorrektur und der neue Androidlauf sind gesondert nachzuweisen.

Hier liegen bytegenaue ausgewählte Originale und das vollständige Mitgliedermanifest des CRC-/hashgeprüften 585-Dateien-Artefakts. Die gesamte ZIP ist nicht nochmals im Repository enthalten. `selected-originals.json` trennt diese Auswahl ausdrücklich vom vollständigen Originalartefakt.

Die letzten 35 Diagnosefenster enthalten 239 Samples über 188.857,508 ms, ein gewichtetes Frameintervall von 790,199 ms und null Sprachsamples. Das ist kein Audioüberlappungs-/Performance-PASS und keine physische Gerätemessung. Das 180,095-s-Video deckt den 223,81-s-Prüfblock nicht vollständig ab. Diese ursprünglichen Grenzen bleiben bestehen.
