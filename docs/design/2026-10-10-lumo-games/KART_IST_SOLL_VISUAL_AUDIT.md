# Lumo Kart – Abweichungsanalyse der sechs echten Rennansichten

**Referenz-/Vergleichsdatum:** 10. Oktober 2026. Der Auftraggeber hat einen 3×2-Vergleich echter Godot-Laufzeitbilder eingereicht (Holo City, Himmelsinseln, Sonnenhafen, Zauberwald und reduzierte Bewegung). Die Rennszenen stammen aus dem GitHub-Lauf [Kart Video Reference Grade](https://github.com/Ullmann27/lumo-godot/actions/runs/38045869261), der die tatsächliche Geometrie und Kamera prüft. Die **Designziele** stehen in den unverändert archivierten Bildern unter `references/`; die sechs Rennbilder sind eine **Ist-Aufnahme**, nicht die Zielqualität.

## Festgestellte Abweichungen aus dem 3×2-Vergleich

| Welt / Aufnahme | Im tatsächlichen Renderer erkennbar | Konkrete nächste Produktionsmaßnahme |
| --- | --- | --- |
| Holo City, normal und Boost | Neon und Linienführung funktionieren, aber Bauten/Straßenbild haben zu wenige Fassadendetails; Kart und Fuchs wirken aus Kameradistanz schlicht und kantig. | Ein kleines Set modularer High/Low-LOD-Stadtfassaden, Lichtfenster, Türen, Vorsprünge und Straßenrequisiten mit sauberem PBR, gebündelten Instanzen und Abstandslimits; Lumo/Kart Hero-LOD überprüfen. |
| Himmelsinseln | Beleuchtete Bögen und schwebender Streckenverlauf sind sichtbar. Wiederholungsmuster und einfache Silhouetten wirken künstlich. | Individuell modellierte schwebende Felsen, Wasserfall-/Schloss-Hintergründe, Brückenverbindungen und größere Landmarken; keine Änderungen an der vorhandenen Sprungbahn und den Kollisionsflächen. |
| Sonnenhafen | Rennstrecke mit Küste vorhanden; Umgebung besteht überwiegend aus wenig strukturierten, flach gefärbten Oberflächen. | Gestaffelte Architektur, Bäume, Hafenobjekte, Geländer und Ufer-/Wasser-Shader mit LOD und Schattenbudget, visuelle Variationen statt flacher Grundflächen. |
| Zauberwald, normal und reduzierte Bewegung | Pastellige Baumkronen und Vegetation sind sehr wiederholt, stark vereinfachte Formen, kaum räumliche Schattierung. | Begrenztes modulartes Baum-/Pilz-/Felsen-Asset-Kit in Blender, besseres Laub-/Rinden-Baking, 2–3 LOD-Stufen, sparsame warm-kalte Lichtinseln, größere organische Silhouetten. |
| Alle sechs | Das Kart wird aus der Verfolgerkamera eher klein und mit vergleichsweise einfachen Rädern/Chassis dargestellt. Die HUD-Felder sind teilweise klein und wenig kontrastreich. | Kart-Fahrzeugsilhouette und Lumo anhand `assets/characters/lumo/reference/` und `references/50288.png` in echten Frontal-/Seiten-/Rückansichten prüfen; maximaler sichtbarer Bildschirmanteil ohne Sichtbehinderung, kindgerechte HUD-Touchgrößen/Fold-Sicherheitsabstand. |

## Maßnahmen nach Priorität

**P0 – Markenidentität und Spielbarkeit erhalten.** Keine Änderung von Lern-App-Hauptmenü, Kinderprofilen, XP, Original-Lumo-Gesicht, Streckenlaufbahn, Rennphysik, Speicherständen oder Spielmodi. Die Quelle der Designwahrheit bleibt `DESIGN_BESTANDSSCHUTZ.md` plus Originalbilder.

**P1 – Tatsächliche 3D-Modelle und Materialien verbessern.** Keine bloße Bildüberlagerung. Erstelle in Blender unabhängige austauschbare GLB/LOD-Assets mit UVs, baked AO/Normal/Roughness, klaren Silhouetten und separaten Emissionsdetails. Erst nach echter Runtime-Kontrolle als Ersatz einbauen. Synthetische Concept-Art gilt niemals als installierbarer Game-Asset-Beleg.

**P2 – Lebendige Strecken statt weiterer flacher Neonlinien.** Pro Welt mindestens drei unterschiedliche Landmarken-Setpieces und organische Requisitenfamilien. Für große Detailmengen MultiMesh verwenden; keine Tausende CollisionShapes für Gras, keine unnötigen Schatten bei jeder Kleinigkeit.

**P3 – Licht und Oberfläche.** Tonemapping, PBR, weich begrenzte Lichtquellen, Farbbounce über gebackene Maps statt pauschalem SDFGI. Mobile Vulkan und GL Compatibility mit sichtbarer vergleichbarer Markenoptik, aber getrenntem Leistungsprofil. Keine unbelegte Behauptung von SSR auf Android.

**P4 – Quantitative Abnahme.** Für jede der vier Landschaften identischer realer Screenshot-/Kamera-/Geschwindigkeitszustand vorher/nachher; Bildseite an Seite, Kamera und FOV dokumentieren, GPU-Zeiten und Speicheraufnahme auf realen Geräten messen, mindestens 30 FPS auf definierten Zielgeräten nachweisen. Saubere 1280×720-, 800×480-, 640×360- und Fold-Layouts; Prozedur beweist alle fünf Menüpunkte tatsächlich zugänglich.

## Abnahmeformel

**Fertig** bedeutet nicht, dass ein Godot-Test grün ist. Fertig bedeutet: Funktionsregression **plus** Lumo-Silhouette **plus** wahrnehmbar bessere 3D-Modell-/Materialqualität **plus** abgebildetes Referenzdesign **plus** messbare Android-Leistung. Die vorliegenden sechs Bilder belegen die Funktion und den Stand der Umgebung, **aber keine Pixel-/Qualitätsgleichheit** mit den anspruchsvollen Referenzbildern.

Konkrete Engine-Einstiegspunkte für Sonnet: `kart_vehicle.gd`, `kart_character_finish.gd`, `kart_world.gd`, `kart_world_meshes.gd`, `kart_track_detail.gd`, `kart_expansion_world.gd`, `kart_stage.gd` sowie der sichere additive Renderer-PR [#46](https://github.com/Ullmann27/lumo-godot/pull/46).
