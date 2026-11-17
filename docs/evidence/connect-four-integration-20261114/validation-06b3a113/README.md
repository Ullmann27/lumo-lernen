# C4-Verifikation am veröffentlichten Anschluss

**Host:** `06b3a1136cfe2a8a8b13e46ac9819e65b7130ea5` / Tree `2e6ffb0a673251d4d09dfaa4c5fc916cbf898797`  
**Native:** `27ae427029a5199699c95a79a84b0027d7571752` / Tree `c389c0de01d9a6ca9fd6e9332fafdf2dedbc8153`

## Tatsächliche Ergebnisse

- **49 Python-/JVM-Verträge bestanden**, ohne Fehler oder Skips:20Runtime-Gate,12C4-Produkt-Kotlin,12bestehende Return-/Routingverträge sowie5Generator-/Cards-Fensterfälle. Laufzeit16,82s.
- **48 Flutterfälle bestanden**, ohne Fehler oder Skips, auf den sieben unveränderten gelieferten C4-Testdateien. Laufzeit18,09s. Regeln/Bots, Profilbindung, Save-/Reward-Replay, Token/Revision/ACK, Route, echte Widgeteingaben und die320dp-Fallback-Kontrollen sind in den Originalprotokollen einzeln benannt.
- Alle gebundenen Host-/Native-Quellen sind vorher/nachher identisch. Die27früh eingefrorenen Integrationsdateien sind weiterhin exakt gleich. Beide Gitstände sind sauber.

## Unveränderte offene Rendererprüfung

Der tatsächliche gelieferte `run_connect_four_runtime.py` wurde gestartet. Seine Quelle-/Pinprüfung akzeptiert die exakten veröffentlichten Commitobjekte; anschließend stoppt er mit **Missing required executable: xvfb-run**, bevor Dart oder Godot gestartet werden. Der vollständige Zweiprozess-Gate bleibt damit offen. Es wurde kein Xorg-/Headless-Ersatz eingeschleust und kein Godot-Import ausgeführt. Root ergänzt den isolierten CI-Anschluss mit der benötigten Umgebung.

## Erhaltener früher Umgebungsfehler

Der erste Flutter-Aufruf scheiterte vor dem ersten Test mit ENOSPC beim Assetbundle. Flutter löscht und erzeugt `build/unit_test_assets` neu; der dortige Unterordnerlink wurde dadurch ersetzt. Der Originalfehlerlog bleibt erhalten. Der tatsächliche installierte Flutter-Quellcode und ein kleiner echter Dart/package:file-Pfadgegenfall belegen die ursächliche Grenze. Nach Roots Freigabe wurde ausschließlich das gesamte eigene build-Elternverzeichnis vorübergehend nach/tmp verknüpft. Exakt derselbe Flutterbefehl bestand danach48Fälle. Der Link ist entfernt, globale Konfigurationen und Quellen bleiben unverändert.

Die607veröffentlichten Assets und das vorgegebene org.json-JAR sind identitätsgeprüft. Die Paketauflösung lief ausdrücklich offline. Nur eigene erzeugte Fehlversuchs-Buildausgaben wurden bereinigt; Originale und Quellen bleiben erhalten. Große reproduzierbare Testcaches werden nicht in dieses Evidenzpaket aufgenommen.

## Grenzen

Dies ist eine lokale Vertrags- und Flutter-Abnahme. Die Kotlinprüfungen verwenden tatsächliche Produktklassen mit ausdrücklichen JVM-Grenzadaptern. Die Flutter-Route verwendet Channelfixtures. **Keine Android-, JNI-/Binder-, C4-Renderer-, native Safe-Area- oder Geräte-FPS-Freigabe folgt daraus.** Der frühere Producer170er-Lauf wird nicht als neue Abnahme verwendet.

`handoff.json` ist die maschinenlesbare Übergabe. Originale Befehle, vollständige Logs, getrennte Fehler-/Erfolgsprotokolle, Quellenbindungen und der begrenzte Pfadgegenfall liegen daneben. `manifest.json` und `SHA256SUMS` binden alle Packdateien.
