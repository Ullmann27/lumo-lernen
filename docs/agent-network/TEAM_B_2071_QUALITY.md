## Verbindlicher Prüfhalt für APK 2071

**Originalrun45191784853 ist beendet: Bau erfolgreich, Android-Pflichtgate fehlgeschlagen, Veröffentlichung übersprungen.** Produktquelle bleibt Flutterb4db287fe562893d849d1c826c9b92e8f2e44761 / Godote0460c0b3eda9d42e9d963eb2236dc8d9c7b5913.

- Originaltour:23/23 Schritte PASS.
- Android-SAF-Sicherung/Wiederherstellung:8/8 Schritte PASS; installierte APK-Identität stimmt.
- Native Pflichtstarts: run/quiz/kart/cards positiv; Memory ohne Router-Ladebeleg, Schach und World ohne erfolgreichen Kachelstart. Nach Memory beziehungsweise Schatzsuche bleibt beim folgenden Versuch dieselbe native Activity/PID sichtbar.
- Tatsächlicher Gatefehler: `ValueError: memory: missing positive observation for router_loaded`.
- Die leeren gefilterten Memory-/Schatzsuche-Logs erlauben keine Aussage, dass diese Starts fehlerfrei waren. Produkt-, Start-/Teardown- und Beobachtungsmechanismen werden anhand der Originalbelege parallel untersucht.
- Original-Androidartefakt14831399839,92447590Bytes, SHA256`61709df3558f864800a2476bed01236ede9713c45a947e2e5193611bcfae6252` tatsächlich heruntergeladen und geprüft.

**Diese APK wird nicht als freigegeben geliefert.** Der separate Publisher bleibt ohne aktivierende Config und würde den fehlgeschlagenen Original-Androidjob abweisen. Keine Gateabschwächung, keine Umwertung fehlender Beobachtungen zuPASS. Main und Hauptteamzweige bleiben unberührt.

[Abschließender Android-Prüfhalt](TEAM_B_2071_ANDROID_HOLD.md).

## Historischer Bau- und Sichtprüfstand

# Team B 2071 · belegter Bau- und Sichtprüfstand

Stand: 23. November 2026, 15:54 Uhr Wien. Dieser Beleg unterscheidet gebaute Produktquelle, spätere Dokumentationsstände und tatsächlich ausgeführte Prüfungen.

## Unveränderte Identität

| Feld | Tatsächlicher Wert |
|---|---|
| Version | 0.14.2+2071 |
| Flutter | b4db287fe562893d849d1c826c9b92e8f2e44761 |
| Godot | e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913 |
| Godot-Engine | 4.6.3 |
| Originalrun / Baujob | 45191784853 / 137751923651 |
| ARM64-Datei | Lumo-Lernen-Test-0.14.2-2071.apk |
| ARM64-Bytes | 537231343 |
| ARM64-SHA256 | c7036b318ba9f3e0c0751abcc1f3745ce0fd0a96a617954501feb40b63627737 |
| Paketname | dev.ullmann.lumo.lumo_lernen.coachpreview |
| minSdk / targetSdk | 24 / 36 |
| Zertifikat-SHA256 | a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702 |
| PCK-Bytes | 279910300 |
| PCK-SHA256 | 398cf6cdd6cac5233037b6cd1247c89b3a92392050a0c9a9696af82d0beedf5f |
| x86_64-Bytes | 540400988 |
| x86_64-SHA256 | 57a48218d833a3e5114cf8ae93d7a32acd51b0aa10d1e9dad6483699e785f306 |

