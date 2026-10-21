# Cloud-Rettung – 21. Oktober 2026

Die Designarbeit wurde auf Nutzeranweisung pausiert. Im ursprünglichen
Workspace wurden vor Branchwechsel/Update alle elf uncommitteten Quell- und
Testdateien erfasst und zusätzlich lokal archiviert. Die vier ausdrücklich
genannten Dateien sind vorhanden; der vollständige Inhalt bleibt unverändert.

- Ausgangs-HEAD: `4746aebdefb10c7c5aaa4d0258a46797bfd7def6`.
- Verfahren: [PR #394](https://github.com/Ullmann27/lumo-lernen/pull/394),
  Hilfsdateien gezielt aus `b63e0e8415404454705e8b33d619237836b99532` übernommen.
  Keine Übernahme der abweichenden App-Basis.
- [Originaldateien und SHA-256](evidence/cloud-rescue-2026-10-21/original-manifest.json).
- [Render-/Protokollinventar](evidence/cloud-rescue-2026-10-21/evidence-manifest.json).
- Beide Scratch-Renderiterationen mit jeweils sechs PNGs sind archiviert.
- Der erhaltene zweite Flutter-Testlauf meldet **15 bestandene Tests**:
  Hero-Begrenzung/Text, kompakte Lernkacheln, Effektbudget/Bewegungsreduktion
  und sechs echte AppShell-Render mit Navigation. Dies ist ein erhaltener
  Testnachweis vom 20. Oktober, kein neuer Lauf und keine visuelle Abnahme.
- Iteration 1 enthält bekannte Layoutfehler. Iteration 2 war vor der
  Unterbrechung noch nicht vollständig visuell überprüft.
- Die vollständigen Referenzbilder wurden inzwischen im Chat bereitgestellt.
  Ihre Bilddateien liegen weiterhin nicht als lokale Produktionsassets vor.
- Generierte Flutter-/Build-Caches wurden inventarisiert und nicht versioniert.
  Es liegen keine weiteren ignorierten Quelländerungen vor.

Der folgende Ausgangsbericht bleibt als historische Dokumentation erhalten.
## Verifizierter Rettungs-Push

- Eigener Branch: `checkpoint/lumo-cloud-rescue-20261021-014435`.
- Erster vollständiger Rettungscommit:
  [`ec0fc517d5c0fc6e01d5c8b221aad94e573a4cbd`](https://github.com/Ullmann27/lumo-lernen/commit/ec0fc517d5c0fc6e01d5c8b221aad94e573a4cbd).
- Sicherungsskript meldete `REMOTE SAVED`. `git ls-remote` bestätigte exakt
  denselben vollständigen SHA auf GitHub.
- Zusätzlich GitHub-Git-Tree über die API gelesen: alle **35** Quell-/Nachweispfade
  stimmen mit den lokalen Git-Blobs überein; alle **elf** ursprünglichen Dateien
  stimmen außerdem bytegenau mit dem SHA-256-Inventar vor dem Branchwechsel überein.
- Python-Sicherungstests aus PR #394: **3/3 bestanden**, neu am 21. Oktober ausgeführt.
  Der Test mit synthetischen Schlüsselmustern wurde gelesen und kontrolliert
  separat hinzugefügt, da der Sicherheitsfilter ihn erwartungsgemäß ausschließt.
- `AGENTS.md`, Rettungsprotokoll, Hilfsskript, Tests und CI-Guard aus dem
  geprüften PR-Head übernommen. Main und andere Entwicklungsbranches unverändert.
- Watcher im ursprünglichen Workspace aktiviert: PID **5863**, Intervall
  **120 Sekunden**, Prozess und Startmeldung geprüft. Log: `/tmp/lumo-autosave.log`.
  Ein suspendierter/beendeter Cloud-Workspace kann den Prozess stoppen;
  manuelle Remote-Checkpoints nach Arbeitspaketen bleiben verpflichtend.


---

# Lumo Next Gen – Produktion, 20. Oktober 2026

## Verifizierte Arbeitsbasis

- Entwicklungsbranch: `design/lumo-home-cinematic-20261020`.
- Ausgangspunkt: PR #392, `be656daed5f1638775e76c3aadcacde4e5e0503b`.
- Git-Abstammung von #389 (`d2a01779`) und #390 (`cdb58c71`) geprüft.
- Nur Designunterlagen und die beiden vorhandenen JPGs aus #391 übernommen,
  keine veraltete App-Basis. Main bleibt unverändert.
- Kart #111 wurde auf GitHub gelesen; keine Kart-Änderung in diesem Paket.

## Kategorie 1: Ausgangszustand erfasst, Umsetzung läuft

Flutter **3.44.9**, Dart **3.12.2**, Linux Flutter-Test-Renderer.
Sechs vollständige Produktions-`AppShell`-Render einschließlich Header,
Lernhelfer und Navigation, echte Nunito-Schrift und Material-Symbole:

| Ansicht | Logische Größe | Textfaktor | Vorher |
|---|---:|---:|---|
| Smartphone | 393 × 852 | 1 | [PNG](evidence/before/phone.png) |
| Kleines Smartphone | 360 × 800 | 1 | [PNG](evidence/before/small-phone.png) |
| Fold geschlossen | 320 × 740 | 1,2 | [PNG](evidence/before/fold-cover.png) |
| Fold geöffnet | 840 × 960 | 1 | [PNG](evidence/before/fold-open.png) |
| Querformat | 840 × 560 | 1 | [PNG](evidence/before/landscape.png) |
| Große Schrift | 393 × 852 | 2 | [PNG](evidence/before/large-text.png) |

Die Bilder sind unretuschierte Widget-Render, keine Android-Geräteaufnahmen.
Profil „Mia“, Klasse 2, mit leerem Fortschritt ist eine Test-Fixture;
keine produktiven Demo-Werte. Safe-Area: oben 24, unten 16 dp.

Prüfung: `test/design/home_nextgen_capture_test.dart`: **6 bestanden**,
einschließlich echter Navigation über „Loslernen“ zur bestehenden Akademie.
Sichtprüfung zeigt trotzdem:

- Lumos Ohren werden auf dem geöffneten Fold abgeschnitten.
- Bei Textfaktor 2 ist „Bereit für ein neues Abenteuer?“ unvollständig sichtbar.
- Zu dominante, gleichförmige Kartenumrandungen; kleine Figureninszenierung.
- Desktop-Lernhelfer zeigt noch eine ältere Figur.

Diese Punkte sind keine visuelle Abnahme. Folgeprüfungen müssen sichtbaren
Text und Figurenbegrenzung ausdrücklich absichern.

## Referenz- und Assetgrenzen

`lumo_lernabenteuer_im_sternenhimmel.png` und die alternative Startreferenz
`lumo_lernabenteuer_bei_nacht.png` sind hier nicht vorhanden. Das im Brief
genannte ZIP `LUMO_NEXTGEN_CODEX_REFERENZEN_2026-10-20.zip` liegt diesem
Arbeitsplatz nicht vor. Die Kontaktübersicht (550 × 428) erlaubt nur eine
grobe Kompositionsprüfung. Sie ist **keine** Produktionsgrafik.

Verwendbare Originale sind vorhanden: `bg_glass_islands.png` (1024 × 1536),
`fox_book_welcome.png` (1254 × 1254, transparent), weitere Fuchsposen,
`logo_lumo.png`, Buch-/Gamepad-Icons. Keine Neugenerierung erforderlich.
Siehe [Assetkatalog](ASSET_CATALOG.md).

## Noch nicht nachgewiesen

Android-Hardware, APK-Installation, GPU-/Speichermessung und 60 FPS.
Die GitHub-Prüfungen der Ausgangs-PR #392 sind rot; Ursachen müssen vor einer
technischen Abnahme geklärt werden. Kategorien 2–10 und Kart sind offen.
