# LUMO 0.14.6+2078 – originale Build- und Transportbelege

Stand: 24. November 2026. Native Prüfungen, APK, Android-Pflichtabnahme, SAF-Rückspiel und verlustfreier Transfer sind belegt. **Beide Publisher-Versuche sind fehlgeschlagen; die öffentliche Auslieferung bleibt blockiert.** Diese Dateien behaupten keinen Gesamt-PASS des ursprünglichen Workflows.

## Unveränderliche Herkunft

| Gegenstand | Identität |
| --- | --- |
| Repository / Originalrun | Ullmann27/lumo-lernen / [45365478105](https://github.com/Ullmann27/lumo-lernen/actions/runs/45365478105) |
| Flutter-Produktquelle | `94cabcff7f6c568eddfe6805801f49a00ad58312` |
| Godot-Produktquelle | `c3f459eca88f659da1a9e4af1c990c804e715528`, Engine 4.6.3 |
| Godot-Baum | `6b7c47a3010cec04736f9cd495adf34ad0ec2e6f` |
| Native-Job | `138346148805` — SUCCESS |
| APK-Job | `138357008376` — SUCCESS |
| Native-Artefakt | `14908790405`, 54.150.986 Bytes |
| Native-Archiv SHA256 | `7a367e809543d94dd71d9e6069e79651be97c1f86e25e0c7abdb3b2910c7d831` |
| Original-APK-Artefakt | `14908418202`, 701.710.167 ZIP-Bytes |
| APK-Archiv SHA256 | `1b52eac413a54f1f8406a76f2880cccec3294c5e16b6ee0705f38e0b4dc2e97e` |

Die Originaldateien [FLUTTER-COMMIT.txt](native/FLUTTER-COMMIT.txt), [GODOT-COMMIT.txt](native/GODOT-COMMIT.txt), [BUILD-PROVENANCE.json](apk/BUILD-PROVENANCE.json) und die Artefaktmetadaten binden diese Quellen. Die Provenienz meldet `tracked_source_clean: true`. Spätere Dokumentations- und Transportcommits werden nicht als Produktquelle ausgegeben.

## Herkunft der 15.246 Assertions

Die Summe stammt genau aus den abschließenden Erfolgszeilen der folgenden **13 Programme desselben Native-Jobs**. Die **2.243 NeonHome-Prüfungen sind darin enthalten** und werden nicht zusätzlich addiert.

| Originalprotokoll | Assertions |
| --- | --- |
| [lumo_world_regression.log](native/lumo_world_regression.log) | 206 |
| [lumo_world_hud_regression.log](native/lumo_world_hud_regression.log) | 939 |
| [lumo_world_device_regression.log](native/lumo_world_device_regression.log) | 44 |
| [lumo_world_camera_regression.log](native/lumo_world_camera_regression.log) | 27 |
| [kart_extra_drivers_regression.log](native/kart_extra_drivers_regression.log) | 333 |
| [kart_spatial_menu_regression.log](native/kart_spatial_menu_regression.log) | 641 |
| [kart_lan_entry_layout_regression.log](native/kart_lan_entry_layout_regression.log) | 78 |
| [kart_neon_home_regression.log](native/kart_neon_home_regression.log) | 2243 |
| [lumo_rival_rig_contract_regression.log](native/lumo_rival_rig_contract_regression.log) | 1558 |
| [lumo_kart_production_driver_regression.log](native/lumo_kart_production_driver_regression.log) | 8245 |
| [kart_driver_gesture_regression.log](native/kart_driver_gesture_regression.log) | 423 |
| [kart_meshy_assets_regression.log](native/kart_meshy_assets_regression.log) | 390 |
| [cards_character_roster_regression.log](native/cards_character_roster_regression.log) | 119 |
| **Summe** | **15.246** |

Die [maschinenlesbare Zusammenfassung](results.json) hält jeweils die originale Ergebniszeile fest. [IMAGE-VERIFICATION.json](native/IMAGE-VERIFICATION.json) verzeichnet zusätzlich **73 quellgebundene Rendererbilder** mit Hashes und den erklärten Viewports. Die Artefaktgröße und der Archivdigest wurden beim lokalen Übernehmen erneut abgeglichen. Es werden keine Bilddateien umbenannt oder alten Bildern neue Quellen zugewiesen.

## Tatsächliche APK und enthaltene Modelle

| APK-Eigenschaft | Bestätigter Wert |
| --- | --- |
| Dateiname bei der Lieferung | `Lumo-Lernen-0.14.6-2078.apk` |
| Größe | **701.640.419 Bytes** |
| SHA256 | `3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Version / Code | **0.14.6 / 2078** |
| ABIs | `arm64-v8a`, `x86_64` |
| Zertifikat SHA256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| PCK-Größe / SHA256 | 394.293.988 Bytes / `c5370a45b32fc72856dc4c0021d800f2e1189fdd47b2793f5a6016c04cf74578` |

[APK-VERIFICATION.json](apk/APK-VERIFICATION.json), [BUILD-PROVENANCE.json](apk/BUILD-PROVENANCE.json) und die unveränderten Original-SHA-Dateien dokumentieren die Identität. [KART-DRIVER-PACKAGE.json](apk/KART-DRIVER-PACKAGE.json) und [das zugehörige Originalprotokoll](apk/KART-DRIVER-PACKAGE.log) belegen **neun Fahrer und 27 Produktionsvarianten im tatsächlich entnommenen APK-Paket**.

## Bytegleicher Transport und lokale Nachprüfung

[Support-Run 45372281795](https://github.com/Ullmann27/lumo-lernen/actions/runs/45372281795) ist erfolgreich. Sein separater Commit lautet `7c0dcc03f45ef85442f7b1d1e3303f4645ac2224`. Er lädt ausschließlich Originalartefakt `14908418202`, prüft dessen Archivdigest und ursprüngliche Provenienz und teilt die unveränderten APK-Bytes in drei Teile.

Der direkte Connector-Download des Originalartefakts überschritt die tatsächlich beobachtete Grenze von 536.870.912 Bytes. Die drei Teile wurden deshalb einzeln heruntergeladen, gegen ihren jeweiligen GitHub-Archivdigest geprüft und unmittelbar aus dem ZIP an die Zieldatei angehängt. Teilgrößen: **251.658.240**, **251.658.240** und **198.323.939 Bytes**. Teilhashes und finaler Gesamt-SHA stimmen. Es erfolgten kein Neubuild und kein erneutes Signieren.

Belege: [Transportmanifest](transport/TRANSPORT-MANIFEST.json), [drei Prüfquittungen](transport/TRANSPORT-RECEIPTS.jsonl), [lokale Gesamtprüfung](transport/LOCAL-TRANSPORT-VERIFICATION.json), [aapt](transport/LOCAL-AAPT-BADGING.txt) und [apksigner](transport/LOCAL-APKSIGNER-VERIFY.txt). `apksigner verify` beendet sich mit Exit 0 und bestätigt Scheme v2 sowie das ursprüngliche Testzertifikat. Lokale Arbeitsverzeichnisse in diesen Belegen sind keine dauerhaften Downloadadressen.

## Originale Android- und SAF-Abnahme

Der ursprüngliche Androidjob **138363355593** im Versuch **1** bestand. Das unveränderte Androidartefakt **14910694437** hat **90.934.708 ZIP-Bytes** und SHA256 `570841ce0bbd0c93c7f0814e614f917ff6c26c66d49fc169607329bb974ee58d`. Der lokale Archivdigest und die hier übernommenen Originaldateien wurden beim Kopieren abgeglichen.

- [tour-result.json](android/tour-result.json): **23/23 Schritte PASS**, keine fatalen Abstürze im beobachteten Lauf. Die installierte APK ist an denselben SHA, Flutter-Commit, Godot-Commit und das Originalzertifikat gebunden.
- [NATIVE-GAME-STARTS.json](android/NATIVE-GAME-STARTS.json): **7/7 verpflichtende Starts PASS** — run, quiz, memory, chess, kart, cards, world. Das Gate beobachtet tatsächlichen UI-Start, Router-Ladebeleg und Prozessüberleben, nicht das vollständige Durchspielen.
- [native-starts.json](android/native-starts.json): **13/16 zusätzliche Diagnoseversuche** erfolgreich; settlement, build und treasure wurden in dieser UI-Diagnose nicht gefunden. Der Diagnoseumfang darf nicht als 16/16 oder als Ersatz für das getrennte Pflichtgate ausgegeben werden.
- [backup-result.json](android/local-backup/backup-result.json): **8/8 SAF-Schritte PASS**, einschließlich Export, Änderung, Dateiauswahl, Prozessende und Wiederherstellung.
- [ANDROID-AUDIT.json](android/ANDROID-AUDIT.json): unabhängiger Abgleich von **17 Einstellungen** und **zehn nativen Dateien**; exportierte, archivierte und wiederhergestellte Dateibytes stimmen überein. Payload-SHA256 `734e0f0e964c06211984eed773e13f3bfbfc80eea295e4446d37cd8f8785d9c6`.

Im Tourlog liegen **drei nichtfatale Godot-`can_process`-/Outside-tree-Meldungen** im Sternenpost-Zeitfenster 10:11:43.200, 10:11:52.227 und 10:12:59.363 UTC. Freiflug, Belohnung und Host-Rückkehr bestanden; es wurde kein fataler Absturz beobachtet. Der genaue Aufrufer ist im Log nicht erkennbar. Der Bericht behauptet keine fehlerfreien Gesamtlogs.

## Originalbild und verbleibender optischer Befund

![Originale Kart-Ansicht mit linker Pfeilfläche über dem Beginn von Sonnenhafen](android/visual/21_kart_premium_start.png)

Die unveränderte Aufnahme **21_kart_premium_start.png**, **2400×1080**, **1.333.585 Bytes**, stammt direkt aus dem originalen Androidartefakt. Root, model_audit und die anschließende Dokumentationsprüfung bestätigten: Im flachen Querformat überdeckt die linke Streckenpfeilfläche den Beginn des Wortes **Sonnenhafen**. Das bleibt als kleiner optischer Restbefund offen. Eine dadurch verursachte Funktions- oder Touch-Störung wurde nicht belegt. [Bildhash, Herkunft und Befund](android/visual/VISUAL-REMAINDER.json).

Das ebenfalls unverändert erhaltene [World-Endbild](android/visual/world-end.jpg) ergänzt den beobachteten World-Start. Es ist kein Nachweis vollständigen World-Gameplays oder physischer Geräteperformance.

## Beide Publisherfehler und fehlender öffentlicher Link

| Versuch | Originaljob | Tatsächlich beobachtetes Ergebnis |
| --- | --- | --- |
| 1 | 138384742953 | FAIL beim Push des vorgesehenen Quell-Tags; [Originalprotokoll](publisher/publisher-original.log) |
| 2, einmaliger Retry | 138386118647 | Derselbe Fehler beim Tag-Push; [Originalprotokoll](publisher/publisher-retry-original.log) |

Beide Originallogs melden: **Unable to determine if workflow can be created or updated due to timeout; workflows scope may be required.** Die Meldung belegt einen Timeout der GitHub-Workflow-Rechteprüfung. Sie beweist allein nicht, dass eine konkret benannte Berechtigung tatsächlich fehlt.

Der Retry veränderte weder Produktquellen, APK-Bytes, Signatur noch Berechtigungen. Nach dem zweiten Fehler bestätigte Root per read-only API **404 für Release und Tag**. Diese Beobachtung ist in [PUBLICATION-STATUS.json](publisher/PUBLICATION-STATUS.json) mit ihrer Herkunft gekennzeichnet; für dieses Dokumentations-Overlay wurde keine erneute Remoteabfrage ausgeführt. Beide Fehler bleiben Fehler. Es gibt hier **keinen öffentlichen APK-Link** und **keinen bereits bestandenen öffentlichen Voll-Download**.

Der vorbereitete öffentliche Byteverifier wurde nicht aktiviert. Seine aktuelle Fassung verlangt den erfolgreichen Publisher-Retry und ist deshalb bei diesem Stand nicht startbar. Der Nachweischeckpoint ist gesichert. Der unten dokumentierte zusätzliche Zugangscheck bestimmt die verbleibende Voraussetzung; eine Browser-Anmeldung ist nicht als alleiniger Weg festgelegt. Nach tatsächlicher Veröffentlichung muss der öffentliche Komplettdownload an genau diesen realen Veröffentlichungsweg gebunden und bytegeprüft werden.

## Nachtrag: verbundener GitHub-Zugang erneut belegt

Der Connector hat den zusätzlichen read-only Workflow erfolgreich gespeichert und gestartet. Run `45385067930` / Job `138413747264` belegt die fehlende Bereitstellung des vorgesehenen Publisher-Zugangs für diesen Job. Der [vollständige Zugangsbericht](publisher/GITHUB-ACCESS-STATUS.md), das [Originalergebnis](publisher/PUBLISHER-PREFLIGHT.json) und das [Originallog](publisher/publisher-preflight-original.log) sind gesichert. Das ist keine neue Produkt- oder Veröffentlichungsprüfung. Keine weitere Browser-Anmeldung, Veröffentlichung oder Rechteänderung wurde daraus abgeleitet.

## Updatekanal und Grenzen

Der bestehende Familien-Updateknopf akzeptiert ausschließlich veröffentlichte Prereleases `coachpreview-build-N` mit exakt `Lumo-Lernen-Neu.apk`. Ein manuelles Asset `Lumo-Lernen-0.14.6-2078.apk` unter dem vorgesehenen separaten Lumo-Tag wird dadurch nicht automatisch auffindbar. [Aktueller Kanalvertrag](../../../releases/LUMO_FAMILIEN_UPDATEKANAL.md).

Die 73 Bildhashes sind kein Beleg einer vollständigen manuellen Sichtprüfung sämtlicher Bilder oder perfekter UI in jeder Ansicht. Desktop-GLES und Emulator belegen keine physische Samsung-Fold7-/60-FPS-Abnahme. **Audioausgabe sowie ein vollständiges Zwei-Runden-Rennen mit Belohnung wurden in dieser Tour nicht abgenommen.** SAF prüfte weder das Wiederherstellen eines laufenden nativen Spielprozesses noch reale Nutzergeräte. Das vorhandene Zertifikat ist eine Testsignatur, keine Play-Store-Produktionssignierung. Die Fahrerintegration behauptet keinen Austausch aller ursprünglichen Dorf-NPCs. Frühere Fehlversuche und der bekannte Headless-Dummy-Renderer-Befund bleiben im übergeordneten historischen Bericht erhalten.

[results.json](results.json) trennt die bestandenen Qualitätsstufen, die bekannten Grenzen und den Veröffentlichungshalt. [evidence-index.json](evidence-index.json) enthält Herkunft, Größe und SHA256 der unverändert übernommenen Belegdateien. Erzeugte Zusammenfassungen und Root-Beobachtungen sind als solche gekennzeichnet.
