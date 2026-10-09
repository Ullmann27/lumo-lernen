# APK 0.12.7+1910 – Build-Auftrag / Quellenidentität

Ausgangsbasis: der bereits gebaute und per SHA256 bestätigte APK-1909-Anwendungszweig (App #223, HEAD 0a4f988eac6c2e7407e29533649936864d0ee8f7).
Vorgeschlagene Godot-Revision: 75e563e32b97865922321c8bcc9f61b6ce32b46c auf Basis des mit 14 Karts, Aquarium und Werkstatt erfolgreich getesteten Quellenzweigs. Details und Quelltests: Godot PR #35.
Unverändert: Paket-ID, Flutter-Funktionen, Photo-Lesson-Fachzuordnung, Profil-/Sterne-/Wallet-Grenzen, Android-Host, Signierung, alle bisherigen Test-Schranken.
Versionsschritt: 0.12.7+1910 (neuerer Android versionCode zur Aktualisierung der 1909-Installation).

Abnahmebedingung: `.github/workflows/lumo-runtime-apk.yml` muss den Quellstand sauber bauen und die APK-Signatur/ABIs/Integrität, native Godot-Fahr- und Renderproben, Lern-App-Regressionen sowie Android 35/36 vollständig prüfen. Vor bestätigtem Workflow-Ergebnis ist **KEINE APK 1910 freigegeben**. Der eingefrorene geprüfte 1909-Build (SHA256 b58e055340595ac882fed47d0c11660f2420e41c1528ed2841c5100f13304fb7) bleibt separat downloadbar.

Keine stillschweigende Aussage über reale 60 FPS am Galaxy Fold, subjektives Fahrgefühl, Animation-/Sprachqualität oder die vollständige Referenzbild-Gleichheit. Kein Merge nach main, kein Release ohne ausdrückliche Freigabe.
