# Sichtprüfung Lumo World 2070

Stand: 23. November 2026. **Die fünf vorgegebenen Spielansichten sind visuell abgenommen.** Diese Freigabe gilt für die geprüften Ansichten und die korrigierten Sichtfehler; sie ist keine vollständige Android- oder AAA-Qualitätsfreigabe.

Flutter-Bauquelle: `11c0711f23f887796a7281ddfc6ee7a2aa56ac67`. Godot-Quelle: `90648b0639391c88d3c2da0e3f235d30f725256d`.

[Buildlauf 45186225313, Versuch 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/45186225313). Frühes Artefakt `LUMO-WORLD-VIEWS-45186225313-1`, ID 14824108999, 1188738 Bytes. Die vollständig heruntergeladene ZIP stimmt mit GitHubs SHA256 überein: `12eeabb64b4f593c71d2f4d4cda88100ce34a555912b6d4825ca85b3eeb5e21c`.

## Tatsächlich angesehene Bilder

| Ansicht | Beobachtung | Ergebnis |
| --- | --- | --- |
| world-treasure_foundation.webp | Lumo und Weg sind sichtbar; der kleine Wegweiser steht seitlich statt vor der Figur. | Bestanden |
| world-village_walking.webp | Lumo und Nelli sind sichtbar; Ansprechen steht vollständig innerhalb des rechten Bildrands. | Bestanden |
| world-school_portrait.webp | Schultür, Podest und Rampe sind sichtbar; alle Bedienelemente liegen im Hochformat innerhalb der Bildgrenzen. | Bestanden |
| world-kart_driving.webp | Lumo und sein Original-Kart sind frei sichtbar; zuvor verdeckendes Blattwerk liegt nicht mehr vor der Kamera. | Bestanden |
| world-saved_village.webp | Avatar, Dorfportal und die Gebäude des tatsächlichen Dorf-Fixtures sind erkennbar; keine verdeckenden Vordergrundbäume. | Bestanden |

Die ursprünglichen Aufnahmeorte und der normale Kamera-/Fahrablauf sind unverändert. Die Quelle des eingeblendeten Dorf-Fixtures blieb bytegleich. Alle fünf Rendererbeobachtungen bestätigen Arbeits- und Quelltransformationen der Vegetation (`rendererVerified=true`). Die jeweils schmale 344px-Bedienfläche wurde zusätzlich funktional durch die HUD-Regression geprüft; sie ist keine der fünf Bildaufnahmen.

## Leistung und verbleibende Abnahme

Godot 4.6.3, GL Compatibility, X11, Mesa llvmpipe auf zwei CPU-Threads. Der Capture meldet keine Shader- oder Scriptfehler. Er meldet Treiberwarnungen zu V-Sync sowie nicht verfügbarem Screen-Space-Antialiasing.

| Ansicht | Median ms/Frame | Draw Calls |
| --- | ---: | ---: |
| treasure_foundation | 1738.455 | 326 |
| village_walking | 1136.699 | 549 |
| school_portrait | 469.065 | 120 |
| kart_driving | 596.551 | 247 |
| saved_village | 881.793 | 127 |

Die Messung beschreibt diesen langsamen Software-Renderer und keine flüssige Wiedergabe. Sie ist kein Android- oder physischer 60-FPS-Nachweis. APK-Bau, World/HUD gegen das entnommene APK-PCK sowie Android-/Backup-Rundgang laufen bei Erstellung dieses Sichtberichts noch. Die Veröffentlichung bleibt an deren tatsächlichen Erfolg gebunden.
