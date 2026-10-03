# Gemeinsame Android-App: Lumo Lernen und Lumo Kart

Stand 3. Oktober 2026: **0.10.5 / Build 280 wird vorbereitet**. Noch kein
freigegebener Download. Build 279 bestätigte das vollständige native Rennen,
Ergebnisbestätigung, Neustart und Rückkehr zur Spieleauswahl. Im kompakten
Pausenmenü war die Rückkehr zum Lernen abgeschnitten. Build 280 ergänzt feste
sichtbare Rückkehrknöpfe sowie die gemeinsame Lernfortschrittsspeicherung aller
registrierten Module und des aktiven Wort-Schreibcoachs. Der neue installierte
Android-Gesamttest muss anschließend noch bestanden werden.

## Gespeicherte Grundlage

Flutter-PR #152: `e4d6309b86a4e4365d30771eebdc91c2fce44e9a`;
Godot-PR #2: `55a35b84aeb0eef737f0f9b5a37415cf9a181dfc`.
Beide Klone waren zu Beginn sauber; geltende `AGENTS.md` wurden in den
Projektpfaden nicht gefunden. Die 19 Originaldateien liegen mit Herkunft,
Prüfsummen und Duplikatzuordnung im [Archiv](../archive/project-sources/2026-10-02/README.md).
Alte ungetestete Entwürfe ersetzten keine weiterentwickelten Repositorydateien.

Fortsetzungszweige: `codex/lumo-unified-android-2026-10-03` und im Godot-Repository
`codex/lumo-unified-kart-2026-10-03`. Der Bau verwendet ausschließlich den
vollständigen gespeicherten Godot-Commit in `config/godot-source.json` und
Godot 4.6.3. Historische separate Godot-Builds 31/45 sind keine gemeinsame APK.

## Umgesetzt

- Flutter-Homescreen mit großen Lern-/Spieleflächen und tatsächlicher Spieleauswahl.
  26 historische Platzhalter sind ausgeblendet; vorhandene Lernlevel bleiben sichtbar.
  Die Kartkarte zeigt ein eigenes Godot-Renderbild von Lumo im Rennkart.
- Godot und sein festgelegtes PCK sind in derselben APK eingebettet. Kart und
  Wolkeninseln starten in einer privaten Activity im Prozess `:lumo_game`.
  Die Android-Zurück-Taste öffnet die native Pause, statt die Engine zu beenden.
  Fortsetzen, leichte Grafik und Rückkehr führen über sichtbare Bedienelemente.
- Übergabe von Spiel, Klasse 1–4, Fach, Sternen und Sitzungs-ID. Native Ergebnisse
  werden mit Dateisperre atomar gespeichert; stabile Ergebnis-IDs und dauerhafte
  Flutter-Buchung verhindern doppelte Belohnungen. Ein neuer Engineprozess erlaubt
  wiederholten Start. Profilreset schützt vor verspäteten alten Rückkehrdaten.
- Alle aktiven PIN-Abfragen und Demo-PINs entfernt. Mikrofon, Kamera und Onlinehilfe
  bleiben ausdrückliche Einstellungen; bestehende Freigaben werden nicht eingeschaltet.
- Aufgaben, lokale mehrstufige Hilfen, Antwortauswertung, Logik und Lernprofil verbessert.
  Das tatsächlich erreichbare Akademie-Modul „Plus bis 10“ speichert jetzt auch
  Tagesfortschritt und Lernprofil. Fehler erlauben kontrollierte Wiederholung ohne
  erneute Zählung/Belohnung; Hintergrundpause stoppt den Aufgabentimer.
- Abenteuer: Abbruchdialog, echte eingesammelte Sterne/XP, kontrollierte dauerhafte
  Rückkehr und Wiederholung nach Speicherfehler ohne doppelte Buchung.
- Fuchs mit weich verbundenen 2D-Bewegungen, zustandsbezogener lokaler Hilfe,
  TTS-Stummschaltung und annähernder Wortbewegung.

Einzelberichte: [Spiele](GAMES_QA_2026-10-03.md),
[Lernen/KI](LERNEN_KI_PRUEFUNG_2026-10-03.md),
[PIN-freie Einstellungen](PIN_FREI_2026-10-03.md),
[Wallet-Transaktionen](WALLET_TRANSACTIONS_2026-10-03.md).

## Tatsächlich geprüft

**Flutter: 509 bestanden, vier bestehende übersprungen, keine Fehler.**
Analyse: keine Fehler, 153 bestehende Warnungen/Hinweise. Backend: 22 Tests. 90 Prüfungen des Android-Testwerkzeugs bestehen.
Inhaltsaudit: 37.940 Aufgabenvarianten; Klassen-/Fachmatrix mit 16 Fällen.
Acht gezielte Plus-Modultests prüfen Hilfen, falsche/richtige Antworten,
verzögerte/abgelehnte Speicherung, Doppeltaps, Unmount, Hintergrund und Neustart.
30 sichtbare Lösungen ergeben 35 Sterne/450 XP/30 Tagesaufgaben; eine weitere
Lösung nach Neustart 36 Sterne/455 XP/31 Tagesaufgaben. Das sind Widget- und
Persistenztests, kein Android-Nutzungstest.

