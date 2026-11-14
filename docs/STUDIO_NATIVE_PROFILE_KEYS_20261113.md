# Stabile native Spielstand-Identität und getrennte Altstand-Wiederaufnahme

## Bestätigter Ausgangsfehler

Der bisherige Launcher berechnete `childKey` aus einem globalen Salt, dem
Anzeigenamen und der Klassenstufe. Zwei unterschiedliche gespeicherte
Schülerprofile mit gleichem Namen und gleicher Klasse erhielten dadurch
denselben Schlüssel. Ein Klassen- oder Namenswechsel erzeugte hingegen einen
anderen Schlüssel für dasselbe Kind. Der konkrete Vorher-Nachweis steht in
`STUDIO_LEARNING_INDEPENDENT_REVIEW_20261113.md` und dessen Rohlog.

## Produktive Reparatur

`NativeProfileKeyRepository` speichert eine dauerhafte Zuordnung von der
bestehenden stabilen Lernprofil-ID zum nativen Hauptschlüssel. Der Launcher
erfasst diese ID über `captureLearningProfile().studentId`, bevor er auf
Einstellungen, Belohnungsspeicherung oder andere asynchrone Arbeit wartet.

Neue Schulprofile erhalten einen aus ihrer ID abgeleiteten Schlüssel. Name und
Klasse sind danach keine Identitätsmerkmale mehr. Eine Umbenennung, ein
Klassenwechsel oder eine neu angelegte Repository-/App-Instanz ändert die
bereits gespeicherte Zuordnung nicht.

Der lokale Einzelprofil-Upgradefall behält den **exakten bisherigen Schlüssel**:
Das lokale `self`-Profil darf den alten Name-/Klasse-Schlüssel einmal fest
binden, wenn bereits ein Salt vorhanden ist, kein Schulkind ausgewählt ist und
keine Schulprofile existieren. Eine beschädigte oder mehrdeutige Schulablage
wird nicht als leere Schülerliste behandelt. Aktive Schulprofile bekommen
immer ihre eigene ID-basierte Hauptidentität. Ist ein alter Schlüssel bereits
gebunden, erhält ihn kein zweites Profil.

## Erreichbare Elternbedienung für historische Stände

Der vorhandene Elternbereich enthält nach der Lernstand-Zuordnung eine neue
Karte **„3D-Spielstände“ → „Spielstände verwalten“**. Normale Spielstarts
stellen keine zusätzliche Frage.

In dieser Ansicht können Erwachsene für das aktuell gewählte Kinderprofil
den damals verwendeten exakten Namen und die damalige Klasse eingeben. Der
anschließende Dialog verwendet das vorhandene ausdrückliche
Erwachsenen-Bestätigungsmuster. Der Bestand besitzt bewusst keinen PIN-Stack;
es wurde keiner ergänzt und keine verifizierte Erwachsenenidentität behauptet.

Eine bestätigte Altstand-Zuordnung bleibt getrennt vom normalen Hauptstand.
Der frühere Schlüssel kann nur einem Besitzer gehören. Unter **„Zugeordnete
ältere Stände“** wird ein Spiel gewählt und dieser Altstand ausdrücklich
geöffnet. Der normale Start aus der Spielewelt verwendet weiterhin den
Hauptstand. Für Jump & Run kann zusätzlich das damals gewählte Fach angegeben
werden, weil dessen vorhandene Sitzungspfade auch Fach und Klasse enthalten.

Die bestehende Android-Brücke bietet keine native Spielstand-Inventur. Die
Ansicht behauptet daher nicht, eine Datei gefunden zu haben. Sie erklärt,
dass das Spiel neu startet, falls unter den angegebenen früheren Daten keine
Datei existiert. Die unveränderten nativen Spiele öffnen genau ihre bisherigen
Dateipfade aus dem geprüften Schlüssel.

## Datenerhaltung und asynchrone Grenzen

Dieser Patch liest, kopiert, benennt, löscht oder vereinigt keine nativen
Spielstanddatei. Er verändert ausschließlich die zusätzliche Identitätsablage.
Auch historische Altstände werden keinem Kind automatisch zugeteilt und nicht
an mehrere Kinder kopiert. Die gespeicherte Hauptzuordnung wird bei einer
Altstand-Zuordnung nicht überschrieben.

Kurze Schreiboperationen laufen über die vorhandene `LearningStorage`-
Serialisierung. Eine fehlgeschlagene Plattform-Schreibung lädt den
`SharedPreferences`-Cache erneut, damit ein lediglich optimistisch gesetzter
Wert nicht als dauerhafte Zusage gilt. Unlesbare Zuordnungen und ein fehlender
Salt werden nicht verworfen oder durch neue Werte ersetzt.

Vor und nach Speicheroperationen sowie unmittelbar vor dem nativen Start
werden die erfasste Profilgeneration, die Lease-Gültigkeit und die tatsächliche
aktive Auswahl geprüft. Das gilt auch nach der nativen Rückkehr. Der letzte
Punkt wurde nach einem unabhängigen Review von Agent B ergänzt: Eine
Sitzungs-Epoche kann bereits ungültig sein, bevor eine langsam laufende
Reset-Operation die Profilgeneration erhöht.

