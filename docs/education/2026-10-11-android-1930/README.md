# Lumo Lernen Neu: integrierte Testversion 1930

Dieser eigene Integrationsbranch bündelt den bestehenden geprüften Lumo-Stand.
Er ist keine Fertigmeldung für die Lern-App und keine Freigabe für Google Play.
Der Bau und die neue Android-Laufzeitprüfung sind beim Anlegen dieses Meilensteins
noch nicht abgeschlossen; ihre tatsächlichen Ergebnisse folgen in den Artefakten.

## Zusammenführung ohne Projektneustart

- **Basis:** `9b8b7c86b4b4137c625d2e4fa727a9669a4962f5` mit kostenloser lokaler
  F2-Stimme, den originalen Sulafat-Aufnahmen, geschützten Schreib-/Lernständen,
  aktiven Aufgabenereignissen, Unterricht und getrennten Entdeckungen.
- **Nachhilfe und Bestandsschutz:** `a306374c92344b3801cc2a26576bd8d1722dca4b`.
  Echte Empfehlungen, Profil-Leases, sichere Fehlerbehandlung, Wiederholung
  tatsächlicher Speicherungen und keine Überschreibung beschädigter Daten.
- **PR #263:** Die Laufzeitmodule und Uhrzeitkorrekturen sind bereits durch
  `73028f1e9e14c55881dd826d5e6abae52a936148` enthalten. Die neueren Ergänzungen
  für Lernereignisse, Erklärungshilfen und Kursnavigation bleiben erhalten.
- **PR #260:** Nur die sechs abgeschlossenen Marktstart-Dokumentationscommits
  werden übernommen. Kein Rückschritt auf dessen ältere Codebasis,
  keine automatische Datenschutzfreigabe, keine echte Zahlung oder Veröffentlichung.
