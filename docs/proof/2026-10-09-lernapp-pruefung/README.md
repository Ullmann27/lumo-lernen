# Belege zum Lernapp-Prüfbericht (9. Oktober 2026)

Zum Bericht `docs/LERNAPP_PRUEFBERICHT_2026-10-09.md`. Rohmaterial der beiden Prüfer, die geliefert haben.

- `denktest/` – Prüfer 3 (Knobel-Test und Denkprofil): `README.txt`, Läufe (`*_audit_log.txt`) und die Skripte
  `scripts/zz_audit_*.dart.txt`. Die Skripte sind absichtlich als `.txt` abgelegt, damit `flutter analyze` sie
  nicht mitprüft. Zum Wiederholen: in einen Arbeitsbaum kopieren, nach `test/zz_audit_*.dart` umbenennen und mit
  `dart run -DN=300 test/zz_audit_iq_gen.dart` starten. Die Simulationen (`zz_audit_iq_sim`) beruhen auf einem vom
  Prüfer angenommenen Antwortmodell, die Generator-Prüfungen (Eindeutigkeit der Lösung) nicht.
- `wettbewerb/` – Prüfer 6: Code-Belege (`01`), Markt, Evidenz und Eltern mit Quellen (`02`), USP-Kandidaten und
  MVP (`03`), Endbericht mit vollständiger Quellenliste (`04`). Marktangaben stammen aus Websuche, nicht aus einem
  App-Audit; Preise teils aus Drittquellen.
- `importgraph_reach.py` – Importgraph ab `lib/main.dart`
  (`python3 -I docs/proof/2026-10-09-lernapp-pruefung/importgraph_reach.py`): 315 von 315 Dateien erreichbar.

Nicht enthalten: die Berichte der vier abgebrochenen Prüfer (Lerninhalt/Lehrplan, Fuzzing, Grafik,
Fehler/Datenschutz), siehe Abschnitt 6 des Berichts.
