# Kleine deutsche Cards-Anredekorrektur auf 4ab

Die tatsächlich gesichtete Meldung `Du fängt an.` entsteht im Controller beim Zusammenfügen des vorhandenen Anzeigenamens mit der dritten Person. Genau die vorhandene Anrede `Du` erhält nun `Du fängst an.`; Kindnamen und `Spieler 1` bleiben bei `… fängt an.`. Die sichtbaren Startmeldungen und die entsprechende Pass-and-Play-Begrüßung verwenden dieselbe lokale Meldung. Die Bot-Begrüßung war bereits korrekt.

**Eine geänderte Produktdatei:** `lib/features/games/lumo_cards/lumo_cards_game_controller.dart`. Keine neue Spielmechanik, kein Saveformatwechsel und keine neue Texttest-Suite. `lib/l10n/app_de.arb` wurde gelesen und bleibt unverändert: Der betreffende Controllerpfad verwendet direkte deutsche Strings; der ARB-Namenplatzhalter wird dafür nicht aufgerufen.

Die Originaldatei wurde über GitHub am vollständigen Commit `4ab96666f954baf258422d6ed277fc297b7ddeef` gelesen, bytegleich mit der vorhandenen Kopie verglichen und an Git-Blob `6b6b22504cc0ff431cf03d4f3496b296282d24b4` gebunden. Alle 444 in der isolierten Testumgebung gemeinsam gelesenen Bibliotheks-/Test-/Pubspec-Dateien entsprechen vor und nach dem Lauf ihren veröffentlichten 4ab-Blobs. Nur der geänderte Controller wurde im separaten Package-Root ersetzt.

**Tatsächlich ausgeführt:** fünf vorhandene Controller-Lifecycletests und sieben vorhandene Persistenztests: **12 PASS, 0 Skip, Exit 0**, Gesamtaufruf 11,540 s. Flutter 3.44.9 / Dart 3.12.2; `--no-pub --no-test-assets`. Die Tests prüfen unter anderem Pausen, Neustart, Wiederaufnahme, Phasenerhalt, getrennte Kinderslots und Belohnungs-Deduplizierung. Sie sind keine neue Android-Bildabnahme.

Der erste Setupaufruf endete vor der Testausführung, weil im isolierten Verzeichnis die erforderliche vorhandene `package_graph.json` fehlte. Dieser Fehlerlog bleibt erhalten. Nach bytegleichem Kopieren genau dieser Cachedatei bestand der unveränderte Testaufruf; keine Produktabhängigkeit oder Testanforderung wurde geändert.

Vorhandene gespeicherte Aktionsmeldungen werden nicht umgeschrieben; die korrigierte Startmeldung entsteht beim Start einer neuen Runde. Der aktive Root-Controller sowie das eingefrorene 187-Dateien-Dokumentationsmanifest sind unverändert.
