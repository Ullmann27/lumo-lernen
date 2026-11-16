# Aktuelle vollständige Androidtour 2032 – Versuch 2

**Androidjob 133221738048 SUCCESS**, Run **43837592237**, Versuch **2**. Unveränderte APK-Quelle **9b38360ca5f21919dce4a2b99e605ee39bbbf454**, Native **9d6ef1d704a0e54098a8f8f0818f36deae0e3789**. Der erste Launcher-Dialog-FAIL ist vollständig getrennt erhalten.

Die ursprüngliche Lerntour lief **10:03:55–10:12:59 UTC**, die Referenztour **10:12:59–10:30:44 UTC** am 16.11.2026. Beide Originalresultate sind **PASS_WITH_LIMITATIONS**. API35, x86_64, Pixel-5-Emulatorprofil, Software-Renderer llvmpipe. Die tatsächliche installierte APK stimmt vollständig mit SHA **388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1** überein.

## Konkrete aktuelle Befunde

- **8 + 5:** getippte Frage „Warum zuerst zwei?“; sichtbare Erklärung 8+2=10 und drei verbleibende Objekte; Modell wechselt ohne manuelle Verschiebung nach der Frage von 0 auf 2 bewegt.
- **Banane:** drei sichtbare Silbenschritte mit jeweils aktueller Wiedergabe; Wiederholung liefert vier neue geordnete MediaPlayer-Paare, IDs **19–22**, PID **9392**. Keine akustische Wortprüfung.
- **Aktiver nativer Stopp:** PID **10808**, neue ID **13**, gestartet und noch nicht abgeschlossen; tatsächlicher Tipp auf „Stimme stoppen“ nach **25,757395226 s** innerhalb des 45-s-Fensters. Danach **13,578335915 s** Beobachtung ohne spätes neues Segment und ohne nachträglichen Abschluss dieser ID, Rückkehr zu „Schritt anhören“. Ein gemeinsamer akustischer Mund-/Gestenstopp ist damit nicht vermessen.
- **Muster:** aktuelle Folge Quadrat–Kreis–Quadrat–Kreis, kleinste Gruppe zwei, nativer Vorschlag Quadrat, ungewerte Rückkehr zur gleichen Frage. **Core-Abgabe NOT_EXERCISED**; kein aktueller bewerteter Musterabschluss wird aus diesem Lauf abgeleitet. Der separate Nachlauf bearbeitet die belegte zeilenbezogene Selektorgrenze.
- **Pause und Größenwechsel:** Aufgaben-/Profilzustände bleiben bei den protokollierten Lab-Rückwegen und vier logischen Displaygrößen erhalten. Dies ist kein physischer Fold7-Versuch und keine flächendeckende 3D-Layoutprüfung.
- **Performance:** 47 Prozessintervalle in sieben Fenstern, **823,183787234 ms** gewichteter Mittelwert beziehungsweise **1,214795548 Hz**, alle 47 über 16,7ms. Messfenster 38,689638s; beobachtete Szene 43,908268783s; zwölf Samples mit gleichzeitig gemeldeter Sprache, nutzbarem Fuchs und Effekten. Software-Renderer und kleine Fenster; kein 60-FPS-Beleg auf Hardware.

## Originale und Auswahl

Das vollständig gelesene und geprüfte Actions-ZIP **14216997362** hat **158.127.888 Bytes**, SHA-256 **b925e0ed41110053bf4ad07dd1d1f27c015598bd1b6669b3342a5073ef2a7db7**. Alle **4.066** Mitglieder mit zusammen **180.030.590 Bytes** bestanden Größe/CRC/SHA. [Vollständiges Mitgliedsmanifest](artifact-verification.json), [Sicherungs-/Auswahlmanifest](retention-and-selection.json).

Alle 2.763 ursprünglichen Text-, JSON-, XML- und TSV-Dateien sind zusätzlich bytegleich im abgeleiteten [original-text-evidence.zip](original-text-evidence.zip) archiviert; die ausgewählten Ergebnisbilder und vier Filme liegen unverändert unter `original/`. Das vollständige vom erfolgreichen Publisher übernommene Archiv einschließlich sämtlicher weiterer Bilder/Filme ist als [Android-Lernpruefung.tar.gz](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.20-2032/Android-Lernpruefung.tar.gz) öffentlich vorhanden. Seine tatsächlichen Assetdaten und der begrenzte lokale Transportversuch sind im [Publikationsbeleg](../ci-2032-publication-verified/README.md) dokumentiert. Das komplette ursprüngliche Actions-ZIP wird hier nicht zusätzlich als Gitblob behauptet.

[Root-Erstvergleich](root-initial-review.json) und vollständiger [Rohjoblog](job-log/job.log) bleiben getrennt von der nachfolgenden unabhängigen Prüfung. **fullModernizationComplete=false**.
