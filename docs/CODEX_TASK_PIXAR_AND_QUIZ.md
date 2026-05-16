# 🎯 CODEX MEGA-AUFTRAG — Pixar-Redesign + Wer-wird-Millionär-Modus

**Von:** Claude Opus 4.7 (Co-CEO / Design Lead)
**An:** ChatGPT Codex (Senior Engineer / Implementation Lead)
**Datum:** 16. Mai 2026
**Status:** Heinz hat Referenz-Bilder geliefert. Du bekommst Vollmacht für Implementation.
**Repo:** `Ullmann27/lumo-lernen`
**HEAD:** `bfc5720`

---

## ⚡ TL;DR — DAS HIER MUSST DU BAUEN

1. **Pixar-Look-Konvertierung** der bestehenden Screens (Hero-Header, Subject-Tiles, Daily-Mission, Result-Bubbles) — **EXAKT** wie in `docs/design_references/01_mathe_mit_lumo_target.png` und `03_deutsch_mit_lumo_target.png`
2. **WWM-für-Kinder-Modus** komplett: 15 Fragen, schwieriger werdend, Coupon-Belohnungen, garantierte Schwellen wie bei "Wer wird Millionär"
3. **6 neue KI-Features** in der App: Voice-Chat, Foto-zu-Aufgabe, adaptive Schwächen-Analyse, KI-Geschichten, Eltern-Tagesbericht, KI-WWM-Fragen
4. **Tests + Build-Stabilität** sicherstellen

---

## 📸 REFERENZ-BILDER (im Repo)

Heinz hat 4 Bilder ins Repo gelegt unter `docs/design_references/`:

| Datei | Was zeigt es |
|---|---|
| `01_mathe_mit_lumo_target.png` | **DAS** Ziel-Design für Mathe-Sektion. Hero + Sterne/Streak + Speech-Bubble + Level-Bar + Aufgaben-Karten + Tägliche Mission + Erfolgs-Bubble + Premium-CTA + Mobile-Nav |
| `02_pixar_scene_full.png` | Pixar-Atmosphäre: Mädchen am Schreibtisch, lila Hoodie-Fuchs zeigt mit Pfote nach oben, Sterne-Mobile, Bücher-Regal, warmes Licht. **DAS** ist die emotionale Stimmung. |
| `03_deutsch_mit_lumo_target.png` | Deutsch-Sektion: Hero + Daily Mission + Rocket-CTA + 2x2 Grid (Wörter lesen / Buchstaben finden / Reime / Satzbau) + Tagesabschluss-Bubble |
| `04_pixar_scene_portrait.png` | Portrait-Variante der Pixar-Szene für Mobile-Hero |

**Halte dich an die Farbcodes und Proportionen aus diesen Bildern.** Bei jedem Pixel-Entscheid: schaue zuerst aufs Bild.

### Extrahierte Farbcodes aus den Bildern:

```dart
// Pixar-Palette - exakt aus Referenz-Bildern destilliert
class PixarColors {
  // Hintergrund-Atmosphäre
  static const skyWarm = Color(0xFFFFF4E0);      // warmes Cremegelb
  static const skyPeach = Color(0xFFFFE8C8);     // Pfirsich
  static const skyMorning = Color(0xFFFFD9A8);   // morgendliche Wärme

  // Lumo (der Fuchs)
  static const foxOrange = Color(0xFFFF8C42);    // Hoodie-Fuchs Körper
  static const foxBelly = Color(0xFFFFE5D0);     // helle Bauchseite
  static const foxHoodie = Color(0xFF9747FF);    // lila Hoodie
  static const foxStar = Color(0xFFFFD700);      // gelber Stern auf Hoodie

  // Text-Akzente
  static const headlineDark = Color(0xFF3D2F26); // dunkelbraun "Mathe"
  static const headlineOrange = Color(0xFFFF7A2F); // "Lumo" akzent
  static const subtitleGray = Color(0xFF8B7355);  // "Rechnen macht Spaß!"

  // Karten-Surfaces (Pastell)
  static const tileYellow = Color(0xFFFFF4D9);   // Wörter lesen Karte
  static const tileGreen = Color(0xFFDFF5E3);    // Buchstaben finden
  static const tilePink = Color(0xFFFFE0EC);     // Reime erkennen
  static const tileBlue = Color(0xFFDCEEFF);     // Satz bilden

  // Buttons / CTAs
  static const ctaGradStart = Color(0xFFFFB347); // Pill-Button Start
  static const ctaGradEnd = Color(0xFFFF7A2F);   // Pill-Button Ende

  // Status-Feedback
  static const correctGreen = Color(0xFF6EE7B7); // grüner Check
  static const correctGreenDark = Color(0xFF10B981);
  static const wrongPeach = Color(0xFFFEC89A);

  // Mission / Streak
  static const streakFire = Color(0xFFFF5722);
  static const xpBlue = Color(0xFF4A9EFF);
  static const starGold = Color(0xFFFFB800);
}
```

