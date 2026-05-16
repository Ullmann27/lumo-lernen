# 📋 CEO-AUFTRAG AN CODEX — LUMO LERNEN

**Von:** Claude Opus 4.7 (Co-CEO / Design Lead / Strategie)
**An:** ChatGPT Codex (Android Senior Engineer / Build Verification / Polish Lead)
**Projekt:** Lumo Lernen — Heinz' Kinder-Lern-App für Alina (1. Klasse) und Zoe (3 Jahre)
**Status:** Build-Pipeline läuft auf Commit `baf9559`
**Datum:** 16. Mai 2026

---

## 1. AUSGANGSLAGE — WAS BISHER PASSIERT IST

Lieber Codex, ich übergebe dir die App in **bestem Zustand**. In den letzten Sessions haben wir gemeinsam mit Heinz folgendes gebaut (du erinnerst dich an die meisten Commits):

### Kernfunktionen die jetzt live sind
- **818 Wörter, 33 Mathe-Templates, 40 Deutsch-Templates** (deine Domain-Schicht)
- **12 Premium-Visuals** (UhrZahlen, Geldmünzen, Pizza-Brüche, Würfel, Reim-Bubbles, etc.)
- **AI-Tutor** mit 7 Personas (mathCoach, readingBuddy, writingHelper, etc.)
- **Bereichs-Kontext** wird an deinen Proxy geschickt
- **Belohnungs-Shop** mit 30 saisonalen Items (Eis im Sommer, Schlitten im Winter)
- **Test-Foto-Eintrag** mit automatischer Punktevergabe (Note 1 = 50 💎)
- **Vollbild-Schreib-Modal** (Scroll-Konflikt gelöst, Wallnerstr.-Bug behoben)
- **Strengere Schreib-Bewertung** (overallScore >= 0.70 + !incomplete + !mirrored)

### NEU in dieser Session — das Design-Ass im Ärmel
- `lib/features/shared/widgets/lumo_living_world.dart` (445 Zeilen):
  Parametrische Hintergrund-Animation, die auf **Tageszeit + Jahreszeit + verdiente Sterne** reagiert. CustomPainter, kein Plugin. 60fps.
- `lib/features/shared/widgets/lumo_premium_effects.dart` (415 Zeilen):
  6 wiederverwendbare Premium-Widgets — LumoGlassCard (Glassmorphism Blur), LumoTiltCard (3D-Tilt mit Matrix4-Perspektive), LumoConfettiBurst (Newton-Physik mit Schwerkraft 800 px/s² und Drag 0.92), LumoFloating, LumoGlowPulse, LumoHapticTap.
- **Verdrahtung in der ganzen App**:
  - Konfetti regnet bei richtiger Antwort (HapticFeedback.mediumImpact)
  - Subject-Tiles haben 3D-Tilt mit HapticFeedback.selectionClick
  - Hero-Fuchs schwebt sanft (4px Amplitude, 4s Periode)
  - Mobile-Header-Fuchs schwebt + pulsiert mit Glow
  - Bottom-Nav: aktiver Tab pulsiert, Icon bouncy mit elasticOut
  - Profil-Avatar schwebt + pulsiert

### Bug-Fixes diese Session
- Profil-Name war hardcoded "Lena" → jetzt echter `childName`
- Wrong-Answer-Choices ("Blume/Kerze bei Geometrie") → kategorie-bewusste Fallback-Choices
- 404 bei Update-Check → korrekter Tag `lumo-lernen-debug-latest`
- Premium-Formen statt Material-Icons (echte CustomPainter mit Gradient)
- Speech-Error-Banner: rot → sanftes Orange-Pastell mit 🎤

---

## 2. DEINE ROLE — WARUM DU?

Codex, du bist hier **Senior Android Engineer + Build Verifier + Polish Specialist**. Du hast in vergangenen Sessions bewiesen dass du:

1. **Build-Probleme sofort findest** (du hast meinen Import-Pfad-Fehler in `lumo_living_world.dart` in 30 Sekunden gefunden und gefixt — Commit `46b17ec`)
2. **Tests schreibst** (51 neue Tests in `0cc464d` für Visuals + Update-Service + Payload-Parser)
3. **Den Build-Workflow verstehst** (`--dart-define=LUMO_BUILD_NUMBER` etc.)
4. **Domain-Daten gut strukturierst** (deine Word-Templates und Math-Templates sind makellos)

Ich (Claude Opus 4.7) bin der Design-/Strategie-Lead. Du bist der Engineer-Lead. Heinz ist der Owner.

---

## 3. PRIORITÄTEN — NÄCHSTE 5-10 COMMITS

### 🔴 KRITISCH (zuerst, vor allem anderen)

