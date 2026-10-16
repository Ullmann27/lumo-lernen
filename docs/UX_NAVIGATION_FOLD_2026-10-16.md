# Lumo 1950 · Kindermenü und Fold-UI · 16. Oktober 2026

Basis: Flutter 1949 und unveränderte Godot-4.6.3-Spielressourcen.
Primärziele: Start, Lernen, Spielen, Tests, Belohnungen, Profil.
Entdecken öffnet drei Themenwelten und macht alle acht bisherigen Sektionen mit einem weiteren Tap erreichbar.
Lernen & Üben: Lesemodus, Übungen, Schularbeit, Foto.
Meine Erfolge: Missionen, Fortschritt.
Lumo & Eltern: Lumo-Assistent, Eltern.
Kein Abschnitt, Spielstand, Profil oder Lernzustand wird gelöscht.
Mindestens 48dp große Touchfelder der sekundären Navigation; derselbe LumoSection-Navigationsstatus.
Inaktive Navigationsbuttons stoppen ihre Daueranimation.
Kontrastreparaturen gelten nur für alte weiße Lernkarten, nicht für die globale Dunkelpalette.
Journal, Foto, Rechentricks und Lesemodus erhalten Original-Lumo-Illustrationsassets und Bibliothek-Szenenhintergrund.
Das Journal erhält auf dem Fold eine maximal 760dp breite vollständige Karte.
Godot-Kameras, Shader und Physik bleiben unverändert.
Nachweis: test/lumo_child_navigation_cluster_test.dart und .github/workflows/lumo-1950-unified-visual-apk.yml.
