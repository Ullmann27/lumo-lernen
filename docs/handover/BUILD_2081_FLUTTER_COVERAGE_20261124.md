# Build 2081: Flutter-Integration und Quellabgleich

Prüfung am 24.11.2026. Basis ist `a0fdd4031ba9a5637d9b943729a5f0df794071bc` (2080), dieser Teilzweig enthält zusätzlich `97ac9c19a8573f8d201d4cd14735610c22062337` (adaptive Nachhilfe, PR 551). Die endgültige gemeinsame APK, ihr Godot-Pin und ihre Android-Abnahme liegen beim Integrationszweig. Dieses Dokument bestätigt keine fertige APK.

## Tatsächlich neue Lernfunktionen

PR 551 ergänzt den strikten, lösungsgeprüften Ganzzahlparser, genauer begrenzte Übertrags-/Entbündelungshinweise und die freiwillige interaktive Zehnerwerkstatt für Plus/Minus bis 100. Die Originalaufgabe bleibt offen und besitzt weiterhin Antwortprüfung und Lernfortschritt. Keine neue Profil-, Belohnungs- oder Sprachpipeline. Der vollständige Diff gegenüber der Basis enthält 11 Dateien (+605/-108).

Quelle: https://github.com/Ullmann27/lumo-lernen/pull/551

## Bereits funktional enthaltene Entwicklung

Ein fehlender Merge in der Commit-Historie bedeutet hier nicht, dass die Funktion fehlt. Der Vergleich der tatsächlichen Dateien und `git cherry` korrigiert die frühere pauschale Einstufung der Sprach-/3D-Zweige als nicht integriert:

| Quelle | Nachweis im 2080-Quellstand | Entscheidung |
|---|---|---|
| `agent/sprache` @ `42bbb2fa74ebd941b44964954c24428b141602aa` | Alle fünf Commits werden von `git cherry a0fdd403 <head>` mit `-` als patchgleich erkannt. Der Conversation Controller ist bytegleich. Intent-Erkennung und Tests enthalten zusätzlich spätere Reparaturen. | Vorhandene Weiterentwicklung erhalten; kein Zurücksetzen auf den alten Zweig. |
| `agent/tutor3d` @ `9b49a2d65b898230acac80a70e54928f0f351555` | Beide Commits patchgleich vorhanden. `boundToTask`, 3D-Einstieg, strikte Tutor-Rückgabe und Rückkehr zur Originalaufgabe sind vorhanden. Aktueller Launcher ergänzt unter anderem World-Verträge. | Vorhandene Implementierung erhalten. |
| PR 530, `lumo-2040/tutor-20261117` @ `58549eae43da85226e38e821e028b5b8e1d698f3` | `lumo_nachhilfe.dart` und dessen Kerntest sind bytegleich. Der aktuelle Screen entfernt das alte deaktivierende WIP-Flag und ergänzt die 3D-Rückkehr. | Alte WIP-Einstiegssperre nicht wieder einführen; ältere Konzeptdateien bleiben in ihrem Ursprungszweig nachlesbar. |
| `feature/logic-world-20261123` und `support/logic-world-team-b-20261123` | Beide Heads sind Vorfahren der Basis; GitHub-Vergleich: jeweils 0 vorausgehende Commits. | Bereits enthalten. |
| `integration/lumo-world-cards-20261123` | Drei abweichende Commits betreffen ausschließlich Android-Tour und zwei Python-Testdateien. Keine fehlende Flutter-Produktdatei. | QA-Abgleich beim Integrator. |
| `grok/schule-*`, `delivery/lumo-schule-demo-20261124`, `audit/lumo-help-scope-20261124`, `lumo-hauptbot/lernen-modernisierung-20261124`, `lumo-hauptbot/lernen-phase-b-20261124`, `lumo-hauptbot/schule-ci-fix-20261124` | Alle aktuellen Heads dieser 24.11.-Zweige sind Vorfahren der Basis. | Keine Doppelübernahme oder Rücknahme neuerer Funktionen. |

Der Holo-Design-Zweig ist historisch enthalten, sein Design wurde danach auf Wunsch des Nutzers zurückgenommen. Die Integration setzt diesen ausdrücklich zurückgenommenen Stil nicht wieder ein.

