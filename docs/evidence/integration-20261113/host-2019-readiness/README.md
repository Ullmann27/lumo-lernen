# Quellengebundene Android-2019-Anschlussreparaturen

Die fünf Quelldateien dieses Checkpoints entsprechen bytegenau den eingefrorenen
Dateien des Implementierungs- und unabhängigen Quellenreviews. Die Basis ist
lokal `851554036f1e78ca5123fcede92bab88ab9458fc`, veröffentlicht als
`2fa3b3d346c9d53930782bf6b9f0ad035ada7ac0`; beide haben Tree
`99f25c730a9a062d9529fea1979f3196e5831692`.

## Verbundene Änderungen

- Der veröffentlichte Scrollpatch aus Host `3022777f` erlaubt eine letzte
  aktuelle Zielbeobachtung nach der letzten erlaubten Scrollgeste. Das
  Gestenbudget, Zielrechtecke, Sichtbarkeitsprüfungen und Recoverygrenzen bleiben.
- Beide 2019-Workflows wählen für die numerische API-37-Matrix das tatsächlich
  veröffentlichte SDK-Paket `37.0`. Die spätere Geräteprüfung verlangt weiterhin
  API 37 und Android 17. Die Originalkataloge und der aufgelöste Action-Quellstand
  sind archiviert; eine Katalogprüfung ist kein Emulatorstart.
- Der absolute `.ci-python`-Pfad bleibt beim Wechsel in den Native-Checkout
  aktiv. Ein tatsächlicher Pillow-Import wird vor den Native-Gates ausgeführt.

Die sechs veröffentlichten Scrollgegenfälle, 25 betroffenen Workflow- und
Plattformverträge sowie 126 bestehende Android-Nachbarverträge bestanden:
157 getrennte Testmethoden, keine Fehler oder Skips. Die ersten Gegenläufe
lieferten sechs Methoden mit sieben Assertionsfehlern beziehungsweise zwei
Methoden mit vier Unterfallfehlern. Beide Workflows bestanden actionlint.
Alle 1.853 gebundenen Pfade blieben während der fokussierten Prüfung unverändert.
Der unabhängige Quellenreview meldete keinen konkreten Integrationsblocker.

Die vorherige vollständige Root-Prüfung mit 434 Script- und 794 Android-QA-Tests
gehört weiterhin zur Basis 2fa/851554. Sie wurde für diese fünf Änderungen nicht
wiederholt und wird nicht als neuer Emulator-, APK- oder Renderernachweis benutzt.
Version, Native-Pins, vorhandene Receipts und Publisherbedingungen sind in diesem
Checkpoint unverändert.

## Unveränderte Originale

`original-evidence.tar.gz` enthält 52 Dateien mit 1.506.420 Transportbytes,
SHA256 `80dd97580ef02749e49b7a28e7251d14595159f38e917df5ee9015677948e2e8`.
Jede Archivdatei wurde nach erneutem Lesen byteweise mit dem Original verglichen.
`archive-manifest.json` bindet jedes Mitglied und alle fünf Quellendateien.

Die beiden ursprünglichen Verzeichnisnamen bleiben im Archiv erhalten:

- `host-2019-readiness-repair-evidence/pack/`: vollständige Vorher-/Nachher-
  Quellen, Patch, ursprüngliche Producer-Logs und SDK-Kataloge, Actionquellen,
  lokale Red-/Green-Logs, Befehle und 1.853-Dateien-Bindung. Das unveränderte
  Packmanifest hat SHA256
  `2f4ddeb0a553175a64a4a60b9ed0c4e921ac34c2682c87fc29fc31d6e14e3591`.
- `host-2019-readiness-source-review/`: ursprünglicher unabhängiger Review mit
  Manifest, Original-README und SHA256SUMS. Review-SHA256
  `31a1642b9d6cc40ff39677de4d3093b3a373181688752485b171d87fdf7b18aa`;
  Manifest-SHA256
  `7e44d0d5b91b1364b63cbf43097ad95ccafd4b7f5be0aa706881e263389ad188`.

Entpacken: `tar -xzf original-evidence.tar.gz -C <leeres-Verzeichnis>`.
Das Packmanifest beschreibt für jede gespeicherte `.gz`-Datei auch den
ursprünglichen relativen Pfad, seine unkomprimierte Größe und seinen SHA256.
`gzip -dc` stellt diese Originalbytes wieder her. Die früheren relativen
Scratch-Verweise im unveränderten Quellenreview beziehen sich auf diese
unkomprimierten Originalpfade. Original-Logs, Leerzeichen und Fehlbefunde wurden
nicht gekürzt oder normalisiert.

Der folgende echte CI-Lauf muss SDK-Installation, Boot, APK/PCK/Signaturidentität,
API35/API37-Tour und die tatsächliche Installation über 2017 weiterhin bestehen.
Dieser Quellencheckpoint erzeugt dafür keinen vorweggenommenen Erfolgsnachweis.
