# Lumo Familien-Testversionen – Updatekanal

Diese Anleitung gehört zur unabhängigen APK-Variante `dev.ullmann.lumo.lumo_lernen.coachpreview`. Die normale Lumo-App verwendet **weiterhin** `/releases/latest` und das Asset `Lumo-Lernen-latest.apk`.

## Kanal und Verhalten

- Die Familien-App (`--dart-define=LUMO_SIDE_BY_SIDE=true`) prüft `https://api.github.com/repos/Ullmann27/lumo-lernen/releases?per_page=50` auf veröffentlichte **Prereleases**.
- Ausschließlich das exakte Tagmuster `coachpreview-build-N` mit dezimaler positiver Versionsnummer und dem gleichnamigen Asset `Lumo-Lernen-Neu.apk` wird berücksichtigt.
- Release-Seite und Download-URL müssen exakt zum selben Tag gehören; die Domain bleibt auf `github.com/Ullmann27/lumo-lernen/releases/...` beschränkt.
- Unveröffentlichte Drafts, normale Releases, falsche APK-Namen, Fremddomains und ältere Versionen werden ignoriert.
- Die neueste passende Version wird gewählt; die App startet nur bei einem höheren `versionCode` die Übernahme. Danach muss der Nutzer dem Android-Systeminstaller zustimmen. Keine stille Installation.
- Der Button im Elternbereich zeigt während des Downloads Prozentfortschritt. Fehler oder fehlende Installationsberechtigungen werden angezeigt.
- Lokal gespeicherte Profile/Sterne bleiben bei einem **Update derselben Paketkennung mit derselben Signatur** erhalten. Nie vorab deinstallieren.

## Wichtiger Einmalschritt

1940/1941 besitzen diese neue Kanal-Logik noch nicht. Die erste APK mit Familien-Updatekanal (voraussichtlich Build 1942) muss **einmalig manuell installiert** werden. Erst künftige Veröffentlichungen können dann über den Button gefunden werden.

## Sichere Freigabe eines künftigen Builds

**Nicht automatisch veröffentlichen oder nach `main` mergen.** Zuerst explizite Freigabe, reale Fold-/Android-Testinstallation und Hörtest der Stimme einholen.

1. Den exakten CI-Head/Build mit `flutter analyze`, gesamter `flutter test`-Suite, Backend-Tests, `scripts/verify_unified_apk.py` sowie SHA-256 prüfen.
2. Gegen die bestehende Familien-App die Android-Paketkennung `dev.ullmann.lumo.lumo_lernen.coachpreview`, denselben Signaturzertifikat-Fingerprint und einen **größeren** `versionCode` prüfen. Keine ungeprüfte Umbenennung einer Original-APK.
3. Nutzerseitige Abnahme auf Fold (Cover, aufgeklappt, Lernhilfe, Geschichten, Ton, Kart) dokumentieren.
4. Erst danach genau die geprüfte signierte Datei **unter dem Namen `Lumo-Lernen-Neu.apk`** im neuen **Prerelease** `coachpreview-build-N` hochladen. Der Release muss öffentlich lesbar sein, damit Geräte ohne GitHub-Login ihn finden. Ein Draft wird absichtlich nicht angeboten.
5. Von einem bereits aktualisierten Familiengerät auf `Auf Update prüfen` tippen, Fortschritt und Android-Installer prüfen, danach Lernstände vergleichen.

## Grenzen

Der Kanal ist für öffentlich lesbare Releases, **nicht** ein privater, authentifizierter Familienverteiler. APK-Downloadlinks können von Dritten gesehen werden. Keine privaten Nutzerprofile, API-Schlüssel oder Familiendaten in GitHub-Releases packen. Geräte ohne passende Signatur können nicht aktualisieren. Keine automatische Download-/Installationsausführung ohne Nutzerhandlung. Die Android-Installation selbst bestätigt die gleiche Paketkennung/Signatur; der Kanal ersetzt keine Signaturprüfung.