Eine bereits abgeschlossene Schreibung bleibt beim ursprünglich erfassten
Besitzer, wenn währenddessen das Profil gewechselt wurde. Sie autorisiert
keinen Start für das danach sichtbare Kind. Abgebrochene Erwachsenen-Dialoge
schreiben keine Altstand-Zuordnung.

## Geänderte produktive Dateien

- `lib/core/native_profile_key_repository.dart` – neue persistente,
  exklusive Haupt-/Altstand-Zuordnung.
- `lib/features/lumo3d/lumo3d_launcher.dart` – stabile Owner-Erfassung,
  Lease-Wachen und geprüfter separater Altstart.
- `lib/features/lumo3d/native_game_saves_screen.dart` – Erwachsenen-Dialog,
  Erhaltung des Hauptstands und explizite Altstand-Wiederaufnahme.
- `lib/features/settings/native_game_saves_card.dart` – neuer Einstieg im
  vorhandenen Elternbereich.
- `lib/features/settings/settings_content.dart` – ausschließlich ein Import
  und die neue Karte nach `LegacyLearningDataCard`.

Es wurden für diesen Reparaturauftrag keine Godot-, Kotlin-, Android-Manifest-
oder sonstigen nativen Quelldateien geändert. Vorhandene Lernergebnisse,
Kompetenzen, Belohnungen, Schreibtrainer und Journal wurden nicht neu bewertet.

## Ausgeführte Verifikation

Der kombinierte Lauf auf dem implementierten Stand bestand mit **53 Tests**:

| Prüfung | Anzahl / Ergebnis |
| --- | --- |
| Neue `native_profile_key_repository_test.dart` | 12 bestanden |
| Neue `native_profile_keys_ui_test.dart` | 7 bestanden |
| Vorhandene `lumo3d_launcher_lifecycle_test.dart` | 15 bestanden |
| Vorhandene/native Lernlauncher- und Sharing-Tests | Zusammen 19 bestanden |
| Gezielte Analyse der vier neuen/geänderten Module und beider Tests | Keine Probleme |
| `git diff --check` | Bestanden |

Die Tests prüfen insbesondere echte, separat gespeicherte gleichnamige
Schülerprofile, einen Klassen-/Namenswechsel, App-/Repository-Neustart,
exakte alte Einzelprofil-Dateischlüssel, konkurrierende Zuordnungen,
Abbrechen, Plattform-Schreibfehler, Profilwechsel vor und während des
Speicherns, ungültige Lease beim Rückweg sowie beschädigte Bestandsdaten.

Der Widgettest benutzt die tatsächliche `SettingsContent`-Elternkarte,
Formularfelder, Dialogknöpfe und Rücknavigation. Er öffnet den zugeordneten
Altstand und anschließend den normalen Hauptstand über den produktiven
Launcher. Die native MethodChannel-Grenze wird hierbei simuliert; das ist kein
Android-Gerätetest. Die invalidierte Lease beim Return wird im Test gezielt
über die vorhandene `canUseLearningLease`-Schnittstelle ausgelöst, ohne die
Profilgeneration zu verändern.

Die letzte vollständige Ausführung steht in
`docs/evidence/studio-native-profiles-20261113/final-targeted.log`. Ein separater
abschließender UI-Lauf und die Analyse stehen in `profile-ui.log` und
`analyze.log`. Ein vorheriger Fehler im Test-Navigator wurde durch die echte
Rücknavigation behoben; sein ursprüngliches Protokoll bleibt unter
`initial-profile-ui-fixture-failure.log` erhalten.

## Neue sichtbare Evidenz

Mit `LUMO_NATIVE_PROFILE_CAPTURE_DIR` erzeugt der Widgettest tatsächliche
Flutter-Rendererbilder. Die vier Aufnahmen sind:

- `native_profiles_parent_entry.png` – produktiver Elternbereich mit neuer Karte.
- `native_profiles_adult_confirmation.png` – ausdrückliche Zuordnung mit Abbruch.
- `native_profiles_phone.png` – vollständige Ansicht bei 412 × 915.
- `native_profiles_fold.png` – Ansicht bei 840 × 760.

Die Aufnahmen wurden visuell geprüft: Texte und Formulare sind lesbar; die
getrennte Altstart-Aktion ist sichtbar und überdeckt keine andere Aktion.
Zusätzlich prüft der Widgettest die Bildschirmgrenzen und eine mindestens
48 Pixel hohe Altstart-Schaltfläche. Die Aufnahmen stammen aus dem
Flutter-Widgetrenderer und sind keine Android-Emulator- oder Fold7-Aufnahmen.

Quell-, Log- und Bildhashen sowie die Ausführungsgrenzen stehen in
`docs/evidence/studio-native-profiles-20261113/RESULT.json`.

## Integrationsgrenze

Diese Reparatur belegt die native Spielstand-Identität und ihre Wiederaufnahme.
Sie ist kein neuer Nachweis für eine vollständige Trennung des unveränderten
globalen Belohnungswallets oder aller eingebetteten Ereignisdienste. Der finale
gesamte Flutter-Lauf und der neue Android-Upgrade-/APK-Lauf müssen den
anschließend gesicherten Hostcommit verwenden; frühere Läufe werden diesem
Patch nicht zugerechnet.
