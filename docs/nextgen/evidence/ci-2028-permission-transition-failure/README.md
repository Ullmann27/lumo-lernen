# Unveränderter Androidfehler 2028: Permission-Übergang

Lauf 43774460935, Job 133004691086, x86-APK aus `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242`, endete mit FAIL. Alle 165 Mitglieder des originalen Artefakts bleiben in der bytegeprüften ZIP erhalten. Der vollständige Joblog ist verlustfrei komprimiert.

Die tatsächliche Tour hatte zuvor die zum aktuellen Lab gehörende Erklärung auf „Warum zuerst zwei?“ und Stopp erreicht. `0125-typed-why-response.png` zeigt die fachlich passende Erklärung. Die vollständige Tour und die zusätzliche native Banane-/Musterprüfung wurden damit nicht bestanden.

`0138-microphone-outcome.xml` enthält für `com.google.android.permissioncontroller` nur einen unsichtbaren FrameLayout-Knoten mit Höhe null (`[27,1205][1053,1205]`). Der Leser prüfte sofort auf eine Zulassen-Taste und brach ab. Das anschließend erfasste Originalbild `0139-failure-current-screen.png` zeigt die passende Audioaufnahme-Berechtigung für Lumo Lernen Neu mit einer „While using the app“-Taste. Der UI-Baum war bei der ersten Beobachtung noch im Übergang.

Eine begrenzte Leser-Korrektur muss echte sichtbare Mikrofon-/App-Bindung prüfen, identische normalisierte Tastentreffer deduplizieren und echte Mehrdeutigkeit weiter ablehnen. Anschließend ist die vollständige Originaltour gegen dieselbe unveränderte APK neu auszuführen. Dieses Originalergebnis bleibt FAIL. Keine Berechtigung wurde für diesen Nachweis per adb vorab erteilt, kein späteres Ergebnis wird hier eingesetzt.

Umgebung: Android-35-x86_64-Emulator mit Software-Grafik, kein physisches Telefon/Fold7. Noch keine Veröffentlichung und kein 60-FPS- oder Spracherkennungsnachweis.

Die originale ZIP ist wegen der Übertragungsgrenze in zwei binäre Teile aufgeteilt. `archive-parts.json` nennt Reihenfolge, Einzelhashes und Gesamthash. Die unveränderten ZIP-Bytes entstehen durch Aneinanderhängen der beiden Teile; es wurde nichts neu komprimiert.
