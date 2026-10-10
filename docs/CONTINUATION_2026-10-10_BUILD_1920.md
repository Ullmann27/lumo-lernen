# Fortsetzung 10. Oktober 2026 · Quellkandidat 0.12.13+1920

**Einstieg für den nächsten Chat.** Godots begrenzte Wangenkorrektur ist an
echten Renderbildern geprüft. Die App enthält die neue Profilisolierung als
Arbeitsstand. Vollständige App-CI, neue APK und Android-Abnahme stehen aus.
**Diese Notiz bestätigt keine fertige oder geprüfte APK 1920.**

## Auftrag und Quellen

Heinz möchte die bestehende App selbstständig weiterentwickeln lassen:
tatsächlich programmieren, prüfen und echte Bildschirmbilder liefern.
Originaldesign, orange-cremefarbenen App-Lumo, vorhandene Karts, Lern- und
Spielfunktionen sowie Fold-taugliche Bedienung bewahren. Ohne PIN
weiterarbeiten; die konkrete Elternbestätigung für alte Lerndaten bleibt
vorgesehen. Keine erneuten Routinefreigaben einholen. Kein Merge nach `main`
und kein öffentliches Release ohne Heinz.

| Bezug | Stand / Ziel |
| --- | --- |
| App-Basis 0.12.12+1919 | `d07b2b48593b939a2a0446fcb83a25a2b2a59db6` |
| Godot-Pin dieser Basis | `d140e5b05cb5afacfe675559b78da4254cb1daed` |
| App-Arbeitsbranch / Zielversion | `codex/lumo-next-2026-10-10` / `0.12.13+1920` |
| Neuer Pin in `config/godot-source.json` | `6b40153126171a5b3193c830855f42c9c597f0a1` |
| Godot-Branch / Engine | `codex/lumo-face-continuation-2026-10-10` / `4.6.3` |

Aktuellen App-HEAD vor dem nächsten Lauf erneut festhalten. Ältere Einträge in
`OPUS_NEXT.md` und deren APK-Nachweise sind historisch; sie gelten nicht für
1920. Übergeordneter Auftrag:
[OPUS_ENTWICKLUNGSAUFTRAG.md](OPUS_ENTWICKLUNGSAUFTRAG.md). Verbindliche Bilder:
`assets/lumo_design/fox/fox_avatar.png` und
`docs/design_targets/2026-10-08-kart-fahrzeuge/`. Konzeptbilder sind keine
Laufzeitnachweise.

## Erledigt: begrenzte Godot-Wangenkorrektur