---

## 📂 AUFGABE 1: PIXAR-REDESIGN DER BESTEHENDEN SCREENS

### 1.1 Neuer Hero-Header (`lib/features/shared/widgets/lumo_pixar_hero.dart`)

Erstelle eine **NEUE** Widget-Datei. Lass `lumo_hero_header.dart` in Ruhe (wird als Fallback gebraucht).

**Struktur** (exakt wie Bild 01):
```
┌─────────────────────────────────────────────────┐
│ [Fox-Avatar 64x64]  Hallo, Alina! 👋      │24⭐│
│                     Weiter so, du bist spitze!  │ 7🔥│
│                                                 │     │
│  Mathe                  [Mädchen-PNG]           │     │
│  mit Lumo               [Lumo-PNG mit Speech    │     │
│  Rechnen macht Spaß!     bubble darüber]        │     │
└─────────────────────────────────────────────────┘
```

**Konkrete Anforderungen:**
- Hintergrund: linearGradient `[PixarColors.skyWarm, PixarColors.skyPeach]` topLeft → bottomRight
- Border-Radius: 28
- Min-Höhe: 320 (Desktop) / 280 (Mobile)
- **Mädchen-Asset**: Falls noch nicht vorhanden, packe `docs/design_references/02_pixar_scene_full.png` als `assets/images/pixar_girl_lumo.png` (cropped auf die Mädchen+Fuchs-Region)
- **Speech-Bubble** rechts vom Fuchs (CustomPaint mit Spitze zum Fuchs zeigend)
- Headline "Mathe mit Lumo" mit "Mathe mit" in `PixarColors.headlineDark`, "Lumo" in `PixarColors.headlineOrange`
- Font: existing 'Nunito', fontSize 38 für Headline, fontWeight 900
- Sub-Headline mit oranger Akzent-Unterstreichung (CustomPaint Bogen drunter)
- **Top-Right Cards** (Sterne + Streak): zwei kleine weiße Karten 88x52 mit Schatten, Emoji links, Zahl groß rechts, Label klein drunter

**Bestehende Aufrufer migrieren:**
- `lib/features/sections/section_content.dart` Zeile 56-150 (case learn, case tests, case schoolwork) → ersetze `LumoHeroHeader(...)` durch `LumoPixarHero(...)`
- Behalte die alten Aufrufe von `LumoHeroHeader` **NUR** wenn `appState.state.settings.classicMode == true` ist (das ist ein neuer Settings-Flag, siehe 1.7)

### 1.2 Subject-Tiles im Pixar-Look (`lib/features/shared/widgets/lumo_pixar_tile.dart`)

**Struktur** (exakt wie Bild 03, das 2x2-Grid):
```
┌─────────────────────────────────────┐
│ [Icon]  Wörter lesen     [Illustration  │
│                          z.B. Buch+Stern]│
│ Lies die Wörter                          │
│ und sammle Sterne!                       │
│                                          │
│ Level 3   ⭐ 12 / 20                     │
└─────────────────────────────────────┘
```

**Anforderungen:**
- Höhe: 180-200
- Hintergrund: Pastell-Surface aus PixarColors (yellow/green/pink/blue je nach Modul)
- Border-Radius: 24
- Box-Shadow: weicher Schatten, `surface.withOpacity(0.3)` blur 20 offset(0,8)
- Icon-Badge oben links: 36x36 weißer Kreis mit Emoji
- Illustration rechts oben (40-60% der Karten-Höhe): Emoji-Stack ODER eigenes Asset
- Footer: Level-Pill links, Sterne-Zahl rechts
- **LumoTiltCard** drumrum (haben wir schon, siehe `lumo_premium_effects.dart`)
- **LumoHapticTap** mit `HapticStrength.light`

### 1.3 Daily Mission Card Pixar-Style (`lib/features/shared/widgets/lumo_pixar_mission.dart`)

**Struktur** (Bild 03 mittlerer Bereich):
```
┌──────────────────────────────────────────────┐
│ 🎯 Tägliche Mission       ┌──────┐ ┌────┐    │
│    3 Aufgaben abschließen │+10⭐│ │+50│    │
│    2/3 ███████████░░░     │ Sterne│ │XP │    │
│                           └──────┘ └────┘    │
└──────────────────────────────────────────────┘
```

- Hintergrund: weißlich `Color(0xFFFFFEFA)` mit subtilem Border
- Target-Emoji links als 40x40 Badge mit Orange-Glow
- Progress-Bar mit Orange-Gradient
- Reward-Pills rechts: gelb für Sterne, blau für XP

### 1.4 Rocket-CTA-Button (`lib/features/shared/widgets/lumo_rocket_cta.dart`)

**Struktur** (Bild 03 großer oranger Pill-Button):
```
┌────────────────────────────────────────────┐
│ ✨   🚀  Deutsch Aufgabe starten  >    ✨ │
└────────────────────────────────────────────┘
```

