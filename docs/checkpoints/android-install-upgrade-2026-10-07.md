# Android-Installationsreparatur – gemeinsamer Kandidat und unabhängige Abnahme

Abgeschlossene Etappe vom 7. Oktober 2026. Diese Datei dokumentiert tatsächliche APK- und Emulatorbefunde, nicht eine Diagnose des physischen Samsung-Geräts.

## Ergebnis und Herkunft

- BASE dieser QA-Lane: `b6a0afa421e5e854345bfac5cc2be1813a7c3e50` (PR207).
- QA-Branch / PR: `chatgpt/android-install-upgrade-2026-10-07` / **PR209**.
- Getesteter QA-RESULT: **`9f9f81acc4031656064df7db1dde9dc8e57d10cc`**.
- EINZIGER gemeinsamer APK-Kandidat: aus **PR208**, Branch `chatgpt/install-upgrade-2026-10-07`.
- APK-SOURCE: **`2beabe722dd40bfe110236a305e66e9122e944b6`**.
- Keine automatischen Merges, Releases, Signierungsänderungen oder Eingriffe in andere Working-Trees.
- PR204/PR206 und der gesonderte Integrationszweig sind NICHT in diesem Installationskandidaten zusammengeführt.

## Nachgewiesener Auslieferungsfehler

Die zuletzt an Heinz gelieferte APK hatte `versionCode=280`, `versionName=0.10.5`. Eine vorher tatsächlich ausgelieferte APK derselben Paketkennung und Signatur hatte bereits `versionCode=1321`, `versionName=0.10.6`. Die frühere reine Neuinstallationsprüfung war kein Nachweis für ein funktionierendes Update über solche vorhandenen Testversionen.

Im echten Android-16-Emulator wurde Original1321 installiert und ein fiktives Profil über die Oberfläche angelegt. Der Updateversuch mit Original280 wurde vom Package Manager abgelehnt:

```text
INSTALL_FAILED_VERSION_DOWNGRADE: Downgrade detected: Update version code 280 is older than current 1321
```

Heinz' Screenshot zeigte nur die Dateiliste. Seine konkrete installierte Version und die genaue Fehlermeldung seines Samsung-Installers sind weiterhin unbekannt. Die Reproduktion belegt den Auslieferungsfehler, nicht zwingend die einzige Fehlerursache auf seinem Gerät.

## Tatsächlich geprüfte neue APK

- Anzeigename: **Lumo Lernen Neu**.
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: **0.10.7+1400**.
- Größe: **169227308 Byte**.
- APK SHA256: **`d33b9f5f04a013bc1bcafb579758d109f511ff69e9c08bc95b68c34d9b1c6e7e`**.
- Unverändertes Zertifikat SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Godot-Pin unverändert `c650ff17a5b6a8016fccab0d9b530e0260c6c797`, Engine4.6.3.
- Build **37576067479**, Build-Job112645129786 erfolgreich.
- Original-APK-Artefakt **11463275673**, Name `lumo-install-candidate-37576067479`.
- Original-ZIP SHA256 `7b9fb4b1ca44971dc50fe8f09daf7dfac3799274454f1ecda4a69cfd9aa0f358`.
- Buildbelege **11462409672**, ZIP SHA256 `6c6d59e3886157ec9d0a69ed1098afd3c104768f0bc5fd49bdb1e8400f65ceec`.

Original-ZIP und Raw-APK wurden heruntergeladen; Digests, CRC und Buildprovenienz lokal kontrolliert. Die APK wurde in der QA-Lane weder neu gebaut noch umsigniert. `tracked_source_clean=true`, Paket-/Zertifikatsidentität, arm64/x86_64, eingebettetes Godot-PCK und Binär-/Ressourcenalignment sind im Build geprüft.

Buildprüfungen: **641 Flutter PASS /4 SKIP**, Backend22 PASS, bestehende Android-Vorbereitung5 PASS, Icon-Tests8 PASS, Inhaltsaudit40960 Aufgaben PASS. Die Projektanalyse hat weiterhin **144 Hinweise/Warnungen**. Keine globale Fehlerfreiheit oder vollständige pädagogische/visuelle Abnahme ableiten.

## Abgeschlossene unabhängige Updateprüfung

**Run37577902696 / Job112650800091: PASS**, Android16/API36/x86_64, Prüfharness exakt9f9f81a. Gegenstand war dieselbe oben benannte APK aus2beabe7.

Tatsächlich ausgeführt:
1. Frische, wegwerfbare Emulatorumgebung; vorbestehende Benutzerdaten wären nicht gelöscht worden.
2. Original1321 installiert; fiktives Profil per sichtbarer Oberfläche angelegt und Spielewelt geöffnet.
3. Original280 per `adb install -r --no-streaming` ohne Downgrade-Ausnahme versucht: tatsächliche Ablehnung `INSTALL_FAILED_VERSION_DOWNGRADE`.
4. Vorhandene Installation blieb1321; danach1400 per normalem Update installiert: **Success**.
5. UID blieb **10216**, Datenverzeichnis blieb `/data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview`.
6. Das vorher angelegte Profil erschien nach Update und nach weiterem Offline-Neustart wieder. Spieleinstieg war erreichbar.
7. Installierter Launcher-Eintrag und Lumo-Fuchs in echter Aufnahme bestätigt; kein Paket-Crasheintrag.

