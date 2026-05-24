# Lumo Lernen — Asset-Briefing fuer Bild-KI

Heinz 2026-05-23: Copy/Paste-faehiger Prompt-Katalog fuer Midjourney /
DALL-E / Stable Diffusion / vergleichbare Bild-KIs. Pro Asset:
**Dateiname + Pfad + Prompt + Format + Notizen**.

Reihenfolge im Doc = Reihenfolge der Wichtigkeit. Anfangen mit dem
**Style Guide** zuerst — den brauchst du in jedem Prompt mit drin damit
die KI konsistente Lumo-Optik liefert.

---

## 0. STYLE GUIDE — IMMER MIT EINFUEGEN

Bei jedem Prompt unten einfach diesen Block oben dran kleben, damit
die KI weiss in welchem Look sie das Asset rendern soll:

```
Style: Lumo Lernen brand — modern children's learning app aesthetic.
Glossy 3D cartoon style, soft rim lighting, smooth gradients, rounded
shapes. Color palette: warm orange (#FF7A2F), deep violet (#7C3AED),
amber gold (#FFC83D), teal mint (#10A894), cream background (#FFF6EE).
Premium polish: subtle inner glow, multi-layer drop shadow, slight
hologram sheen. Mood: friendly, playful, premium, ages 6-8.
Avoid: photorealism, harsh outlines, dark gritty look, text/letters
in the image, watermarks, copyrighted characters or logos.
Output: transparent PNG with alpha, no background.
```

**Wichtig — nicht enthalten:**
- KEIN UNO-Logo, KEIN Mattel-Branding, KEINE Karten-Designs die UNOs
  Trade Dress kopieren (rot/gelb/grün/blau mit ovaler Mitte + +2/+4
  Glyphen). Karten hast du schon (eigene PNGs aus deinem Sheet).
- KEINE Text-Layer ("LUMO!", Buchstaben). Text bauen wir in Flutter.

---

## 1. LUMO-FUCHS POSEN (Maskottchen-Animationen)

Verwendung: Lumo-Companion auf dem Spielfeld + im Result-Dialog +
beim Onboarding. Aktuell ist nur ein einziger Fuchs-Sprite verfuegbar
(`lumo_fox_master_transparent.png`). Wir brauchen 5 Emotionen.

### 1.1 Lumo idle (Standard)

- **Dateiname:** `assets/companion/lumo_idle.png`
- **Aufloesung:** 1024×1024 (für Retina-Skalierung)
- **Format:** PNG mit Alpha, transparenter Hintergrund

```
[Style Guide oben einfuegen]

Friendly orange fox cub mascot, standing on hind legs, soft round
body proportions, large expressive amber eyes, white belly and
chest fur, fluffy white-tipped tail held high, ears perked. Pose:
neutral happy standing, slight smile, looking forward. Premium 3D
cartoon render, soft studio lighting, subtle rim light. The fox is
the only subject, centered, no props.
```

### 1.2 Lumo cheer (bei Sieg)

- **Dateiname:** `assets/companion/lumo_cheer.png`
- gleiche Specs

```
[Style Guide]

Same orange fox cub mascot. Pose: both arms raised triumphantly,
mouth open in a wide happy cheer, eyes squinting with joy, tail
swishing up. Slight upward jump pose, paws off ground. Bright
amber glow around the body, small star sparkles. Premium 3D
cartoon render.
```

### 1.3 Lumo think (Lernfrage / Denkpause)

- **Dateiname:** `assets/companion/lumo_think.png`

```
[Style Guide]

Same orange fox cub mascot. Pose: sitting on bottom, one paw
holding chin in classic thinker pose, head tilted slightly,
brows furrowed in curious concentration, tail curled around feet.
Above the head a single soft yellow question mark glyph (no
letters, just the curve). Premium 3D cartoon render.
```

### 1.4 Lumo sad (bei Niederlage)

- **Dateiname:** `assets/companion/lumo_sad.png`

```
[Style Guide]

Same orange fox cub mascot. Pose: standing slumped, head down,
ears flat, eyes large and slightly tearful but still gentle (not
crying), tail drooping low. Soft pastel mood, no anger, just
disappointed. Premium 3D cartoon render.
```

