Prüfer 3 (Denk-/IQ-Test), Arbeitsbaum /home/user/aud-a3 (Commit b04bee5, detached, nichts committet).
Skripte (Kopien) in scripts/; Original-Ort im Arbeitsbaum: test/zz_audit_*.dart (untracked, nicht committen).
Aufruf (Umgebung: export PATH=/opt/flutter-3449/flutter/bin:$PATH PUB_CACHE=/opt/pub-cache):
  dart run -DN=300 test/zz_audit_iq_gen.dart     # Generator: Regel-Löser, Mehrdeutigkeit, Ratestrategien   -> gen_audit_log.txt
  dart run -DS=1500 test/zz_audit_iq_sim.dart    # Sitzungen, Messgenauigkeit, Farbsehen, Dopplungen        -> sim_audit_log.txt
  dart run test/zz_audit_cog.dart                # Denkprofil-50: Platzhalter, Antwortschlüssel             -> cog_audit_log.txt
  dart run test/zz_audit_coach.dart              # Wirkung auf Lumo-Coach (Lernanalyse)                     -> coach_audit_log.txt
  dart run test/zz_audit_factory.dart            # Coach-Start „IQ-Rätsel“ -> welche Aufgaben?              -> factory_audit_log.txt
  dart run test/zz_audit_size.dart               # Stufe 8 Größe vs. Anzahl                                  -> size_audit_log.txt
  dart run test/zz_audit_diff.dart               # Schwierigkeits-Proxys, Aufgabenvielfalt                   -> diff_audit_log.txt
  flutter test test/iq/iq_puzzle_generator_test.dart test/cognitive_profile_test.dart test/lumo_tests_screen_test.dart  -> targeted_tests.txt (23 Tests grün)