Kein `uninstall`, kein `pm clear`, kein `-d`, kein Signatur- oder Schutzfunktions-Bypass. Das ist eine Prüfung des Profilerhalts, nicht sämtlicher Lernstände oder gespeicherter Karten-/Rennpartien.

Hinweis zur Testgenauigkeit: Der UI-Automat gab als Zielname LumoTest ein; die Originalscreenshots zeigen LLumoTest. Der Reader prüft den enthaltenen Text, nicht die exakte Eingabeschreibweise. Vorher/Nachher ist dasselbe angelegte Profil sichtbar. Kein Behaupten einer separat getesteten Texteingabe-Korrektheit.

Originalartefakt **11463835457**, Name `lumo-1321-update-evidence-37577902696`, **14250707 Byte**, ZIP SHA256 **`a362c1dfa3a42b992a41de0a231f9346221b35cdf3c1281c5cef338cbaa02752`**. Originalreport, Installerlogs, sechs echte PNGs, XML und logcat erhalten. ZIP-CRC, APK-Bezug und alle sechs protokollierten PNG-Digests wurden lokal überprüft. Launcher und Profil nach Neustart wurden zusätzlich visuell betrachtet.

Eine zweite, getrennte PR208-Prüfung **37576939193**, Harness0bc1a962, ist ebenfalls PASS für dieselbe1321→1400-APK und prüft zusätzlich erneutes Installieren derselben1400-Version. Artefakt **11462453449**, ZIP SHA256 `5326011781ce5cb5282ccc457a6f0b10778deefe7e8c903c159a98bdf18e4d31`; Originalreport und Installer-Ausgaben tatsächlich gelesen. Diese beiden Läufe sind getrennte Emulatorprüfungen, keine unterschiedlichen APKs.

## Fehlerbelege und Koordination bleiben erhalten

Die parallel gestarteten Installationsarbeiten wurden auf EINEN1400-Kandidaten zusammengeführt, ohne fremde Branches zu überschreiben. Unser zunächst begonnenes1335-Experiment wird nicht ausgeliefert. Der konkurrierende Build wurde mit52038a3 gestoppt; mit946a43b wurden dessen Versionsrichtlinie, Buildänderung und gleichnamiger Workflow aus dem aktuellen Diff entfernt. Alte Experimente/12 Negativtests bleiben nur in Git-Historie und Diagnoseartefakten; sie sind kein zweiter Lieferstand.

Eigener früherer Lauf37575848838 bestand Tests, scheiterte aber an der CI-Pfadaktivierung von Godot. Das war ein Buildharness-Fehler. Die ursprünglichen PR208-Updatejobs aus37576067479 scheiterten am Parser `userId` statt tatsächlich `appId`, nach erfolgreicher Baselineinstallation. Owner erhielt konkrete Originalbefunde; kein APK-Fehler daraus erfunden.

Eigener erster Updateversuch37577120818 bestand bereits Downgrade-Reproduktion, Update und Profilerhalt, scheiterte danach am zweiten konkurrierenden CLI-UIautomator-Prozess mit Exit137. Originalartefakt11462293903, ZIP SHA256 `0f610b268a1f0ff73e1e7de32f413010d9c9f067fe662729b342fd6889843bcb`. Der letzte Harnessfix verwendet für die Launcherprüfung dieselbe bereits aktive UI-Verbindung. Keine Assertions abgeschaltet und keine App geändert; anschließend gesamter Lauf37577902696 erfolgreich.

## Verbleibende Änderungen in PR209

- `.github/workflows/lumo-1321-update-audit.yml`
- `scripts/probes/lumo_upgrade_install_check.py`
- `scripts/probes/lumo_upgrade_launcher_check.py`
- dieser Checkpoint.

Produktcode, ursprüngliches Buildskript, Signierung, Grafiken, Cards, Godot und fremde PRs sind gegenüber der QA-Basis unverändert. PR208 bleibt der Lieferzweig; keine automatische Zusammenführung.

## Abgabe, Grenzen und Wiederaufnahme

Die neue Datei ist als APK1400 gedacht; die alte280-Datei nicht noch einmal installieren. Bestehende Lumo-App behalten. Bei höher nummerierten bereits installierten Testversionen oder weiterem Fehler keinen Datenverlust durch Deinstallation erzwingen; genaue Installer-Fehlermeldung und installierte Version ermitteln.

Physisches Samsung-/Fold-Gerät, dortige genaue Fehlerursache, alle gespeicherten Lern-/Spielstände und komplette Spielabläufe sind **NOT TESTED**. Bereits bekannte Design-/Leistungslücken bleiben unverändert.

Nächste drei priorisierte Schritte: (1) Ergebnis auf Heinz' Gerät anhand tatsächlicher Installationsmeldung prüfen, falls1400 weiter abgelehnt wird; (2) Versionsvergabe und Updateprüfung bei der getrennten Gesamtintegration vonPR204/206/207 übernehmen und Folgelieferung bewusst >1400 wählen; (3) vollständige Cards-/Kart-Speicher-/Rückkehrabläufe und physische Fold-/Grafikprüfung fortsetzen.

Vor erneuten Writes zuerst aktuelle Heads und #170-Claims lesen. Getrennte Worktree-Wiederaufnahme nach `git status --short` und `git fetch origin chatgpt/android-install-upgrade-2026-10-07`; keinen fremden Working-Tree zurücksetzen. APK-SOURCE2beabe7, QA-SOURCE9f9f81a und Dokumentations-HEAD getrennt halten. Kein automatischer Merge/Release und keine Weiterarbeit nach Sitzungsende behauptet.