[Godot-PR #43](https://github.com/Ullmann27/lumo-godot/pull/43) baut auf dem
1919-Pin auf. Der untere Kopf erhält eine cremefarbene Oberfläche; die
vorhandene Wange läuft um den Kopf. Abgetrennte hintere Wangenpolster und
freigelegte kleine Blattkörper wurden nur beim Fuchs entfernt. Andere Fahrer,
Augen, Nase, Lächeln, Kiefer-/Ohrposen und Griff wurden bewahrt.

| Echter Vergleichslauf | Ergebnis |
| --- | --- |
| [Baseline `5f47cfc`, Lauf 38030347821](https://github.com/Ullmann27/lumo-godot/actions/runs/38030347821) | Sechs PNGs zeigen orange Lücke und getrennte Wangenpolster. Gesamt-Lauf **FAIL** wegen eines unbenutzten, nicht freigegebenen Podests der Capture-Fixture. |
| [Zwischenstand `a84f4d9`, Lauf 38030743431](https://github.com/Ullmann27/lumo-godot/actions/runs/38030743431) | Capture und 68 Prüfungen grün; Bildprüfung beanstandete nun sichtbare harte Blattkörper. Danach gezielt entfernt. |
| [Final `6b401531`, Lauf 38030986867](https://github.com/Ullmann27/lumo-godot/actions/runs/38030986867) | **PASS**, sechs erneut geprüfte PNGs, **68/68** Oberflächenprüfungen und Abbau ohne Fehler/Lecks. Für die Wangenkorrektur visuell angenommen. |

Die identische Oberflächenprobe zeigte an der Basis lokal **19 Fehler bei
68 Prüfungen**. Nach dem letzten Fix stimmen zusätzlich **16/16**
Geometrie-/Pose-Fingerprints mit `d140e5b` überein: übrige Fahrer in Renn- und
Begleitermodus sowie die bewahrten Fuchsbestandteile. Die Fixture gibt ihr
ungenutztes Podest frei; der strenge Fehlerprüfer blieb unverändert.

Finaler Job: `114151704388`; Artefakt: `11662003517`, **2.741.243 Bytes**.
Geprüfte Archiv-SHA256:

```text
4d77a795e170d05a3b8decdc290d187a7654307a4f0c9a0733030e5bede8b6e2
```

Enthalten: Front, Dreiviertel, Seite, Rückseite und zwei Sprechposen, je
**960 × 960**, Manifest, Quell-SHA und Logs. Alle sechs Bildhashes und fünf
Quellhashes wurden geprüft. Echte Godot-X11-/GL-Bilder belegen keine
Android-Leistung oder Geräte-FPS. **Der getrennte Kinnkörper beim Sprechen
bleibt eine bekannte vorhandene Abweichung**; vollständige Referenzgleichheit
ist nicht behauptet. Der finale
[Vehicle-Lauf 38030988853](https://github.com/Ullmann27/lumo-godot/actions/runs/38030988853)
ist grün. Auch der vollständige
[Stage-2-Lauf 38030988847](https://github.com/Ullmann27/lumo-godot/actions/runs/38030988847)
ist auf dem finalen `6b401531` **PASS** (Job `114151710812`). Darin sind
Physik, Rennspeicherung/I/O-Wiederholung, Fold/Pause, Menü-Sicherheitsabstände,
vier Streckenwelten und echte Figuren-/Menüaufnahmen geprüft.

## Vorbereitet: App-Profilisolierung und Elternzuordnung

Der Arbeitsstand bearbeitet
[Issue #233](https://github.com/Ullmann27/lumo-lernen/issues/233) und den
[Profil-Audit](PROFILE_IDENTITY_AUDIT_2026-10-09.md):

- Lernfortschritt und Kosmos gehören stabilen Profilkennungen. Die zu einer
  Antwort gehörige Profilbindung wird schon vor dem Warten auf die
  Belohnungsspeicherung erfasst; ein Wechsel A → B darf keine alte Antwort B
  zuschreiben. Wechsel
  und Reset berücksichtigen ausstehende Vorgänge und veraltete Anzeigen.
- `legacy_learning_data.dart` bewahrt alte globale Daten und eine stabile
  lokale Kennung. Eine Zuordnung gilt genau einem unberührten Ziel; eine
  unterbrochene Speicherung bleibt für dasselbe Ziel wiederholbar.
  Vorhandener Kinderfortschritt wird nicht überschrieben.
- `legacy_learning_data_card.dart` ergänzt die Elternauswahl mit Bestätigung,
  Abbruch und Fehlerwiederholung ohne PIN. Betroffene Lernmodule und weitere
  Aufrufer verwenden die Profilbindung.
- Neue Tests betreffen Wechsel, Neustart, verzögerte Speicherung, Kosmos und
  Altdaten. `scripts/ci/run_profile_checks.py` trennt den historischen
  1918/1919-Protokollvergleich vom aktuellen Profiltest. Vier geforderte
  Elternansichten für Telefon, Fold und große Schrift sind ausdrücklich
  **Flutter-Widget-Fixtures** mit Hashmanifest, keine Geräteprüfung.

Dies beschreibt den vorbereiteten Quellumfang, noch keinen vollständigen
Ausführungserfolg der App. Wallet, separate Lese-/Schreibspeicher und native
Spielstände sind nicht durch diese Arbeit vollständig pro Schulkind isoliert.
Issue #233 bleibt daher offen; dieser Stand ist keine pauschale Datenschutz-
oder Mehrbenutzerabnahme der gesamten App.

## Noch abschließen

1. App-Änderungen gemeinsam prüfen und auf dem Arbeitsbranch sichern;
   Quellversion, Godot-Pin und neue App-Commit-SHA zusammenhalten.
2. Gesamte App-CI einschließlich Analyse, Flutter-/Profiltests, historischer
   Kontrollen, tatsächlicher Widgetbilder und erhaltener nativer Gates
   ausführen. Den ersten konkreten Fehler beheben, keine Gates abschwächen.
3. Eine neu gebaute, signierte APK anhand eigener Bytes, Version, Signatur
   und APK-/PCK-Quellbindung bestätigen. Android 15/16, vollständiges Rennen,
   Pause, Größenwechsel, Offline-Wiederaufnahme, ACK und einmalige Belohnung
   müssen auf genau dieser APK geprüft werden.
4. A/B-Profilwechsel und Altdatenzuordnung in der tatsächlichen App prüfen;
   echte Bilder und verbleibende Kinn-/Referenzabweichungen dokumentieren.
   Physisches Fold und belastbare Geräte-FPS bleiben eigene Nachweise.
