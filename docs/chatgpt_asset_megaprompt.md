# ChatGPT Megaprompt — Lumo-Assets als ZIP

**Workflow:** Du kopierst den **gesamten Block zwischen den `===` unten** in eine
neue ChatGPT-Konversation (am besten GPT-4o oder GPT-5 mit Image-Generation +
Code Interpreter / "Advanced Data Analysis" aktiv). ChatGPT generiert alle
Assets der Reihe nach, packt sie in eine ZIP-Datei mit korrektem Ordner-Layout,
und stellt sie dir als Download bereit.

**Wenn dein ChatGPT-Modell keine Image-Generation hat:** der Prompt funktioniert
auch als reine Prompt-Sammlung — die KI gibt dir dann pro Asset einen
detaillierten Image-Prompt, den du in Midjourney/Stable Diffusion einkippst.

**Wichtig nach dem Download:** ZIP entpacken, Inhalt in dieses Repo unter
`assets/` einfuegen (Pfade matchen 1:1), committen, pushen. Beim naechsten Build
nutzt die App alles automatisch.

---

# ===== ANFANG MEGAPROMPT (alles kopieren) =====

Ich baue eine Kinder-Lern-App namens **Lumo Lernen** (Flutter/Android, fuer
oesterreichische Erstklaessler). Im Spiel **Lumo Cards** fehlen mir noch
Premium-3D-Grafiken. Du hilfst mir, **alle Assets als PNG-Bilder im Lumo-Stil
zu generieren** und am Ende in einer ZIP-Datei mit korrektem Ordner-Layout
zu liefern, die ich direkt in mein Repo entpacken kann.

## Lumo-Brand Style Guide (gilt fuer JEDES Bild)

- **Stil:** Modernes Cartoon-3D, glossy, premium, kinderfreundlich (Ages 6-8).
  Soft Rim Lighting, weiche Verlaeufe, abgerundete Formen, subtle Inner Glow,
  multi-layer Drop Shadow, leichter Hologramm-Schimmer.
- **Farbpalette:**
  - Hauptorange `#FF7A2F`
  - Tieflila `#7C3AED`
  - Amber-Gold `#FFC83D`
  - Mint-Teal `#10A894`
  - Creme-Hintergrund `#FFF6EE`
- **Mood:** freundlich, verspielt, premium. Keine duestere/horror Optik.
- **Hintergrund:** bei Characters und Icons IMMER **vollstaendig transparent
  (Alpha-Kanal, PNG-32)**. Bei Hintergrund-Texturen darf der Hintergrund
  opaque sein.
- **VERBOTEN in jedem Bild:**
  - KEIN Text/Buchstaben/Logos (Schrift rendert spaeter die App in Nunito)
  - KEIN UNO-Logo, KEIN Mattel-Branding, keine UNO-Style-Karten
    (rot/gelb/gruen/blau mit ovaler Mitte und +2/+4-Glyphen) — meine Karten
    sind eigenstaendig
  - KEINE realistischen Foto-Renders — alles Cartoon-3D
  - KEINE Watermarks, kein "AI generated"-Stempel, keine Signature

## Konkrete Asset-Liste (23 PNGs, exakte Pfade fuer ZIP)

Generiere bitte alle der folgenden 23 Bilder. Jedes mit dem Style Guide oben +
dem spezifischen Prompt. Ordner-Pfade so wie unten genau einhalten (die ZIP
soll diese Struktur abbilden).

### Kategorie A: Lumo-Fuchs Maskottchen (5 Bilder, je 1024×1024, PNG mit Alpha)

Alle 5 zeigen denselben **Lumo-Fuchs**: orangener Fuchs-Junge, weicher runder
Koerper, grosse Bernstein-Augen, weisser Bauch + Brust + Schwanz-Spitze,
Ohren aufgerichtet, kindlich-suess. Pose unterscheidet sich.

1. **`assets/companion/lumo_idle.png`** — Pose: aufrecht stehend, neutral
   freundlicher Blick, leichtes Laecheln, nach vorn schauend, Arme entspannt.
