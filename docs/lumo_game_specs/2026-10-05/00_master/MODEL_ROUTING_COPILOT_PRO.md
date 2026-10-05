# GitHub Copilot Pro — explizite Modell-Routen (kein Auto)

WICHTIG: Bei jeder Cloud-Agent-Sitzung das Modell im GitHub-Modellpicker explizit wählen. `Auto` ist für diese Aufgaben verboten. Modellnamen in Issue-Texten allein sind kein Nachweis.

## Empfohlene Pro-Lanes

### 1. GPT-5.3-Codex — primärer Agentic Implementer
Aufgabe: Codebase-Exploration, echte Implementierung, Refactorings, Tests, kleine sichere Commits. Besonders geeignet für agentische Softwareentwicklung.

### 2. Claude Sonnet 5.5 — Feature-Implementierung / Flutter / State
Aufgabe: klar abgegrenzte Features, UI-State-Verkabelung, Lern-/Persistenzlogik, kleinere bis mittlere Multistep-Aufgaben. Effizient mit wenigen Tool-Schritten.

### 3. MAI-Code-1.1-Flash — Visual QA
Aufgabe: Bilder/Technical Boards gegen echte Runtime-Screens vergleichen; read-only. Native Bildverständnis, schnelle Instruktionsbefolgung.

### 4. Gemini 3.8 Flash — Terminal-/Validation-Lane
Aufgabe: Builds, Tests, reproduzierbare Fehler, CI/CLI-Prüfungen, unabhängiges Gegenchecken. Stark bei terminalbasierten Coding-Aufgaben und Recovery.

### 5. Grok 4.7 — unabhängiger komplexer Review
Aufgabe: komplexe, mehrstufige Gegenprüfung von Architektur, Gameplay-Flows und Cross-Lane-Risiken. Standardmäßig read-only.

### 6. GPT-5.6 Luna — schnelle kleine UI-/Asset-Arbeiten
Aufgabe: kleine, klare Flutter-UI-/Asset-/Responsive-Schritte. Nicht für tiefes Architektur- oder 3D-Systemdesign.

## Nicht als Pro voraussetzen
Claude Opus 5.5, GPT-5.6 Sol, GPT-6 Astra und GPT-6 Sol sind nach aktuellem GitHub-Rollout nicht für Copilot Pro gedacht, sondern mindestens Pro+/Max bzw. Business/Enterprise. Sie können später in einer separaten Opus-/höheren Plan-Sitzung Restarbeit übernehmen.

## Regel
Kein Agent überschreibt fremde Claims. Implementer schreiben; Reviewer ändern keine Produktionsdateien. Jeder Agent meldet tatsächliches Modell/Session und SHA. Wenn GitHub die exakte Modellauswahl nicht bestätigt, `BLOCKED_MODEL_SELECTION` statt Arbeit starten.
