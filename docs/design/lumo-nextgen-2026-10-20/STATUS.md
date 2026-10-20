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
