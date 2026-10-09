# Profilidentität: abgegrenzte Korrektur und offene Isolation

Geprüfte Basis: [`ab21b2295ca5307bae5e07c0c8a01c3017ee91a3`](https://github.com/Ullmann27/lumo-lernen/commit/ab21b2295ca5307bae5e07c0c8a01c3017ee91a3), Quellstand von [PR #240 / APK 1918](https://github.com/Ullmann27/lumo-lernen/pull/240).

## Befund: verspätete Zuordnung eines Aufgabenprotokolls

`LumoAppState.recordLearningAnswer` lädt und speichert zuerst den Lernfortschritt.
Erst danach liest `_logAttempt` die aktive Schulkindkennung. Die Lehrkraft kann
das Gerät während dieser asynchronen Arbeit über
`TeacherStudentScreen` → `SchoolRepository.setActiveStudent` einem anderen
Kind zuordnen. Eine bereits angenommene Antwort von A kann dadurch im
Aufgabenprotokoll von B landen. Das ist ein aus dem Code abgeleiteter,
deterministisch prüfbarer Ablauf; kein Nachweis eines Vorfalls auf einem Gerät.

Quellen der Basis:

- [`app_state.dart`](https://github.com/Ullmann27/lumo-lernen/blob/ab21b2295ca5307bae5e07c0c8a01c3017ee91a3/lib/app/app_state.dart): `recordLearningAnswer`, `_logAttempt`.
- [`teacher_student_screen.dart`](https://github.com/Ullmann27/lumo-lernen/blob/ab21b2295ca5307bae5e07c0c8a01c3017ee91a3/lib/features/teacher/teacher_student_screen.dart): direkte Gerätezuordnung.
- [`school_repository.dart`](https://github.com/Ullmann27/lumo-lernen/blob/ab21b2295ca5307bae5e07c0c8a01c3017ee91a3/lib/core/school_repository.dart): aktiver Schüler unter `lumo_school_active_student_v1`.

Die abgegrenzte Korrektur erfasst die Kennung vor dem ersten Laden/Speichern
des Lernfortschritts und reicht sie unverändert an das Aufgabenprotokoll
weiter. Die nächste Antwort verwendet die dann aktuelle Kennung.
Bestehende Speicherformate, Schlüssel und die bisherige Zuordnung `self`
für nicht zugeordnete Geräte bleiben dabei erhalten.

Die Bindung beginnt am vorhandenen asynchronen Identitätsabruf in
`recordLearningAnswer`. Sie ersetzt keine synchron erfasste Profil-Lease
beim UI-Klick und bindet keine vorgelagerten Warteschlangen, etwa das
Wallet-Schreiben eines Lernmoduls. Dafür bleibt ein gemeinsamer
Profilwechselpfad erforderlich.

## Regression

`test/app_state_student_identity_test.dart` hält echte
`ProgressRepository`-Lade- und Speicheroperationen mit `Completer` an.
Währenddessen wird das Gerät von A auf B umgestellt. Die Tests verlangen:

1. Die angenommene Antwort bleibt A zugeordnet.
2. Der Fortschritt zählt diese Antwort genau einmal.
3. Die nächste Antwort wird B zugeordnet.
4. Ein neuer Protokoll-Repository-Aufruf liest beide Zuordnungen wieder.
5. Der bisherige Fall ohne Schulkindzuordnung behält `self`.

**Lokaler RED-Lauf: BLOCKED.** Der erste Aufruf
`flutter test test/app_state_student_identity_test.dart` konnte nicht starten,
weil keine Flutter-Laufzeit im Pfad vorhanden war (Exit 127). Beim folgenden
Bootstrap der projektspezifischen Flutter-Version blockierte die automatische
Freigabeprüfung einen unerwarteten Zugriff auf Cloud-Instanzmetadaten. Der
lokale Prozess wurde gestoppt; die Tests hatten noch nicht begonnen. Es wurde
kein lokaler Vorher-/Nachher-Erfolg festgestellt.

Der Nachweis soll in der vorhandenen GitHub-Actions-Umgebung erfolgen:
dieselbe Testdatei zunächst gegen `app_state.dart` aus der oben genannten
unveränderlichen Basis ausführen, die beiden falschen Studentenzuordnungen
als erwartete Fehler feststellen, danach die Kandidatendatei wiederherstellen
und alle drei Tests sowie die vorhandenen Speicher-/Schul-/Modultests
ausführen. Die Hashes der Testdatei vor und nach beiden Läufen müssen
übereinstimmen. Ausführungsnachweise und endgültiger Status sind vor
Abschluss zu ergänzen. `git diff --check` wurde lokal erfolgreich ausgeführt.

## Issue #233 bleibt offen

[#233](https://github.com/Ullmann27/lumo-lernen/issues/233) fordert vollständige
kindgetrennte Persistenz und verlustfreie Migration. Die einzelne Korrektur
des Aufgabenprotokolls erfüllt diese Anforderungen nicht vollständig.
Die folgenden Befunde gelten für die genannte Basis:

| Bereich | Noch offener Befund | Erforderlicher nächster Schritt |
| --- | --- | --- |
| Lernfortschritt | `ProgressRepository` nutzt drei globale Schlüssel. `LearningProfileEngine` besitzt keine Profilkennung. | Unveränderlich an eine stabile Kennung gebundene Repository-/Engine-Instanzen und getrennte Namensräume. |
| Profilwechsel | Die Gerätezuordnung informiert `LumoAppState` nicht; `_profileGeneration` steigt nur beim vollständigen Reset. | Ein gemeinsamer Wechselpfad mit Generation oder Lease, eindeutig zugeordneten offenen Schreibvorgängen und erneuertem UI-Zustand. |
| Kosmos | Globale Schlüssel, Singleton-Cache und Listener. `grantReward` wartet nicht auf das initiale Laden; `save` prüft das boolesche Schreibergebnis nicht. | Pro Kind gebundene Welt, Ladebarriere und geordnete Speicherung mit sichtbarem Fehler-/Wiederholungsverhalten. |
| Fehlende Kennung | `UserProfile` fällt auf `local` beziehungsweise einen Namens-Slug zurück; Aufgabenprotokolle verwenden `self`. Diese Werte sind nicht allgemein pro Kind eindeutig. | Einmalig erzeugte und erfolgreich gespeicherte lokale Profilkennung; gleiche Namen und Neustarts prüfen. |
| Vorhandene Daten | Alte globale Lern- und Kosmosdaten haben keine belegbare Eigentümerkennung. | Legacy-Daten unverändert sichern; erst bei eindeutiger Zuordnung oder Elternentscheidung einem Kind zuweisen. Keine automatische Kopie an mehrere Kinder. |
| Asynchroner Reset | Der vollständige Reset wartet auf Wallet-Schreiben, aber nicht auf alle Lern-Lade-/Schreibvorgänge. | Separate Regression für verspätetes Laden/Schreiben und Reset; keine Wiederherstellung alter Daten durch spätere Antworten. |

Auch der ältere [PR #180](https://github.com/Ullmann27/lumo-lernen/pull/180)
hat die geräteweiten Schlüssel nur dokumentiert; er änderte keine Produktdatei.
PR #234 und PR #240 weisen die Mehrkind-Isolation ausdrücklich als offen aus.

Vor einer aktivierten Migration sind getrennte A/B-Lernstände und Kosmosobjekte,
Neustart, schneller A→B→A-Wechsel, Schreibfehler mit Wiederanlauf und der
bewusste Umgang mit nicht zugeordneten Legacy-Daten nachzuweisen. Die
Elternabläufe und der reale Mehrprofil-Gerätetest bleiben eigene Abnahmepunkte.
Dieser Audit erteilt keine Migrations-, Main-Merge- oder Releasefreigabe.