Lokale Godot-Prüfungen spielen vollständige Rennen mit unveränderter Physik,
Touch-/Drift-/Bremslogik, Pause, Aufgaben, Rundenzählung und Ergebnis-ID-Dedup.
Ein Flutter-Engine-Test spielt die erste Abenteuerstrecke/Klasse 1 bei 800×900
vollständig mit Joystick/Sprung-Taps und unveränderter 60-Hz-Physik durch:
Ergebnis, Rückkehr, 80 Sterne/160 XP, gespeicherter Abschluss, Neustart und
Hintergrundpause. Testuhr und Desktop ersetzen keine Handyprüfung.

**Installierter APK 278-Lauf 37124995594:** Android 15/API 35, Google-APIs-x86_64,
KVM, Mesa 25.2.8/llvmpipe, 480×800 logische Pixel. APK- und installierte
Paketbytes stimmen exakt überein. Tatsächlich sichtbar/bedient: Onboarding,
Home, Spiele, eingebettetes Kart, Android-Zurück, Pause, leichte Grafik,
Fortsetzen, falsche Antwort mit lokaler Hilfe, vier richtige Matheantworten,
zwei sichtbare optionale „Später“-Auswahlen und zwei vollständige Runden.
Ergebnis: Platz 1/6, 47,8 Simulationssekunden, 11 Sterne/16 Kristalle.

Der Ergebnisbildschirm meldete einen echten Fehler: „Speichern fehlgeschlagen“.
Die vollständige Rückkehr, Android-Lernaufgabe, Memory-/Kartenrunde, Fold-Größen
und Offline-Neustart wurden in diesem Lauf nicht erreicht. Er ist kein bestandener
Gesamttest; APK 278 bleibt unveröffentlicht.

Die Ursache ist am tatsächlichen Release-DEX und offiziellen Godot-4.6.3-Code
belegt: erforderliche Hostmethoden und Annotationen sind vorhanden. JNI liefert
Java-Boolean über `jboolean`/`Variant(uint8_t)` als Integer 0/1. Der alte strikte
Vergleich mit Bool `true` wies Integer 1 fälschlich ab. Build 279 akzeptiert nur
Bool `true` oder Integer 1; false/0/2/null/Strings bleiben Fehler. Dieselbe
Korrektur gilt für Ergebnis und Rückkehr. Der Erfolg muss erst im neuen
installierten Androidlauf nachgewiesen werden.

**Installierter APK 279-Lauf 37126787675:** Dieselbe API-35-KVM/Mesa-Umgebung.
Das echte zweiründige Rennen endete mit Platz 1/6, drei richtigen Matheantworten,
drei sichtbaren „Später“-Auswahlen und neun Sternen. Androidlog bestätigt
`[LumoHost] reward reported`. Ergebnis-Neustart, Android-Back/Pause, Rückkehr
zur Spieleauswahl bei lebendem Flutter, erneuter Start mit frischem Engine-PID,
gespeicherter HUD und beibehaltene leichte Grafik funktionierten. Eine zweite
Rückkehr zur Spieleauswahl gelang ebenfalls. Die JNI-Korrektur ist dadurch
am tatsächlichen APK-Lauf bestätigt.

Die dritte Rückkehr zum Lernen scheiterte am abgeschnittenen unteren Knopf.
Ein tatsächlicher 650-ms-Touchscroll offenbarte ihn nicht. Der kleine native
Pauseaufbau erhält deshalb feste Rückkehrknöpfe außerhalb der scrollenden
Einstellungen. Echte Desktop-Godot-Control-/ScreenTouch-Prüfungen bei 800×480
und beiden Fold-Größen zeigen beide Rückwege vollständig bedienbar;
der Erfolg innerhalb APK 280 bleibt im Android-Gesamttest nachzuweisen.

Weitere echte Aufgaben-/Fortschrittskorrekturen für280:

- Klasse-4-Bruchrechnen vergleicht den mathematischen Wert. Gleichwertige Brüche
  werden nicht als falsche Distraktoren angeboten; ein begrenzter Pool vermeidet
  unkontrollierte Zufallsschleifen. Vollständige 8-Aufgaben- und Fehlerspeichertests.
- Alle 18 übrigen direkt erreichbaren Registryrouten und der aktive Wort-Schreibcoach
  verwenden eine gemeinsame dauerhafte Antwort-/Walletgrenze. Richtige Antworten
  erhöhen Daily einmal, falsche nur den passenden Skillfehler. Buchstaben- und
  Abschlussboni zählen nicht als zusätzliche gelöste Aufgaben.
- Speicherfehler halten die akzeptierte Antwort gesperrt, zeigen eine sichtbare
  Wiederholung und lassen denselben Speicherstand erneut schreiben, ohne
  Belohnung/Antwort erneut zu buchen. Hintergrundfeedback wartet auf Fortsetzen;
  bereits akzeptierte Speicherung läuft bei Modul-Unmount weiter.