- **Godot:** `853175c634dcb62c325fbd9b272e2ebc791830ad` enthält als getestete,
  vier Commits vorausliegende Kette Menü, Fixture-Bereinigung und Lenkradkontakt
  ([geprüfter Godot-PR #57](https://github.com/Ullmann27/lumo-godot/pull/57)).
- **Parallelentwicklung:** Ungesicherte Cards-/Gegnerarbeiten anderer Checkouts
  werden weder kopiert noch überschrieben. Die bestehende Spielewelt bleibt erhalten.

## Geplanter tatsächlicher Build und Prüfpfad

Version `0.12.23+1930`, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`,
separate Variante „Lumo Lernen Neu“, gleiche bestehende Testsignatur. Eine
ARM64-APK und eine x86_64-Prüf-APK werden zusammen aus exakt demselben Commit gebaut.
Das vorhandene Skript prüft native Bibliotheken, Godot-Pin, Modell-/Clip-Hashes,
Android-16-Kompatibilität, 16-KiB-ELF- und Ressourcen-Ausrichtung.

Die vollständige Flutter-Suite läuft einmal über den exakten PR-Head. Das
APK-Workflow wiederholt sie nicht, führt aber native Bauprüfungen, bestehende
Python-/Backend-Prüfungen und den Inhaltsaudit aus. Die finale ZIP wird nur bei
tatsächlich erfolgreicher kompletter CI und Android-Prüfung erzeugt.

Die unabhängige Android-Prüfung verwendet die bestehende APK 1929 als Baseline
([ursprünglicher Build](https://github.com/Ullmann27/lumo-lernen/actions/runs/38132054824)).
Sie installiert das Update ohne Deinstallation, bewahrt das tatsächliche fiktive
Testprofil und prüft native Offline-Synthese, Wiedergabe, Pause/Fortsetzen/Stopp,
Elterneinstieg sowie tatsächliches Godot-Menü und Rückkehr.

Anschließend werden beide vollständigen realen Lernkurse durch tatsächliche
Antworttaps, Fehler, Hinweise und lokale Elternwahl geprüft. Reguläre Antworten
werden genau einmal gespeichert. Höherklassige Entdeckungen dürfen weder die
Schulklasse noch regulären Fortschritt oder Lernwallet verändern. Neustart
muss beide Lernwege und Freigaben unverändert erhalten.

## Grenzen und Fortsetzung

Physisches Samsung, echtes Scharnierverhalten, ARM64-Hörprüfung, menschliche
Stimmabnahme, vollständiger Rennablauf, komplette Lehrplan-/Fachabnahme,
Erwachsenen-/Datenschutzprüfung und kommerzielle Sprachmodell-Lizenz bleiben offen.
Der Teststatus wird aus echten Protokollen übernommen, nicht aus der bloßen
Existenz dieses Dokuments oder aus einer höheren Testschrittzahl.

Bei einem erneuten reinen Prüf-Navigationsfehler wird nur der Prüfhelfer repariert
und dieselbe bereits gebaute APK nachgeprüft. Kein unnötiger Neubau.
Keine Main-Merges, echten Kinderprofiländerungen, kostenpflichtigen Sprachabfragen,
öffentliche Veröffentlichung oder Aktivierung echter Zahlungen.

## Tatsächlich isolierter Android-Prüfhelferfehler

Die APK aus `5f3a47a676477ddaec05c11e31311001a015cb11` wurde erfolgreich gebaut;
ihre vollständige CI hat 1.272 bestandene und 115 optionale übersprungene Tests
([exakter CI-Lauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38147913894)).
Die native Prüfung hat Update 1929→1930, erhaltenes Testprofil und Wallet,
Offline-Synthese, Pause/Fortsetzen/Stopp, Elternbereich, Godot-Menü und Rückkehr
bestanden, ist aber anschließend in der Navigation zum Lernkurs abgebrochen
([tatsächlicher Android-Lauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38147910017/job/114496762865)).

Die unveränderte gespeicherte Hierarchie zeigt die Ursache: „Lernen“ im Logo
liegt bei `[31,109][113,135]` und ist `clickable=false`; die tatsächliche
Navigation bei `[47,230][121,298]` ist `clickable=true`. Der alte Helfer hat
zuerst das kleinere Textrechteck gewählt und danach die nicht bedienbare
Überschrift angetippt. Das anschließende echte Laufzeitbild zeigt weiterhin
den Startbildschirm. Dies ist keine bestandene Kursprüfung.

Nur der neue Kurs-Prüfhelfer wird korrigiert: Ausgewählt werden ausschließlich
aktuelle, aktivierte, anklickbare App-Knoten mit exaktem zugänglichem Text
und gültigen Bounds. Die Originalhierarchie ist als fiktive Testdatenfixture
gesichert. Der runtime-only Workflow prüft, dass keine App-, Modell-, Asset-,
Signatur- oder Verpackungsdateien gegenüber der gebauten Quelle verändert wurden.
Er prüft dieselbe APK nach, ohne Neubau oder künstlich eingespeiste Lernfortschritte.
Sein vollständiges Laufzeitergebnis ist bei diesem Reparaturcommit noch offen.

Die erneute Laufzeitprüfung bestätigt den reparierten Einstieg, die erste echte
Antwort und die Erklärung „Sieben und fünf“ samt Player-Pause/Fortsetzen
([erneuter Android-Lauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38149620562)).
Der nächste Abbruch ist ebenfalls konkret eingegrenzt: Die Antwort `1` ist in der
gespeicherten aktuellen Hierarchie tatsächlich als `1, richtig` markiert.
Rückmeldung und Weiter-Taste liegen jedoch unterhalb des sichtbaren Ausschnitts.
Der Prüfer hat `Weiter` als Teil von `Weiterkommen` im Logo akzeptiert und danach
eine noch nicht sichtbare Rückmeldung geprüft.

Der Helfer verlangt jetzt gleichzeitig im aktuellen echten Frame die als richtig
markierte abgegebene Antwort, die korrekte Rückmeldung und eine aktivierte
Weiter-Taste. Er scrollt ausschließlich innerhalb des aktuell beobachteten
App-Viewports. Getrennte alte Frames werden nicht zusammengemischt.
Ein weiterer native-only Nachtest derselben APK ist erforderlich; ein kompletter
Kursabschluss wird weiterhin nicht behauptet.
