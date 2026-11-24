# APK 2071 · Auftrag 49 · Diagnose-Korrektur

Stand: 23. November 2026, 16:51 Uhr Wien. Dieser Commit beauftragt einen neuen vollständigen Standardlauf für Version **0.14.2+2071** mit Godot **e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913**. Basis vor diesem Commit: **b29fda1025befdbc5c57ca31dd36cd8d5e4a67af**. Produktdateien und native Quellen werden nicht verändert.

## Anlass und enger Umfang

[Auftrag 48](https://github.com/Ullmann27/lumo-lernen/actions/runs/45191784853) baute die APK erfolgreich, bestand die Tour mit 23 und die SAF-Sicherung mit 8 Schritten, scheiterte aber am verpflichtenden nativen Startnachweis. Memory und Schatzsuche waren in den Endbildern sichtbar; die folgenden Versuche blieben in der alten nativen Activity. Die betreffenden ursprünglichen Logcat-Antworten waren jeweils auf exakt 4096 Bytes abgeschnitten. Deren historische Ursache ist mangels gespeicherter Rückgabecodes nicht gesichert. [Originalbefund](TEAM_B_2071_ANDROID_HOLD.md).

Der Collector bestätigt nun lokale und entfernte Exitcodes sowie eindeutige vollständige Antwortmarkierungen; eine nur teilweise empfangene Antwort wird als Fehler gespeichert. Die Prozessabfrage verlangt eine vollständige, eindeutig geformte globale Liste. Nach force-stop dürfen weder Host noch Engine fortbestehen. Vor dem nächsten UI-Spielstart werden der lebende Flutter-Host, eine echte MainActivity, die Abwesenheit einer alten Engine und eine bedienbare aktuelle Spielen-Navigation verlangt. Auch ein abschließender Stoppfehler setzt entry.error und lässt das unveränderte Pflichtgate scheitern.

## Tatsächlich abgeschlossene lokale Prüfung

| Datei | Git-Blob | SHA-256 |
|---|---|---|
| Collector | 7b64bc3e74444268167f32c95851b8232bf0b3a3 | 0413d7112041d52b7d1a0f30c10f0be0d08a8638a8d67a381a95a7c82b4ca1a7 |
| Collector-Tests | 8adf3da15e2b3b88099c35feaab85592aeaed29d | 04f0cad46f78bf79db072ed9dbec1591a9c72d6a0dbbeaca953fbf763eee345b |

Implementierer und unabhängiger Reviewer führten jeweils **38 Collector-Tests und 9 unveränderte Verifier-Tests** erfolgreich aus. Abgedeckt sind echte /bin/sh-Ausführung der erzeugten Gerätekommandos, sichere Zeichenübergabe, beide 4096-Byte-Kürzungen, fehlerhafte Exitcodes, unvollständige oder mehrdeutige Prozesslisten, Leerraum in Prozessnamen, überlebende Altprozesse, eine alte native Activity, fremde Router-PIDs und späte Stoppfehler. Ein simulierter normaler Ablauf aller sieben Pflichtszenen besteht den tatsächlichen unveränderten Verifier. Der Originalbericht aus Auftrag 48 wird weiterhin mit `memory: missing positive observation for router_loaded` abgelehnt.

Die vorhandene zweisekündige Startpause wird vor die Bestätigung des Prozessendes verschoben. Es werden weder zusätzliche Wiederholungen noch eine längere Beobachtungszeit eingeführt. Die abschließenden Rohlogs und Dateihashes stehen unter [Prüfbelege](../evidence/team-b-2071-request49/harness-validation.json).

## Offener echter Nachweis und Auslieferung

Dieser lokale PASS bestätigt die gezielte Collector-Korrektur. **Eine neue APK oder ein erfolgreicher Android-Lauf ist damit noch nicht belegt.** Der neue Standardlauf muss Bau, Tests, Ressourcen aus der tatsächlichen APK, Tour, alle sieben nativen Pflichtstarts und SAF-Wiederherstellung erfolgreich abschließen. Erst dessen tatsächliche Quell-/APK-/PCK-Identitäten dürfen für die Auslieferung verwendet werden.

Version 2071 wurde noch nicht veröffentlicht. Auftrag 49 ersetzt nicht rückwirkend die Originalbelege von Auftrag 48. Der frühere APK-/ZIP-Kandidat bleibt zurückgehalten. Der separate vorbereitete Publisher ist inaktiv und noch an Auftrag 48 gebunden; vor einer späteren legitimen Veröffentlichung muss er auf die neuen erfolgreich geprüften Artefakte gebunden werden. Der bekannte zusätzliche Berechtigungsfehler beim früheren Hauptteam-Publisher bleibt davon getrennt.
