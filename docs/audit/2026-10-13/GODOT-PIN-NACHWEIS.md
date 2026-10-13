# Godot-Pin: erneut geprüfte CI-Provenienz

Produktpin: `ec96515a2e359d21e9591120fc81dfd15116e81e`, Godot 4.6.3. Am 13.10.2026 wurden Metadaten, Jobs, Originalprotokolle und Artefakt erneut gelesen. Keine Godotdatei und kein Pin wurden verändert.

[Stage2-Lauf 38238000582](https://github.com/Ullmann27/lumo-godot/actions/runs/38238000582), Job `114773338263`, ist erfolgreich. Checkout und `git log -1` belegen den exakten Pin. Engine: `4.6.3.stable.official.7d41c59c4`. Import-, Modell-, Physik-, Renn-, Touch- und Animationsprüfungen sowie tatsächliche Godot-Aufnahmen stehen im Originalprotokoll. Das ist ein Nachweis für dieses unveränderte Godotprojekt, kein neuer Android-, Flutterhost- oder physischer Fold-Leistungsnachweis.

Andere erfolgreiche PR-65-Läufe prüften dagegen `45995f0` aus `refs/remotes/pull/65/merge`, einen Merge von `ec96515…` in `82b53fc…`:

- VideoGrade: Lauf 38238000587, Job 114773338416.
- RivalFeedback: Lauf 38238000579, Job 114773338274.
- Vehicle: Lauf 38238000591, Job 114773338520.

Ihre Testzahlen werden nicht ungeprüft als Nachweis des Pins übernommen. Diese Unterscheidung folgt aus den echten Checkoutzeilen, obwohl die Head-Metadaten `ec96515…` enthalten.

Artefakt `11742720010` wurde heruntergeladen; ZIP-SHA256 ist `2fe6f9e16c77c28f2595f80a035cb4e61d6f2ef419ee9892895c8b93a8872b19`. `STAGE2-CHARACTER-EVIDENCE.json` bestätigt Pin, Engine sowie 2.325 Pose-, 23 FaceDepth- und 225 StartHero-Kontrollen. Alle 15 darin erfassten Quelldateien stimmen per SHA256 mit dem lokalen Pin überein. Ausgewählte Originalbilder und Manifest unter `visuals/ec96515-*`: historische Godotlaufbilder, keine neue APK.

Astra PR #57 ist Vorfahr des Pins. Animationsadapter und Kontaktregression sind identisch; Details in `ASTRA-ANBINDUNG.md` und dem Quellvergleich.

Konkreter Build-Prüfpunkt: Der ältere App-Workflow `lumo-runtime-apk.yml` erwartet an drei Stellen nur 69 StartHero-Kontrollen. Der aktuelle Pin-Nachweis enthält 225. Vor Verwendung dieses Workflows müssen der tatsächlich ausgeführte Probe und sein neues Character-Evidence verglichen werden. Keine Zahl wird ungeprüft übernommen oder gelockert.

Vor der freigegebenen Gesamt-APK bleiben konkrete Flutterhost-, Bridge-, PCK-, Offline-Stimmen-, Paket-, Signatur-, Update- und Androidprüfungen nötig.