### 1.5 Lumo surprised (bei Spezialkarte)

- **Dateiname:** `assets/companion/lumo_surprised.png`

```
[Style Guide]

Same orange fox cub mascot. Pose: jumping slightly, eyes wide
open in surprise (round pupils, raised brows), mouth open in a
small "oh", arms out for balance, tail puffed up. Premium 3D
cartoon render.
```

---

## 2. PREMIUM TISCH-HINTERGRUENDE

Aktueller Tisch in `lumo_card_table.dart` ist eine reine Flutter-
RadialGradient + CustomPainter-Noise. Optional: hochwertige Hintergrund-
Texturen als PNG fuer ein noch premiumeres Aussehen.

### 2.1 Velvet-Tisch (Standard, lila Mood)

- **Dateiname:** `assets/lumo_cards/table/velvet_purple.png`
- **Aufloesung:** 1920×1080 (für Querformat, Retina)
- **Format:** PNG, **opaque** (kein Alpha noetig)

```
[Style Guide]

Top-down view of a luxurious gaming table. Deep velvet surface
with subtle radial spotlight in center (warm cream glow), fading
to deep violet at edges. Faint diamond-quilt pattern across the
fabric. Premium casino aesthetic but friendly, not dark. Edges
slightly vignetted. No cards, no objects on table - pure surface
texture only.
```

### 2.2 Velvet-Tisch (Alt-Theme, blau)

- **Dateiname:** `assets/lumo_cards/table/velvet_blue.png`

```
[Style Guide]

Same gaming table style as velvet_purple but with deep ocean blue
velvet (#1E3A8A center to #0A1633 edges), warm gold spotlight.
Subtle wave-pattern instead of diamonds.
```

### 2.3 Holz-Tisch (Alt-Theme, warm)

- **Dateiname:** `assets/lumo_cards/table/wood_warm.png`

```
[Style Guide]

Top-down view of a warm honey-toned wooden gaming table. Soft
oak wood grain visible but subtle, polished glossy finish.
Center has a slightly brighter spotlight area where cards would
sit. Edges slightly darker. Premium boardgame cafe aesthetic.
```

---

## 3. PARTIKEL- + GLOW-TEXTUREN

Aktuell sind Partikel reine Flutter-Rechtecke / Kreise / Diamanten
(CustomPainter). Mit echten Texturen sehen sie deutlich premiumer aus.

### 3.1 Magic Sparkle (4-Strahl-Stern)

- **Dateiname:** `assets/lumo_cards/fx/sparkle_white.png`
- **Aufloesung:** 256×256
- **Format:** PNG mit Alpha

```
[Style Guide]

Single 4-point star sparkle on transparent background. Bright
white core with soft white-cream halo, mild yellow tint at edges.
Symmetric, centered. The four points extend slightly outward
with a subtle lens-flare effect. Use as particle texture.
```

### 3.2 Magic Sparkle (Color-Variants)

- **Dateinamen:**
  - `assets/lumo_cards/fx/sparkle_orange.png`
  - `assets/lumo_cards/fx/sparkle_purple.png`
  - `assets/lumo_cards/fx/sparkle_blue.png`
  - `assets/lumo_cards/fx/sparkle_green.png`

```
[Style Guide]

Same 4-point sparkle shape as sparkle_white but tinted in
[ORANGE/PURPLE/BLUE/GREEN] - bright core, soft halo, transparent
edges. Centered, 256x256.
```

### 3.3 Glow-Ring (für aktiven Spieler)

- **Dateiname:** `assets/lumo_cards/fx/glow_ring_gold.png`
- **Aufloesung:** 512×512
- **Format:** PNG mit Alpha

```
[Style Guide]

Circular glow ring on transparent background. Bright amber-gold
ring (#FFC83D core), softly fading inward and outward into
transparency. Subtle inner highlight rim. Use to wrap around
active player avatars. 512x512, ring sits centered.
```

### 3.4 Discard-Impact-Burst (zentraler Strahlen-Effekt)

