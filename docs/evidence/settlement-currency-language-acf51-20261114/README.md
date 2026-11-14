# Siedlung: Singular bei genau einer Münze

## Tatsächlicher Befund

Die frisch gelesene Quelle ist Native `acf51d3bd2997c4b731e9a48e1791e05e756a132`. Der GitHub-Gitblob von `scripts/creative/build_settlement_world.gd` ist `a4c55b4daba91f19b5cd8f846cdb62f9a727466c`; die heruntergeladenen Originalbytes stimmen mit diesem Blob überein.

Die aktuelle Originalaufnahme `nextgen-evidence/nextgen/captures/build_settlement_play_regression/06_settlement_relocation.png` wurde tatsächlich geöffnet und mit demselben ZIP-Mitglied verglichen. Sie zeigt bei 388×390: „Du erhältst 4 Holz, 3 Stein, 1 Münzen zurück.“ Quelle, Originalarchiv und Bildhash stehen in `source-binding.json`. Das Originalbild wird nicht dupliziert.

## Minimale Korrektur

`_cost_text(cost)` verwendet für `coins` bisher unabhängig von der Menge die Beschriftung `Münzen`. Der Rückerstattungsdialog ruft genau diesen Formatter mit `quote.refund` auf. Die Ergänzung wählt ausschließlich bei `resource == "coins"` und der bereits verwendeten ganzzahligen Menge 1 die Beschriftung `Münze`. Bei allen anderen Mengen bleibt `Münzen` erhalten. Holz, Stein, Essen, Zahlen, Reihenfolge, Kommas, Kosten, Rückerstattung und Speicherzustände bleiben unverändert. Derselbe bereits vorhandene Formatter wird auch für Baupreise/Produktion/Handel verwendet, weshalb dort ebenfalls genau diese Singularbildung gilt.

Es gibt nur eine zu integrierende Source-Datei. Die aktive Nativekopie, Root-/C-Pakete, Regeln, Saves, Pins, Receipts und Gitrefs wurden nicht verändert. Nach Rücknahme genau dieses einen Hunks sind sämtliche Sourcebytes identisch zur veröffentlichten Basis.

## Abnahmegrenze

Dieser Auftrag verlangte den isolierten Sprachpatch ohne zusätzliche Spiegel-Unit-Tests. Es wurde keine neue Engineausführung, keine neue Testreihe und keine neue Aufnahme gestartet. Der vorhandene echte Settlement-Capture wird im nächsten gemeinsamen Native-Lauf erneut ausgeführt. Dieser Stand ist deshalb ein präzise gebundener Sourcefix und **noch kein neuer Renderer-PASS**.
