# Android-Hostkompilierung auf 86445f53

Der Job **132307097883** im Run **43549076631**, Versuch 1, hat am 14.11.2026 um **03:01:20 UTC** erfolgreich abgeschlossen. Das unveränderte Originaljoblog belegt den tatsächlichen Checkout `86445f53af5d573549fc8cf03405261611f3cb7e`. Quelltext- und Ergebnisstempel im Originalartefakt nennen dieselbe Identität; es ist kein PR-Merge-Checkout.

Das einmal heruntergeladene Originalartefakt **14095622744** enthält **5.390 Bytes**. Sein SHA256 ist `7775b9346f9a065b5f036de12c3f8407b847b4b561deb264a125eedc0d4bdca8`; alle fünf ZIP-Mitglieder wurden per CRC und einzelnem SHA256 geprüft. Die unveränderten Originale liegen unter `originals/`.

Die realen Gradle-Aufgaben `:app:compileDebugKotlin` und `:app:compileDebugJavaWithJavac` endeten mit **BUILD SUCCESSFUL in 2m 25s**, 107 Aufgaben, davon 102 ausgeführt und 5 aktuell. Die sechs Authority-/Einbettungsverträge bestanden in 1,197 Sekunden. Der Bericht nennt neun erzeugte Klassen mit CI-seitig gemessenen Hashes; ihre Binärdateien sind nicht im kleinen Archiv und wurden lokal nicht erneut gehasht.

Der Compilerbericht enthält 33 Warnungszeilen, unter anderem veraltete Kotlin-/Android-DSL-Verwendung und unnötige Nullprüfungen, aber keine Compilerfehlermeldung. Die genaue Warnungsliste bleibt im Original und in `review.json` erhalten.

Um **03:03:45 UTC** lief der separate `verify-and-build`-Job noch in der vollständigen Flutter-Suite. Die Hostkompilierung belegt deshalb weder einen fertigen APK-Kandidaten noch erfolgreiche Android-, Creative-, Update- oder Publisher-Prüfungen. Es wurden keine großen Flutterarchive und keine Gerätebilder geladen. Der ursprüngliche fehlgeschlagene c081-Lauf bleibt unverändert dokumentiert.