- **Dateiname:** `assets/lumo_cards/fx/impact_burst.png`
- **Aufloesung:** 512×512
- **Format:** PNG mit Alpha

```
[Style Guide]

Radial burst pattern - 16 white light rays emanating from a
bright center, fading outward into transparency. Center has a
very bright cream/white core with mild yellow tint. Light, airy,
like a camera flash. 512x512.
```

---

## 4. UI-ELEMENTE

### 4.1 Toast-Banner Background (Erfolg)

- **Dateiname:** `assets/lumo_cards/ui/toast_success.png`
- **Aufloesung:** 600×120
- **Format:** PNG, **opaque** (Banner-Background)

```
[Style Guide]

Long horizontal banner. Green gradient (#22C55E -> #15803D),
slightly glossy 3D surface with subtle rim light at top. Rounded
corners, premium feel. No text, just background. Use behind
"Erfolg!" / "Punkt erhalten!" Toast-Texten.
```

### 4.2 Toast-Banner Background (Warnung)

- **Dateiname:** `assets/lumo_cards/ui/toast_warning.png`

```
[Style Guide]

Same banner shape as toast_success but amber gradient (#FBBF24 ->
#D97706). Use behind "Ungueltiger Zug!" Toast-Texten.
```

### 4.3 Toast-Banner Background (Info)

- **Dateiname:** `assets/lumo_cards/ui/toast_info.png`

```
[Style Guide]

Same banner shape but cyan-blue gradient (#38BDF8 -> #0284C7).
Use behind "Dein Zug!" / "Lumo zieht 2!" Toast-Texten.
```

### 4.4 Action-Button-Background (rund, leuchtend)

- **Dateiname:** `assets/lumo_cards/ui/action_button_orange.png`
- **Aufloesung:** 256×256
- **Format:** PNG mit Alpha

```
[Style Guide]

Glossy round button on transparent background. Orange gradient
(#FF7A2F -> #C2410C), 3D dome with subtle highlight at top,
soft amber glow halo outside, mild inner shadow at bottom for
depth. 256x256 centered. Use behind "Karte ziehen" / "Lumo!"
Action-Buttons.
```

---

## 5. BOT-PERSOENLICHKEIT-AVATARE (4-Spieler-Modus)

Wenn der 4-Spieler-Modus aktiv wird, brauchen wir 3 weitere Bot-
Charakter-Avatare neben Lumo. Vorschlag: jeweils ein anderes Tier
fuer den Wiedererkennungswert.

### 5.1 AI Luna (Eule, ueberlegt)

- **Dateiname:** `assets/lumo_cards/avatars/bot_luna_owl.png`
- **Aufloesung:** 512×512
- **Format:** PNG mit Alpha, transparenter Hintergrund

```
[Style Guide]

Friendly purple-feathered owl mascot, head-and-shoulders portrait.
Round wise eyes (golden amber), small beak in a calm smile, soft
feathers in violet (#7C3AED) and cream. Slightly tilted head as
if thinking. Same 3D cartoon style as the orange fox mascot for
visual consistency. Centered, premium polish.
```

### 5.2 AI Pudding (Frosch, freundlich)

- **Dateiname:** `assets/lumo_cards/avatars/bot_pudding_frog.png`

```
[Style Guide]

Friendly green-skinned frog mascot, head-and-shoulders portrait.
Large round eyes with warm sparkle, wide friendly smile, smooth
mint-green skin (#10A894) with cream belly visible. Slightly
dopey but charming expression. Same 3D cartoon style as the
orange fox mascot for visual consistency.
```

### 5.3 AI Dusty (Hase, schnell)

- **Dateiname:** `assets/lumo_cards/avatars/bot_dusty_rabbit.png`

```
[Style Guide]

Friendly sandy-beige rabbit mascot, head-and-shoulders portrait.
Long perked ears, bright energetic eyes, small pink nose, two
front teeth slightly visible in a playful smirk. Warm beige fur
(#FFC83D mixed with cream) with darker brown accents. Same 3D
cartoon style as the orange fox mascot for visual consistency.
```