2. **`assets/companion/lumo_cheer.png`** — Pose: beide Arme triumphierend hoch,
   Maul weit offen im Jubel, Augen vor Freude zusammengekniffen, Sprung in der
   Luft, Schwanz nach oben. Heller Amber-Glow um den Koerper, kleine
   Stern-Funken.
3. **`assets/companion/lumo_think.png`** — Pose: sitzend, eine Pfote unterm
   Kinn (klassischer Denker), Kopf leicht geneigt, Brauen gewoelbt, neugieriger
   Ausdruck. Ueber dem Kopf ein weiches gelbes Fragezeichen-Glyph (NUR die
   Kurve, kein Buchstabe).
4. **`assets/companion/lumo_sad.png`** — Pose: niedergeschlagen stehend, Kopf
   gesenkt, Ohren flach, Augen gross + leicht traenend (aber NICHT weinend),
   Schwanz haengt. Sanfter Pastell-Mood.
5. **`assets/companion/lumo_surprised.png`** — Pose: erschrocken hoch springend,
   Augen weit auf, Maul offen im "Oh", Arme zum Balance-Halten gespreizt,
   Schwanz aufgeplustert.

### Kategorie B: Premium Tisch-Hintergruende (3 Bilder, je 1920×1080, PNG opaque)

Top-Down-Sicht auf einen Luxus-Spieltisch, kein Objekt darauf, nur Oberflaeche.

6. **`assets/lumo_cards/table/velvet_purple.png`** — Tiefer Velvet-Stoff, sub-
   tiles Radial-Spotlight im Zentrum (warm-cremiges Glow), faded zu tiefem
   Violett am Rand. Schwacher Diamond-Quilt-Pattern auf dem Stoff. Edges leicht
   vignettiert.
7. **`assets/lumo_cards/table/velvet_blue.png`** — Dasselbe wie velvet_purple
   aber in tief-ozeanischem Blau (`#1E3A8A` Zentrum -> `#0A1633` Rand). Warmes
   Gold-Spotlight. Wave-Pattern statt Diamond.
8. **`assets/lumo_cards/table/wood_warm.png`** — Honig-warmer Holz-Spieltisch,
   subtle Eichenmaserung, polierte glossy Oberflaeche, Zentrum heller (Spot).
   Edges leicht dunkler. Premium-Boardgame-Cafe-Look.

### Kategorie C: Partikel- + Glow-FX (7 Bilder)

9. **`assets/lumo_cards/fx/sparkle_white.png`** (256×256, PNG mit Alpha) —
   Einzelner 4-Punkte-Stern-Sparkle. Heller weisser Kern, weicher
   weiss-cremiger Halo, milder gelber Edge. Symmetrisch, zentriert. Die 4
   Strahlen leicht ausgedehnt mit dezenter Lens-Flare-Anmutung.
10. **`assets/lumo_cards/fx/sparkle_orange.png`** (256×256) — Gleicher Sparkle
    wie 9, getoent in `#FF7A2F` (heller Kern, weicher Halo, transparente Edges).
11. **`assets/lumo_cards/fx/sparkle_purple.png`** (256×256) — Gleicher Sparkle
    in `#7C3AED`.
12. **`assets/lumo_cards/fx/sparkle_blue.png`** (256×256) — Gleicher Sparkle in
    `#2D7BFF`.
13. **`assets/lumo_cards/fx/sparkle_green.png`** (256×256) — Gleicher Sparkle
    in `#35C759`.
14. **`assets/lumo_cards/fx/glow_ring_gold.png`** (512×512, PNG mit Alpha) —
    Kreisfoermiger Glow-Ring. Heller Amber-Gold-Ring (`#FFC83D` Kern), faded
    sanft nach innen UND aussen in Transparenz. Subtle Inner-Highlight-Rim.
    Ring sitzt zentriert.