- Pill-Form (border-radius 99)
- Gradient: `[PixarColors.ctaGradStart, PixarColors.ctaGradEnd]`
- Höhe: 64
- Sparkles links + rechts (animiert, abwechselndes Pulsieren)
- Rocket-Emoji mit `LumoFloating` (subtle bobbing)
- Text "Aufgabe starten" mit fontSize 20, fontWeight 900, weiß
- Arrow-Icon rechts in einem kleinen weißen Circle
- Bei Tap: `HapticFeedback.mediumImpact()` + Skalierung 0.97
- **Glow-Pulse drumrum** mit Orange (nutze `LumoGlowPulse`)

### 1.5 Aufgabe-Karte im Mathe-Style (`lib/features/learning/widgets/pixar_question_card.dart`)

**Struktur** (Bild 01 untere Hälfte — die zwei Aufgaben):
```
┌─────────────────────────────────────────────────┐
│ [Aufgabe 1]  Wie viel ist 7 + 5?      [💡Tipp]│
│              Zähle mit und wähle die richtige  │
│                                                 │
│ ┌────────────┐    +    ┌────────────────┐     │
│ │ 🍎🍎🍎🍎  │         │  ⭐⭐⭐ ⭐⭐    │     │
│ │ 🍎🍎🍎    │         │                 │     │
│ └────────────┘         └────────────────┘     │
│                                                 │
│  ┌────┐  ┌────┐  ┌────┐✓ ┌────┐                │
│  │ 10 │  │ 11 │  │ 12 │  │ 13 │                │
│  └────┘  └────┘  └────┘  └────┘                │
└─────────────────────────────────────────────────┘
```

**Visuelle Hinweise**:
- "Aufgabe 1" als Pill oben links mit Orange-Gradient
- "💡 Tipp" als Pill oben rechts mit Lila-Gradient
- Zwei Mengen-Boxen mit dashed Border (`DottedBorder`-Paket NICHT verwenden — selbst zeichnen mit CustomPainter)
- Apfel-Emojis 32px, Stern-Emojis 32px (oder eigenes Asset)
- 4 Antwort-Buttons in einem Wrap, je 64-72px breit, 56px hoch
- Bei Auswahl: grüne Outline + grüner Check-Badge oben rechts am Button
- Bei richtiger Antwort: `LumoConfettiBurst` triggern (haben wir schon)

### 1.6 Result-Bubble "Super gemacht!" (`lib/features/learning/widgets/pixar_result_bubble.dart`)

**Struktur** (Bild 01 unten rechts):
```
┌──────────────────────────────────────────┐
│ [Fox holds trophy]    Super gemacht,     │
│                       Alina! 🎉          │
│                       Du bist ein        │
│                       Mathe-Star!        │
└──────────────────────────────────────────┘
```

- Fox-mit-Trophäe als Asset (`assets/images/fox_trophy.png` — falls nicht da, Fallback `🦊🏆` mit Layering)
- Sprechblasen-Text mit personalisierter Anrede (`appState.state.childName`)
- Stern-Burst-Animation auf rechter Seite
- Bei Erscheinen: `ScaleTransition` mit `Curves.elasticOut`
- Wird im `_ExplanationCard` (existiert schon in `learning_content.dart:1720`) als oberer Banner eingebaut

### 1.7 Settings-Flag für Classic-Mode

Damit niemand den alten Look komplett verliert, füge in `lib/core/app_settings.dart` einen neuen Flag hinzu:

```dart
// Pixar-Look statt Classic-Look. Default = true (Pixar)
final bool pixarMode;
```

In Settings-UI eine Toggle-Card hinzufügen ("Modernes Design", Default an).

### 1.8 Bottom-Nav Pixar-Style

Bild 01 + 03 zeigen Bottom-Nav: **Start, Lernen, Missionen, Belohnungen, Profil** (5 Items). Aktuell hat unser `_MobileBottomNavigation` 5 Items (Start, Lernen, Lesen, Missionen, Profil) — fast korrekt. Ersetze "Lesen" durch "Belohnungen" weil das im Referenzbild so ist:

```dart
static const _items = <_MobileNavItem>[
  _MobileNavItem(LumoSection.home, Icons.home_rounded, 'Start'),
  _MobileNavItem(LumoSection.learn, Icons.menu_book_rounded, 'Lernen'),
  _MobileNavItem(LumoSection.missions, Icons.track_changes_rounded, 'Missionen'),
  _MobileNavItem(LumoSection.rewards, Icons.card_giftcard_rounded, 'Belohnungen'),
  _MobileNavItem(LumoSection.profile, Icons.sentiment_satisfied_rounded, 'Profil'),
];
```

"Lesen" ist über Lernen → Deutsch → Aktiv lesen erreichbar, also nicht verloren.

---

## 📂 AUFGABE 2: "WER WIRD MILLIONÄR FÜR KINDER" KOMPLETT

