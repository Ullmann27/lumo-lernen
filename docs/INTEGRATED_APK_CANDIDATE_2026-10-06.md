# Lumo integrierter Test-APK-Kandidat – 6. Oktober 2026

## Zweck

Dieser Branch ist ausschließlich der reproduzierbare Test-APK-Kandidat für Heinz. Er wird nicht automatisch nach `main` gemergt.

## Quellstände

- Flutter/App-Basis: `450f73465e1df5a56b767908171e402fcebdb924`
  - identischer Tree wie der vollständig grün geprüfte PR-#201-Head nach der Flame-Teststeuerungsreparatur;
  - neues dunkelblau/cyanes Hologlass-Lern-/Aufgabenlayout;
  - angepasstes Hologlass-Onboarding;
  - sieben echte Onboarding-Runtime-Captures;
  - beweglicher Lumo mit Pose-/Talk-/Think-/Wave-Reaktionen.
- Eingebettetes Godot/Kart: `c650ff17a5b6a8016fccab0d9b530e0260c6c797`
  - Repository: `Ullmann27/lumo-godot`;
  - Engine: Godot 4.6.3.

## Kart-Abnahme des gepinnten SHA

GitHub Actions Run `37455260541`:

- PASS static project validator;
- PASS structured track developer packs;
- PASS Godot import / GDScript / shader parsing;
- PASS track geometry contract;
- PASS Sky Halo authoring safety contract;
- PASS Kart physics regression einschließlich Mystery-Prism-Lesbarkeit;
- PASS dynamic cup / mode regression;
- PASS Xvfb Fold / pause layout regression;
- PASS Runtime-Captures für Himmelsinseln, Sonnenhafen, Zauberwald und Holo City.

Das Sky-Halo-Loop-Modul bleibt authoring-only: keine Runtime-Collision und keine Behauptung einer 360°-Fahrbarkeit.

## APK-Hard-Gate

Eine APK darf nur als neuer Teststand ausgegeben werden, wenn der Build auf **diesem Branch-Head** erfolgreich abschließt und folgende Nachweise im selben Run erzeugt:

1. komplette Flutter-Suite PASS;
2. exakt der oben genannte Godot-Pin wird eingebettet;
3. APK-Signaturprüfung PASS;
4. erwartete Android-ABIs nachgewiesen;
5. eingebettetes Godot-PCK/Assets nachgewiesen;
6. `APK-VERIFICATION.json`, `BUILD-PROVENANCE.json`, `SHA256SUMS.txt` und `TEST-RESULTS.txt` stammen aus demselben Build;
7. kein alter APK-Artefakt wird als neuer Stand wiederverwendet.

Physisches Fold 7 und reale 60-FPS-Messung bleiben **NOT EXECUTED**, bis Heinz die APK tatsächlich auf dem Gerät prüft.
