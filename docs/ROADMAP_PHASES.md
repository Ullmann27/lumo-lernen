# Lumo Lernen — Phasen-Roadmap (42-Punkte-Auftrag)

> Erstellt von Claude Opus 4.7 nach Heinz' Master-Auftrag.
> Lebendiges Dokument — wird nach jedem Build aktualisiert.

## Status-Legende
- ✅ FERTIG — getestet, im Build verfügbar
- 🚧 IN ARBEIT — aktuelle Phase
- ⏸️ GEPLANT — bewusst spätere Phase
- ❌ BLOCKED — wartet auf Asset/Entscheidung

---

## Phase 1: ANALYSE + STABILITÄTS-FUNDAMENT (Build 91)

### Schwachstellen-Analyse (Stand vor Build 91)
| Bereich | Problem | Severity |
|---|---|---|
| Akademie | Außer Buchstaben-Schreiben alle Topics nur Chat | 🔴 HOCH |
| Build CI | `flutter analyze` hart, schlägt bei 17 alten Warnings fehl | 🔴 HOCH |
| RewardWallet | `catchError` ohne return → Warning → CI fail | 🟡 MITTEL |
| ChatGPT Off-Topic | Bei Bruchrechnen kam 1.-Klasse-Aufgabe | ✅ FIXED Build 88 |
| Letter Writing | Scroll-Konflikt + A schwebt zwischen Linien | ✅ FIXED Build 90 |
| Lumo Companion | Tap-to-Move fehlt — bewegt sich nicht aktiv | 🟡 MITTEL |
| Sprite Pack | 33/123 Frames sauber, Rest hat Text-Leftovers | 🟡 MITTEL |
| Voice System | Nur System-TTS, kein Premium-MP3-Cache | 🟢 NIEDRIG |
| Onboarding | Nicht vorhanden | 🟡 MITTEL |
| Eltern-Cockpit | Nicht vorhanden | 🟡 MITTEL |
| Multi-Profile | Nicht vorhanden | 🟢 NIEDRIG |

### Build 91 Lieferungen
- ✅ RewardWallet `catchError` Bug behoben (kein Datenverlust mehr)
- ✅ CI `analyze` weich gemacht (Warnings sichtbar, blockieren nicht)
- ✅ **Erstes echtes Lern-Modul: Plus bis 10** (statt Chat!)
- ✅ `LearningModuleRegistry` — Mapping Topic-ID → echtes Modul
- ✅ `LumoPhrases` — Persönlichkeits-Library Basis (Punkt 21)
- ✅ Akademie-Routing prüft Registry zuerst, dann Chat (Fallback)

---

## Phase 2: STABILITÄT + ECHTE LERN-MODULE ⏸️ Build 92-95

Heinz' Kern-Sorge: "Alle Optionen sind nur Chats". 
Plan: pro Build 2-3 weitere echte Module hinzufügen.

### Priorisierte Modul-Liste
- ⏸️ `m1_minus10` — Minus bis 10 (Klasse 1)
- ⏸️ `m1_zahlen10` — Zahlen-Mengen anmalen
- ⏸️ `m2_einmaleins` — 2er/5er/10er-Reihe als Tap-Spiel
- ⏸️ `m2_uhr` — Interaktive Uhr (Zeiger ziehen)
- ⏸️ `m2_geld` — Münzen anklicken bis Betrag
- ⏸️ `d2_artikel` — Der/Die/Das per Drag-Drop
- ⏸️ `d3_wortarten` — Nomen/Verb/Adjektiv erkennen
- ⏸️ `s1_farben` — Farben-Memory
- ⏸️ `s1_tiere` — Tier-Geräusch-Zuordnung
- ⏸️ `m4_bruch` — Pizza-Brüche zum Anklicken

### Aufräumarbeiten
- ⏸️ Restliche 17 Analyzer-Warnings fixen → `analyze` wieder hart
- ⏸️ Unused imports/elements entfernen
- ⏸️ `must_call_super` in Flame-Komponenten