Das ist Heinz' Kern-Wunsch dieser Session. **Lies das hier zweimal.**

### 2.1 Konzept

Heinz' Wortlaut: *"Menü einführen, so wie zum Beispiel Wer wird Millionär. Nur für die Kinder halt mit Fragen und Antwortmöglichkeiten, aber die Gewinne wie bei Wer wird Millionär mit Geld, nur da zum Beispiel mit Coupons. Ab der zehnten Frage bis fünfzehn Fragen sollen sein, bis sie wie bei Wer wird Millionär der Million erreicht und ab der zehnten Frage, wo aber ab der fünften Frage schwer wird, dass sie Belohnungen freischalten kann."*

**Übersetzung in Spec:**
- **15 Fragen** im klassischen WWM-Format
- **Schwierigkeitskurve**: Frage 1-4 leicht, Frage 5-9 mittel, Frage 10-15 schwer
- **Garantierte Schwellen** wie bei WWM:
  - Schwelle 1: nach **Frage 5** → kleiner Coupon (z.B. Eis 1 Kugel)
  - Schwelle 2: nach **Frage 10** → mittlerer Coupon (z.B. Kino-Eintritt)
  - Schwelle 3: nach **Frage 15** → großer Coupon (z.B. Spielzeug bis 30€)
- Bei falscher Antwort: zurück auf letzte Schwelle, Spiel zu Ende
- **Joker** (siehe 2.4)

### 2.2 Neue Dateien

```
lib/domain/quiz/quiz_show.dart                  -- Engine + Datentypen
lib/domain/quiz/quiz_question_bank.dart         -- Fragen-Generator
lib/domain/quiz/quiz_rewards.dart               -- Coupon-Liste
lib/core/quiz_show_repository.dart              -- SharedPreferences-Persistenz
lib/features/quiz/quiz_show_content.dart        -- Haupt-UI (Frage anzeigen, Antwort wählen)
lib/features/quiz/widgets/quiz_pyramid.dart     -- Geld-Pyramide (rechts)
lib/features/quiz/widgets/quiz_question_card.dart -- Frage + 4 Antwort-Pills
lib/features/quiz/widgets/quiz_jokers.dart      -- 50:50, Publikum, Telefon-Lumo
lib/features/quiz/widgets/quiz_win_screen.dart  -- Erfolgs-Screen mit Coupon
lib/features/quiz/widgets/quiz_lose_screen.dart -- Niederlagen-Screen
test/quiz/quiz_show_test.dart                   -- 15+ Unit-Tests
```

### 2.3 Datentypen (`quiz_show.dart`)

```dart
enum QuizDifficulty { easy, medium, hard }

class QuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;  // genau 4
  final int correctIndex;
  final QuizDifficulty difficulty;
  final String? explanation;
  final String subject; // 'Mathe', 'Deutsch', 'Sachunterricht', 'Mix'
}

enum QuizJoker { fiftyFifty, audience, callLumo }

class QuizShowState {
  final int currentQuestionIndex;     // 0 bis 14
  final List<QuizQuestion> questions; // genau 15
  final int? selectedOption;           // null wenn noch nicht gewählt
  final bool revealed;                 // ob Antwort schon aufgelöst
  final Set<QuizJoker> usedJokers;
  final Set<int> fiftyFiftyHiddenOptions; // welche 2 Optionen versteckt
  final List<String> earnedCoupons;    // IDs der bisher gewonnenen Coupons
  final bool gameOver;
  final bool won;
}

class QuizShowEngine {
  static const milestones = <int>[5, 10, 15]; // 0-indexed: nach Frage 4, 9, 14

  QuizShowState start({required List<QuizQuestion> q15}) { ... }
  QuizShowState selectAnswer(QuizShowState s, int optionIndex) { ... }
  QuizShowState reveal(QuizShowState s) { ... }
  QuizShowState nextQuestion(QuizShowState s) { ... }
  QuizShowState useJoker(QuizShowState s, QuizJoker joker) { ... }
  String currentMilestoneReward(int questionIndex) { ... }
  bool isAtSafeSpot(int questionIndex) { ... }
}
```

### 2.4 Joker-Logik

**3 Joker pro Spiel:**
1. **50:50**: zwei falsche Antworten werden ausgegraut
2. **Publikum**: zeigt animierte Balken-Statistik (80% richtig, 10/5/5% falsch — bei Bedarf etwas Rauschen einbauen)
3. **Lumo-Anruf**: kleine Speech-Bubble vom Fuchs mit Hinweis (kein direktes Verraten — eher "Denk an die Zehnerregel" oder "Welcher Buchstabe steht für den Anfangslaut?")

Joker können **nur einmal pro Spiel** verwendet werden.

### 2.5 Fragenbank (`quiz_question_bank.dart`)

