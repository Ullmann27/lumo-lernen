# Android 1932: dieselbe APK mit echter Ruhephase prüfen

Produktquelle d20501476243e3a016c2574a9016c07e2ebe8f85; gebaut in Run38190879913. Vollständige Flutter-CI38190883778:1325 bestanden/117 optionale Aufnahmen übersprungen. ARM64/x86-Bau erfolgreich. Tatsächliches Update1931→1932, kostenlose lokale F2-Synthese/Wiedergabe, Pause/Fortsetzen/Stopp, Kart-Rückkehr und vollständiger Pluskurs bestanden.

Der Lauf ist insgesamt fehlgeschlagen: minus-active-help-offer scrollte fortlaufend und setzte damit die korrekte Ruhefrist des neuen Companions zurück. Echter Fehlerbeleg: Android-Artefakt11721798934, Screenshotminus-active-help-offer-missing.png und Hierarchien. Keine Minus-/Entdeckungs-/Neustartabnahme daraus behauptet.

Nur der Prüfhelfer wartet jetzt18Sekunden ohne Eingabe, bevor er nach dem Angebot scrollt. Die tatsächlichen Antworttaps, richtige Rückmeldung und aktivierte Weiter-Taste sowie zwei gespeicherte Fehlversuche bleiben verpflichtend. Zwölf Navigationsregressionen bestanden nach echtem RED→GREEN. Die unveränderte d205014-APK wird ohne Neubau geprüft; der Workflow begrenzt sämtliche QA-Änderungen auf eine explizite Dateiliste. Originalhierarchie für das ausgewählte Fünferfeld wurde lediglich von CRLF auf LF normalisiert.

Physisches Fold/ARM64, menschliche Hör- und externe pädagogische Abnahme bleiben offen. Keine Veröffentlichung oder kostenpflichtige Sprachanfrage.
