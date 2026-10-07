# Lumo-Stimme – drei Varianten (7. Oktober 2026)

Alle drei Proben sprechen dieselben Texte: Begrüßung, Mathe-Erklärung (8 + 5 über die Zehn),
Ermutigung nach einem Fehler. Erzeugt offline mit Piper-Neuronalstimmen (Lizenz CC0) und
Cartoon-Nachbearbeitung (Formant-/Tonhöhenanhebung, Präsenz-EQ, Lautheit −16 LUFS).
Generator: `tools/voice/lumo_voice_gen.py samples <ordner>`.

| Datei | Varianten-Idee |
|---|---|
| lumo_stimme_a_hell.m4a | A – heller Fuchs: weibliche Stimme (Kerstin), leicht angehoben, klar |
| lumo_stimme_b_verspielt.m4a | **B – verspielter Cartoon-Fuchs (Standard)**: derselbe Sprecher (Thorsten) fröhlich bei Begrüßung/Lob, klar beim Erklären und Trösten; +5 Halbtöne, davon 2,5 als jüngerer Stimmklang |
| lumo_stimme_c_erzaehler.m4a | C – ruhiger Erzähler-Fuchs: warm und tiefer, am wenigsten Cartoon |

## Objektive Prüfung (`tools/voice/voice_eval.py`)

Wortfehlerrate per Spracherkennung (Whisper small, Deutsch) gegen den Solltext, Tempo,
mittlere Tonhöhe und Tonhöhen-Spannweite (Ausdruck).

| Datei | Wortfehler | Wörter/min | Tonhöhe | Spannweite |
|---|---|---|---|---|
| lumo_stimme_a_hell.m4a | 7.6 % | 145 | 197 Hz | 92 Hz |
| lumo_stimme_b_verspielt.m4a | 1.5 % | 156 | 170 Hz | 112 Hz |
| lumo_stimme_c_erzaehler.m4a | 1.5 % | 157 | 141 Hz | 75 Hz |

Die Wortfehlerrate dieser Tabelle stammt aus einer früheren Metrik, die Ziffern nur teilweise
normalisierte; Zahlwörter wie „acht“ vs. „8“ zählen dort teils noch als Fehler.

**Entscheidung:** B wird Standard, weil sie bei guter Verständlichkeit die lebendigste Satzmelodie
hat und durchgehend dieselbe Figur bleibt. A ist die Alternative, falls Lumo weiblicher klingen
soll. Die Wahl ist hörend noch nicht von Heinz bestätigt; ich (Claude) kann die Proben nicht
selbst anhören und habe nur gemessen.

## In der App

- 227 feste Sätze (Lob, Trost, Begrüßung, Plus/Minus/Mal-Aufgaben der Module) liegen als
  vorproduzierte Clips in `assets/audio/voice/lumo/` (4,9 MB, AAC 64 kbit/s mono) mit Katalog
  und Lautstärke-Hüllkurve für Lumos Mund.
- Jeder Clip hat das Qualitätstor bestanden (bis zu 8 Takes, Whisper-Wortfehler ≤ 30 %).
  „Tipp:“ und „Testmodus. Lies ruhig …“ bestanden nicht und bleiben bei der Geräte-Stimme.
- Alle anderen Texte (Aufgaben, KI-Antworten) sprechen weiterhin über die Geräte-Sprachausgabe
  (Offline-Fallback). Stumm, Stopp, Seitenwechsel und App-Hintergrund beenden beide Wege.
- Musik wird während Lumo spricht auf 0,16 abgesenkt (250 ms) und danach in 600 ms
  wieder auf 0,55 angehoben.
