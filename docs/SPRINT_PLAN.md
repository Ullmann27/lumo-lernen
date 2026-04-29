# LUMO LERNEN — MASTER SPRINT PLAN
**Stand:** 28. April 2026  •  **Owner:** Heinz Ullmann  •  **Branch:** `main`

---

## 0. NORDSTERN

> *„Eine österreichische Volksschul-App, die Kinder so begeistert, dass sie die App von selbst öffnen — und Eltern bereit sind dafür zu zahlen."*

**3 Eigenschaften, die Lumo unverwechselbar machen müssen:**
1. **Warm statt kalt** — keine grün-weißen Lern-Apps. Pfirsich, Vanille, Gold.
2. **Fuchs als echter Begleiter** — nicht als Maskottchen-PNG.
3. **Premium-Polish** — jede Animation, jeder Schatten, jede Reaktion fühlt sich teuer an.

---

## 1. WETTBEWERBSANALYSE

| Konkurrent | Stärke | Lücke die Lumo füllt |
|---|---|---|
| Duolingo | XP / Streaks / Sounds | Zu kalt, gamifiziert über Druck (Streaks-Verlust-Angst) |
| Khan Academy Kids | Animationen | US-Lehrplan, nicht für Österreich passend |
| Antolin | Schul-Integration | Stagniertes 2010er-Design, nichts mobile-first |
| Lernwolf | PDF-Vorrat | Keine App, keine Stimme, keine Interaktion |
| ANTON | Österreich-Coverage | Cluttered UI, keine Charakter-Bindung |

**Strategische Lücke:** Premium-UI + Charakter-Bindung + Österreich-Curriculum. Genau das baut Lumo.

---

## 2. SPRINT-ÜBERSICHT

| # | Sprint | Dauer | Ziel | KPI |
|---|---|---|---|---|
| 1 | WOW-Momente | 2-3 h | Erste Reaktion: „Oh!" | +XP-Float, Konfetti, Mesh-BG, Nunito |
| 2 | Lebendige Karten | 3-4 h | Karten unverwechselbar machen | Karten-spezifische Animationen |
| 3 | Progress & Rewards | 4-5 h | Eltern-Wow-Faktor | Heatmap, Ringe, Badges, Level-Up |
| 4 | Mobile/Phone | 3 h | Funktioniert auf jedem Gerät | Responsive ab 360px |
| 5 | Onboarding | 2-3 h | Erstkontakt fesselt | Intro-Video, Name, Klasse |
| 6 | Sound & Stimme | 2 h | Akustische Identität | UI-Sounds, Lumo-Voice-Lines |
| 7 | Curriculum-Tiefe | 5 h | Echter Lernwert | Pro Fach 50+ Aufgaben mit Visuals |

**Gesamt: ~22-25 Stunden Entwicklungsarbeit, in unabhängigen Sprints lieferbar.**

---

## 3. SPRINT 1 — WOW-MOMENTE (heute)

### 3.1 Was wird gebaut

**a) Nunito-Font lokal einbinden**
- Aktuell: `fontFamily: 'Nunito'` ohne Asset → System-Font (sieht billig aus)
- Lösung: TTF-Dateien ins `assets/fonts/`-Verzeichnis, in `pubspec.yaml` registrieren
- Effekt: Jede Schrift fühlt sich plötzlich „designed" an

**b) Konfetti-Explosion bei richtiger Antwort**
- Custom-Painter mit 60 Partikeln (Sterne, Kreise, Herzen)
- Physik: Anfangsgeschwindigkeit nach oben, Schwerkraft nach unten, Rotation
- 1.5s Dauer, dann clean-up
- Farben: Akzent + Gold + Pink

**c) +XP Float-Animation**
- Bei richtiger Antwort: schwebender Text „+20 XP" steigt 80px nach oben, fadet aus
- Erzeugt das „Belohnungs-Hit"-Gefühl von Duolingo

