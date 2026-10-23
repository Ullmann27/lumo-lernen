# Lumo Next Generation – integrierte Navigation

**Auftrag:** Ausführungsauftrag vom 23.10.2026; zuerst aktive alte Menüs entfernen,
vorhandene Lernlogik und Originalgrafik erhalten. Keine neue Konzeptfreigabe nötig.

**Basis:** Flutter PR404 `5d269c3608771f9a61434b4eb8b03ab4521fdf7a` enthält
PR401/Kristalle und PR331. Godot-Pin bleibt `3a3142608f6b150ee251373ba81e6face2eed4b3`.
Dieser enthält PR113/114; keine automatische Übernahme ungeprüfter Branches.

- [ ] Regression zuerst: Klassenwahl ist im modernen Hub direkt erreichbar;
  Thema öffnet echte Aufgabe, Profilklasse bleibt unverändert.
- [ ] Kleinen Browsing-Controller in der Shell halten (Klasse/Fach), keine
  dauerhaft lebenden Audio-/Spiel-/Scanner-Screens. Zurück: Aufgabe → Themen →
  Fächer → Start. Home-Fachkarten öffnen denselben Hub mit vorausgewähltem Fach.
- [ ] Alte Academy-Präsentation aus der aktiven Navigation entfernen;
  Original-Spezialmodule, Geschichten und Schreibtrainer direkt anbinden.
- [ ] 16 Fach-/Klassenpfade, Spezialmodule, Zurück und schmale/Fold-Layouts prüfen.
  Vorhandene Tests auf tatsächlich produktive Routen umstellen, Pixel-/Touch-
  und Safe-Area-Anforderungen erhalten.
- [ ] Additive, profilgetrennte Tagesmission separat integrieren. Keine
  Behauptung eines vollständigen Offline-Manipulationsschutzes; vorhandene
  globale/native Reward-Identität als offene Migrationsaufgabe dokumentieren.
- [ ] Statische Analyse, Flutter-/Python-Regression, vorhandene Godot-Tests und
  echten kombinierten Android-Build versuchen. APK nur nach verifizierter
  Android-Tour veröffentlichen. Alle Grenzen in Übergabe und Commit sichern.

**Prüffokus:** Schulklasse beim Browsen unverändert; kein fremder Lernfortschritt;
Spezialmodule statt Chat-Fallback; richtige Frage nach Themenwahl;
Android-Zurück erhält den Fachkontext. Kein Main-Merge/Force-Push/Signaturwechsel.