15. **`assets/lumo_cards/fx/impact_burst.png`** (512×512, PNG mit Alpha) —
    Radial-Burst-Pattern: 16 weisse Licht-Strahlen emanieren von einem hellen
    Zentrum, faden nach aussen in Transparenz. Zentrum sehr hell cream/weiss
    mit milder Gelb-Toenung. Wie ein Kamera-Blitz.

### Kategorie D: UI-Elemente (4 Bilder)

16. **`assets/lumo_cards/ui/toast_success.png`** (600×120, PNG opaque) —
    Langer horizontaler Banner. Gruener Verlauf (`#22C55E` -> `#15803D`), leicht
    glossy 3D-Oberflaeche mit subtle Rim Light oben. Abgerundete Ecken. KEIN
    Text.
17. **`assets/lumo_cards/ui/toast_warning.png`** (600×120) — Gleicher Banner
    aber Amber-Verlauf (`#FBBF24` -> `#D97706`).
18. **`assets/lumo_cards/ui/toast_info.png`** (600×120) — Gleicher Banner aber
    Cyan-Blue-Verlauf (`#38BDF8` -> `#0284C7`).
19. **`assets/lumo_cards/ui/action_button_orange.png`** (256×256, PNG mit
    Alpha) — Glossy runder Button. Orange-Verlauf (`#FF7A2F` -> `#C2410C`),
    3D-Dom mit subtle Highlight oben, weicher Amber-Glow-Halo aussen, milder
    Inner Shadow unten. Zentriert. KEIN Text.

### Kategorie E: Bot-Persoenlichkeit-Avatare (3 Bilder, je 512×512, PNG mit Alpha)

Head-and-shoulders Portrait. Selber Cartoon-3D-Stil wie Lumo-Fuchs fuer
visuelle Konsistenz.

20. **`assets/lumo_cards/avatars/bot_luna_owl.png`** — Freundliche Eule mit
    violetten Federn. Runde weise Augen (golden Amber), kleiner Schnabel im
    ruhigen Laecheln, weiche Federn in `#7C3AED` und Creme. Kopf leicht
    geneigt, als wuerde sie nachdenken.
21. **`assets/lumo_cards/avatars/bot_pudding_frog.png`** — Freundlicher
    gruener Frosch. Grosse runde Augen mit warmem Funken, breites freundliches
    Laecheln, glatte Mint-gruene Haut (`#10A894`) mit cremiger Bauch sichtbar.
    Leicht naiver aber charmanter Ausdruck.
22. **`assets/lumo_cards/avatars/bot_dusty_rabbit.png`** — Freundlicher
    sandfarbener Hase. Lange aufgerichtete Ohren, helle energetische Augen,
    kleine pinke Nase, zwei vordere Zaehne leicht sichtbar im verspielten
    Grinsen. Warmes Beige (`#FFC83D` mit Creme) mit dunkleren Braun-Akzenten.

### Kategorie F: Intro-Hintergrund (1 Bild)

23. **`assets/lumo_cards/ui/intro_backdrop.png`** (1920×1080, PNG opaque) —
    Traum-Hintergrund tief-violett mit subtilem Sternenfeld. Warmes Spotlight
    unten in der Mitte (wie eine Buehne). Milde Lens Flares verstreut. Kuschelig,
    magisch, premium. KEINE Charaktere, KEIN Text.

## Anweisungen fuer dich, ChatGPT

1. **Generiere jedes der 23 Bilder einzeln** mit deinen Image-Generation-Tools
   (DALL-E falls verfuegbar). Verwende fuer jedes Bild den Style Guide oben +
   den spezifischen Prompt + die Aufloesung.

2. **Pruefe nach jedem Bild:**
   - Hintergrund tatsaechlich transparent (bei den PNG-mit-Alpha-Items)?
     Wenn nicht: regenerate mit explizitem "transparent PNG, alpha channel".
   - Kein Text/Logo/Buchstabe drin?
   - Cartoon-3D-Stil eingehalten (kein Foto-Realismus)?
   - Wenn ein Bild deine Filter ausloest, beschreibe nur und ersetze mit
     Platzhalter — der Rest soll trotzdem generiert werden.

