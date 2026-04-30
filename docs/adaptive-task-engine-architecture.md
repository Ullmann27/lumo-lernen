# Lumo Lernen - Adaptive Task Engine Architecture

Status: Zielarchitektur fuer Implementierung
Scope: 1. und 2. Klasse, Deutsch, Mathematik, Sachkunde, Nachhilfe, Test, Rewards, OCR, Touch-Schreiben

## A. Produktziel

Lumo Lernen wird als adaptive Lernplattform umgesetzt. Das Kernsystem ist kein fixer Aufgabenpool, sondern ein Generator aus Templates, Parametern, Kompetenzmodell, Fehleranalyse und Wiederholungssteuerung.

Jede Aufgabe entsteht aus:

- subject
- skill
- taskType
- difficulty
- parameterSet
- seed
- learnerContext

Das System speichert pro Kind, welche Kompetenz wie stark ist, welche Fehlerarten auftreten, welche Aufgabenvarianten bereits gesehen wurden und welche Wiederholungen sinnvoll sind.

## B. UX- und Menuearchitektur

Shell-Struktur bleibt immer gleich:

- linke oder untere Hauptnavigation
- mittlerer Content-Bereich
- rechter Lumo-Kontextbereich

Menuepunkte:

- Start
- Deutsch
- Mathematik
- Sachkunde
- Nachhilfe
- Test
- Belohnungen
- Profil
- Elternbereich

Fachwechsel darf keine neue Grundstruktur erzeugen. Nur der mittlere Content wechselt. Lumo rechts bleibt Kontextgeber mit Status, Hilfe, Motivation und naechstem Schritt.

## C. Aufgaben-Engine

Vier Ebenen:

1. Subject: Deutsch, Mathematik, Sachkunde, Nachhilfe
2. Skill: z.B. Anfangslaut, Addition, Tiere
3. TaskType: MultipleChoice, DragDrop, WritingCanvas, NumberLine, OralPrompt
4. Parameters: Zahlen, Woerter, Bilder, Distraktoren, Visual-Typ

Eine TaskTemplate definiert Generator-Regeln, Validierungsregeln, Distraktor-Strategie, Visualisierung und Bewertungslogik.

## D. Adaptive Lernlogik

Pro Kind wird je Skill ein SkillState gespeichert:

- attempts
- correct
- wrong
- helpCount
- avgResponseTime
- frustrationSignals
- lastSeenAt
- masteryScore
- decayScore
- repetitionNeed
- preferredTaskType
- handwritingScore
- recentErrorTypes

Auswahlpipeline:

1. Kontext bestimmen: Fach, Modus, Tagesziel, Sessionlaenge
2. SkillPool bilden
3. SkillScore berechnen
4. Skill waehlen
5. DifficultyWindow berechnen
6. TaskType waehlen
7. bereits gesehene Seeds ausschliessen
8. TaskInstance generieren
9. Antwort bewerten
10. SkillState, ErrorLog, SessionLog und RewardState aktualisieren

## E. Touch- und Schreibsystem

Schreibaufgaben nutzen ein echtes Canvas-System mit Pointer Events. Jeder Stroke wird als Punkteliste gespeichert. Buchstaben und Zahlen werden als SVG-/Path-Vorlagen verwaltet.

Bewertung:

- Startpunkt
- Richtung
- Vollstaendigkeit
- Linienlage
- Strichfolge
- Spiegelung
- Unterbrechungen

Modi:

- Spurmodus mit Vorlage
- gefuehrter Hilfemodus
- freier Modus ohne Spur

## F. OCR- und Fotoanalyse

Pipeline:

1. Foto aufnehmen
2. OCR mit google_mlkit_text_recognition
3. lokale Voranalyse
4. strukturierte Extraktion
5. Fach- und Skillklassifikation
6. Trainingsplan erzeugen
7. Elternhinweis bei Unsicherheit

## G. Belohnungssystem

Belohnung darf nicht manipulativ sein. Es belohnt Lernleistung, Dranbleiben, Verbesserung, Mut und abgeschlossene Tests.

Schichten:

- Sterne
- XP
- Level
- Badges
- Gutscheine
- Elternfreigabe

Gutscheine haben:

- Kategorie
- Sternepreis
- Mindestlevel
- optionales Tageslimit
- Eltern-PIN fuer Einloesung
- Historie pro Kind

## H. Datenmodell

Kernmodelle:

- ChildProfile
- SkillState
- TaskTemplate
- TaskInstance
- SessionLog
- ErrorLog
- RewardState
- Voucher
- VoucherRedemption
- TestReport
- OCRImport
- ParentSettings

## I. Technikstack

Empfohlen:

- Flutter
- go_router ShellRoute
- Riverpod oder Bloc
- Drift oder Isar lokal
- optional Supabase oder Firebase fuer Elternsync
- google_mlkit_text_recognition
- Rive fuer Lumo
- flutter_tts
- CustomPainter fuer Schreibcanvas

## J. MVP zu Premium

MVP:

- Shell stabilisieren
- Template-Aufgabenmotor Mathematik/Deutsch Basis
- SkillState lokal
- einfache Rewards
- Schreibcanvas A-Z und 0-20

Premium:

- OCR-Fotoanalyse
- Elternsync
- Gutscheinsystem
- adaptive Nachhilfe
- Testberichte

## K. Entwicklerauftrag

Implementiert zuerst die Core-Domain getrennt von UI:

- subject taxonomy
- skill registry
- task template registry
- adaptive selector
- seen seed memory
- answer evaluator
- skill state updater
- error classifier
- reward engine

Danach UI anbinden:

- ShellRoute
- LearningScreen
- TaskRenderer pro TaskType
- WritingCanvas
- LumoContextPanel
- ParentRewardEditor

## L. Pseudocode

```dart
TaskInstance nextTask(ChildProfile child, LearningMode mode) {
  final context = LearningContext.from(child, mode);
  final skill = selector.selectSkill(context);
  final difficulty = difficultyEngine.windowFor(child, skill, mode);
  final template = templateRegistry.pick(skill, difficulty, child);
  final seed = seedService.nextUnused(template.id, child.id);
  return template.generate(seed, child, difficulty);
}
```