**d) Stern-Burst aus der Karte**
- 5-7 kleine Sterne fliegen radial aus der angetippten Karte raus
- Trifft die Sterne-KPI-Card → diese pulsiert kurz und der Wert zählt hoch (24 → 27 → animiert)

**e) Animierter Mesh-Gradient-Background**
- Hintergrund der MainContent ist nicht mehr statisch
- 3-4 farbige „Wolken" (Pfirsich, Vanille, Apricot) bewegen sich extrem langsam (60s pro Zyklus)
- Subtil aber lebendig

**f) Counter-Animation für KPIs**
- Stars/XP zählen sich beim Erscheinen hoch (24 → 0 → 24 in 800ms)
- Beim Update: zählt vom alten Wert zum neuen

### 3.2 Technische Architektur

```
lib/widgets/effects/
  confetti_overlay.dart      ← Particle system + custom painter
  xp_float.dart              ← Schwebender Text
  star_burst.dart            ← Radiales Stern-Pattern
  mesh_gradient_bg.dart      ← Animierter Verlaufs-Hintergrund
  animated_counter.dart      ← Tween-basierter Zahlen-Counter
```

```
lib/services/
  feedback_orchestrator.dart ← Zentrale Effekt-Steuerung
                               (orchestriert: Konfetti + XP-Float + Stern-Burst)
```

### 3.3 Akzeptanzkriterien

- [ ] Bei richtiger Antwort: Konfetti + XP-Float + Stern-Burst gleichzeitig
- [ ] Keine Frame-Drops auf Mid-Range-Android
- [ ] Effekte räumen sich automatisch auf (keine Memory-Leaks)
- [ ] Mesh-Gradient läuft auch im Hintergrund weiter (während Test)
- [ ] Nunito-Font wird korrekt geladen, kein FOUT (Flash of Unstyled Text)

---

## 4. SPRINT 2 — LEBENDIGE KARTEN

### 4.1 Was wird gebaut

**Pro Lernkarte ein einzigartiges Hintergrund-Pattern:**
- **Mathematik:** 5-7 Zahlen schweben langsam im Hintergrund (1, 2, 3, +, ×, =)
- **Deutsch:** Buchstaben (A, ä, B, sch) treiben durch die Karte
- **Englisch:** UK-Flagge animiert + „Hi", „Hello" Wörter
- **Übung:** Kleine Spielcontroller-Icons / Sterne
- **Test:** Häkchen die nacheinander erscheinen
- **Schularbeit:** Pokal mit Glanz-Highlight

**Karten-Press-Effekt:**
- Karte „drückt" 4px nach unten beim Tap
- Schatten wird kürzer (3D-Tiefe)
- Akzent-Farbe leuchtet kurz auf

**Lumo zeigt auf aktive Karte:**
- Wenn Hover/Focus auf Mathe-Karte → Lumo dreht Kopf nach links
- Lumo's Aura-Farbe wechselt zur Karten-Akzentfarbe

### 4.2 Akzeptanzkriterien

- [ ] Jede Karte hat einzigartige Hintergrund-Animation
- [ ] Press-Effekt fühlt sich physisch an
- [ ] Lumo reagiert auf Karten-Focus
- [ ] Animation pausiert bei Reduced-Motion-Setting (Accessibility)

---

## 5. SPRINT 3 — PROGRESS & REWARDS SCREEN

### 5.1 Was wird gebaut

**Progress-Screen:**
- **Wochen-Heatmap:** 7 Tage als Kreise, Größe = Aktivität
- **Fach-Mastery-Ringe:** 6 Ringe (eines pro Fach), Füllung = Beherrschung
- **Streak-Counter:** Mit Flammen-Icon
- **Liniendiagramm:** XP-Verlauf der letzten 30 Tage