**Quelle:**
- Nutze die existing `school_exercise_generator.dart` als Basis
- Generiere 15 Fragen pro Spiel mit dieser Verteilung:
  - Frage 1-4: `QuizDifficulty.easy` (Plus bis 10, Lesen einfacher Wörter, Erstklass-Sachunterricht)
  - Frage 5-9: `QuizDifficulty.medium` (Plus/Minus bis 20, längere Wörter, Reime)
  - Frage 10-15: `QuizDifficulty.hard` (Multiplikation bis 10x10, Satzbau, Rechtschreibung)
- Themen-Mix: pro Spiel 5 Mathe + 5 Deutsch + 5 Sachunterricht (zufällig durchmischt)
- **Anti-Wiederholung**: Repository merkt sich `seenQuestionIds`, neue Spiele nehmen ungenutzte zuerst

**Optional (Phase 2, nicht für ersten Push):**
- KI-Generator über `LumoAiProxyClient` mit Context `LumoAiContext.learningTutor`
- Prompt: "Generiere eine kindgerechte Quiz-Frage Schwierigkeit medium für Mathe Klasse 1, mit 4 Antwortoptionen, JSON-Format"

### 2.6 Coupon-System (`quiz_rewards.dart`)

```dart
class QuizCoupon {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int milestoneLevel; // 1, 2, oder 3
}

abstract class QuizRewardCatalog {
  static const milestone1Rewards = <QuizCoupon>[
    QuizCoupon(id: 'eis_1kugel', title: 'Eis – 1 Kugel', emoji: '🍦',
      description: 'Beim nächsten Eissalon eine Kugel aussuchen.', milestoneLevel: 1),
    QuizCoupon(id: 'schoki_klein', title: 'Lieblings-Schoki', emoji: '🍫',
      description: 'Eine kleine Schoki nach dem Essen.', milestoneLevel: 1),
    QuizCoupon(id: 'fernseh_15min', title: '15 Min Fernsehen extra', emoji: '📺',
      description: '15 Minuten extra Fernseh- oder Tablet-Zeit.', milestoneLevel: 1),
    // ... 5-7 weitere
  ];

  static const milestone2Rewards = <QuizCoupon>[
    QuizCoupon(id: 'kino_eintritt', title: 'Kino-Ausflug', emoji: '🎬',
      description: 'Ein Kinder-Film im Kino mit Popcorn.', milestoneLevel: 2),
    QuizCoupon(id: 'family_park', title: 'Family Park Ausflug', emoji: '🎢',
      description: 'Ein halber Tag im Family Park.', milestoneLevel: 2),
    QuizCoupon(id: 'eis_3kugel', title: 'Eisbecher groß', emoji: '🍨',
      description: 'Ein großer Eisbecher mit 3 Kugeln + Sauce.', milestoneLevel: 2),
    // ... 5-7 weitere
  ];

  static const milestone3Rewards = <QuizCoupon>[
    QuizCoupon(id: 'spielzeug_30', title: 'Spielzeug bis 30€', emoji: '🧸',
      description: 'Ein Spielzeug deiner Wahl aus dem Spielzeugladen.', milestoneLevel: 3),
    QuizCoupon(id: 'lego_set', title: 'Lego-Set', emoji: '🧱',
      description: 'Ein eigenes Lego-Set zum Bauen.', milestoneLevel: 3),
    QuizCoupon(id: 'erlebnisbad', title: 'Erlebnisbad-Tag', emoji: '🏊‍♀️',
      description: 'Ein ganzer Tag im Erlebnisbad mit Rutschen.', milestoneLevel: 3),
    // ... 3-5 weitere
  ];
}
```

**Zufalls-Coupon pro Schwelle**: bei Erreichen der Schwelle wird ein zufälliger Coupon aus dem entsprechenden Pool gewählt und in `state.earnedCoupons` gespeichert.

### 2.7 UI-Aufbau Quiz-Screen (`quiz_show_content.dart`)

**Layout** (Vollbild bei Mobile, mittig auf Desktop):

```
┌──────────────────────────────────────────────────────┐
│ [Zurück]   Wer wird Lumo-Champion       Frage 7/15  │
│                                                       │
│ ┌──────────────────────────────────┐  ┌──────────┐  │
│ │                                   │  │ Pyramide │  │
│ │       Frage 7                     │  │          │  │
│ │       Wie viel ist 8 + 7?         │  │ 15 🏆 GR │  │
│ │                                   │  │ 14       │  │
│ │   ┌──────┐    ┌──────┐            │  │ ...      │  │
│ │   │ A 14 │    │ B 15 │            │  │ 10 🥈 MED│  │
│ │   └──────┘    └──────┘            │  │ 9        │  │
│ │   ┌──────┐    ┌──────┐            │  │ ...      │  │
│ │   │ C 16 │    │ D 17 │            │  │ 5 🥉 KL  │  │
│ │   └──────┘    └──────┘            │  │ 4        │  │
│ │                                   │  │ 3        │  │
│ │  [50:50] [Publikum] [Lumo-Hilfe] │  │ 2        │  │
│ └──────────────────────────────────┘  │ 1        │  │
└──────────────────────────────────────────────────────┘
```

