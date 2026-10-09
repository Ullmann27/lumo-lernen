# APK 1909: Android-Bildleser

Die APK aus Actions 37888592898 wurde erfolgreich gebaut: 808 Flutter-Prüfungen bestanden (4 vorgesehene Skips), 579 Android-Werkzeugprüfungen, 36 Vorbereitungstests, 25 native Spielproben und 24 Profilbudget-Prüfungen bestanden. Bauwelt, Puzzle, Rhythmus und Schatzsuche wurden auf Android API 35 mit Installation als Update, erhaltenem Profil, Offline-Start und Save/Reward-Guards geprüft.

Die beiden Kart-Läufe stoppten vor dem Vollrennen an der Bildleser-Meldung `Current native screenshot lacks DRIFT` im Fold-Cover-Layout. In beiden unveränderten Fehleraufnahmen ist DRIFT vollständig vorhanden. Der alte Neutralweiß-Filter entfernte antialiasierte Randpixel unter Helligkeit 150. Ein nachgeschalteter Filter mit Grenze 120 liest dieselben vollständigen Bilder mit unveränderten Wort-, Konfidenz-, Ausschnitt-, Aktualitäts- und Zeitgrenzen. Fehlendes D (RIFT) bleibt unzulässig. Der Originalfilter bleibt zuerst aktiv. Identische Masken werden nicht zweimal gelesen.

Die echten API-35/36-Aufnahmen liegen mit fixierten SHA256-Werten in den neuen Regressionstests. Die alten 579 Prüfungen bleiben erhalten; insgesamt 581 Tests. APK oder Spiel werden durch diese Änderung nicht verändert.

Der neue Workflow `lumo-action-android-qa.yml` führt beide vollständigen bestehenden Android-Proben auf API 35 und 36 erneut gegen exakt die bereits gebaute APK aus: App aa6519226fded77d5d5022dc6fe8c223e9dc82b8, Godot a377b9e2db3337ae46f9439200ef0af17af06cb5, APK SHA256 b58e055340595ac882fed47d0c11660f2420e41c1528ed2841c5100f13304fb7. Quelldaten und Testwerkzeug-Commit werden getrennt protokolliert. Keine Fahr-, Touch-, Speicher- oder Belohnungsprüfung wird entfernt.