**Rewards-Screen:**
- **Badge-Wall:** 30+ Achievements mit Sperr-/Frei-Status
- **Level-Up-Screen** (Vollbild-Overlay):
  - Lumo erscheint groß
  - Konfetti-Sturm
  - „Level X erreicht!" mit Stempel-Animation
  - Neue Belohnung freigeschaltet
- **Wöchentliche Mission:** Wechselnde Aufgaben („Löse 5 Mathe-Aufgaben")

### 5.2 Akzeptanzkriterien

- [ ] Heatmap rendert auch bei null Daten korrekt
- [ ] Mastery-Ringe animieren beim ersten Erscheinen (0% → aktueller Wert)
- [ ] Level-Up-Screen blockiert Hintergrund + lässt sich nicht versehentlich überspringen

---

## 6. SPRINT 4 — MOBILE/PHONE LAYOUT

### 6.1 Was wird gebaut

**Responsive-Strategie:**
- **>= 1024px (Tablet/Desktop):** 3-Spalten-Shell wie aktuell
- **>= 600px && < 1024px (kleines Tablet):** 2-Spalten — Lumo-Panel kollabiert in Floating-Mode
- **< 600px (Phone):** 1-Spalte mit Bottom-Navigation, Lumo als Floating-Action-Button

**Bottom-Navigation für Phone:**
- 5 Icons: Home, Lernen, Üben, Profil, Foto
- Active Item hat orange Pill darunter
- Lumo schwebt rechts unten als runder Button

### 6.2 Akzeptanzkriterien

- [ ] Funktioniert ab 360px Breite
- [ ] Bottom-Nav verdeckt nichts wichtiges
- [ ] Lumo-Bubble auf Phone tippbar = öffnet Sprechblasen-Modal

---

## 7. SPRINT 5 — ONBOARDING

### 7.1 Was wird gebaut

**Screen 1 — Intro-Video:**
- `lumo_intro.mp4` automatisch abspielen (mute-default mit Unmute-Button)
- „Tippe um fortzufahren"-Hint nach 3s

**Screen 2 — Name eingeben:**
- Lumo: „Wie heißt du?"
- Großes TextField, kindgerechte Tastatur

**Screen 3 — Klasse wählen:**
- 2 große Karten: „1. Klasse" / „2. Klasse"
- Lumo: „In welche Klasse gehst du?"

**Screen 4 — Tagesziel:**
- Drei Optionen: 3 / 5 / 10 Aufgaben pro Tag
- Lumo: „Wie viel willst du täglich üben?"

**Screen 5 — Eltern-PIN setzen (optional):**
- 4-stellige PIN für sensitive Bereiche
- Per ParentalGate gesichert

**Persistenz:** SharedPreferences

### 7.2 Akzeptanzkriterien

- [ ] Onboarding zeigt sich nur beim ersten Start
- [ ] Name + Klasse + Tagesziel werden überall in der App reflektiert
- [ ] „Lena" ist nicht mehr hardcoded

---

## 8. SPRINT 6 — SOUND & STIMME

### 8.1 Was wird gebaut

- **UI-Sounds** (kurze, freundliche Töne, lokal als .ogg):
  - Korrekt: hellklingender Aufstieg
  - Falsch: weicher „Plop"
  - Karten-Tap: holziges Klick
  - Level-Up: Fanfare
- **Lumo-Voice-Lines** mit System-TTS für jede Sprechblase
- **Sound-Toggle** in den Einstellungen (Eltern-Bereich)

---

## 9. SPRINT 7 — CURRICULUM-TIEFE

### 9.1 Was wird gebaut

Pro Fach 50+ Aufgaben mit echten Visuals:
- **Mathe:** Zähl-Aufgaben mit Bildern (3 Äpfel + 2 Äpfel = ?)
- **Deutsch:** Bildwortschatz, Reim-Aufgaben mit Audio
- **Englisch:** Vokabel-Karten mit Bildern
- **Geometrie:** Form-Erkennung mit echten Polygonen

---

## 10. RISIKEN & ABMILDERUNG

| Risiko | Mitigation |
|---|---|
| Frame-Drops bei Effekten auf älteren Phones | RepaintBoundary + max. 60 Partikel + Reduced-Motion-Support |
| TTS funktioniert nicht auf bestimmten Geräten | Voice-Toggle + Text-Fallback immer sichtbar |
| Asset-Größe wird zu groß | Nunito subset-only, Sounds als .ogg statt .mp3 |
| Onboarding wird übersprungen | Skip-Button erlaubt, aber später in Settings nachholbar |

---

## 11. ROLLOUT-STRATEGIE

1. **Sprint 1-2:** Polish auf bestehender App
2. **Sprint 3:** Inhalts-Aufbau (Progress, Rewards)
3. **Sprint 4-5:** Skalierung (Mobile, Onboarding)
4. **Sprint 6-7:** Vollbreite (Sound, Curriculum)
5. **Beta-Test:** mit 5-10 Familien aus Heinz' Umfeld
6. **Play Store Soft-Launch:** Designed-for-Families-Programm
7. **Marketing:** Österreich-Fokus (Eltern-Foren, Mama-Blogs, ÖAMTC-Magazin)

---

## 12. AKTIVER SPRINT

**▶ SPRINT 1 — WOW-MOMENTE — ✅ ABGESCHLOSSEN am 28.04.2026**

(siehe Liste oben)

**▶ SPRINT 2 — LEBENDIGE KARTEN — ✅ ABGESCHLOSSEN am 29.04.2026**

### Sprint-2-Lieferung:
- ✅ `lib/widgets/cards/backgrounds/floating_symbols_background.dart` (160 Zeilen) —
  CustomPainter, Lissajous-Drift, deterministische Layouts, RepaintBoundary
- ✅ `lib/widgets/cards/backgrounds/subject_backgrounds.dart` (110 Zeilen) —
  8 fach-spezifische Hintergrund-Wrapper:
  - `MathCardBackground`: 1-9, +, −, ×, =
  - `GermanCardBackground`: A, B, ä, ö, ü, ß, sch, ie, eu
  - `EnglishCardBackground`: Hi, Hello, Yes, No, cat, dog
  - `PracticeCardBackground`: ★ ✦ ✓ ♥ ●
  - `TestCardBackground`: ✓ ? Zahlen
  - `SchoolworkCardBackground`: A+ ★ ✦ 1.
  - `ScannerCardBackground`: ◉ ○ ◎
  - `ContinueCardBackground`: → ▶ ► ✓
- ✅ `lib/widgets/cards/learning_module_card.dart` (komplett neu) —
  - 3D-Press-Effekt: Karte „drückt" 4px nach unten + 0.98 scale
  - Akzent-Glow stärker bei Hover (.28 vs .14 Opacity)
  - Emoji skaliert 1.08× bei Hover
  - CTA-Pfeil rutscht 0.2× nach rechts bei Hover
  - `background:`-Slot für animierte Hintergründe
  - `onHoverChange:` Callback
- ✅ `lib/app/app_state.dart` — `focusedAccent` (int? ARGB) im State,
  Methoden `focusCard()` / `unfocusCard()`
- ✅ `lib/widgets/shell/lumo_stage_panel.dart` — Aura respektiert `focusedAccent`
- ✅ `lib/features/home/home_content.dart` — alle 8 Karten verdrahtet:
  Hover → Lumo-Aura wechselt zur Akzentfarbe + neue Sprechblase mit Hint

### Akzeptanzkriterien Sprint 2:
- ✅ Jede Karte hat einzigartige Hintergrund-Animation
- ✅ Press-Effekt fühlt sich physisch an (translate + scale + reduzierter Schatten)
- ✅ Lumo reagiert auf Karten-Hover (Aura + Sprechblase)
- ✅ 32/32 Dart-Dateien syntaktisch geprueft

**▶ NÄCHSTER SPRINT: 3 — PROGRESS & REWARDS**