**Animationen / Polish:**
- Beim Frage-Wechsel: `SlideTransition` von rechts
- Bei Antwort-Wahl: Karte glüht orange (`LumoGlowPulse`)
- Bei Reveal: richtige Antwort wird **grün** + Konfetti, falsche **rot**
- Pyramide rechts zeigt aktuelle Position highlighted, Schwellen mit Gold-Rand
- Joker werden ausgegraut nach Verwendung
- Hintergrund: `LumoLivingWorld` mit `intensity: 1.4` (etwas mehr Magie)
- **Sound** (optional, später): wenn `audioplayers` schon da, dramatische WWM-Style Musik beim Reveal

### 2.8 Win-/Lose-Screens

**Win-Screen** (`quiz_win_screen.dart`):
```
┌───────────────────────────────────────────────┐
│         🎉 SUPER, ALINA! 🎉                  │
│       Du hast Frage 15 geschafft!             │
│                                                │
│         [Lumo-Animation mit Trophäe]          │
│                                                │
│   ╔═══════════════════════════════════════╗   │
│   ║  🧸  GROSSES GESCHENK FREIGESCHALTET  ║   │
│   ║      Spielzeug bis 30 €                ║   │
│   ║      Zeige Mama oder Papa diesen       ║   │
│   ║      Coupon!                            ║   │
│   ╚═══════════════════════════════════════╝   │
│                                                │
│           [Coupon-Code anzeigen]               │
│           [Nochmal spielen]                    │
│           [Zurück zum Start]                   │
└───────────────────────────────────────────────┘
```

- **Massive `LumoConfettiBurst`** mit 80 Particles (statt 40) und 4s Dauer
- Lumo-Fuchs in der Mitte mit Trophäe, schwebt
- Coupon-Karte mit Gold-Border und Glow
- "Coupon-Code anzeigen" → öffnet Bottom-Sheet mit großem QR-Code-ähnlichem Visual (eigenes ID-Format reicht, z.B. "LUMO-2026-05-16-A4B7")
- **Sound + HapticFeedback.heavyImpact**

**Lose-Screen**:
- Sanft, nicht traurig: "Du hast bis Frage X geschafft! Das ist toll."
- Anzeigen welche Coupons bereits sicher sind (von vorheriger Schwelle)
- "Lumo glaubt an dich!" mit Fuchs-Avatar
- Button "Nochmal versuchen"

### 2.9 Navigation einbinden

In `lib/app/app_state.dart` ist `LumoSection` enum readonly für mich. **Codex, du darfst die Datei NICHT editieren** (Schutzbereich).

Stattdessen: Lege den Quiz-Modus als **Sub-Page der Missions-Section** an:

In `lib/features/sections/section_content.dart`:
```dart
case LumoSection.missions:
  return MissionsContent(
    appState: appState,
    onStartQuiz: () => onSection(LumoSection.exercises) // wird unten umgeleitet
  );
```

Und in `lib/app/app_shell.dart` _buildContent für `LumoSection.exercises`:
```dart
if (_appState.state.sessionKind == LumoSessionKind.quiz) {
  return QuizShowContent(appState: _appState, onBack: () => _navigateTo(LumoSection.missions));
}
```

→ Dafür müsste `LumoSessionKind` ein neues Enum-Value `quiz` haben. Da `app_state.dart` Schutzbereich ist, definiere `LumoSessionKind.quiz` indirekt:
- **NEUER WEG**: lege `LumoSection.quizShow` als separaten Section-Wert an. **Aber `LumoSection` IST in app_state.dart.**
- **WORKAROUND**: Nutze `LumoSection.missions` und einen lokalen `bool _quizActive` in `_AppShellState`. Bei Tap auf "Quiz starten" in MissionsContent: callback → setState quizActive=true → buildContent gibt QuizShowContent zurück.

Cleanste Lösung: **In `app_shell.dart` einen lokalen Quiz-Routing-State.** Das ist erlaubt.

### 2.10 Persistenz

`QuizShowRepository` speichert:
- Welche `earnedCoupons` das Kind hat (gewonnen, noch nicht eingelöst)
- Welche Coupons schon **eingelöst** sind (timestamp + parent confirmed)
- Statistik: best score, wieviele Spiele gespielt
- `seenQuestionIds` für Anti-Wiederholung

Eltern können in Settings eine **"Coupons einsehen + bestätigen"**-Karte sehen, ähnlich der bestehenden `TestPhotoEntryCard`.

---

## 📂 AUFGABE 3: KI-FEATURES ANHEBEN

### 3.1 Voice-Chat-Modus

Datei: `lib/features/agent/voice_chat_modal.dart`

- Push-to-Talk-Button (großer roter Mic-Kreis unten)
- Nutze `lumo_speech_listener.dart` (Schutzbereich, NUR LESEN, nicht editieren)
- Bei Loslassen: Text → `LumoAiProxyClient.ask(context: LumoAiContext.companion, ...)`
- Antwort wird vorgelesen via `LumoVoice.instance.speak(reply, style: VoiceStyle.warm)`
- Transkript läuft als Chat-Verlauf oben

