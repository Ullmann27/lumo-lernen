# Core: Aufgabenbindung im eigenen Gespräch

Basis: `b49cf9c7e1e60c4e3901883d1c6bfc4a46e9ede4`.

Der echte AppShell-Header öffnete bisher ein allgemeines Modal. Core behandelte
dieses eigene Gespräch wie eine fremde Seite und löschte seinen Aufgaben-Snapshot.
Der unveränderte Produktstand scheitert in `red.log` an der erwarteten Aufgaben-ID.
`red-test.dart.txt` und `red-provenance.json` bewahren den damaligen Test und die
konkreten Quellhashes. Die beiden vorausgehenden Harnessfehler sind separat in
`red-first.log` und `red-shader-setup.log` erhalten; sie sind kein Produkt-RED.

Die Shell delegiert über eine kleine UI-Schnittstelle an den aktuellen Core-Owner.
Dieser nutzt die vorhandene eigene Conversation-Route und hält seine Bindung nur
für dieselbe taskId, SessionScope und tatsächlich vorderste eigene Modalroute.
Fremdrouten entziehen sie weiterhin. Ein alter Owner kann die neue Header-Bindung
nicht lösen. Nach vollständigem Dialogabbau wird die sichtbare Aufgabe neu
veröffentlicht und der benötigte Frame ausdrücklich angefordert.

`joined-green.log`: **14/14 bestanden**, davon drei neue Dialogtests und elf
bestehende Core-/Header-/Navigationsprüfungen. `analyze.log`: keine Probleme.
Die früheren Einzelläufe überlappen und werden nicht addiert. Der gemeinsame
Lauf erfolgte im veränderten Arbeitsbaum vor dem Producer-Commit; `source.json`
belegt exakt diese Produkt-/Testbytes. Ein erster Analyzerlauf mit zwei
anschließend korrigierten Stilhinweisen bleibt in `analyze-initial.log`.

Die neue Regression verwendet echte Widget-/Dialog-/Fachcodepfade, aber kleine
synthetische Artwork-/JSON-Antworten und SDK-Schriften. Sie ist kein optischer
Abnahmebeleg. Kein Androidlauf, echte Spracherkennung oder Audioerfolg wird
behauptet. Die vorhandenen IDs, ValueKeys, Wertung, Belohnungen und Prüfungsgrenzen
bleiben erhalten; kein Nativepin oder Freigabegate wurde geändert.