Quelle: der tatsächlich erfolgreiche [Baujob](https://github.com/Ullmann27/lumo-lernen/actions/runs/45191784853/job/137751923651), Originalmetadatenartefakt14827937341. Strukturierte Kopien der drei tatsächlich gelesenen JSON-Metadaten stehen in [evidence/team-b-2071](../evidence/team-b-2071). Sie sind Datenkopien, keine Behauptung bytegleicher JSON-Formatierung. ARM64 und x86_64 haben nachweislich dieselbe PCK und dasselbe Zertifikat. Die APK ist eine signierte Testversion.

## Ausgeführte Prüfungen

- Endgültiger Supportlauf [45191784803](https://github.com/Ullmann27/lumo-lernen/actions/runs/45191784803): alle Jobs erfolgreich, 61 Flutter-Tests, 20 JAR-Helfertests und gezielte Analyse ohne Befund.
- Tatsächlicher APK-Bau: 79+12+28=119 JVM-Tests und 190 Flutter-Tests erfolgreich.
- Gesamtanalyse: 0 Fehler, 5 Warnungen, 296 Hinweise. Die 301 Meldungen werden nicht als warnungsfreies Gesamtrepository bezeichnet.
- Native Quellprüfung mit Godot4.6.3: World194, Freundepost289, Controller22, tatsächliche World-Methoden27, HUD499, Kartenrenderer152 und Schatzsuche92 erfolgreich. HostBridge und Kartentisch starten ihre bestehenden Gates ebenfalls erfolgreich.
- Tatsächliche APK/PCK: Paketstruktur, Manifest, ABI, Signatur, Quellenidentität und 16-KiB-ELF-/Ressourcenausrichtung geprüft. World194 und HUD499 gegen die extrahierte ARM64-PCK erfolgreich. Serialisierter kalter Ressourcenimport erfolgreich; alle Compile-/Importfehlergates bleiben aktiv.
- Original-Androidjob137767273722 läuft noch. Tour, acht echte SAF-Sicherungs-/Rückspielschritte und verbindliche native Starts werden erst nach ihrem tatsächlichen Ende beurteilt. Kein Android-PASS vorweggenommen.

## Tatsächliche Bildprüfung

Die Original-World-Bilder aus Artefakt14825704906 wurden vollständig heruntergeladen, ZIP-Digest geprüft, sicher entpackt und von Root sowie dem World-Agent betrachtet. Alle fünf Spielansichten und die Weltkarte zeigen in den aufgenommenen Ansichten sichtbare Figuren, Kart, Schulrampe und lesbare Bedienelemente. Die bekannten verdeckenden Vordergrundkronen, angeschnittenen Aktionstasten und der übergroße Wegweiser sind dort korrigiert. Aufnahmeorte und Fehlergates blieben erhalten.

Die endgültigen Flutter-Ansichten wurden aus dem Supportlauf und dem tatsächlichen APK-Bau geprüft. Vier direkte Spieleinstiege bleiben auf schmalen Telefonen und kurzem Querformat mit großer Schrift erreichbar. Pfotenpfad zeigt bei normaler Schriftgröße auf344/390px das vollständige Brett zusammen mit den Pfeilen; große Schrift erhält den scrollbaren Aufbau. Root öffnete die endgültigen schmalen aktiven und deaktivierten Ansichten, der Design-Agent alle sieben Pfotenpfad-PNGs.

Im verworfenen Zwischenstand af1b15a war „Los!“ weiß auf Hellgrün und damit kontrastarm. Der abschließende minimale Fix b4db lässt den Button-Vordergrund erben: #071C38 auf #95FF79, berechneter Kontrast etwa13,681:1; das deaktivierte Paar bleibt gesondert abgestimmt. Der ältere Screenshot mit „Cancelled“ betrifft den ersetzten Lauf45190521151; der aktuelle Lauf ist45191784853. Keine tatsächliche laufende Stopp!-PNG wird behauptet.

Die sechs World-Bilder zeigen ausgewählte anfängliche Missionsstände0/6, nicht alle späteren Freundepost-Dialoge, Blickwinkel oder Drehungen. Linux-Software-Rendererzeiten sind kein60-FPS-Beleg. [Strukturierter visueller Review](../evidence/team-b-2071/VISUAL-REVIEW.json).

## Spielbare Ergänzungen

24 Pfotenpfad-Bretter, sechs pro Schulstufe1–4, ergänzen die bestehenden144 Aufgaben auf168. Die tatsächliche Pfeilausführung prüft Hindernisse, Rand und Sternreihenfolge; gültige Umwege sind erlaubt. Auswahl, Programme und Abschlüsse gehören zum jeweiligen Kinderprofil und sind in Backup/Reset integriert. Die Oberfläche bietet Rücknahme, Neubeginn, Tipp, Start/Stopp, nächste Aufgabe und reduzierte Bewegung.

Die gleichmäßig skalierte Weltkarte zeigt Spieler, Blickrichtung, Ziel und vier Orte. Drei Freundepost-Lieferungen werden nach den sechs Hauptmissionen zugänglich: Nelli→Bruno→Tilda→Nelli. Übergaben benötigen tatsächliche Nähe und eine Interaktion zu Fuß. Ein falscher Empfänger verbraucht das Paket nicht; Fuchs beziehungsweise Kart zeigen das getragene Paket. Drei Stempel werden gespeichert. Unbekannte zukünftige Spielstände bleiben erhalten.

Die Ampel ist von beiden Gehsteigen bedienbar. Wiederholte Betätigung setzt die Wartezeit nicht zurück. Die integrierten Hauptteam-Änderungen verbessern die gewöhnliche Kamera, HUD-Bedienflächen und Schulrampe. Schreibtrainer, Journal, ursprüngliche Schatzsuche und Dorfwirtschaft bleiben angeschlossen.

## Artefakte und Auslieferungsgrenze

| Originalartefakt | ID | ZIP-SHA256 |
|---|---:|---|
| ARM64-APK | 14828082269 | 6734f70eb18d217320d38d4dc3101ddb821fd949e45f7efd75da17b768cb813a |
| Metadaten | 14827937341 | e30a532ccefec22cb98a10472c46d79b7cac0e4f7e405aebaf7da544bfe749b1 |
| Emulator-APK | 14828446718 | 31e2e96c51d5948f3804a810e3ac4d7c959c7093bdaf99c1bc931df14162bb4e |
| Bauprüfungen | 14829430168 | 68fe93507bdb709a937e2b9a533478106dc673980b82a6302de7941850d09fcb |
| Sechs World-Ansichten | 14825704906 | 452c231e49a700a5ddad418bc90e1367f84eb7f668aea440e88a6328bd1ac34b |

Der isolierte Transportlauf45196734395 unter Commitafad403a1f4221a9330d76ef09eb85cf266da267 war erfolgreich. Neun Teile wurden vor dem Laufzeitausfall nach Manifest zusammengefügt und erneut gegen Dateigröße und vollständigen APK-SHA256 geprüft. Es wurde keine neue APK gebaut oder signiert.

Seit etwa15:49Uhr Wien ist die lokale Runtime unavailable. Der danach nicht bestätigte ZIP-Abschluss und frühere lokale Pfade werden deshalb nicht als dauerhaft verfügbar ausgegeben. Die einzelne2071-APK überschreitet die beim Hauptteam real bestätigte512-MiB-Dateigrenze um360431Bytes. Ein ZIP wäre nur ein Zusatzweg, kein Ersatz für den verlangten öffentlichen Einzel-APK-Link.

Ein früherer tatsächlicher Releaseversuch erhielt HTTP403 „Resource not accessible by integration“. Laut [GitHub-Dokumentation](https://docs.github.com/en/rest/releases/releases#create-a-release) benötigt ein Releaseziel mit Workflowänderungen gegenüber dem Defaultbranch eine ausdrücklich berechtigte Identität mit Contents:write und Workflows:write; GITHUB_TOKEN kann diese Workflowberechtigung nicht erhalten. Das passt zum beobachteten Zustand, beweist aber nicht nachträglich jedes serverinterne Detail der historischen403-Antwort. Kein Secret wurde gesucht, keine alternative Identität zum Umgehen versucht. Der eigene nachgelagerte Publishjob bleibt bis zu seinem echten Ergebnis offen.

## Verbleibender tatsächlicher Umfang

Die existierende installierte Android-Tour prüft Onboarding, Lernatelier, native Szenen, Kartfahrt, Rückkehr und Lernstand; Pfotenpfad wird darin noch nicht bedient. Seine Domain-, Speicher-, Widget- und Bildprüfungen werden nicht als Android-Ende-zu-Ende-Beleg ausgegeben. Physische Fold7-/ARM64-Tests,60FPS, thermische Eigenschaften und hörbare Sprachqualität bleiben offen. Die World ist ein spielbares erstes Kapitel mit Erweiterungen, keine als vollständig behauptete AAA-Welt.

## Gesonderter Publisher tatsächlich geprüft

Der ausschließlich prüfende [Lauf45200058196](https://github.com/Ullmann27/lumo-lernen/actions/runs/45200058196), Job137780845069, ist auf Commit1128d28dd9aed476228757e2efe8973493f75885 vollständig erfolgreich. Die exakte Team-B-Anpassung besteht **24 Schutztests**, Python-Syntax, den Vergleich der drei tatsächlichen2071-Metadaten durch verify_metadata sowie echtes Parsen beider YAML-Dateien und **11 Bashblöcke**. Root und Design-Agent haben das abgeschlossene Log unabhängig gelesen. Logic-Agent bestätigte vorab20 unveränderte Schutz-/Hilfsblöcke und24 erhaltene Testkörper.

Die vorbereiteten Dateien sind aktivierungsfrei. Keine config/lumo-team-b-reviewed-publish.json, kein Secretzugriff, kein Release und keine vorweggenommene Android-Freigabe. [Konkreter späterer Ablauf](REVIEWED_PUBLISH_2071.md) und [Prüfbeleg](../evidence/team-b-2071/PUBLISHER-VALIDATION.json). Das lokale Runtimeproblem wird dadurch nicht als behoben dargestellt.
