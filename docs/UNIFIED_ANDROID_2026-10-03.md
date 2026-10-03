# Gemeinsame Android-App: Lumo Lernen und Lumo Kart

Fortsetzung vom gespeicherten Flutter-PR-152-Commit
`e4d6309b86a4e4365d30771eebdc91c2fce44e9a` und Godot-PR-2-Commit
`55a35b84aeb0eef737f0f9b5a37415cf9a181dfc`.
Die historischen Prototypen bleiben Quellen im Archiv; sie ersetzen keine
weiterentwickelten Repositorydateien. Beide Klone waren am Anfang sauber.
Es wurden keine geltenden `AGENTS.md` in den Projektpfaden gefunden.

## Umgesetzt

- Flutter bleibt Einstieg, Lernen, Profil, Elternbereich und gemeinsame Wallet.
  Der Homescreen zeigt Lernen und Spielen als große erste Auswahl.
- Spieleauswahl mit tatsächlichen Spielen und 24 implementierten Lernleveln;
  26 historische Platzhalter sind ausgeblendet. Kartkarte verwendet ein eigenes
  echtes Godot-Renderbild des vorhandenen Lumo-Fuchses im Kart.
- Godot 4.6.3 und dessen genau festgelegtes PCK sind in derselben APK enthalten.
  Eine private `LumoGameActivity` im Prozess `:lumo_game` startet Kart beziehungsweise
  Wolkeninseln, ohne zweite Installation oder externen Browser. Der separate
  Engineprozess ermöglicht wiederholte Starts ohne veraltete Engineglobals.
- `LumoHost` übergibt Spiel, Klasse 1–4, Fach, aktuelle Sterne und Sitzungs-ID.
  Godot liefert Ergebnis, Pause und Rückkehr zum Lernen beziehungsweise zur
  Spieleauswahl. Flutter liest native Rückkehrdaten bei Wiederaufnahme.
- Native Ergebnisse werden vor dem Engineende atomar mit Dateisperre gespeichert.
  Stabile Ergebnis-IDs verhindern doppelte Sterne beim erneuten Start/fehlender
  Bestätigung. Flutter bestätigt erst nach erfolgreicher dauerhafter Walletbuchung.
- Kart-Klasse und Fach bleiben gespeichert. Profilreset löscht auch bekannte
  Godot-Spielstände; verspätete alte Rückkehrdaten erhalten keinen neuen Profilstand.
- PINs sind aus den aktiven Einstellungen und Dialogen entfernt. Mikrofon,
  Kamera und Onlinehilfe haben verständliche ausdrückliche Freigaben.
- Aufgaben, mehrstufige Hilfe, Logik, TTS-Stummschaltung und Fuchsbewegung verbessert.

Die Fachberichte enthalten konkrete Einzeländerungen und deren Grenzen:
[Spiele](GAMES_QA_2026-10-03.md), [Lernen/KI](LERNEN_KI_PRUEFUNG_2026-10-03.md),
[PIN-freie Einstellungen](PIN_FREI_2026-10-03.md),
[Wallet-Transaktionen](WALLET_TRANSACTIONS_2026-10-03.md).

## Historische APKs und sicheres Update

Flutter-Build 274 ist durch einen erfolgreichen tatsächlichen GitHub-Baulauf
und die heruntergeladene APK belegt, nicht nur durch eine Übergabeangabe:

- Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Version `0.9.0`, Code 274.
- 142.859.956 Bytes, SHA-256
  `25e764ddc12a9577f49f091ff48d749d1ace9e22c70acab0c1089fe01f836bd4`.
- Zertifikat SHA-256
  `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.

Die gemeinsame neue APK verwendet dasselbe Parallelpaket und Zertifikat,
Version `0.10.0`, Code 275, Mindestversion Android 7 (API 24), Ziel-API 36.
Enthaltene Architekturen: `arm64-v8a` für aktuelle Handys einschließlich Galaxy
Z Fold und `x86_64` für den Emulator. Die neue APK enthält keine 32-Bit-Engine.

Das ursprüngliche Paket ohne `.coachpreview` aus Build 270 trägt ein anderes
Zertifikat (`edff8e83e12993fbdf0e054bda44949269ea69f1949c7ccafc1ecd47a1735b74`).
Dessen passender Schlüssel liegt nicht vor. Deshalb ist kein problemloses
Direktupdate dieses alten Pakets behauptet. Nicht deinstallieren: dessen Daten
bleiben getrennt erhalten. Ein Datenimport zwischen diesen Paketen ist nicht
implementiert. Die alte separate Godot-APK wird für die gemeinsame App nicht benötigt.

Godot-Build 31 existierte als eigene historische Release-APK. Der später
gespeicherte Build 45 und PR #2 enthalten bereits weitere Reparaturen.
Für den gemeinsamen Bau gilt allein die Commitreferenz in
`config/godot-source.json`, kein historischer Dateiname.

## Prüfstand

Die gemeinsame Release-APK wurde erfolgreich gebaut. Der Prüfer kontrolliert
APK-Signatur, Paket, Version, Mindest-API, beide Enginebibliotheken je Architektur,
uncompressed `resources.arsc`, ZIP-Integrität, PCK-Hash und gespeicherte Godot-Revision.
Die erste gemeinsame APK wurde wegen unnötiger 32-Bit-Bibliotheken von rund
366 MB auf rund 148 MB verkleinert; diese Zwischenstände sind keine finale Lieferung.

Lokale vollständige Spielrunden, Aufgaben- und Widgetprüfungen sind in den
Fachberichten belegt. Der gemeinsame Android-Test und endgültige Downloadhash
werden nach dem tatsächlichen installierten Nutzungstest hier ergänzt.
Dieser Zwischenbericht behauptet noch keine bestandene Android-Gesamtprüfung.

Android-Umgebung: Linux, Android-11-Emulator/API 30, x86_64, CPU-Emulation ohne KVM.
Der alte SwiftShader-Grafikmodus stürzte schon beim historischen Build 274 mit
SIGSEGV/`bad color buffer handle 208` ab; derselbe AVD wurde ohne Wipe auf ANGLE
umgestellt. Fiktives Profil war nach Neustart erhalten. Google-Zusatzdienste sind
für die Offline-/Navigationsprüfung deaktiviert; System-UI, Launcher und TTS bleiben.
Das ist keine Prüfung auf dem echten Galaxy Z Fold und keine Handy-FPS-Messung.

## Offen

Die neutrale echte Tutor-Aufgabenanfrage liefert weiterhin HTTP 503 nach
OpenAI HTTP 429. Ein Health-200 aktiviert keine KI. Lokale Lernhilfe bleibt
vorhanden; der genaue Quota-/Rate-Limitgrund wird nicht aus unvollständigen
Providerlogs erfunden. Kein Schlüssel wird in die APK eingebaut.

Kart ist eine eigene farbige Welt mit geführter Fahrt und seitlicher Lenkung.
Frei fahrbare Fahrzeugphysik, professionelle Grafik auf dem genannten
Referenzniveau, weitere Strecken und Hardwareleistungsprüfung sind noch offen.
Der Fuchs besitzt weich verbundene 2D-Animationen und annähernde TTS-Wortbewegung,
kein vollständiges 3D-Skelett oder Phonemabgleich.
Laufende Flutter-Brettpositionen überleben Hintergrundwechsel mit erhaltenem
Prozess, aber noch keinen vollständigen Prozessabbruch; abgeschlossene Fortschritte
und Belohnungen sind persistent. Das Flame-Abenteuer ist noch nicht komplett geprüft.