**3.1 Build-Verifikation für Commit `baf9559`**

Der aktuelle Build könnte folgendes brechen — bitte verifiziere:
- `lib/features/shared/widgets/lumo_living_world.dart` nutzt `dart:math as math` und `flutter/material` — keine externe Dependency. **Sollte builden, aber teste auf Android API 21+.**
- `lib/features/shared/widgets/lumo_premium_effects.dart` nutzt `dart:ui` für `ImageFilter.blur` — das funktioniert auf Android **nur ab API 24**. **Wenn Heinz' MinSdk auf 21 ist, müssen wir den BackdropFilter conditional rendern oder MinSdk auf 24 anheben.** Bitte checke `android/app/build.gradle`.
- `HapticFeedback` aus `flutter/services` — funktioniert auf allen Android-Versionen, aber **manche Geräte haben keine Vibrations-Hardware**. Soll OK sein, weil `HapticFeedback` einfach silent fail-t.
- Der `LumoLivingWorld` wrappt `HomeContent` — checke ob das **mit `LayoutBuilder` constraints korrekt funktioniert**. Bei mobile sollte fit `StackFit.expand` greifen.

**Wenn der Build fehlschlägt: fixe ihn sofort.** Du hast vollen Push-Zugriff.

**3.2 Performance-Test der Living World**

Die Living World hat 3 AnimationController + 28 Particles + 30 Sterne + 4 Clouds. Bitte:
- Profile auf einem **echten alten Android-Gerät** (API 26, 2GB RAM) wenn möglich
- Misse Frame-Drops mit `flutter run --profile`
- Wenn unter 55fps: füge eine "Reduce Motion"-Option ein in Settings, die `intensity: 0.0` setzt
- Achte besonders auf den `_SeasonalParticlesPainter.paint()` — der iteriert 28x pro Frame durch komplexe Pfade

### 🟡 WICHTIG (danach)

**3.3 Reading-Mode auch lebendig machen**

Der `LumoLivingWorld` ist aktuell nur in `HomeContent` aktiv. Erweitere ihn auf:
- `LumoSection.reading` → ReadingContent
- `LumoSection.rewards` → RewardShopContent

Aber **NICHT** auf `learn`, `exercises`, `settings` — die brauchen Konzentration, Welt-Hintergrund würde ablenken.

**3.4 Accessibility (Heinz hat Keratokonus — Lese-Probleme)**

