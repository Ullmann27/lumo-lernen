# Core: Aufgabenbindung beim Layoutwechsel

Basis ist der separat geprüfte Dialogfix `fd4a1eea31bcf1aeff41086e3e739da1136933d2`.
Der unveränderte Stand verliert im echten AppShell-Pfad bei 430→1000 dp während
des eigenen Gesprächs den Core-State, erzeugt eine andere Aufgaben-ID und leert
den Bus. Genau dieser einzelne Fall ist in `red.log` samt damaliger Testdatei
und Provenienz erhalten.

Ein zusätzlicher GlobalKey hält ausschließlich den Core-Inhaltssubtree beim
Wechsel zwischen den beiden AppShell-Elternbäumen fest. Der vorhandene fachliche
ValueKey bleibt in Wert und Aufgabe unverändert. Echte Abschnitts-/Aufgabenwechsel
erhalten einen neuen äußeren Schlüssel; eine noch ausblendende alte Section
wird deshalb nicht mit einer neu geöffneten Aufgabe vermischt.

Gezieltes GREEN: 1/1. Gemeinsamer enger Lauf: **15/15**, einschließlich der
bisherigen 14 Dialog-/Core-/Header-/Navigationsprüfungen. Analyse: keine Probleme.
Die Läufe überlappen. Die Hashes in `source.json` belegen die getesteten Bytes
im Arbeitsbaum vor dem Zusatzcommit. Rohe Logs bleiben einschließlich Leerzeichen
unverändert. Kein Android-/Fold-Scharnier-/Darstellungsnachweis wird behauptet.
