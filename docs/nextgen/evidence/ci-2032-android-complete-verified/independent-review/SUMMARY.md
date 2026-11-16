# Unabhängige Originalauswertung – Android 2032, Versuch 2

**Beide Originalresultate lauten `PASS_WITH_LIMITATIONS`; die unveränderte aktuelle `verify_tours`-Prüfung einschließlich des Pflichtfalls „aktiver nativer Stopp“ besteht auch bei der erneuten Auswertung der gespeicherten Originaldaten.** Das ist keine neue Androidausführung und keine Veröffentlichung.

## Exakte Bindung

Run **43837592237**, Versuch **2**, Androidjob **133221738048**, Artefakt **14216997362**. Produkt und QA: `9b38360ca5f21919dce4a2b99e605ee39bbbf454`, Tree `1c572ff37dde942229e8ae8b1f141ec95df50545`; Native: `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`. Version **0.13.20+2032**, bestehendes Paket und Testzertifikat. Original- und Referenztour verwenden dieselbe x86_64-APK mit SHA-256 `388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1`; die beiden frischen UI-Profile sind absichtlich verschieden.

Das Originalarchiv umfasst **158.127.888 Bytes / 4.066 Mitglieder**, SHA-256 `b925e0ed41110053bf4ad07dd1d1f27c015598bd1b6669b3342a5073ef2a7db7`. Die vollständige ZIP-/CRC-Prüfung erfolgte bereits durch Root. Diese Review hat nichts heruntergeladen oder erneut extrahiert. Neun tatsächlich verwendete Quellen sind bytegleich an den APK-/QA-Commit gebunden; beide aktuellen Stopphelper und die ursprünglichen Ergebnisdateien sind separat gehasht.

## Belegte Fälle und Grenzen

| Bereich | Konkreter Originalbefund | Grenze |
|---|---|---|
| 8 + 5 / „Warum zuerst zwei?“ | Wirklich eingegebene native Frage, sichtbare Erklärung „10 minus 8 ist 2“, Modell von 0 auf 2/5 bewegt; danach zehn belegte Plätze und drei übrige Objekte. Kein manueller Bewegungsbutton nach der Frage. Frisches Playback PID 7096 / ID 19. | Getippte Frage, kein Spracherkennungsnachweis. |
| Banane | Drei sichtbare Silbenschritte bis „Banane: Ba – na – ne. Das Wort hat 3 Silben“; Wiederholen liefert vier neue geordnete gestartete/abgeschlossene MediaPlayer-Paare 19–22 in PID 9392. | Wortfolge ist sichtbare Szene und Quellvertrag. Keine akustische Prüfung; natives „Langsamer“ wurde in dieser Tour nicht ausgeführt. |
| Muster | Sichtbarer Hinweis auf die kleinste Gruppe mit zwei Zeichen, hervorgehobenes Quadrat/Kreis-Paar, ungewerteter Vorschlag „Quadrat“, Rückkehr zur identischen unbeantworteten Core-Aufgabe. | **Keine fachliche Abgabe.** `NOT_EXERCISED`; vor Szene, nach Rückkehr und am Ende jeweils null gespeicherte Versuche. |
| Aktiver nativer Stopp | Neue gestartete, noch nicht abgeschlossene ID **13**, PID **10808**, korrektes Sprachprofil; zwei frische Bilder derselben sichtbaren Taste „Stimme stoppen“, tatsächlicher direkter Tap, anschließend „Schritt anhören“. Alle **59** protokollierten PID-/Sprachbeobachtungen unabhängig nachgeprüft. Kein abgeschlossenes ID-13-Ereignis und kein Folgesegment im endlichen **13,578-s**-Nachfenster. Modell bleibt **2/5 bewegt**, Profil/Lernwerte bleiben gleich. | Kein eigener Stop-Callback im Hostlog, keine akustische Stille, Mund-/Gestenstoppaussage oder Millisekundenlatenz. |
| Pause, Rückkehr, Größe, Speicher | **18** Vergleiche tatsächlicher Profil-/Lernwerte, darunter **11** identische Aufgabencheckpoint-Vergleiche; drei echte Home-Wechsel zeigen den Launcher. Vier Größen-/Dichteklassen und Rückstellung behalten denselben Bridgecheckpoint. | Zwei tatsächlich vorhandene kanonische Lern-/Belohnungseinträge eines synthetischen Profils; kein Upgrade-/Prozesstod-/Bestandsdaten- oder physischer Fold7-Test. |