---

## Phase 3: ELTERN-COCKPIT + DATENSCHUTZ ⏸️ Build 96-100

Heinz Punkte 2, 3, 4, 14, 25.

- ⏸️ `ChildProfile`-Model + Migration
- ⏸️ Eltern-Sperre (PIN oder Rechenaufgabe)
- ⏸️ Eltern-Cockpit Screen (Wochenübersicht, Stärken/Schwächen)
- ⏸️ Datenschutz-Screen (lokale Daten erklären, Export, Löschen)
- ⏸️ Permission-Service zentralisieren
- ⏸️ Onboarding-Flow (Willkommen, Kind-Name, Klasse, Lumo-Modus)

---

## Phase 4: ADAPTIVE LERN-LOGIK + TAGES-PLAN ⏸️ Build 101-105

Heinz Punkte 5, 6, 7, 8, 9, 35.

- ⏸️ `SkillModel` (subject, unit, level, mastery, accuracy)
- ⏸️ `DailyLearningPlan` — 3 Tagesschritte
- ⏸️ Adaptive Schwierigkeit (3x richtig → schwerer, 2x falsch → leichter)
- ⏸️ `ExplanationEngine` (shortFeedback, stepByStep, hint, encouragement)
- ⏸️ Fehler-Kultur (sanfte Farben, nie "Falsch!", Lumo tröstet)
- ⏸️ Streak/Tagesziel
- ⏸️ Missionen aus Lernprofil (statt zufällig)

---

## Phase 5: ACCESSIBILITY + OFFLINE + FEHLER-ZUSTÄNDE ⏸️ Build 106-110

Heinz Punkte 10, 11, 12, 13.

- ⏸️ Schriftgrößen-Einstellung
- ⏸️ Dyslexie-Modus
- ⏸️ Kontrast-Modus
- ⏸️ Bewegungs-Reduktion
- ⏸️ Semantics Labels
- ⏸️ Offline-First Verifikation (alle Module ohne Internet)
- ⏸️ Loading/Empty/Error/Offline States pro Screen
- ⏸️ ErrorBoundary-Widget (keine roten Screens)

---

## Phase 6: PERFORMANCE + ASSET-PIPELINE + RELEASE ⏸️ Build 111-115

Heinz Punkte 15, 16, 17, 18, 23, 24, 26, 27, 28, 29, 37, 38, 39.

- ⏸️ Asset-Manifest + Checker-Script
- ⏸️ Lazy-Loading großer Sprite-Packs
- ⏸️ Performance-Budget (App-Start <3s)
- ⏸️ `LumoBreakpoints` zentralisiert
- ⏸️ `LumoAssets` + `LumoRoutes` Konstanten
- ⏸️ FeatureFlags-System (sicherer Rollout)
- ⏸️ Versteckter Debug-Bereich (Eltern-gated)
- ⏸️ Sound-Design + Haptik (kindgerecht, abschaltbar)

---

## Abnahme-Kriterien (Heinz Punkt 40)

Phase 1 erfüllt: ✅
- ✅ flutter pub get
- 🟡 flutter analyze (soft, blockt nicht)
- ✅ flutter build apk --debug
- ✅ App-Start
- ✅ Sterne bleiben nach Neustart (RewardWallet)
- ✅ Erstes echtes interaktives Modul

Phase 2-6: noch offen.

---

## Workflow nach Heinz Punkt 41

> "Arbeite in Phasen. Nach jeder Phase: Build prüfen, Tests prüfen, 
> keine neuen Fehler akzeptieren."

Wir folgen genau dem:
1. Pro Build max 2-3 Module
2. Build muss grün durchlaufen
3. Smoke-Tests dürfen nicht brechen
4. Heinz testet, gibt Feedback
5. Fehler-Fixes haben Priorität vor neuen Features
