# Vorhandene Leistungsinstrumentierung – begrenzter Quellenbefund

Stand: 2026-11-14 17:51:17 UTC. Host `b7210db3f53361987fd33592de438fd7984d991a`, Native `29080ef8cd1a5b385eeeec97976fbefd31280427`.

Dieser Bericht ist eine reine Leseprüfung der 17 im JSON einzeln mit SHA256/Gitblob gebundenen Quellen. Es wurden keine Gerätewerte gemessen, keine lokalen Tests ausgeführt und keine Produktdateien verändert.

## Tatsächlicher Bestand

- `tools/android_qa/fold_device_capture.py` bindet ein explizites Gerät, die installierte monolithische ARM64-APK und den Native-PCK vor/nach der lesenden Sammlung. CPU-Zähler, Native-PSS/optionales RSS, Host-Meminfo, Display-/Fenster-/Eingabe-, thermische und Surface-Rohdaten sind vorhanden.
- Native-FPS, GPU-Framezeit und Touchlatenz bleiben ausdrücklich `NOT_MEASURED/null`. HWUI und SurfaceFlinger werden nicht in Godot- oder Flutter-FPS umgerechnet. Nicht lesbare Quellen bleiben fehlend. Der Standard `--expected-api 37` belegt keine tatsächliche Fold7-OS-Version.
- `runtime_resource_evidence.py` liefert ausschließlich gebundene Emulator-CPU-/Speicherstichproben. `kart_complete_android_probe.py` verlangt diese in den Phasen `first-driving` und `completed-before-fold`. Der Root-Emulatorpfad ist vom gewöhnlichen UID2000-Fold-Sammler getrennt.
- `scripts/tests/kart_showcase.gd` protokolliert Desktop-Loopzeiten p50/p95 und letzte Drawcall-/Objektzähler, arbeitet aber mit deaktivierter Livephysik und Demonstrationszuständen. `creative_objects_capture.gd` ergänzt Desktop-Objekt-/Primitivzähler.
- `scripts/tests/lumo_animation_cpu_benchmark.gd` misst manuelle AnimationPlayer-/Knochen-/IK-CPUabschnitte und eine statische Speicherstichprobe, ausdrücklich ohne GPU-Skinning/Draw/volle App.
- `PerformanceManager` wählt Plattformstandard oder gespeichertes low/medium/high und wendet die Einstellung bei Szenenwechsel an. Die geprüften Qualitätsquellen enthalten keinen Framezeit-/Temperaturregelkreis. `LumoQuality` kennzeichnet Fold7-Budgets ausdrücklich als ungemessen.

## Noch physisch offen

Die tatsächliche finale ARM64-APK muss auf dem echten Fold7 bytegebunden beobachtet werden. Es fehlen die eindeutige Godot-/Flutter-Surface-Zuordnung, synchronisierte Frameauslieferung/CPU-GPU-Zeiten und Fristverletzungen, Dauerlast mit thermischer Entwicklung und Speichertrend, reale Eingabelatenz sowie Innen-/Außendisplay-/Querformatübergänge. Emulator- oder Film-Bildraten ersetzen diese Messungen nicht. Keine neue Instrumentierung wird durch diesen Befund eingeführt.

Die genaue Quellenbindung, Einzelgrenzen und URLs stehen in `review.json`. Dies ist kein umfassender Audit aller Repositorydateien und keine Geräte-/Releasefreigabe.
