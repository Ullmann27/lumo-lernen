# ChatGPT-Megaprompt — Lumo-Lernen Uebersetzung DE → EN / TR / BS

**Workflow:** Du laedst die Quell-Datei [`lib/l10n/app_de.arb`](../lib/l10n/app_de.arb)
in eine neue ChatGPT-Konversation hoch (Anhang / Drag-and-Drop) und kopierst
den **Block zwischen `===== ANFANG =====` und `===== ENDE =====`** in den Chat.
ChatGPT erstellt 3 uebersetzte ARB-Files und packt sie in eine ZIP.

**Aktivieren:** Code Interpreter / Advanced Data Analysis (fuer ZIP-Packing).

**Wichtig:** Datei `app_de.arb` hochladen BEVOR du den Prompt schickst.

---

## ===== ANFANG MEGAPROMPT (alles kopieren) =====

Hallo ChatGPT. Ich habe dir gerade die Datei `app_de.arb` hochgeladen — das
ist die deutsche Quell-Sprachdatei meiner Flutter-Kinder-App **Lumo Lernen**
(Klasse 1-2 Oesterreich) im Standard-Flutter-ARB-Format. Du sollst sie
**in 3 Sprachen uebersetzen**:

1. **Englisch** (en) — britische Schule-Variante
2. **Tuerkisch** (tr) — Standardtuerkisch, schulkindgerecht
3. **Bosnisch** (bs) — Latinica, schulkindgerecht

## Regeln

1. **Schluessel NICHT veraendern.** Jeder Schluessel im Output-ARB muss
   exakt dem Schluessel in der Quelle entsprechen (gleicher
   camelCase-Name).

2. **Metadaten-Eintraege** (alle Schluessel die mit `@` beginnen wie
   `@@locale`, `@cardsIntroTitle`, etc.) **unveraendert uebernehmen**.
   Nur den Wert von `@@locale` auf die Ziel-Locale setzen
   (`en` / `tr` / `bs`).

3. **Placeholder syntax beibehalten.** Wenn ein deutscher String
   `{player}`, `{count}`, `{streak}`, `{color}`, `{number}` oder
   `{hint}` enthaelt, MUSS der uebersetzte String denselben Placeholder
   in geschweiften Klammern enthalten — auch wenn die Wortstellung
   anders ist. Beispiel:
   - DE: `"Du bekommst {count} Sterne!"`
   - EN: `"You get {count} stars!"`
   - TR: `"{count} yıldız kazandın!"`
   - BS: `"Dobijaš {count} zvjezdica!"`

4. **Marken-Namen NICHT uebersetzen:** `LUMO CARDS`, `LUMO!`, `Lumo`
   (Fuchs-Maskottchen), `AI Luna`, `AI Pudding`, `AI Dusty` — die
   bleiben in allen 3 Sprachen identisch zur Quelle.

5. **Ton:** kinderfreundlich, ermutigend, Klasse-1-2-Niveau. Keine
   Buerokraten-Sprache. Im Englischen die du/dich-Adressierung als
   informelles `you` belassen — kein Sie/Mr./Mrs.

6. **Tuerkisch + Bosnisch:** Schul-Standard, einfache Worte, lateinische
   Schrift fuer beide. Tuerkisch mit korrekten Umlauten (ı, ö, ü, ç, ş,
   ğ). Bosnisch in Latinica (š, č, ć, ž, đ).

7. **Zeilenumbrueche (`\n`) und Sonderzeichen** wie `–` (en-dash) und
   `…` (Ellipsis) in der Uebersetzung beibehalten oder sprach-typisch
   ersetzen — wenn ersetzen, dann sprachlich konsistent.

8. **`description`-Felder in den Metadaten** muessen NICHT uebersetzt
   werden — sie bleiben Englisch wie in der Quelle (sind nur fuer
   Entwickler).

## Ausgabe-Format

Erstelle 3 Dateien:

- `app_en.arb` — Englisch-Uebersetzung
- `app_tr.arb` — Tuerkisch-Uebersetzung
- `app_bs.arb` — Bosnisch-Uebersetzung

Jede Datei muss **valides JSON** sein (parse + re-serialize zum Pruefen),
mit:
- `@@locale` auf der jeweiligen Ziel-Locale
- ALLE Schluessel aus der Quelle uebersetzt (kein Schluessel weglassen)
- Metadaten-Eintraege (`@xxx`) uebernommen wie sie sind

## Was du tun sollst

1. Parse die hochgeladene `app_de.arb`.
2. Erstelle die 3 uebersetzten Versionen unter Beachtung aller Regeln oben.
3. Validiere jede mit `json.loads()` bevor du sie speicherst.
4. Packe alle 3 in eine ZIP-Datei `lumo_translations.zip` mit Layout:
   ```
   lumo_translations.zip
   ├── lib/l10n/app_en.arb
   ├── lib/l10n/app_tr.arb
   ├── lib/l10n/app_bs.arb
   └── TRANSLATION_NOTES.md
   ```
5. In `TRANSLATION_NOTES.md` schreibe:
   - Anzahl uebersetzter Strings pro Sprache (muss bei allen gleich
     sein wie in der Quelle)
   - Eventuelle Schwierigkeiten / Mehrdeutigkeiten in der Quelle
   - Liste der Marken-Namen die unveraendert geblieben sind
   - Datum der Uebersetzung
6. Stelle die ZIP zum Download bereit.

## Bestaetige + leg los

Bestaetige in 1 Satz dass du `app_de.arb` empfangen hast und die Aufgabe
verstanden hast, dann uebersetze alle 3 Sprachen und liefere die ZIP.
Bei Unklarheiten in der Quelle (z.B. mehrdeutiges deutsches Wort):
nimm die kindgerechte Variante und notiere die Entscheidung in
`TRANSLATION_NOTES.md`. Stop nicht in der Mitte — wenn ein Rate-Limit
kommt, signalisiere und liefere was du hast.

Danke.

## ===== ENDE MEGAPROMPT =====

---

## Nach dem Download

```bash
cd lumo-lernen
unzip ~/Downloads/lumo_translations.zip
git add lib/l10n/
git commit -m "feat(i18n): EN/TR/BS Uebersetzungen via ChatGPT"
git push
```

Beim naechsten Build sind die ARB-Files im Repo. Der **Code-Refactor** (alle
hardcoded deutschen Strings durch `AppL10n.of(context).xxx` ersetzen +
`flutter_localizations` als Dependency aufnehmen) ist ein separater PR,
weil er ueber alle Dart-Dateien geht — der kommt wenn du die Uebersetzungen
einbinden willst.

## Was du jetzt hast

| Datei | Zweck |
|---|---|
| `lib/l10n/app_de.arb` | **70 deutsche Quell-Strings** als Flutter-ARB. Single Source of Truth. |
| `l10n.yaml` | Config fuer `flutter gen-l10n` (Aktivierung in spaeterem PR) |
| `docs/chatgpt_translation_megaprompt.md` | Dieser Megaprompt - kopier ihn + lade `app_de.arb` hoch und schick ChatGPT |

## Wenn du spaeter mehr Strings willst

Editiere `lib/l10n/app_de.arb`, fuege neue Schluessel hinzu nach dem Muster:

```json
"meinNeuerSchluessel": "Mein neuer deutscher Text",
"@meinNeuerSchluessel": {
  "description": "Wo wird das verwendet"
}
```

Dann den Megaprompt nochmal an ChatGPT mit der erweiterten Datei — er
liefert die 3 aktualisierten Uebersetzungen.