## Warum die Core-Musterabgabe ausblieb

Die acht Original-XMLs `0450` bis `0457` belegen einen funktionierenden Scrollweg im einzigen beobachteten Scrollcontainer `[0,356,1080,1914]`. Ab `0452` sind alle vier echten, aktivierten Antwortkarten vorhanden; `0453` bis `0457` zeigen sie vollständig innerhalb dieses Bereichs. „Quadrat“ ist ein eigenes `android.widget.Button` mit genau diesem `content-desc`, `enabled=true` und `clickable=true`.

Die Überschrift **„Wähle die richtige Antwort:“** steht in allen acht Aufnahmen als genaue Zeile innerhalb eines längeren `content-desc`. Der bestehende Leser verlangt dagegen Gleichheit mit einem vollständigen Knotenlabel. Diese Bedingung bleibt falsch, obwohl die Karten erreichbar sind. Entsprechend wurden weder `pattern-core-observed-answer-controls.json` noch ein Core-Antwort-Touch oder ein Nachabgabe-Präferenzdump erzeugt. Der unveränderte Publisher erlaubt diesen expliziten `NOT_EXERCISED`-Zweig. `--submit-core-answer` und ein erfolgreicher Gesamtlauf belegen keine abgegebene Antwort. Die gespeicherten historischen Bounds dienen nur der Diagnose; ein künftiger Test braucht frische Beobachtungen derselben Aufgabe und desselben Profils.

## Medien und Leistung

Alle **28** gespeicherten Videos wurden vollständig gehasht und mit `ffprobe -count_frames -show_streams -show_format` bis Dateiende gelesen: **1.969 Frames**, **1.028,169354 Sekunden**, **38.552.953 Bytes**, jeweils Exit 0 und leere Decoderfehlerausgabe. Keine Audiospur. Außerdem **64** referenzierte PNG-Dateihashes geprüft und sieben relevante Originalbilder direkt angesehen. Die neuen vollständigen ffprobe-Ausgaben liegen in `ffprobe/`; Medien und Originale wurden nicht kopiert oder verändert.

Die sieben originalen, PID-7096-gebundenen Nativefenster **35–41** wurden neu aus dem Rohlog berechnet: **47 Samples**, **38,689638 s** Messfenster während **43,908269 s** Beobachtung; gewichteter mittlerer Prozess-Frameabstand **823,183787 ms**, entsprechend **1,21479555 Hz**. **47/47** Abstände überschreiten 16,7 ms. Höchstes Fenster-P95/P99: **1.012,011 ms**; bei sechs bis sieben Samples je Fenster ist das kein belastbarer Verteilungsrand. **12** Samples zählen gleichzeitig native Sprachwiedergabe, nutzbare Figur und Effekte. Renderer: `gl_compatibility`, **llvmpipe LLVM 20.1.2** im Android-x86-Emulator. Das sind native Prozessintervalle, keine physischen Display-Präsentationszeiten und kein 60-FPS-Nachweis.

Die deutsche Mikrofonerkennung bleibt laut Originalresultat `explicit_device_limitation` / `NOT_VERIFIED`. Keine Gesamtmodernisierung, individuelle 3D-Simulation für jede Katalogfamilie oder ständig inline sichtbare native Figur wird durch diese beiden Touren belegt.

## Paket

`review.json` ist die kompakte maschinenlesbare Zuordnung. Die Detaildateien trennen Quellen-/Installationsbindung, reine Ergebnisprüfung, originale Sprach-/Stoppereignisse, Präferenzen/Checkpoints, Musterlesergrenze, neu berechnete Messwerte und Medien. `raw-input-binding.json` bindet die gezielt gelesenen Rohbelege an das vollständige Root-Artefaktmanifest; `handoff.json` bindet alle erzeugten Reviewdateien. Keine Testsuite, API-/CI-Aktion, neue Aufnahme, Produkt- oder Rootdateiänderung.