## Geretteter lokaler Schachstand

Der verfügbare ältere Workspace `/workspace/scratch/2c007901863c/lumo-lernen` steht auf `1664993` (2048-Arbeitszweig). Er enthält 16 modifizierte Dateien und eine zusätzliche WebP-Datei. Vor jedem Abgleich wurden Original-Diff und alle 17 Dateiinhalte mit SHA-256 separat gesichert; der Workspace blieb unverändert.

**Alle 17 Dateien stimmen bytegenau mit dem bereits gesicherten Remote-Zweig `delivery/lumo-schach-2048-20261118` überein.** Dieser konkrete lokale Stand ist deshalb kein verlorener, nur lokal vorhandener Funktionsblock. Die zuvor erwähnten ungefähr 450 lokalen Hauptbot-Änderungen konnten an diesen beiden verfügbaren Flutter-Workspaces nicht bestätigt werden. Eine Wiederherstellung anderer, nicht vorhandener Workspaces wird nicht behauptet.

Die aktuelle Basis besitzt bereits den Schach-Einstieg, native Freigaben, Ergebnisannahme, Portal-Tests und das neuere `cover_chess.jpg`. Die alte WebP-Grafik, alte Versionsnummer und alte Godot-Revision werden nicht über die neueren Dateien geschrieben.

Zwei konkrete Teile des älteren Patches waren noch nicht übernommen und werden hier ergänzt:

- Der Schachknopf ruft wieder `_launchChess` auf. Dieser prüft unmittelbar vor dem Start die aktuelle Tagesmission und Profilgeneration über `_allowLaunch` und meldet den bestehenden `gameRequested`-Interaktionstyp. Der vorhandene native Start und seine Rückkehr bleiben bestehen.
- Der bestehende Ergebnis-Wiederholungstest enthält jetzt auch Schach: fünf gültige Ergebnisse ergeben einmalig 15 Sterne/120 XP, auch nach fehlgeschlagener Empfangsbestätigung.

Ein ergänzender Widget-Regressionstest ändert die Elternvorgabe nach dem Rendern des Schachportals und verlangt, dass der veraltete sichtbare Knopf keine native Szene mehr startet und die aktuelle Tagesmission lädt.

## Ausgeführte Prüfung und verbleibende Abnahme

- `git diff --check`: bestanden.
- Dart 3.12.2 / Flutter 3.44.9 lokal vorhanden. `dart format --output=none` konnte alle drei ergänzten Dart-Dateien parsen (Exit 0); fehlende lokal aufgelöste `flutter_lints` wurden als Paketauflösungswarnung gemeldet. Vorbestehende Formatierung wurde nicht pauschal umgeschrieben.
- PR-551-Lauf `45424664425`, Job `138553325984`: GitHub meldet Erfolg für vollständige Analyse, reale Szenen-/Profil-/Wiederherstellungsbelege und vollständige Flutter-Suite. Das ist die Abnahme des PR-551-Stands, nicht die Abnahme dieser zusätzlichen Schachänderung oder der endgültigen 2081-APK.
- Neue Schach-Widget-/Ergebnisprüfung und vollständige gemeinsame Flutter-/Android-Prüfung: **noch auszuführen**. Ein langsamer lokaler Dependency-Aufbau ist kein bestandener Test.

Für den gezielten gemeinsamen Flutter-Lauf:

```bash
flutter test --no-pub --reporter expanded \
  test/learning/adaptive_whole_arithmetic_test.dart \
  test/tutoring/guided_place_value_arithmetic_test.dart \
  test/tutoring/arithmetic_task_aid_test.dart \
  test/tutoring/lumo_nachhilfe_3d_test.dart \
  test/tutoring/lumo_nachhilfe_entry_test.dart \
  test/lumo_learning_dialogue_contract_test.dart \
  test/learning/core_conversation_route_test.dart \
  test/games/spielwelt_routing_test.dart \
  test/embedded_game_service_test.dart
```

Schreibtrainer, Journal, Profile, Paketkennung, Signaturschlüssel und Godot-Pin werden von diesem Teilpatch nicht verändert. Die vollständige Quellabnahme kann nur die tatsächlich zugänglichen und abgeglichenen Entwicklungsstände erfassen.