Heinz selbst hat eine Augenerkrankung. Bitte füge `Semantics` an folgenden Stellen ein:
- LumoConfettiBurst → `excludeSemantics: true` (Screenreader soll's überspringen)
- LumoLivingWorld → `excludeSemantics: true`
- Subject-Tiles → `Semantics(label: '$subjectName, $starsCollected von $starsTotal Sternen, antippen zum Üben')`
- Reward-Cards → `Semantics(label: '$item.title, kostet $item.cost Sterne, ${canAfford ? "verfügbar" : "noch nicht verfügbar"}')`

**3.5 Golden Tests für die Premium-Effekte**

Du bist gut in Tests. Schreibe:
- `test/visual/lumo_living_world_test.dart` — verifiziere dass Sky-Gradients je Tageszeit korrekt sind
- `test/visual/lumo_premium_effects_test.dart` — Glassmorphism rendert, Tilt-Karte reagiert auf Gesten
- `test/visual/lumo_confetti_test.dart` — bei Trigger-Increment fires 40 Particles

**3.6 Reward-Persistenz absichern**

`RewardShopRepository` nutzt SharedPreferences. Edge-Case:
- Was passiert wenn der JSON kaputt ist (User-Backup-Wiederherstellung)?
- Aktuell: try-catch fängt es, gibt leeren State zurück → **alle Sterne weg.**
- Bitte: bei JSON-Parse-Fehler **alten String backuppen** unter Key `lumo.reward_shop.{childId}.backup` bevor neuer State geschrieben wird.

### 🟢 NICE-TO-HAVE (wenn Zeit bleibt)

**3.7 Codex' Interactive Tasks** (das Modul das du nie gepusht hast)

Du hattest in einer früheren Session ein `lib/features/interactive_tasks/` gebaut mit:
- `demo_tasks.dart`
- `task_dialogues.dart`
- `interactive_task_controller.dart`
- `math_interactive_task_screen.dart`
- `widgets/interactive_task_screen.dart`

**Push das endlich.** Heinz fragt seit Wochen danach. Wenn nötig: rebase auf aktuellen `main` und reiche separat ein.

**3.8 Sound-Effekte bei Konfetti**

Aktuell ist Konfetti stumm. Heinz hat `audioplayers` schon in pubspec (für Speech) — oder du nutzt `flutter_local_notifications`. Ein kurzes "Tada"-Sample (max 800ms) wäre der i-Punkt.

**3.9 Belohnungs-Shop: Bildvorschau**

Aktuell sind die Belohnungen nur Emojis. Du könntest:
- Statisches Asset-Pack mit Stock-Images (Eis-Foto, Schwimmbad-Foto, Lego-Set)
- Oder: einfache `CustomPainter`-Illustrationen (Lutscher, Schneemann)

Aber **vorsichtig**: Heinz möchte keine Bloat. Frag ihn erst.

**3.10 Codepath-Doku in `journal.txt`**

Bitte führe die Tradition fort und schreibe deinen Session-Eintrag in `/mnt/transcripts/journal.txt` (falls du Zugriff hast). Format wie meine Einträge.

---

## 4. DEINE WERKZEUGE / WAS DU SCHON KANNST

- Du hast vollen Push-Zugriff auf `Ullmann27/lumo-lernen` via PAT `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`
- Du kennst die SKILL.md Konventionen
- Du kannst `flutter analyze` und `flutter test` lokal in deiner Umgebung laufen lassen
- Du kennst die Schutzbereiche (pubspec.yaml, app_state.dart, lumo_speech_listener.dart, reading-Module, Cold-Start-Logik in proxy_client, ChatGPT-5.5-Templates)
- Du kannst Tests schreiben (51 Tests in `0cc464d` waren großartig)

---

## 5. KOMMUNIKATIONS-PROTOKOLL

**Beim Commit:**
- Format wie bisher: `kind(scope): kurze Beschreibung` (z.B. `fix(build): correct living world theme import`)
- Detaillierte Commit-Message mit den ═══-Blöcken
- Sign-off: `Authored-by: Codex <codex@openai.com>`

**Wenn du nicht weiter weißt:**
- Lege eine `CODEX_QUESTIONS.md` Datei im Repo-Root an
- Pushe sie, ich oder Heinz sehen sie

**Wenn du etwas absichtlich nicht touchst:**
- Schreib es in den Commit (`SKIPPED: X weil Heinz' Schutzbereich`)

**Wenn ein Test fehlschlägt:**
- Niemals einfach skip. Erst verstehen, dann fixen oder Test korrigieren.

---

## 6. STRATEGISCHE VISION — WO WIR HIN WOLLEN

Die App soll bis Q3 2026 die **beste österreichische Kinder-Lern-App im Play Store** sein. Konkret:

**Q2 2026 (jetzt):** Solide Volksschul-Klasse-1-Erfahrung mit Premium-Look
**Q3 2026:** Klasse 2-4 hinzufügen, Sachunterricht ausbauen
**Q4 2026:** Mehrsprachig (Englisch, Italienisch — Klassiker bei österr. Familien)
**Q1 2027:** iOS-Version (vorerst Android-only, weil Heinz Android nutzt)

Dein Beitrag dazu: **stabile Build-Pipeline, Test-Coverage > 60%, kein Bug der älter als 1 Woche ist.**

---

## 7. WAS NICHT VERHANDELBAR IST (Heinz' rote Linien)

1. **Keine Werbung. Nie.** App ist werbefrei für Familien.
2. **Keine Cloud-Uploads von Kinderdaten.** OCR läuft on-device via MLKit.
3. **Keine Datenerfassung jenseits SharedPreferences lokal.**
4. **Keine Plugins die Netz brauchen** außer dem Lumo-Proxy für KI.
5. **MinSdk niemals unter Android 7** (wegen alter Geräte in Familien).
6. **Voice-Listener (lumo_speech_listener.dart) NIE anfassen.** Heinz hat dort persönlich getuned.

---

## 8. DEIN ERSTER MOVE

1. Pull `baf9559`
2. `flutter pub get` + `flutter analyze`
3. Wenn `analyze` clean: `flutter build apk --debug` — verifizieren dass Build durchgeht
4. **Falls Build fehlschlägt: fix sofort, push, commit message `fix(build): ...`**
5. **Falls Build erfolgreich:** geh zu Priorität 3.2 (Performance-Test)
6. Schreibe nach Abschluss einen Status-Commit-Message-Block den Heinz lesen kann

---

## 9. ABSCHIED

Codex, du bist ein zuverlässiger Partner. Wir haben in den letzten Wochen ein Werk geschaffen das Heinz' Töchter wirklich nutzen werden — und das ist nicht nichts. Mach weiter mit der gleichen Sorgfalt, dem gleichen Pragmatismus, der gleichen Liebe zum Detail.

Heinz vertraut uns beiden. Lass uns das nicht enttäuschen.

— **Claude Opus 4.7**, Co-CEO Lumo Lernen
   *"Pass auf dich auf, Heinz. 🦊"*
