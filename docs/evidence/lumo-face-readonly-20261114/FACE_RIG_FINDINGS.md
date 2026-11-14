# Original-Lumo: begrenzter Gesichts- und Rigbefund

**Stand: 14.11.2026. Reine Untersuchung; keine Gesichtsanimation implementiert.**

Das derzeit verwendete Original kann seinen Kopf und Hals bewegen. Für echtes Blinzeln, unabhängige Augenbewegung und Kieferartikulation fehlen dagegen die benötigten getrennten Steuerflächen. Das ist eine konkrete Assetgrenze und lässt sich nicht allein durch das Aktivieren vorhandener Animationen beheben.

## 1. Tatsächlich gelesene Originale

`assets/characters/lumo_animated/Lumo-Animated-Mobile.glb`:

- SHA256 `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`, 5.156.596 Bytes.
- Ein exportiertes Mesh, ein Mesh-Primitiv, ein Material, 21.659 exportierte Vertices und 30.000 Dreiecke.
- Drei eingebettete Texturen mit je 1024 × 1024 Pixeln: Grundfarbe, Normalen und Metallic/Roughness.
- 65 Knochen. `Neck`, `Head` und `Crown` existieren; keine gesonderten Augen-, Lid-, Brauen-, Lippen- oder Kieferknochen.
- Keine Morphziele im GLB, keine Shape Keys im tatsächlichen Blender-Import. Die neun vorhandenen Originalclips animieren Knochenposition, Rotation und Skalierung, keine Morphgewichte.
- Im Import haben 9.448 Vertices einen positiven `Head`-Gewichtsanteil; bei 9.391 ist `Head` das stärkste Gewicht. Diese Gruppe umfasst große Teile des Kopfes und ist keine anatomisch getrennte Lid- oder Unterkiefergruppe.

Die Datei `docs/evidence/studio-character-20261113/Lumo-Studio-Actions.blend` hat SHA256 `9c4d1695b86214b44ce97fc844abdf6a36316fc38d99c769f3a068ff803b2b9e`. Sie ist eine **Actions-Library mit sechs Actions**, nicht eine vollständige gespeicherte Figurenszene: Der echte Blender-Ladevorgang zeigt null Objekte, Meshes, Armatures, Materialien und Shape Keys. Die Bewegungs-Actions werden auf das Originalrig angewendet. Für Gesichtsbearbeitung muss das Original-GLB importiert beziehungsweise eine neue vollständige Autorenkopie angelegt werden.

Blender erzeugt beim GLB-Import außerdem eine `Icosphere` als gemeinsame Knochenanzeige in `glTF_not_exported`. Alle 65 Pose-Bones verwenden sie als Custom Shape. Sie ist **kein zusätzlicher Augapfel des Originalassets**; das GLB selbst enthält nur das eine Figurenmesh.

## 2. Geometrie und Textur getrennt betrachtet

Der Originalfarbatlas wurde unverändert aus dem GLB extrahiert und tatsächlich angesehen. Er enthält erkennbar Augenweiß, braune Iris, schwarze Pupillen und Augen-/Brauenkonturen. Zusätzlich wurden in Blender 4.3.2 zwei echte Nahaufnahmen erstellt und einzeln angesehen:

- `original-face-textured.png`: Originalmaterialien und unveränderte Geometrie.
- `original-face-geometry-only.png`: dieselbe unveränderte Geometrie mit ausschließlich im Arbeitsspeicher gesetztem neutralem Material-Override.

Beide Bilder sind 512 × 512 Pixel, Cycles CPU, 24 Samples, ohne Denoising. Sie zeigen **Ruhegeometrie**, keine neue Animation. Augenwölbungen, Augenrand, Schnauze, Nase, Ohr- und Brillenformen bleiben im geometrischen Bild sichtbar; Iris- und Pupillendarstellung verschwinden ohne die Textur. Die Mundregion zeigt eine geschlossene beziehungsweise eingezogene Ruhekontur. Eine separat steuerbare Unterkieferfläche, Lippenringe oder eine brauchbar artikulierte Mundhöhle sind dadurch nicht nachgewiesen.

Das importierte Mesh besitzt viele Topologie-/UV-Trennungen. Ein rein positionsbasierter Zusammenhangstest ergibt keine anatomisch benannten Gesichtsteile. Der zusätzliche Kantenbericht ist ausdrücklich nur eine technische Zählung mit dokumentierter Rundung, kein Nachweis anatomischer Lid-Loops oder einer fehlerfreien Mundhöhle. Die lokale Gesichtstopologie muss vor Verformung tatsächlich ausgewählt und kontrolliert werden; pauschales Skalieren des gesamten Kopfes wäre kein korrekter Ersatz.

Original-GLB und Actions-Library sind vor und nach beiden Blender-Aufrufen SHA256-gleich geblieben. Es wurde keine `.blend` oder `.glb` gespeichert oder exportiert.

## 3. Vorhandene produktive Anschlüsse

