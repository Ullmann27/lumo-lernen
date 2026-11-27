# Baby Lumo – Live-Gespräch, erster Implementierungsstand

Basis: 6574b19f92abb4f6421fd3074cec09738dc0974a (2082). Original:
assets/lumo_jump/fox/master/lumo_fox_master_512.png und vorhandene
Idle-Sprites. Violetter Kapuzenpullover, gelber Stern. Der native
65-Knochen-Rennfuchs ist nicht dieselbe Figur und wird nicht verwendet.

## Implementiert
- Auftritt im bestehenden Lern- und Gesprächsfenster: größerer Baby Lumo,
  weicher Pop-in, Atmung, Blinzeln, Kopf-, Pfoten- und Schwanzbewegung,
  Zuhören, Denken, Sprechen, beruhigender Ausdruck.
- Originale 2D-Gelenk-/Maskenanimation. Ausschließlich während des eigenen
  hörbaren Audioauftrags wird die Mundöffnung durch echte Wiedergabe-
  Hüllkurve gesteuert; kein künstlicher Sprechoszillator in diesem Modus.
- Kind kann Hallo sagen, Fragen stellen und die Antwort vorlesen lassen.
  Vorhandene Alters-/Aufgabenregeln, Elternfreigaben, lokale Stimme,
  Gesprächs- und Mikrofonsteuerung bleiben zuständig. Kein neuer Anbieter,
  kein automatisches Einschalten des Mikrofons, keine neue Telemetrie.
- Reduzierte Animation, inaktiver Dialog, Audioabbruch und Pause werden
  berücksichtigt. Unbeteiligte Audioaufträge dürfen den Mund nicht öffnen.

## Grenzen / Abnahme
Kein vollständiges 3D-Rig: kein passender verifizierter Baby-Lumo-GLB
im geprüften Bestand; der vorhandene Rennfuchs darf nicht ersetzt oder
umetikettiert werden. Amplitudenbasierte Mundöffnung ist keine
Phonem-/Visem-Synchronisation. Noch keine Geräte- oder Flutter-Ausführung
in dieser Arbeitssitzung. Kein APK-Release und kein Main-Merge.

Nächster 3D-Schritt: Originalfigur als Textur-/Formreferenz verwenden;
neutralen A-Pose-Mesh mit geschlossenem, separat modelliertem Unterkiefer,
Augen und Zunge herstellen; Körper-, Finger-, Ohr- und Schwanzknochen
mit Skinning versehen; Viseme und Blinzeln als Morph Targets exportieren;
die vorhandene Audio-Lease weiterverwenden, mit zeitcodierten Phonemen
der lizenzierten lokalen Stimme erweitern. Viseme nur bei verifizierten
Zeitdaten behaupten. Auf realem Fold und Tablets Bildrate, Wärme,
Audio/Video-Offset und Lebenszyklus messen.

## Lokale Prüfung
flutter test test/lumo_animated_fox_motion_test.dart
flutter analyze

Zusätzlich bestehende Gesprächs-, Kinderschutz- und Lernkontexttests
ausführen. Keine externe CI manuell gestartet.