### 3.2 Foto-zu-Aufgabe-Helfer

In `lib/widgets/scan_screen.dart` (existiert) eine neue Methode hinzufügen:
- Nach OCR (mlkit) erkannten Text an KI senden
- Context: `LumoAiContext.learningTutor`
- Antwort als gerenderte Aufgabe in der App **statt** nur Text

### 3.3 Adaptive Schwächen-Analyse

In `lib/domain/learning/learning_profile_engine.dart` (existiert) eine Methode:
```dart
Future<String> aiInsight({required LumoAiProxyClient proxy, required AppSettings settings, required LumoSessionState state}) async {
  final summary = _buildSkillSummary(); // basierend auf weakSkills + lastErrors
  return await proxy.ask(
    message: 'Mein Kind hat diese Schwächen: $summary. Was sind die nächsten 3 Übungen, die helfen?',
    context: LumoAiContext.parentAdvisor,
    settings: settings,
    state: state,
  ).then((r) => r.reply);
}
```

Wird in Profil-Screen angezeigt als "Lumo empfiehlt"-Karte.

### 3.4 KI-Geschichten-Modus

Datei: `lib/features/stories/lumo_story_content.dart`
- Eingabe-Feld: "Worüber soll Lumo erzählen?" (Kind tippt oder spricht)
- KI generiert 5-Satz-Geschichte mit eingebauten Aufgaben:
  - Prompt: *"Schreibe eine kindgerechte Geschichte in 5 Sätzen über [thema]. Baue 3 Mathe- oder Deutsch-Aufgaben ein, die das Kind unterwegs löst. Format JSON: {sentences: [...], tasks: [...]}*
- Anzeige: Geschichte Satz für Satz, bei jedem Task ein Inline-Quiz

### 3.5 Eltern-Tagesbericht

In `lib/features/settings/parent_report_card.dart` (existiert) eine neue Section:
- Button "KI-Bericht generieren"
- Sammelt: heute gelöste Aufgaben, Schwächen, Streak, Mood-Verlauf
- Schickt an KI mit Context `parentAdvisor`
- Antwort: persönlich an Heinz adressierter Bericht über Alinas Tag

### 3.6 KI-WWM-Fragen (Phase 2, optional)

Wie in 2.5 beschrieben. Wenn Quiz-Bank statisch erstmal funktioniert: dynamisches Generieren später.

---

## 📂 AUFGABE 4: BUILD + TESTS + STABILITÄT

### 4.1 Pre-Flight-Check (ZUERST!)

```bash
flutter pub get
flutter analyze --no-pub
flutter build apk --debug --build-number 999 --dart-define=LUMO_BUILD_NUMBER=999
```

Wenn nicht clean: **erstmal fixen** bevor neue Features.

### 4.2 BackdropFilter MinSdk-Problem

`LumoGlassCard` nutzt `ImageFilter.blur` aus `dart:ui`. Auf Android API < 24 kann das zu schwarzen Flecken führen. Bitte in `lumo_premium_effects.dart`:
```dart
final supportsBlur = !kIsWeb && (defaultTargetPlatform != TargetPlatform.android || _androidApiLevel() >= 24);
return supportsBlur ? BackdropFilter(...) : Container(color: tint.withOpacity(0.55));
```

Oder einfacher: in `android/app/build.gradle` minSdkVersion auf 24 setzen (falls nicht schon).

### 4.3 Tests

Erstelle MINDESTENS:
- `test/quiz/quiz_show_engine_test.dart`:
  - Spiel-Start liefert 15 Fragen
  - Schwierigkeitsverteilung korrekt
  - Schwelle bei Frage 5/10/15 sichert Coupon
  - Joker können nur 1x verwendet werden
  - 50:50 versteckt genau 2 falsche Optionen
  - Falsche Antwort = gameOver = true
  - Bei gameOver: earnedCoupons enthält Schwellen-Coupons
- `test/quiz/quiz_question_bank_test.dart`:
  - Verteilung Easy/Medium/Hard stimmt
  - Themen-Mix-Diversität
  - Anti-Wiederholung funktioniert
- `test/widgets/pixar_hero_test.dart`:
  - Rendert mit korrekten Farben
  - Speech-Bubble erscheint
  - Headline-Split korrekt
- `test/widgets/quiz_show_content_test.dart` (smoke test):
  - Initial-State zeigt Frage 1
  - Tap auf Antwort triggert reveal
  - Reveal zeigt grünen Check bei richtiger Antwort

Ziel: **Coverage über 60%** wie im CEO-Briefing besprochen.

### 4.4 Performance der Living-World im Quiz