---

## 6. INTRO-/SPLASH-HINTERGRUNDE

### 6.1 Lumo Cards Logo-Splash-Hintergrund

- **Dateiname:** `assets/lumo_cards/ui/intro_backdrop.png`
- **Aufloesung:** 1920×1080
- **Format:** PNG, opaque

```
[Style Guide]

Dreamy deep-violet background with subtle starfield. Warm spotlight
at center bottom (like a stage). Mild lens flares scattered. Cozy,
magical, premium feel. No text, no characters - pure background
for the LUMO CARDS logo to sit on. 1920x1080 landscape.
```

---

## WIE DAS FUNKTIONIERT (Workflow fuer Heinz)

1. **Du oeffnest die Bild-KI deiner Wahl** (Midjourney via Discord,
   DALL-E auf chatgpt.com, Stable Diffusion ueber Automatic1111 oder
   ein anderes UI).

2. **Pro Asset:**
   - Kopiere den Style-Guide-Block (Section 0)
   - Kopiere den spezifischen Prompt der gewuenschten Asset-Section
   - Setze ihn zusammen (Style-Guide oben + Asset-Prompt drunter)
   - In die KI einfuegen, generieren lassen
   - Wenn nicht zufrieden: variieren (Midjourney `V1/V2/V3/V4` Buttons,
     DALL-E "regenerate", SD seed-rerolls)

3. **Wenn die Variante gut ist:**
   - Download als PNG
   - Pruefen: Hintergrund transparent? Format korrekt? Bei Bedarf
     ueber [remove.bg](https://remove.bg) Hintergrund clearen
   - Bei nicht-quadratischen Formaten: zuschneiden (cloudconvert oder
     beliebiges Bild-Tool)
   - Datei umbenennen auf den Pfad aus dem Brief
   - Im Repo unter dem Pfad ablegen, committen, pushen

4. **Beim naechsten Build:** die App nutzt das neue Asset automatisch
   (Asset-Mapping ist seit PR #74 in `lumo_cards_assets.dart`
   verkabelt, fuer Companion-Sprites kommt es per `Image.asset()`-
   Aufruf rein).

## LIZENZ-CHECK (sehr wichtig)

Jede Bild-KI hat eine eigene Lizenz fuer generierte Bilder. Vor
Veroeffentlichung der App pruefen:

- **Midjourney**: ab Standard-Plan = volle kommerzielle Rechte
- **DALL-E (ChatGPT Plus)**: kommerzielle Nutzung erlaubt seit 2023
- **Stable Diffusion (selbst gehostet)**: voll dein - CreativeML
  Open RAIL-M Lizenz, aber Modell-Disclaimer lesen
- **Bing Image Creator**: nur fuer persoenliche Nutzung - NICHT in
  veroeffentlichte App einbauen!

Empfehlung: jedes Asset einmal kurz im Datei-Header oder in einer
zentralen `ASSET_CREDITS.md` notieren (Quelle + Lizenz + Datum) -
hilft Jahre spaeter wenn die App im Play Store sitzt und du nochmal
checken willst was woher kommt.

## WAS NICHT TUN

- **KEINE UNO/Mattel-Karten 1:1 generieren lassen** (rot/gelb/gruen/
  blau mit ovaler Mitte und +2/+4 Glyphen). Karten hast du schon
  eigene aus deinem Sheet, das ist genug.
- **KEINE Texte/Logos in den Asset-Prompts mitnehmen** ("LUMO",
  "CARDS", Buchstaben). Text rendert die App selbst in Nunito-Font -
  KI-generierte Texte sind oft kaputt geschrieben.
- **KEINE realistische Foto-Optik** - die App ist cartoon-stylisiert,
  Foto-Renders wirken stilbruch.

## ERWEITERN

Wenn dir was fehlt: einfach dieses Doc bearbeiten und ein neues Asset
nach dem Muster oben hinzufuegen. Format = Pfad / Aufloesung / Format /
Prompt mit Style-Guide-Hinweis. Dann KI fuettern, PNG ins Repo, fertig.