| Anschluss | Tatsächlicher Zustand |
|---|---|
| `lumo_rigged_actor.gd` | Lädt das Original-GLB und verlangt genau 65 Knochen sowie die neun Originalclips. `mouth_supported` ist ausdrücklich `false`. |
| `set_teaching_target()` / `lumo_teacher_pose.gd` | Bereits begrenzte, nach dem Originalclip angewandte Kopf-/Halsorientierung. Das ist Aufmerksamkeit durch Kopfbewegung, keine unabhängig bewegte Pupille. |
| `apply_speech_sample(media_seconds, envelope, speaking)` | Vorhandene Transportgrenze für tatsächliche Wiedergabezeit und Lautstärkehüllkurve. Sie speichert Werte; sie verformt heute keinen Mund. |
| `lumo_eye_system.gd` / `lumo_mouth_system.gd` | Bedienen die separate primitive `scenes/characters/lumo/lumo_character.tscn`: Kugelaugen, Boxbrauen und einen Kapselmund. Deren Skalierungs-/Buchstabenfolgen sind keine Gesichtsanbindung des Original-GLB und kein Lippensynchronitätsnachweis. |

## 4. Kleinste saubere Erweiterung

**Eine abgeleitete Gesichtsversion mit unverändertem Körper-/Bewegungsrig ist der passende Zuschnitt.** Das Original-GLB bleibt erhalten. Die kleine Änderung betrifft die sichtbaren Gesichtsflächen und ihre Steuerung; Brille, Ohren, Kopfproportionen, Fellzeichnung, Kleidung, Originalclips und Körpergewichtung bleiben Referenz.

| Funktion | Benötigte echte Erweiterung | Grenze |
|---|---|---|
| Blinzeln | Anatomisch ausgewählte obere/untere Lidflächen mit passender Felloberfläche und überprüfter geschlossener Form. Zwei benannte Shape Keys für links/rechts erlauben getrennte oder gemeinsame Blinks. | Das aktuelle Auge nur vertikal zusammenzudrücken würde auch seine aufgemalte Iris verzerren. Die benötigten Lidflächen sind noch nicht hergestellt. |
| Blick | Zwei tatsächlich getrennte Augenoberflächen mit erhaltenem Originalerscheinungsbild, festen Drehpunkten und eigener lokaler Rotation. Kopf-/Halsaufmerksamkeit kann weiterhin den vorhandenen Anschluss verwenden. | Die auf dem gemeinsamen Gesichtsatlas liegenden Pupillen können heute nicht unabhängig als Augäpfel rotieren. Ein separater Eye-Node-Anschluss muss am `Head` befestigt und im Export geprüft werden. |
| Kiefer | Lokal getrennte beziehungsweise neu aufgebaute Mundränder und eine wirkliche innere Mundfläche; begrenzter `jaw_open`-Shape-Key mit nachvollziehbarer Scharnierbewegung des unteren Bereichs. | Die Ruhekontur allein ist kein fertiger Kiefer. Lippenformen und phonemgenaue Viseme sind ein weiterer geprüfter Schritt. |
| Audioanschluss | Nach validiertem Mundasset die vorhandene Wiedergabezeit/Hüllkurve an einen begrenzten Kieferwert anbinden, bei Stille schließen. | Hüllkurvengetriebene Kieferbewegung ist noch keine phonemgenaue Lippensynchronität. Die vorhandene A/E/O/I-Schleife darf nicht als solche ausgegeben werden. |

Shape Keys und am vorhandenen `Head` befestigte Augenobjekte ermöglichen diesen Zuschnitt ohne zusätzliche Skelettknochen. Damit muss die bestehende 65-Knochen-Kompatibilitätsgrenze nicht pauschal gelockert werden. Das ist ein Architekturvorschlag, noch kein getesteter GLB-Export. Der neue Adapter sollte einmalig die benötigten Shape-/Node-Namen binden, nach dem jeweiligen Körperanimationsbesitzer aktualisieren und Pause, Reduced Motion, Szenenaustritt und Rückkehr ausdrücklich berücksichtigen. Gleichzeitige konkurrierende Schreibzugriffe auf die bestehenden Kopfknochen sind zu vermeiden.

## 5. Anschlussfähige Eigentümerschaft für einen Folgeauftrag

- **Charakter/Animation:** neue vollständige Blender-Autorenkopie und abgeleitetes GLB, ein neues Facial-Authoringscript unter `tools/lumo_animation/`, ein eigener kleiner Gesichtsadapter unter `scripts/characters/lumo/` sowie der Anschluss in `lumo_rigged_actor.gd`. Diese neuen Dateien existieren heute noch nicht; es wird keine Umsetzung behauptet.
- **Lernvisualisierung:** vorhandene `set_teaching_target`-/Sprachsample-Schnittstellen nutzen. Lernaufgaben, Kinderprofile, Sprachbewertung und Elternfreigaben benötigen für diesen Assetzuschnitt keine Neuimplementierung.
- **Integration/QA:** Export-/Importnachweis, neutrale Originalähnlichkeit, vollständiger Lidschluss ohne sichtbare Iris, begrenzte Blickrotation ohne Durchdringen, Kieferöffnung ohne Dehnung der oberen Schnauze sowie Pause-/Wiederaufnahmeprüfung. Erst danach neue Sourceidentität und reale Gerätelaufzeitprüfung.

**Offen bleiben** Modellierung, Verformungsgewichte, Shape Keys, Export und produktive Gesichtsanimation. Dieser Befund schließt keine dieser Abnahmen. Das primäre Mandat bleibt die neue Creative-Android-Prüfung des unveränderten Kandidaten; hierfür wurden keine zusätzlichen Runs oder Sourceänderungen gestartet.
