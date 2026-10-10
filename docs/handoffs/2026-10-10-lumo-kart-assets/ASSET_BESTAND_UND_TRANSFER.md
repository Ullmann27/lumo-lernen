# Lumo Kart – Datenbestands- und Transferprotokoll

## Tatsächlich geprüfter lokaler Bestand

| Kennzahl | Wert |
|---|---|
| ZIP-Bände | 10 (alle unabhängig entpackbar) |
| Gesamtgröße | 492.200.065 Bytes (ca. 492,2 MB) |
| Bilddateien über alle Bände | 95 |
| Verschiedene Ausgangsbilder | 32 |
| Native Original-PNGs | 32 |
| 4K hochskalierte PNGs | 32 |
| 4K hochwertige JPEGs | 31 |
| Integritätsprüfung | alle zehn ZIPs via Python `zipfile.testzip()` erfolgreich; keine fehlerhaften ZIP-Einträge |
| GitHub-Upload-Status der ZIPs | **NICHT HOCHGELADEN** – ausschließlich Textübergabe auf diesem Branch |

Die Archive enthalten zusätzlich Metadaten: `PAKET_INHALT.json`, `README_START_HIER.md`, Assetkataloge und Umsetzungsanweisungen. Originale liegen unter `ORIGINAL_NATIVE/`, Bildarbeitskopien unter `4K_UPSCALED_PNG/` und `4K_HIGH_QUALITY_JPG/`. Bei dem 4K-Upscale handelt es sich um höhere Auflösung **ohne** zusätzliche echte 3D-Geometrie.

## ZIP-Namen, exakte Größen und SHA-256

| Dateiname | Bytes | SHA-256 |
|---|---:|---|
| `Lumo_Kart_4K_Paket_01_von_10.zip` | 49.738.274 | `d6c7597036dc167b897da9a8cfad831efb74f34111ecc57d77a0345ff92f661f` |
| `Lumo_Kart_4K_Paket_02_von_10.zip` | 49.757.438 | `06a86a7ca54fdbf86e28aad3fd3a110205ba9177cac17b878217ec7c6da58af5` |
| `Lumo_Kart_4K_Paket_03_von_10.zip` | 49.836.964 | `d16687a960831f43dacf549180b425fde63986cae9798751f246f9baa6d3cf62` |
| `Lumo_Kart_4K_Paket_04_von_10.zip` | 49.845.714 | `5305815164f5c1457e2a33e8f53376273444616780c829199f95b0fcb108faaf` |
| `Lumo_Kart_4K_Paket_05_von_10.zip` | 49.835.513 | `000b65a5f699874f7830772ad9f95562d6633e8daac6a71a83b40dbe799cd1d2` |
| `Lumo_Kart_4K_Paket_06_von_10.zip` | 49.424.964 | `2f08b409290e7301ed6bedd2353de9c55d070208eafbdc5b655f9eb35aa65dbc` |
| `Lumo_Kart_4K_Paket_07_von_10.zip` | 49.832.534 | `1dafb546e3289a819420cd81aed5bd17966761a43da1855e9b117f06e5ce14f3` |
| `Lumo_Kart_4K_Paket_08_von_10.zip` | 48.656.061 | `04ffc2a84bb9ee64b287436bb5bff243227aa0a71f254642caeb0476c89b815d` |
| `Lumo_Kart_4K_Paket_09_von_10.zip` | 48.416.585 | `bd15371ceff723fab2eaf92caf8c1b5fbf8365c995bdc4f00eb96967d18aad63` |
| `Lumo_Kart_4K_Paket_10_von_10.zip` | 46.856.018 | `cb973b329b0ebce22bb66d6e6677398935904544eb552c68efd372819d7d1e90` |

Prüfung nach dem Übertragen:

```bash
sha256sum Lumo_Kart_4K_Paket_*.zip
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
for path in sorted(Path('.').glob('Lumo_Kart_4K_Paket_*.zip')):
    with ZipFile(path) as zf:
        assert zf.testzip() is None, path.name
        print(path.name, len(zf.namelist()), 'Einträge OK')
PY
```

## Archiv-Beschaffung

**Wichtig:** Die Dateien sind in der ursprünglichen ChatGPT-Konversation als zehn Downloadanhänge verfügbar, aber bislang **nicht auf GitHub**. Diese GitHub-Dokumentation allein ist kein Downloadort der Bände. Agent: Überprüfe zuerst, ob der Nutzer die ZIPs bereits im Perplexity-Computer-Workspace hochgeladen hat. Falls nicht, bitte ihn ausdrücklich, die zehn `Lumo_Kart_4K_Paket_*.zip` bereitzustellen. Erfinde keine URLs. Verwende keine anonymen Drittanbieter-Uploads ohne Zustimmung.

ZIPs nicht wahllos in ein Git-Repository einchecken: bevorzugt ein dokumentierter GitHub-Release-Anhang oder ein ausdrücklich genehmigter Git-LFS-Asset-Speicher mit Prüfsummen. Repository-Gesundheit, Speicherkosten, Zugriffsberechtigungen und Datenschutz prüfen. Nach erfolgreichem Binär-Upload hier die **tatsächlich verifizierten** Release-URLs und Hashwerte ergänzen.

## Inhaltliche Kategorien

- Animierbare Rennfiguren-Referenzen: Lumo, Hase, Schildkröte, Eichhörnchen, Löwe, Eule/Nachtkatze und weitere Entwurfsansichten.
- Streckenmodule: Gerade, Links-/Rechtskurve, Rampe, Sprung, Brücke, Tunnel, Boost-Pads und Randmodule.
- Rennatmosphäre: Startbogen, Garage, Ziel, Pfeilschilder, Leitplanken, Tribünen, Item-Boxen.
- Landschaften: Bäume, Büsche, Felsen, schwebende Inseln, Wasserfälle, Kristalle, Burgen, Szenerie.
- Collage-/Übersichtsmotive: **nur Referenz**, nicht als Einzel-Mesh importieren.

### Zusätzliche Konzeptbilder aus derselben Unterhaltung

Es gibt außerdem zwei spätere große Lumo-Sky-Raceway-Konzeptansichten (Vogelperspektive, Looping, Sprünge), die **nicht Bestandteil der zehn ZIPs** sind. Bei zusätzlicher Übergabe separat aufnehmen:
- `futuristische_lumo_kart_rennstrecke_in_den_wolken.png`
- `schwebende_inseln_lumo_kart_rennstrecke.png`
- `a_vibrant_high_detail_fantasy_racing_game_concept.png`

Diese sind ausdrücklich Illustrationen, keine bereits vermessenen, befahrbaren Godot-Strecken.

## Import nach erfolgreicher Beschaffung

1. ZIPs nach der Hashprüfung in EINEN Ordner entpacken; Pfade zusammenführen, ohne Dateien zu überschreiben.
2. Doppelte Motivversionen anhand Ursprungsschlüssel erkennen; 4K-PNG und 4K-JPEG nicht als eigenständige 3D-Motive zählen.
3. Native Referenz priorisieren. Für präzise Fahrbahnen Godot/Blender-Geometrie modellieren, keine Collage als 3D-Track hochladen.
4. Runtime-Texturen je nach Kameraabstand/LOD reduzieren und mobile Renderer tatsächlich messen.
5. Visual-QA immer gegen die originalen Lumo-Vorlagen und echte Godot-Screenshots durchführen.