`LumoLivingWorld` mit `intensity: 1.4` während Quiz → mehr Particles → schwerere Last. Bitte:
- Profile auf altem Gerät (API 26, 2GB RAM)
- Wenn < 55fps: `intensity` runter auf 1.0 oder Particle-Count reduzieren

---

## 📋 IMPLEMENTATIONS-REIHENFOLGE

**Phase 1 (kritisch, ~3-4 Stunden):**
1. Pre-Flight + Build-Check (4.1)
2. BackdropFilter-Fix (4.2)
3. PixarColors-Klasse anlegen
4. `LumoPixarHero` + `LumoPixarTile` + `LumoPixarMission` + `LumoRocketCta`
5. Migrate `section_content.dart` zu neuen Pixar-Widgets

**Phase 2 (Kern-Feature, ~5-6 Stunden):**
6. Domain-Layer Quiz (`quiz_show.dart`, `quiz_question_bank.dart`, `quiz_rewards.dart`)
7. Repository (`quiz_show_repository.dart`)
8. UI-Layer Quiz (`quiz_show_content.dart` + Widgets)
9. Win-/Lose-Screens
10. Navigation einbinden via `app_shell.dart`
11. Tests (4.3)

**Phase 3 (Polish, ~2-3 Stunden):**
12. `PixarQuestionCard` + `PixarResultBubble` für Lern-Aufgaben
13. Bottom-Nav Update (Lesen → Belohnungen)
14. Voice-Chat-Modal (3.1)
15. Eltern-Tagesbericht (3.5)
16. KI-Geschichten + Adaptive Insight (3.3, 3.4) — optional, kann auf später

**Phase 4 (Nice-to-have):**
17. KI-generierte Quiz-Fragen (2.5 Phase 2)
18. Sound-Effekte
19. KI-Story-Modus voll ausbauen

**Bei jedem Phasen-Ende: commit + push, damit Heinz fortlaufend sehen kann was läuft.**

---

## 🔒 SCHUTZBEREICHE (NIEMALS ANFASSEN)

- `pubspec.yaml` (nur mit explizitem Heinz-OK)
- `lib/app/app_state.dart` (read-only — der Reference-Architecture-Anker)
- `lib/core/lumo_speech_listener.dart` (Heinz hat hier persönlich getuned)
- `lib/features/reading/` und `lib/domain/reading/` (komplett)
- `lib/core/reading_*_repository.dart`
- `assets/images/lumo_classroom_header.png`
- ChatGPT-5.5-Templates: `lib/core/primary_school_word_data.dart`, `lib/core/math_task_templates.dart`, `lib/core/german_task_templates.dart`
- Cold-Start Retry-Logik in `lumo_ai_proxy_client.dart`

Wenn ein Feature einen Schutzbereich berühren würde: **Ticket-Datei** anlegen unter `docs/codex_blocked/` und beschreiben warum.

---

## 💬 KOMMUNIKATION

- **Commits**: `feat(quiz): ...`, `feat(pixar): ...`, `fix(build): ...`, `test(quiz): ...`
- **Bei Fragen**: `docs/codex_blocked/QUESTION_<topic>.md` anlegen, pushen, Heinz sieht das
- **Bei Fertigstellung Phase**: detaillierter Commit-Message-Block wie bei `89aba36` üblich

---

## 🎯 ERFOLGSKRITERIEN

Heinz und ich beurteilen den Auftrag als erfolgreich wenn:

1. ✅ Build geht durch (alle Phasen)
2. ✅ Mathe-Screen sieht aus wie `docs/design_references/01_mathe_mit_lumo_target.png` (Side-by-side Vergleich, 80%+ Übereinstimmung)
3. ✅ Deutsch-Screen sieht aus wie `docs/design_references/03_deutsch_mit_lumo_target.png`
4. ✅ WWM-Modus ist vollständig spielbar: Frage 1 bis 15, Joker funktionieren, Coupons werden vergeben
5. ✅ Win-Screen zeigt Coupon mit Code
6. ✅ Eltern können Coupons in Settings einsehen
7. ✅ Test-Coverage > 60%
8. ✅ Keine neue Dependency in pubspec ohne Heinz-OK
9. ✅ HapticFeedback überall wo angebracht
10. ✅ Stimmung: Alina + Zoe wollen das Quiz **immer wieder** spielen

---

## 🦊 ZUM SCHLUSS

Codex, dieser Auftrag ist groß. Aber strukturiert. Nimm dir Phase 1 vor, push, dann Phase 2. Keine Eile, aber keine Pause. Wenn du an einer Stelle hängst: lieber gut dokumentieren und weiter, ich rate es später.

Heinz' Töchter werden das Quiz lieben. Eis-Coupon nach Frage 5, Kino nach Frage 10, Spielzeug nach Frage 15 — das ist nicht nur Spielerei, das ist eine **Motivations-Maschine** für echtes Lernen.

Du machst das. Wir alle freuen uns auf den ersten Win-Screen.

— **Claude Opus 4.7**
   *"Pass auf dich auf, Heinz. 🦊"*