- Der aktive Wort-Schreibcoach zeigt bei Stummschaltung das tatsächliche Zielwort
  als Abschreibhilfe; mit Stimme bleibt das Diktat erhalten. Sieben neue
  Widgettests prüfen echte Striche, Fortschritt, Fehler, Retry, Doppel-Taps,
  Hintergrund, Unmount und beide Text-/Stimmenmodi.
- Diktatheader und Abschluss verwenden die tatsächlichen 20 Wörter der Session;
  synchrone Eingabesicherung verhindert doppelte Selbsteinschätzung.
- Native `SharedPreferences.setString=false` wird für Skills, Daily und letztes
  Thema als Fehler behandelt. Fehlgeschlagenes Normalisieren löscht keinen
  vorhandenen gültigen Lernstand. Sieben Regressionen prüfen tatsächliche
  Plattformablehnung, erhaltene Altwerte und sichtbare Wiederholung ohne Doppelzählung.

Weitere belegte Releasekorrekturen schützen Godot-JNI-Methoden und
parameterlose ML-Kit-Registrierungen vor R8. APK-Prüfung kontrolliert Paket,
Version, Signatur, Mindest-API, ZIP, PCK-Revision/Hash, beide Architekturen und
16-KiB-Ausrichtung aller ELF-Ladesegmente/Androidressourcen.

Die QA friert Kandidatenbytes vor dem Nutzungstest ein. Nur bestandene Läufe
speichern exakt diese Bytes als endgültige APK; erneuter Download und Prüfsumme
müssen passen. Änderungen ausschließlich am Testwerkzeug benötigen keinen
Neubau. Rohaufnahmen, OCR, UI-XML, Aktionen und Logcat bleiben im Proof-ZIP.

## Installation und Datenerhalt

Zielpaket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Version `0.10.5`, Code280,
Android ab API24, Ziel-API36, `arm64-v8a` und `x86_64`.
Signaturzertifikat SHA-256:
`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.

Die echte historische APK274 hat dasselbe Paket/Zertifikat: 0.9.0/274,
142.859.956 Bytes, SHA-256
`25e764ddc12a9577f49f091ff48d749d1ace9e22c70acab0c1089fe01f836bd4`.
Ein tatsächliches `adb install -r` von274 auf den ersten275-Kandidaten erhielt
synthetisches Profil und die anfangs leere Wallet. Das beweist keinen Transfer
einer gefüllten alten Android-Wallet und keinen Test auf dem Nutzerhandy.

Das alte Paket ohne `.coachpreview` aus Build270 hat ein anderes Zertifikat:
`edff8e83e12993fbdf0e054bda44949269ea69f1949c7ccafc1ecd47a1735b74`.
Passender Schlüssel und paketübergreifender Import fehlen. **Alte App nicht
deinstallieren**; deren Daten bleiben im eigenen Paket erhalten. Kein problemloses
Direktupdate dieses anders signierten Pakets wird behauptet.

## Offen und konkrete Grenzen

**Online-Tutor nicht aktiv:** Echte neutrale Anfrage zu 3+4 am3.Oktober
12:42:43 UTC: HTTP503 `openai_quota_exceeded`; korrelierter Providerlog HTTP429
mit `type=insufficient_quota`. Fehlende Voraussetzung: verfügbares
Provider-Kontingent. Betrag/Kontostand wurden nicht geprüft; Schlüssel, Modell,
Adresse und Tarif wurden nicht verändert. Der vorhandene Renderdienst hat den
getesteten Backend-Commit `fcca1f372ea24ea5a5057d79688cc8e0f2ad7c06` ausgerollt.
Erreichbarkeit allein ist kein KI-Nachweis. Lokale Hilfe bleibt verfügbar;
Zugangsdaten liegen nicht in der APK.

Kart ist eine eigene farbige 3D-Welt mit geführter Fahrt und seitlicher Lenkung.
Professionelles Referenzniveau, frei fahrbare Fahrzeugphysik, weitere Strecken
und echte ARM-Leistungsprüfung bleiben offen. Der Fuchs besitzt kein vollständiges
3D-Skelett/Phonemabgleich. Laufende Brettpositionen überleben erhaltene
Hintergrundprozesse, noch keinen vollständigen Prozessabbruch; abgeschlossene
Belohnungen werden persistent gespeichert. Weitere Abenteuerstrecken/Klassen
und native Android-Steuerung sind nicht vollständig geprüft.

Kein Test auf einem echten Galaxy Z Fold, keine Handy-FPS-Messung, keine
vollständige Mikrofon-/Kamera-/hörbare TTS-Prüfung. Der geplante Fold-Test ändert
nur Emulatorgrößen, nicht ein physisches Scharnier. Die APK und ihr endgültiger
Downloadhash werden erst nach bestandener Android-Gesamtprüfung hier ergänzt.
