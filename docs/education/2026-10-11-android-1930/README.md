# Lumo Lernen Neu: integrierte Testversion 1930

Dieser eigene Integrationsbranch bündelt den bestehenden geprüften Lumo-Stand.
Er ist keine Fertigmeldung für die Lern-App und keine Freigabe für Google Play.
Die Testversion ist gebaut. Der vollständige Android-16-Nachtest und das geprüfte
Download-ZIP sind abgeschlossen; Quellzuordnung, Ergebnisse und Download stehen
im Abschlussnachweis am Ende dieses Dokuments.

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

## Bau und Prüfpfad

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


## Abgeschlossener Nachtest und überprüftes Downloadpaket

Der übernommene Prüfstand `bfbd26b1c96f4ed7a1c261b3a80d383e963fcaf4` besteht den
vollständigen [Android-Nachtest und Paketlauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38150844811).
Beide Jobs `android-runtime` und `package-download` sind erfolgreich. Auch die
[vollständige Flutter-CI dieses Prüfstands](https://github.com/Ullmann27/lumo-lernen/actions/runs/38150848835)
ist erfolgreich. Die oben beschriebenen Abbrüche bleiben als historische
Fehlernachweise erhalten; die folgende Abnahme löst den zuletzt offenen Prüfblock.

Tatsächlich abgeschlossen auf Android 16/API 36 im x86_64-Emulator:

- Update 1929 → 1930 ohne Deinstallation, erhaltenes fiktives Testprofil und Wallet,
  Offline-Synthese/Wiedergabe mit Pause/Fortsetzen/Stopp, Elternbereich, Godot-Menü
  und Rückkehr. Keine kostenpflichtigen Sprachanfragen.
- Acht Schritte „Über den Zehner“ einschließlich echter falscher Antwort,
  angefordertem Tipp, zwei selbstständigen richtigen Antworten und einmaliger
  Speicherung: `correct=2`, `wrong=1`, `hintCount=1`.
- Sieben Schritte „Das Einmaleins entdecken“: gesperrter Einstieg ohne Freigabe,
  ausdrückliche lokale Elternwahl für Klasse 2, vollständig gespeicherte separate
  Entdeckungsaufgaben; reguläre Klasse 1, Schulfortschritt und Wallet unverändert.
- Gespeicherte Schul-/Entdeckungsfortschritte und Wallet nach vollständigem
  App-Neustart unverändert. Die lokale Elternwahl ist keine Erwachsenenidentitätsprüfung.

Die heruntergeladenen Nachweise wurden zusätzlich geprüft: Alle neun gespeicherten
aktuellen Antwortframes enthalten gleichzeitig die markierte richtige Antwort,
korrekte Rückmeldung und aktivierte Weiter-Taste; die neun Kursbild-Hashes stimmen
mit dem Android-Ergebnis überein. Der lokale gesamte Python-Testlauf besteht
95 Tests ohne Fehler. Die echte Fold-Aufnahme zeigt die Erklärung 7 + 5, zwölf
Äpfel, Zehnerzerlegung und bedienbare Vorlesen-/Stopp-Aktionen.

### Download und Identität

[Downloadartefakt des erfolgreichen Laufs](https://github.com/Ullmann27/lumo-lernen/actions/runs/38150844811/artifacts/11706732005)
enthält `Lumo-Lernen-Neu-0.12.23-1930.zip`, Installationshinweise und
`ZIP-VERIFICATION.json`. Das GitHub-Artefakt und anschließend das darin enthaltene
Installations-ZIP entpacken; danach `Lumo-Lernen-Neu.apk` als Update öffnen.
Die vorhandene Test-App behalten und nicht deinstallieren. Die GitHub-Artefakte
haben 30 Tage Aufbewahrung ab Erstellung.

- APK-Quellstand: `5f3a47a676477ddaec05c11e31311001a015cb11`; unveränderte
  App-/Asset-/Modell-/Signatur-/Verpackungseingaben gegenüber dieser Bauquelle.
- ARM64-APK: 302.317.647 Bytes, SHA-256
  `d416c74de0b61bc363a426c80056c86156f19306239c95309d8e5e2dd7fe5b73`.
- x86_64-Prüf-APK: SHA-256
  `db66de1fcb58d80b76c982b96e71deba3c24c1797495106dd8bb63f68bedfe44`.
- Installations-ZIP: 311.147.474 Bytes, SHA-256
  `19a78c8c576a48b2650f8bf71f70d6f13f449b89d2d7ce1e9b89d6ea5300bd9b`.
- ZIP erneut heruntergeladen: Gesamt-CRC, ZIP-Hash, eingebetteter APK-Hash
  und ARM64-Architektur stimmen; 18 Dateien einschließlich zehn echter Android-PNGs.
- Komplette CI der tatsächlichen APK-Bauquelle: 1.272 bestanden, 115 optionale
  Tests übersprungen, keine Fehler. Paketkennung und Testsignatur bleiben gleich.

[Originale Android-Nachweise](https://github.com/Ullmann27/lumo-lernen/actions/runs/38150844811/artifacts/11706766679)
enthalten die echten PNGs/XMLs, `education-android-result.json`,
`EXISTING-APK-SOURCE.json` und native Laufzeitprotokolle.

Die Prüfung gilt für den Emulator. Physisches Samsung/Fold, echtes Scharnier,
ARM64-Hörprüfung, vollständiges Kart-Rennen und die oben genannten fachlichen/
kommerziellen Abnahmen bleiben offen. Kein Neubau war erforderlich und kein
Merge nach main oder Store-Release wurde durchgeführt.