3. **Bei Code Interpreter / Advanced Data Analysis aktiv:**
   - Speichere alle generierten Bilder im richtigen Ordner-Layout
     (`assets/companion/...`, `assets/lumo_cards/table/...` etc.)
   - Packe alles zu einer ZIP-Datei `lumo_assets_pack.zip`
   - Stelle die ZIP als Download bereit
   - Liste am Ende ALLE Dateinamen + Pfade in der ZIP (Inhalts-Verzeichnis)

4. **Wenn Image-Generation NICHT verfuegbar in deiner Session:**
   - Erstelle stattdessen eine `prompts.txt`-Datei mit pro Asset einem
     fertigen Image-Prompt (Style Guide + Asset-spezifisch zusammengefuegt),
     den ich in Midjourney/Stable Diffusion verwenden kann
   - Packe NUR diese Text-Datei in eine ZIP
   - Sag mir klar: "Image-Generation nicht verfuegbar — hier sind die Prompts
     zum manuellen Generieren."

5. **Lizenz-Check am Ende:** kurz erinnern welche Bild-KI das ist und ob die
   generierten Bilder kommerziell verwendbar sind (Midjourney/Plus-DALL-E =
   ja, Bing Image Creator = nur privat).

## Was ICH am Ende erwarte

- Eine ZIP-Datei zum Download (`lumo_assets_pack.zip` oder aehnlich)
- Inhalts-Verzeichnis der enthaltenen Dateien
- Knapper Lizenz-Hinweis
- Wenn du Probleme hast (Filter, Limit, Style): klare Notiz pro Asset welches
  du NICHT liefern konntest und warum

Generiere jetzt, ZIP zum Schluss. Danke.

# ===== ENDE MEGAPROMPT =====

---

## Realistische Erwartungen

- **ChatGPT Plus mit GPT-4o** kann pro Konversation ca. 15-40 DALL-E-Bilder
  generieren bevor das Rate-Limit greift. Wenn du 23 willst, klappt das meist
  in einer Session. Bei Limit: in 1-2 Stunden weitere Bilder nachgenerieren.
- **GPT-5 Thinking** ist primaer ein Reasoning-Modell und hat oft KEINE
  Image-Generation. Dann liefert dir der Megaprompt die `prompts.txt` (Fall 4
  oben) und du nutzt Midjourney/SD selbst.
- **ChatGPT Free / o4-mini** hat oft keine Image-Generation. Plus oder Pro
  abonnieren oder direkt Midjourney/SD.
- **Code Interpreter / Advanced Data Analysis** muss aktiviert sein damit
  ChatGPT eine ZIP-Datei packen kann. Bei Plus-Account: in der Chat-Toolbar
  oben links Modell-Picker -> "ChatGPT 4o" oder "ChatGPT 5" -> Tools/Mode
  aktivieren.
- **Wenn die ZIP-Funktion nicht klappt:** ChatGPT bittet dich pro Bild einzeln
  zu downloaden. Geht auch — landest du am Ende mit 23 Files manuell im Repo.

## Nach dem Download

```bash
# In das Repo wechseln
cd lumo-lernen

# ZIP entpacken - Pfade matchen 1:1 dem Repo-Layout
unzip ~/Downloads/lumo_assets_pack.zip

# Pruefen was reingekommen ist
git status

# Wenn alle Files am richtigen Platz: committen
git add assets/
git commit -m "feat(assets): KI-generierte Lumo-Assets eingebunden"
git push origin <dein-branch>
```

Beim naechsten CI-Build sind alle Assets im APK. Die App nutzt sie automatisch
ueber `Image.asset(...)` mit `errorBuilder`-Fallback — wenn ein Asset noch
fehlt, faellt sie auf die gezeichnete Variante zurueck (kein Crash).

## Wenn du das Briefing erweitern willst

Asset-Liste in diesem Doc bearbeiten, neues Asset nach demselben Muster ergaenzen
(Pfad + Aufloesung + Prompt + Format), dann den Megaprompt nochmal komplett an
ChatGPT geben.
