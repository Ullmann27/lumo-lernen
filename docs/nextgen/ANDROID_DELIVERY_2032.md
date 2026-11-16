# LUMO Lernen 0.13.20 (2032): veröffentlichte Test-APK und aktueller Prüfstand

**Status: `APK_PUBLISHED_CURRENT_SUPPLEMENT_PENDING`**

**Dokumentstand: 16. November 2026. `fullModernizationComplete=false`.**

Die signierte integrierte **ARM64-Test-APK 0.13.20+2032 ist veröffentlicht und vollständig anonym heruntergeladen geprüft**. [APK herunterladen](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.20-2032/Lumo-Lernen-Neu-0.13.20-2032.apk). Quellvalidierung, Build und die aktuelle vollständige Androidtour sind abgeschlossen; deren genaue Grenzen stehen unten. Vier zusätzliche gezielte Gerätefälle sind als separater Nachlauf in Vorbereitung. Eine vollständige Modernisierung aller Lernbereiche ist weiterhin nicht belegt.

Die APK-Quelle ist `9b38360ca5f21919dce4a2b99e605ee39bbbf454`, der native Pin `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`. [Run 43837592237](https://github.com/Ullmann27/lumo-lernen/actions/runs/43837592237) ist im zweiten Versuch **SUCCESS**. Der erste Androidversuch bleibt als eigenständiger **FAIL** mit seinen unveränderten Originalen erhalten; er wurde nicht nachträglich umgewertet. [Aktuelle Androidbelege](evidence/ci-2032-android-complete-verified/README.md), [Veröffentlichungs- und Downloadprüfung](evidence/ci-2032-publication-verified/README.md).

## 1. Welche Lernbereiche vollständig modernisiert und erreichbar sind

**Eine vollständige Modernisierung aller Lernbereiche ist derzeit nicht belegt.** Die folgende Liste beschreibt konkrete erreichbare Anschlüsse und macht die noch eingeschränkten oder inaktiven Bereiche sichtbar.

- **Der ausgeführte aktuelle Katalogexport erfasst 61 Inventareinträge, 55 Bildschirmdateien und 236 Lehrplanfamilien.** Die 61 Einträge enthalten auch Navigation, Verträge, geschützte Bereiche und inaktive Altpfade. Sie sind daher keine Behauptung von 61 vollständig modernisierten oder gerätegeprüften Lernaufgaben. Die 236 Familien sind Klassen-/Fach-/Einheitskombinationen; erzeugte Aufgabenvarianten werden dadurch nicht vollständig aufgezählt oder durchgespielt. Zusätzlich sind 60 Mathe- und 32 Deutsch-Templates sowie 79 Akademie-Themen erfasst; diese Bestände werden nicht als disjunkte Aufgabenmengen addiert. [Vollständige Matrix](COVERAGE.json), [lesbare Einordnung](COVERAGE.md).
- **Die Akademie ist der gemeinsame Einstieg.** Über „Lernen“, Klasse, Fach und Themenkarte wird die konkrete Einheit geöffnet. Vorhandene Fach- und Schreibmodule haben Vorrang; andere passende Einheiten führen in die reguläre Aufgabenfläche oder in freiwilliges Üben einer anderen Klasse. Die acht Katalogfächer sind Mathematik, Deutsch, Lesen, Rechtschreibung, Schreiben, Englisch, Sachunterricht und Logik. Das zusätzliche aktive Vorlesen ersetzt die Themenauswahl für Lesen nicht. [Lernübersicht](../../lib/features/sections/lumo_learning_hub.dart), [Einheitenaufruf](../../lib/features/teacher_mode/lumo_akademie_screen.dart).
- **Lernatelier und geführte Lektionen sind getrennte Wege.** Unter „Lernwerkzeuge & Geschichten“ liegen „Lumos interaktives Lernatelier“, „Lumo erklärt es mir“ und „Mit Lumo Neues entdecken“. Das Atelier enthält sechs Modi mit 35 festen Problemkennungen: Zehnerübergang, Wörter/Silben, Englisch, Pflanzen, Brüche und Muster. Die sieben geführten Lektionen behandeln Zehnerübergang, gleiche Gruppen, Subtraktion, Silben, Pflanzenteile, Hunderterübergang und Bruchteile. [Laborkatalog](../../lib/features/learning/lab/learning_lab_catalog.dart), [geführter Katalog](../../lib/domain/tutoring/guided_lesson_catalog.dart).

Die nachstehende Gruppierung umfasst sämtliche 61 Inventareinträge. Sie nennt den Einstieg und bewahrt die Unterschiede zwischen aktiver Lernfläche, Auswahl, geschütztem Bestand und inaktivem Code. Die jeweilige Einzelkennung, Bedingung, Fachautorität und Quelldatei steht in [COVERAGE.json](COVERAGE.json).

| Bereich / Anzahl Inventareinträge | Tatsächlicher Einstieg und Umfang | Grenze der Aussage |
| --- | --- | --- |
| Akademie, reguläre Aufgaben, freiwilliges Üben / **3** | „Lernen“ → Klasse/Fach/Einheit; reguläre Aufgabe beziehungsweise CrossGrade | 236 Familien sind im Hub zugeordnet; nicht jede Variante ist auf einem Gerät geprüft |
| Atelierauswahl und Lernlabor / **2** | „Lernwerkzeuge & Geschichten“ → „Lumos interaktives Lernatelier“ → Thema | Sechs vorhandene Labormodelle; native Ergänzung dort als aktuelle Aufgabenkarte |
| Auswahl und geführte Lektion / **2** | „Lumo erklärt es mir“ beziehungsweise „Mit Lumo Neues entdecken“ → Lektion → Schritt | Sieben Lektionen; Beispiel, angeleitete Aufgabe und selbstständige Abgabe bleiben unterschieden |
| Native Erklärung und älterer Stellenwertvertrag / **2** | Sichtbarer 3D-Einstieg an einer erlaubten aktuellen Aufgabe | Die native Szene ist erreichbar; der ältere Stellenwertvertrag ist kein zusätzlicher eigenständiger Lernweg |
| Aktives Lesen und Reading Buddy / **2** | Lese-Einstieg beziehungsweise Reading Buddy auf der Startseite | 24 Buddy-Texte; Vorlesen und Verständnisbewertung bleiben getrennt |
| Geschichtenbibliothek, Erstellung, Reader / **3** | Akademie → Geschichtenbibliothek → vorhandene oder neue Geschichte | Gespeicherte und erzeugte Geschichten haben keine abschließend erfasste Variantenliste |
| Narrative Lernabenteuer / **1** | Lernabenteuer auf der Startseite → Quest | Vier feste Quests im Katalog |
| Foto-Lernheft und tatsächliche Fotoübungen / **2** | Startseite → Foto-Lernheft → erkannter Auftrag → Übung | Scannen oder Anzeigen allein ist keine richtige Antwort |
| Fachtests, Denkaufgaben, kognitives Profil / **3** | Tests → jeweiliger Prüfbereich | Prüfungsgrenzen gelten; keine diagnostische Standardisierung behauptet |
| Zugewiesene Schulaufgaben und alter Themenchat / **2** | Aufgabenkarte auf der Startseite; separater Teacher-Restfallback im Code | Der Restfallback ist kein aktuell belegter bewerteter Lernweg |
| Live-Wortmagie, Foto-Quiz, Safari / **1** | Live-Einstieg auf der Startseite → vorhandener Modus | Teilnahme und Safari-Zuordnung sind nicht automatisch unabhängige Fachbeherrschung |
| ABC- und Rechentricks-Tafel / **2** | Entsprechende Tafeln auf der Startseite | Nachschlageflächen, keine eigenständigen bewerteten Aufgaben |
| Schreibcoach, Wortcoach, Buchstabenschreiben, freiwilliger Aufsatz, Journal / **5** | Akademie-Werkzeuge beziehungsweise Journal auf der Startseite | Geschützte Schreib-/Journalinternas bleiben erhalten; äußere Anbindung ist keine interne Neuentwicklung |
| Praktische Fachaufträge / **1** | Fach-/Aktivitätskarten → vorhandener Auftrag → „Beobachtung im Journal festhalten“ | 60 Aktivitäten; körperliche Tätigkeit und Beobachtung werden nicht automatisch fachlich bewertet |
| Alte Deutsch-Lückensätze / **1** | Kein aktiver App-Einstieg | Wegen mehrdeutiger Inhalte und ungeklärter alter Bewertungsgrenzen nicht wieder angeschlossen |
| Registrierte Fachmodule / **20** | Akademie → passende Fach-/Einheitskarte, teilweise Werkzeugkarte | 19 aktive Einstiege auf 18 Screens; siehe folgende Liste |
| Lernspielbereiche / **9** | „Spielen“ → jeweiliges Spiel beziehungsweise dessen Lernfrage | Fünf MiniGame-Einstiege, gemeinsame Lernspielfläche, Cards-Denkpausen, Quizshow und 2D-Flame-Lernfragen; Spielwelt und Fachabgabe bleiben getrennt |

- **Die 20 registrierten Modulkennungen sind vollständig erhalten:** `m1_plus10`, `m1_minus10`, `m1_zahlen10`, `m1_formen`, `s1_tiere`, `s1_farben`, `m2_uhr`, `m2_geld`, `m2_zahlen100`, `d2_artikel`, `d2_mehrzahl`, `s2_jahreszeiten`, `s2_wetter`, `s2_verkehr`, `d3_wortarten`, `d3_zeitformen`, `d1_woerter`, `m2_einmaleins`, `m3_einmaleins_voll`, `m4_bruch`. Der geschützte Wort-Schreibcoach hat bei `d1_woerter` Vorrang; zwei Einmaleins-Einstiege teilen denselben Screen. Deshalb bedeuten 20 Registry-Einträge **19 aktive Modul-Einstiege und 18 aktive Modul-Screens**. [Registry](../../lib/features/learning_modules/learning_module_registry.dart), [Zählregeln](COVERAGE.md).
- **Die Lernspielzählung bleibt präzise:** 50 Kataloglevel bestehen aus 49 MiniGame-Leveln und einem abschließenden Quiz-Level. Die fünf MiniGame-Einstiege sind Sternenpfad, Zahlenhaus, Farbboxen, Buchstaben ergänzen und Lernpfad; ihre gemeinsame Lernfragefläche ist zusätzlich inventarisiert. Dazu kommen Cards-Denkpausen, Quizshow und die Frage-/Truhenflächen des 2D-Flame-Spiels. Die Kataloge enthalten außerdem 108 deklarierte Quizfragen, 200 Kartenbankeinträge und 200 kognitive Fragen; diese Zahlen sind keine aktuellen Android-Testzahlen. [Bestandszahlen](COVERAGE.json), [Spiele-Einstiege](../../lib/features/games/games_content.dart).

### Native Darstellung und konkrete Beispielwege

- **Die native Darstellung läuft in einer eigenen Android-Activity.** „Mit Lumo in 3D ausprobieren“ beziehungsweise der jeweilige sichtbare 3D-Einstieg übergibt einen geprüften aktuellen Aufgabenkontext. Das ist keine durchgängig in jede Flutter-Aufgabe eingebettete 3D-Fläche. Für gesperrte Prüfungsaufgaben darf aus dem vorhandenen Adapter kein erlaubter Einstieg abgeleitet werden. [Aktivitätsadapter](../../lib/domain/tutoring/native_learning_activity.dart), [Launcher](../../lib/features/lumo3d/lumo3d_launcher.dart), [Abdeckungsgrenzen](COVERAGE.md).
- **Es gibt zwölf native Darstellungsarten, davon eine generische Aufgabenkarte.** Spezialisierte Modelle entstehen nur, wenn der Adapter die passende Aufgabe und ihre Parameter prüfen kann. Eine Aufgabenkarte zeigt den begrenzten aktuellen Auftrag und gegebenenfalls Antwortmöglichkeiten; sie ersetzt kein eigenes räumliches Fachmodell für sämtliche 236 Familien.

| Native Kennung | Darstellung im geprüften Anwendungsbereich |
| --- | --- |
| `addition` | Kleine Addition mit zählbaren Mengen |
| `bridge_ten` | Ergänzen zum Zehner, anschließend den Rest betrachten |
| `subtract_ten` | Begrenzte Subtraktion beziehungsweise passende geführte Lektion |
| `equal_groups` | Gleiche Gruppen als Multiplikationsmodell |
| `equal_sharing` | Geprüfte gleichmäßige Aufteilung ohne Rest |
| `bridge_hundred` | Passender Zehnerübergang über die Hundertergrenze |
| `fraction_parts` | Geprüfte Teil-Ganzes- beziehungsweise Bruchdarstellung |
| `syllables` | Geprüftes Wort mit zusammenpassenden Silben |
| `plant_parts` | Pflanzenteile im geführten Lernkontext |
| `english_objects` | Gegenstände aus der geprüften englischen Zuordnung |
| `pattern` | Geprüfte Folge, Auswahl und kleinste Wiederholungsgruppe |
| `task_card` | Generische Karte für den exakten Auftrag; ohne Lösungs- oder Belohnungsfeld |

Die konkreten Zahlen-, Wort- und Auswahlgrenzen stehen in [NativeLearningActivity](../../lib/domain/tutoring/native_learning_activity.dart) und `nativeCompatibility` in [COVERAGE.json](COVERAGE.json).

- **8 + 5:** Der geführte Weg führt über „Lumo erklärt es mir“ und „Über den Zehner“ zum aktuellen Beispiel „Acht und fünf“. Die Frage „Warum zuerst zwei?“ kann auf den fehlenden Zweieranteil bis zehn verweisen und dessen Bewegung auslösen. Die fachliche Zerlegung bleibt 8 + 2 = 10, anschließend 3 übrig. Die tatsächliche 2032-Tour zeigt die getippte Frage, die passende Erklärung und den Modellwechsel von null auf zwei bewegte Objekte ohne anschließende manuelle Verschiebung. Eine gesprochene Frage wurde dabei nicht erkannt oder geprüft.
- **Banane:** „Lumo erklärt es mir“ → „Wörter in Silben hören“ → „Ba – na – ne“ → 3D-Einstieg führt zur Silbenszene. „Nächste Silbe zeigen“ baut die drei Teile auf. Im tatsächlichen Fragepanel „Frag Lumo“ führen **„Noch einmal“ und „Langsamer“** zu vier aufeinanderfolgenden Audiosegmenten: Wort, Ba, na, ne. Der gleichnamige äußere Footer „Noch einmal“ setzt dagegen das Modell zurück. Der verlangsamte Auftrag setzt die Sprechrate auf 75 Prozent der Basisrate, mit einer Untergrenze von 0,70; das ist implementierte Laufzeitsemantik, keine akustische Messung.
- **Muster:** Akademie → gegebenenfalls „Alle Fächer“ → „Weitere Lernbereiche“ → Logik → Muster → aktuelle unbeantwortete Aufgabe → 3D. Die Formen kommen aus der tatsächlichen Aufgabe. „Gruppe entdecken“ verwendet ihre geprüfte kleinste Periode. Eine native Formwahl ist ein Vorschlag; die Rückkehr bewertet sie nicht automatisch. Die ausdrückliche Abgabe erfolgt im zuständigen Flutter-Aufgabenweg. Das Muster im Lernatelier und die spezialisierte native Musterfolge sind unterschiedliche Anschlüsse.

Quellen dieser drei Abläufe: [geführte Lektionen](../../lib/domain/tutoring/guided_lesson_catalog.dart), [Aufgabenadapter](../../lib/domain/tutoring/native_learning_activity.dart), [lokaler nativer Dialog](../../tools/auto_install/LumoLearningConversation.kt) sowie Native `scripts/learning/learning_world.gd`, `learning_activity.gd` und `learning_conversation_panel.gd` am oben gebundenen Commit. [Native Lernweltquelle](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/scripts/learning/learning_world.gd).

- **18 geschützte Schreib-/Journaldateien sind bytegleich zur Baseline** `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`, auch an der vorgesehenen APK-Quelle `9b38360…`. Dazu gehören Schreibfortschritt, Wortbanken, Schreibregeln, Zeichenflächen, Schreibscreens und Journalrepository/-screen. Einzelpfade und SHA-256-Werte stehen in [COVERAGE.json](COVERAGE.json) und im [Quellenvergleich](evidence/2032-native-contrast-integration-20261116/host-product-boundary-review.json). Bestehende Profile, Aufgabenkennungen und Speicherformate werden nicht durch den neuen Dialog ersetzt.
- **Kart und nativer Dschungel bleiben außerhalb dieses Änderungsumfangs.** Der inventarisierte 2D-Flame-Anschluss betrifft dessen Lernfragen und Truhenfragen. Er ist keine Aussage über eine modernisierte Spielphysik oder native Dschungelwelt. [Umfangsdefinition](COVERAGE.json).

## 2. Welche Figur-, Animations- und Gesprächsfunktionen neu angeschlossen sind

Die folgenden Funktionen gehören zum integrierten Next-Generation-Stand. Die konkrete neue Produktänderung für Kandidat 2032 ist die Button-Kontrastkorrektur aus Abschnitt 3; die bereits vorhandenen Dialog- und Figurenfunktionen werden nicht als sämtlich erst in dieser Version neu entwickelt bezeichnet.

### Figur und Animation

- **Die Lernfigur ist eine Weiterbearbeitung des vorhandenen Lumo-Fuchses.** Der Quellhinweis dokumentiert die vorhandene Figurenherkunft und die lokal mit Blender erstellten Lernposen, Mundformen und zusätzlichen Ohrknochen. Die ursprünglichen 65 Knochen und neun Originalanimationen bleiben erhalten; hinzu kommen **14 Lernanimationen**. Die tatsächliche Learning-GLB enthält damit **23 benannte Animationen**, nicht insgesamt 14. [Herkunfts- und Bearbeitungshinweis](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/assets/lumo_next/character/ATTRIBUTION.md), [Erzeugungsquelle](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/tools/lumo_next/build_character.py).
- **Die 14 Lernclips sind:** ruhiges Atmen (`idle_breathe`), Zuhören (`listening`), Nachdenken (`thinking`), Antworten (`answer`), Erklären (`explain`), Zeigen (`point`), Nicken (`nod`), Unsicherheit (`unsure`), Ermutigen (`encourage`), einen Schritt feiern (`celebrate_step`), Unterbrechen (`interrupt`), Verabschieden (`farewell`), Begrüßen (`greeting`) und ruhige Eingabebegleitung (`focused_input`). Das Vorhandensein im Asset belegt nicht, dass jeder Clip auf dem aktuellen Androidgerät gesehen wurde.
- **Die verwendete Datei ist konkret gebunden:** `assets/lumo_next/character/Lumo-Learning.glb`, **7.734.740 Bytes**, SHA-256 **`cc210fb03bd831f21f0ba99aa12c7b7ef60f2fb5a38e0ca30a8b059d51f08163`** an Native `9d6ef1d…`. Der Lern-Actor lädt genau dieses Modell und bindet dessen Skelett und Animationsplayer. [Lern-Actor](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/scripts/lumo_next/learning_lumo_actor.gd).
- **Blick und Pfote beziehen sich auf registrierte aktuelle Lernobjekte.** Aktion, Objektkennung, Aufgabe, Schritt und laufender Gesprächszug werden geprüft. Das ist eine Quellbindung an den Lerngegenstand, keine Garantie, dass jede Pose aus jedem Kamerawinkel ideal sichtbar ist. Die Figur entscheidet keine fachliche Richtigkeit und vergibt keine Belohnung. [Animationssteuerung](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/scripts/lumo_next/avatar_director.gd), [Zielregister](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/scripts/lumo_next/learning_target_registry.gd).
- **Die Mundbewegung erhält aktuelle Wiedergabedaten.** Der Androidhost liefert Wiedergabe-ID, Position, Zustand und eine aus dem tatsächlichen Audiopuffer abgeleitete Hüllkurve. Der Director schließt den Mund bei ungültiger oder veralteter Bindung, Pause und fehlender Wiedergabe; vorhandene zeitgebundene Formhinweise können gesondert genutzt werden. Benannte Mundformen und Callbackdaten belegen keine phonetisch genaue Lippensynchronität. Ein akustisch und visuell gemeinsam vermessener Stopp von Ton, Mund und Geste ist für 2032 noch offen. [Android-Sprachtransport](../../tools/auto_install/LumoLearningSpeech.kt), [Director](https://github.com/Ullmann27/lumo-godot/blob/9d6ef1d704a0e54098a8f8f0818f36deae0e3789/scripts/lumo_next/avatar_director.gd).

### Sprache und Gespräch

- **Der lokale Dialog ist an die Aufgabe gebunden.** Ein Intentrouter erkennt unterstützte Anliegen; lokale Fachhinweise beantworten den aktuellen Lernkontext. Der native Kotlin-/Java-Pfad verwendet einen lokalen Dialogrouter. Die vorhandene Texteingabe ist deshalb kein Nachweis eines frei generativen Gesprächs. [Flutter-Controller](../../lib/core/lumo_conversation_controller.dart), [nativer Dialog](../../tools/auto_install/LumoLearningConversation.kt), [lokale Dialoglogik](../../tools/auto_install/LumoLearningDialogLogic.java).
- **Ein KI-Proxy ist optional.** Der Flutter-Pfad kann einen ausdrücklich aktivierten und konfigurierten Proxy für zusätzliche Antworttexte verwenden. Ohne diese Voraussetzungen bleibt lokale Begleitung verfügbar. Der aktuelle Androidlauf belegt keine konkrete Proxy-Verbindung und keine entfernten KI-Antworten. Eine unklassifizierte Frage darf gesperrte Hilfe nicht über den lokalen oder entfernten Ersatzpfad umgehen. [Proxyclient](../../lib/core/lumo_ai_proxy_client.dart), [Controller](../../lib/core/lumo_conversation_controller.dart).
- **Wiederholen, langsamer, warum, Hinweis, Korrektur und Stopp haben unterschiedliche Wirkungen.** Der kanonische Vertrag kennt `explain`, `repeat`, `slower`, `hint`, `highlight`, `point`, `look`, `stop` und `proposeAnswer`. Erlaubt ist jeweils nur die aktuelle Aufgabenfreigabe. Der native Dialog nimmt als semantische Hilfsaktionen `explain`, `repeat`, `slower`, `hint` und `stop` an; eine geprüfte Objektkennung steuert die begleitende Darstellung. Eine Gestenfähigkeit erweitert nicht automatisch die Hilfeerlaubnis. [Bus und Vertrag](../../lib/widgets/fox/lumo_companion_requests.dart), [nativer Dialog](../../tools/auto_install/LumoLearningConversation.kt).
- **Antwortvorschläge bleiben bis zur ausdrücklichen Abgabe ungewertet.** Ein erkanntes oder eingegebenes Ergebnis kann als bearbeitbarer Kandidat erscheinen. Korrektur ersetzt diesen Kandidaten. Nur die aktuelle Fachoberfläche darf nach ihrer vorgesehenen Bestätigung bewerten und Fortschritt oder Belohnung buchen. Bei normalen Auswahlkacheln kann bereits der bewusste Kacheltipp die Abgabe sein; ein zusätzlicher Bestätigungsdialog wird nicht überall behauptet. Native Demonstration und native Rückkehr sind keine automatische Fachabgabe. [Gemeinsamer Fragecoach](../../lib/features/learning/widgets/learning_question_coach.dart), [Aufgabenrenderer](../../lib/features/learning/renderers/adaptive_task_renderer.dart), [COVERAGE](COVERAGE.md).
- **Spracheingabe nutzt das endgültige Erkennungsergebnis.** Teiltranskripte können sichtbar werden, die Gesprächsverarbeitung wartet auf das finale Ergebnis. Mikrofonfreigabe, erlaubte Sprache, Vordergrund, aktuelle Aufgabe und Abbruchrevision werden geprüft. Ein Berechtigungsdialog oder ein sichtbarer Bereitschaftstext beweist keine erfolgreiche deutsche Erkennung. **Echte deutsche STT-Erkennung, verhörte Zahl und gesprochene Korrektur bleiben für 2032 unbestätigt**, bis ein entsprechender Gerätebeleg vorliegt. [Mikrofonoberfläche und Lifecycle](../../lib/features/agent/lumo_agent_content.dart).
- **Die Sprachausgabe ist ein konkreter lokaler Audiopfad.** Der native Host verwendet das Offlineprofil `lumo-free-supertonic-de-v1`, Synthese und MediaPlayer-Wiedergabe. Erklärungstext bleibt sichtbar; bei Silben folgt die Hervorhebung einem angenommenen aktuellen Wiedergabestatus. `started`/`completed` belegen Transportereignisse und Reihenfolge, keine akustisch geprüfte Aussprache, tatsächliche Lautstärke am Ohr oder gemessene Verlangsamung. [Offlineengine](../../tools/auto_install/LumoOfflineSpeechEngine.java), [Sprachtransport](../../tools/auto_install/LumoLearningSpeech.kt).
- **Stopp, Aufgaben-/Profilwechsel, fremde Route und App-Pause entziehen alte Ansprüche.** Alte Antworten, Audiobesitzer und Eingaben dürfen keine neue Aufgabe übernehmen. Eigene Gesprächsrouten sind ausdrücklich an ihre Aufgabe und Session gebunden; die Ausnahme gilt nicht für beliebige darübergelegte Seiten. Prüfungen erlauben nur ausdrücklich freigegebene Wiederhol-/Tempoaktionen auf den sichtbaren Auftrag; keine Lösungshilfe oder KI-Wertung. Diese implementierten Grenzen brauchen ihre jeweils passende Laufzeitprüfung. [Gesprächs-Host](../../lib/app/lumo_companion_host.dart), [Controller](../../lib/core/lumo_conversation_controller.dart), [Aufgabenbereich](../../lib/features/learning/learning_content.dart).

### Gemeinsamer Anschlussvertrag

Der [versionierte Vertrag](INTEGRATION_V1.md) verwendet `protocolVersion: 1` und die vorhandenen Aufgaben-/Speicherstrukturen. Sitzung, Aufgabe, Kontextrevision, Abbruchgeneration und Erklärschritt sind durch `sessionId`, `taskId`, `revision`, `cancelEpoch` und optional `stepId` gebunden. Gespräch und Wiedergabe ergänzen `turnId`, `utteranceId` sowie registrierte Objektkennungen. Fachliche Rückmeldung, Fehlerart und zulässige Hilfe kommen vom aktuellen Aufgabenbesitzer; `allowedActions` begrenzt Erklären, Wiederholen, langsamer, Hinweis, Hervorheben, Zeigen, Blick, Stopp und Antwortvorschlag. Ein Vorschlag ist keine Fachbewertung.

Die bestehenden Busereignisse verbinden Präsentation, Abbruch und tatsächliche Audiozustände. Blick, Zeigegeste und Mundhüllkurve dürfen nur zur aktuellen Bindung gehören. Aufgaben-/Profilwechsel, Pause und Stopp entziehen alte Ansprüche; unbekannte Protokollversionen werden nativ verworfen. Die kanonische Vertragsdatei ist am APK-Quellstand bytegleich zum ursprünglichen EA-Vertrag `421a0c3261a57dd15733531058cf2291d765d38d`. Der [unabhängige Integrationsvergleich](evidence/2032-original-team-integration-review-20261116/readonly-review-bd876747.json) und die [Root-Byteprüfung](evidence/2032-original-team-integration-review-20261116/root-byte-review.json) sichern die Zuordnung; sie ersetzen keine Geräteprüfung.

## 3. Welche Prüfungen tatsächlich liefen und auf welchem Gerät beziehungsweise welcher Umgebung

### Quellvalidierung und Build

Validate-Job **133197989015** und Buildjob **133206155437** an APK-Quelle **9b38360ca5f21919dce4a2b99e605ee39bbbf454** sind **SUCCESS**. Die tatsächlichen Originale stehen unter [Quellvalidierung](evidence/ci-2032-validation/README.md) und [Buildprüfung](evidence/ci-2032-build/README.md). Beim zweiten Androidversuch wurden dieselben bereits gebauten Artefakte verwendet; neue Metadaten-Job-IDs der übernommenen erfolgreichen Jobs werden nicht als zusätzlich ausgeführte vollständige Builds gezählt.

| Prüfebene | Tatsächliches Ergebnis und Reichweite |
|---|---|
| Flutter, Flutter 3.44.9 | **2.896 PASS / 202 SKIP / 0 FAIL** |
| Analyzer | **0 Fehler / 4 Warnungen / 274 Infos** |
| Host-unittest | **174 Methoden PASS**, einschließlich aller elf neuen Stopp-Hostfälle |
| Godot-Import | **SUCCESS**, `4.6.3.stable.official.7d41c59c4` |
| Native Programme | **13 Programme / 55.631 Prüfaussagen**, darin Buttonkontrast **79/79** |
| Separater Projektvalidator | **118 PASS / 0 WARN / 0 FAIL** |
| Quellen / Schutz | **364** Coverage-Quellhashes / **18** bytegleiche geschützte Dateien |
| Frischer Katalogexport | Run **43836322226**, Job **133193729169**, **ein Exporttest PASS**, 480 Exportquellen verglichen |
| Gezielter aktueller Stopp-Anschluss | **26/26** lokale Hostprüfungen; gesondert von der tatsächlichen Androidprüfung |

Die 202 Skips bleiben ausgewiesen; einzelne Skipgründe sind dem parallelen expanded-Log nicht zuverlässig zuzuordnen. Die vier Analyzerwarnungen betreffen ungenutzte Importe/Felder. Der isolierte Avatarprüfer enthält eine erhaltene ObjectDB-Warnung beim Beenden. Diese Zahlen werden nicht mit anderen historischen Läufen zu einer vermeintlichen Gesamttestzahl addiert.

Die konkrete native Produktkorrektur für 2032 betrifft die Schriftfarben der interaktiven Lernbuttons: Die vorhandene dunkle Normalschrift gilt jetzt zusätzlich für Hover, Fokus, gedrückt und Hover+gedrückt. Die gezielte echte Godot-Regressionsprüfung zeigte zuerst **32 erwartete Fehler**, anschließend **79/79 PASS**. Die aktuellen Originalbilder des aktiven Stopps und des Rückwechsels zeigen die lesbaren dunklen Beschriftungen. Hintergrund, Geometrie, deaktivierter Zustand und fachliche-/Playbacklogik wurden durch diese Korrektur nicht verändert. [Integration](evidence/2032-native-contrast-integration-20261116/root-source-review.json), [aktuelle Bilder](evidence/ci-2032-android-complete-verified/README.md).

### Aktuelle vollständige Androidtour

**Run 43837592237, Versuch 2, Androidjob 133221738048 SUCCESS.** Tatsächliche Umgebung: API 35, x86_64, frischer Pixel-5-Emulator, reguläre Ansicht 1080 × 2340 bei gemeldeter physischer Testdichte 440 dpi, Software-Renderer `llvmpipe (LLVM 20.1.2, 256 bits)` über `gl_compatibility`. Das ist kein physisches Telefon und kein ARM64-Gerät.

Die Lerntour lief am **16.11.2026 von 10:03:55 bis 10:12:59 UTC**, die zusätzliche Referenztour von **10:12:59 bis 10:30:44 UTC**. Beide Originalresultate lauten **PASS_WITH_LIMITATIONS**. Die frisch installierten vollständigen APK-Bytes, Paket, Version, Signaturbindung und nativer Pin wurden geprüft. [Rootvergleich und Originale](evidence/ci-2032-android-complete-verified/root-initial-review.json).

| Aktueller Fall | Tatsächlicher Befund |
|---|---|
| **8 + 5 / „Warum zuerst zwei?“** | Getippte freie Frage; passende Erklärung, acht blaue und zwei ergänzte gelbe Objekte im Zehnerfeld, drei weitere gelbe Objekte daneben. Modellwechsel von 0 auf 2 bewegt ohne manuelle Verschiebung nach der Frage. Aktuelle MediaPlayer-Wiedergabeereignisse; keine akustische Wort- oder STT-Prüfung. |
| **Banane** | Drei sichtbare Silbenschritte Ba–na–ne mit aktueller Wiedergabe. „Noch einmal“ im nativen Fragepanel ergibt vier neue geordnete MediaPlayer-Paare, IDs **19–22**, PID **9392**. Rückkehr zur gleichen geführten Aufgabe ohne native Bewertung. |
| **Aktiver nativer Stopp** | PID **10808**, neue ID **13**, `started` vor dem tatsächlichen Tap und noch kein `completed`. Zwei frische Bilder derselben sichtbaren Stopptaste; Tap nach **25,757395226 s** im unveränderten 45-s-Fenster. Danach **13,578335915 s** Beobachtung ohne spätes neues Segment oder Abschluss dieser ID, Rückkehr zu „Schritt anhören“. Akustischer und gemeinsam vermessener Mund-/Gestenstopp bleiben offen. |
| **Muster** | Aktuelle Folge **Quadrat–Kreis–Quadrat–Kreis**, kleinste Gruppe zwei; Hinweis und nativer Vorschlag Quadrat; gleiche unbeantwortete Frage nach Rückkehr. **Core-Abgabe NOT_EXERCISED**. Die Antwortkarten waren vorhanden; die Prüfsoftware erkannte die zeilenweise Überschrift im mehrzeiligen Beschriftungsfeld nicht. Der gezielte Nachlauf muss eine wirkliche gespeicherte Fachabgabe liefern. |
| **Falscher Vorschlag und Korrektur** | Im Lernatelier Wechsel von Kreis zu Dreieck bei unverändertem Lernstand. Das ist keine tatsächliche falsche bewertete Zahlenabgabe; diese ist Gegenstand des gezielten Nachlaufs. |
| **Wiederholen / langsamer / Stopp im Flutter-Lab** | Reale Bedienung am aktuellen Banane-Lab und Erhalt des Aufgabenstands. Die zusätzliche verlangsamte native Viersegmentfolge wird getrennt geprüft. |
| **Pause, Rückkehr und Größenwechsel** | Derselbe aktuelle Lab-Aufgabencheckpoint und das synthetische Profil bleiben in den protokollierten Rückwegen und vier Größenwechseln erhalten. Kein Upgrade-Test mit einem vorhandenen echten Kinderprofil. |
| **Mikrofon** | Reale Anforderung und sichtbare explizite Gerätegrenze. **recognition=NOT_VERIFIED**, `postgrant_explicit_start=false`; keine eingesprochene Äußerung, keine nachgewiesene verhörte Zahl. |

Die vier logischen Displaykonfigurationen waren **720×1600 @ 320 dpi**, **1768×2208 @ 360 dpi**, **1080×2520 @ 420 dpi** und **1968×2184 @ 420 dpi**, anschließend Rückstellung. Die beiden letzten Konfigurationen sind als emulierte Fold7-Außen-/Innenansicht bezeichnet. Die Dichte ist eine gewählte Android-Testdichte, keine Behauptung physischer PPI. Geprüft wurde dabei die Flutter-Laboraufgabe; ein physischer Faltvorgang oder eine vollständige native 3D-Prüfung in allen Größen folgt daraus nicht.

### Gemessene Leistung

Die aktuelle 3D-Szene wurde mit Fuchs, Effekten und tatsächlichen Wiedergabestatus erfasst: **47 Prozessintervalle in sieben Messfenstern**, zusammen **38,689638 s**, bei **43,908268783 s** beobachteter Szene. Der gewichtete Mittelwert ist **823,183787234 ms** pro Godot-Prozessintervall, entsprechend **1,214795548 Hz**. Alle 47 Intervalle liegen über 16,7 ms; zwölf Samples enthalten gleichzeitig gemeldete Sprache, einen nutzbaren Fuchs und Effekte. Die Mittelwerte betragen **268 Draw Calls** und **318.007,51 Primitive**.

Der höchste einzelne Fenster-P95-/P99-Wert beträgt **1.012,011 ms**. Die Fenster enthalten jeweils nur sechs oder sieben Samples; ihre Perzentile sind keine globalen Perzentile oder belastbaren Schätzungen seltener Verzögerungen. Gemessen sind Godot-Prozessintervalle, keine Display-Presentation-Zeitstempel. **60 FPS sind in dieser Umgebung nicht erreicht.** Die Software-Rendererwerte erlauben weder eine physische Fold7-FPS-Prognose noch die eindeutige Zuschreibung eines einzelnen Engpasses. [Neue Messwerte und Messgrenzen](evidence/ci-2032-android-complete-verified/root-initial-review.json).

### Erhaltener erster Fehlversuch

Androidjob **133211685356** endete am **16.11.2026 um 09:46:04 UTC FAIL**, bevor eine Lernaufgabe erreicht wurde. Über dem sichtbaren Onboarding lag der Android-Systemdialog **„Pixel Launcher isn't responding“**; alle 22 XMLs enthielten diesen Dialog und keine erlaubten Lumo-Startknoten. Es wurde kein Starttap ausgeführt. Die 42 Originaldateien, ZIP, Rohlog, Fehlerbild und Video sind [vollständig erhalten](evidence/ci-2032-android-launcher-anr-failure/README.md). Ein Lumo-ANR oder die genaue Launcherursache ist daraus nicht belegt.

Erst nach dieser Sicherung wurde der genau einmalige unveränderte zweite Androidversuch am **09:58:59 UTC** gestartet. Er verwendet dieselben APKs und Prüfbedingungen. Sein neuer Erfolg ersetzt den alten FAIL nicht. [Aktivierungsbeleg](evidence/2032-android-retry-20261116/activation.json).

## 4. Repositories, Branches und genaue Commits des integrierten Stands

| Repository / Rolle | Branch | Genauer integrierter beziehungsweise zugeordneter Stand |
| --- | --- | --- |
| `Ullmann27/lumo-lernen`: aktivierte APK-Quelle | `integration/lumo-nextgen-learning-20261115` | Commit `9b38360ca5f21919dce4a2b99e605ee39bbbf454`, Tree `1c572ff37dde942229e8ae8b1f141ec95df50545` |
| `Ullmann27/lumo-godot`: gepinnte native Quelle | `integration/lumo-nextgen-learning-20261115` | Commit `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`, Tree `26b6e5301372d4ade91ca8955f7c1ccf5d0dee78` |
| `Ullmann27/lumo-godot`: veröffentlichter Kontrastbaustein | `fix/lumo-learning-button-state-contrast-20261116` | API-Commit `4eeafe49e632e56dd7f517804f09032ab0be0fe5`; identischer Tree zum integrierten nativen Stand; ursprünglicher lokaler Producer `570e8238aabcb5d0e2c7dc19d237ad82d03a3959` |
| `Ullmann27/lumo-lernen`: veröffentlichter aktueller Stopp-Prüfweg | `qa/lumo-current-native-stop-20261116` | API-Commit `c55df64ce3c699363e04f6d2472c71a9db230fb1`, Tree `41ed1d22425f6a1c499b3986bd81738f1cba620d`; ursprünglicher Producer `e0df201c73509a44384bcce3ebaad82cce00bde3` |
| `Ullmann27/lumo-lernen`: tatsächlicher Katalogexport | `integration/lumo-nextgen-learning-20261115` | Commit `a5ea7422b1152576b34cf80519856129ff264ac1`, Tree `e72c53feed7e5360f7f677b6bc49c58bfd50cd5d` |
| Veröffentlichter ursprünglicher Berichtsentwurf | `docs/lumo-nextgen-2032-delivery-draft-20261116` | API-Commit `05e0b3a97cfbcee7db5d1aaf48cd499ff9f2d153`, Tree `4ee97f942f9b31712b3efbfe782c4bc7b83b545b`; Root-Integration `7b2cabc89ace083eb7f30d9d06f19c7d840406e5`, spätere Ergebnisergänzungen getrennt von der APK-Quelle |

- **Version und Pin stimmen im gebauten Quellstand überein:** `0.13.20+2032`, tatsächlicher Tag `lumo-nextgen-learning-0.13.20-2032`, Godot `4.6.3`. Der erneut abgefragte Tag und das veröffentlichte Release zeigen auf die oben bezeichnete APK-Quelle; die genaue Prüfung ist im Publikationsbeleg erhalten. [Releasekonfiguration](../../config/nextgen-release.json), [pubspec.yaml](../../pubspec.yaml), [Godot-Pin](../../config/godot-source.json).
- **Baustein, Integration und APK-Quelle sind verschiedene Identitäten.** Die Integration bindet die geprüften Dateien an die oben genannte Buildquelle. Der lokale Producer und der API-Commit können trotz identischem Tree unterschiedliche Commit-Hashes haben. Die [Native-Integration](evidence/2032-native-contrast-integration-20261116/root-source-review.json) und die [Stopp-Integration](evidence/2032-current-stop-integration-20261116/root-integration-review.json) halten diese Zuordnung fest. `main` wurde für diesen Dokumentauftrag nicht verändert.

- **Die Host-Produktquellen sind gegenüber der 2031-Quelle unverändert.** Der Vergleich von `e05a96a52aaf57e466e79831f15aaffd144284ee` zu `9b38360ca5f21919dce4a2b99e605ee39bbbf454` enthält keinen Unterschied in `lib/`, `android/`, `assets/`, `tools/auto_install/` und `pubspec.lock`. Der Lockfile-Hash lautet weiterhin `4c612feb2e36fa91b798da5d032b73148ece9897a66197c125013e7f7b0764ea`. Versions-/Pin-, Prüf- und Dokumentationsänderungen sind davon getrennt. Das überträgt keine Android-Abnahme auf die neu gebaute APK.

### Tatsächliche ursprüngliche Teamlieferungen

Auch die ursprünglichen Chatlieferungen sind im [quellgebundenen Review](evidence/2032-original-team-integration-review-20261116/readonly-review-bd876747.json) nachvollziehbar. Es handelt sich um ausgewählte und weiterintegrierte Komponenten; ein vollständiger unveränderter Merge aller Teambranches wird nicht behauptet.

| Team / tatsächlicher Zweig | Belegter Übergabestand und Integration |
|---|---|
| Chat 2 – `feature/lumo-nextgen-learning-chat2-20261115` | Owner-Checkpoint `573eb1a14045eb2e7071f250107d6b9a4fb3bf96`, ergänzt um ausdrücklich eingefrorene damalige Arbeitsbaumdateien im Freeze `8d612f074254548ef8e9296423222832c61f0375`. Alle 18 Modul-Screenhashes des abschließenden Snapshots stimmen am APK-Stand; spätere Adapter-/Lebenszykluskorrekturen sind getrennt belegt. |
| Chat 3 – `art/lumo-nextgen-avatar-20261115-54fe` | Beobachteter Owner-HEAD `20fb9f71939f4acdb7dd87cbca54a5d9da36e504` war **kein finaler Commit der gelieferten Dateien**. Runtime-/Authoring-Snapshots dokumentieren die damaligen uncommitteten Lieferdateien. In Native `9d6ef1d…` sind 24 von 28 Runtime-Dateien sowie alle 14 Authoring-Dateien unverändert; vier Runtime-Skripte wurden anschließend integriert und korrigiert. Dauerhafte native Integrationscommits umfassen `7b3f327deab471000488f9bed1d82ea21a77bdc8` und `e5a36bcecf3f9d5b0f59b25848a2cccdaf441a2f`. |
| Chat 4 – `feature/lumo-nextgen-conversation-20261115-403a` | Aus `818096d4ec2e1b8abfad53a14b38cea0538ec250` wurden der kompatible SpeechListener und `LumoLocalRecognition.kt` selektiv übernommen. Beide sind am APK-Stand bytegleich; dauerhafter Hostcheckpoint `a31080c90284b705853e5e340ce8063e4d007ed9`. Die konkurrierende Datei `lumo_task_dialogue.dart` wurde nicht in die App aufgenommen. |
| Kanonische Vertrags-/Gesprächsgrundlage – `integration/lumo-learning-generation-20261115-ea41` | Vertrag `421a0c3261a57dd15733531058cf2291d765d38d`, Flutter-Gesprächsgrundlage `9c0eba6c540e6262d6238236a3999971c8799ce4`, native Gesprächsgrundlage `79529b133b2b5640442948616d80596047220e67`. Die anschließenden Integrationskorrekturen bleiben Teil der oben gebundenen APK-Quelle. |

## 5. APK und echte Screenshots beziehungsweise Videos

### Direkter APK-Download

[**Lumo-Lernen-Neu-0.13.20-2032.apk**](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.20-2032/Lumo-Lernen-Neu-0.13.20-2032.apk)

- **ARM64, 535.026.462 Bytes**, Version **0.13.20+2032**.
- SHA-256 **`cfa6709547ed82ffe6f081568c3bc454e1cc41afbfea2ecf9c85f534a6ea42de`**.
- Paket **`dev.ullmann.lumo.lumo_lernen.coachpreview`**, bestehendes Testzertifikat SHA-256 **`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`**; keine Play-Produktionssignatur.
- Release **446893589**, APK-Asset **754429456**, Publisherjob **133238196787 SUCCESS**.
- Vollständiger anonymer Download mit **HTTP 200**, passender Größe und SHA am **16.11.2026 um 10:33:37 UTC**; [Originalbeleg](evidence/ci-2032-publication-verified/original/PUBLIC-DOWNLOAD-VERIFIED.json), [zusätzlicher Root-Abgleich](evidence/ci-2032-publication-verified/root-publication-review.json).

Die x86-Prüf-APK umfasst **538.191.855 Bytes**, SHA-256 **`388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1`**. Beide enthalten dasselbe PCK: **278.589.884 Bytes**, SHA-256 **`e7313f1cd28dd00ee324e6798aec6be65e91b28a09bb2b5d2a012a45de5953e7`**. minSdk 24, targetSdk 36, ABI, ELF-16-KiB- und Ressourcen-Ausrichtung wurden im Paketprüfer bestätigt. Root hat zusätzlich sämtliche ARM64-Archiv-/APK-Bytes und Sidecars abgeglichen; `apksigner` wurde lokal nicht erneut ausgeführt.

Der Tag und das Release zeigen auf die tatsächliche APK-Quelle. Die Veröffentlichung ist öffentlich und als Vorabversion markiert; frühere APKs wurden nicht ersetzt. GitHub meldet **immutable=false**, daher wird keine serverseitige unveränderliche Release-Sperre behauptet.

### Aktuelle Originalaufnahmen

Alle folgenden Bilder stammen aus der tatsächlichen 2032-APK im API-35-Emulator; sie sind keine Desktopaufnahme und kein generierter Entwurf.

| Aufnahme | Aktueller unveränderter Originalbeleg |
|---|---|
| Acht im Feld und fünf daneben | [Bild](evidence/ci-2032-android-complete-verified/original/original-android/0438-why-native-eight-and-five-before-question.png) |
| Zehn im Feld und drei übrig | [Bild](evidence/ci-2032-android-complete-verified/original/original-android/0462-why-native-ten-and-three-after-explanation.png) · [Frage und sichtbare Bewegung im Film](evidence/ci-2032-android-complete-verified/original/original-android/0435-native-why-two-question-and-demonstration.mp4) |
| Banane, Ba–na–ne | [Bild](evidence/ci-2032-android-complete-verified/original/reference-android/0143-banana-syllable-3.png) · [Viersegment-Wiederholung](evidence/ci-2032-android-complete-verified/original/reference-android/0165-banana-four-segment-repeat.mp4) |
| Wiederholungsgruppe im Muster | [Bild](evidence/ci-2032-android-complete-verified/original/reference-android/0427-pattern-two-sign-group.png) · [Hinweis und ungewerteter Vorschlag](evidence/ci-2032-android-complete-verified/original/reference-android/0403-pattern-observed-group-and-unconfirmed-proposal.mp4) |
| Aktive Stopptaste und anschließender Ruhezustand | [Vorher](evidence/ci-2032-android-complete-verified/original/reference-android/0336-runtime-voice-stop.png) · [Nachher](evidence/ci-2032-android-complete-verified/original/reference-android/0354-runtime-bridge-after-stop.png) · [Originalfilm](evidence/ci-2032-android-complete-verified/original/reference-android/0287-runtime-bridge-current-playback-direct-stop.mp4) |
| Kompakte Laboransicht | [720×1600](evidence/ci-2032-android-complete-verified/original/original-android/0201-bridge-compact.png) |
| Emulierte Fold7-Laboransichten | [Außen](evidence/ci-2032-android-complete-verified/original/original-android/0221-bridge-fold7-cover-emulated.png) · [Innen](evidence/ci-2032-android-complete-verified/original/original-android/0231-bridge-fold7-inner-emulated.png) |

Die Bildschirmfilme enthalten **keine Tonspur**. Die getrennten Audioereignisse belegen aktuelle MediaPlayer-Abläufe; daraus wird keine akustische Wortqualität abgeleitet. Die vollständigen Originale einschließlich aller weiteren Aufnahmen sind im veröffentlichten [Android-Lernpruefung.tar.gz](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.20-2032/Android-Lernpruefung.tar.gz) enthalten. Root hat das gesamte Actions-ZIP und alle **4.066** Mitglieder geprüft; [Archiv-/Auswahlbindung](evidence/ci-2032-android-complete-verified/retention-and-selection.json).

## 6. Konkrete verbleibende Grenzen

- **Gesamtmodernisierung:** `fullModernizationComplete=false` und `allTaskVariantsReviewed=false` bleiben bestehen. Der vollständige Katalog und die äußeren Anschlüsse belegen keine individuelle räumliche Überarbeitung jeder der 236 Familien oder jeder erzeugten Variante. Die native Szene ist eine separate Activity; Lumo steht nicht dauerhaft als 3D-Figur in jeder Flutter-Aufgabe. Praktische Beobachtungen, Nachschlageflächen und geschützte Module behalten ihre eigenen Abläufe.
- **Aktueller gezielter Nachlauf:** Noch offen sind eine tatsächlich falsch bewertete Zahl mit anschließender Korrektur, ein Aufgabenwechsel während aktiver Wortwiedergabe, die verlangsamte native Banane mit vier Segmenten und die echte fachliche Musterabgabe nach nativer Hilfe. Dafür wird ein getrennter QA-Zweig zur unveränderten veröffentlichten APK erstellt. Historische 2031-Teilfälle werden nicht als neue 2032-Ergebnisse ausgegeben.
- **Sprache und Gespräch:** Echte deutsche STT, verhörte Sprachzahl und gesprochene Korrektur bleiben unbestätigt. Die aktuelle Tour erfasst eine explizite Gerätegrenze. Ein frei generatives KI-Gespräch über den optionalen Proxy wurde nicht gerätegeprüft. Der lokale aufgabengebundene Dialog ist nutzbar; seine Texteingabe ist kein Nachweis beliebiger freier KI-Unterhaltung.
- **Audio und Figur:** Aktueller Playerstopp und geordnete Wiedergabesegmente sind belegt. Akustische Aussprache, tatsächliches Sprechtempo am Ohr, phonemgenaue Lippenbewegung sowie ein gemeinsam vermessener Stopp von Ton, Mund und Geste sind damit nicht nachgewiesen. Nicht jeder der 23 vorhandenen Clips wurde einzeln auf Android visuell abgenommen.
- **Leistung:** Das Ziel 60 FPS ist nicht erreicht beziehungsweise auf physischer Hardware nicht geprüft. Die aktuelle Software-Emulator-Messung ist ausdrücklich ausgewiesen; eine konkrete Engpassursache und eine physische Leistungsprognose werden daraus nicht erfunden.
- **Geräte und Bediengrößen:** Es liegt kein physischer ARM64-/Fold7-Test, kein realer Scharnierversuch und kein flächendeckender 48-dp-Nachweis für sämtliche Steuerelemente vor. Die vier logischen Größenwechsel betreffen die protokollierte Flutter-Laboraufgabe. Drehung, große Schrift, alle nativen Szenen und sämtliche Varianten auf physischer Hardware bleiben gesondert zu prüfen.
- **Speichern und Updates:** Geschützte Dateien, Paket, Signatur und bestehende Datenformate bleiben erhalten; die beobachteten synthetischen Profile und Aufgabenstände überleben die geprüften Rückwege. Ein tatsächliches Upgrade über ein vorhandenes echtes Kinderprofil ist nicht Bestandteil dieses Laufs.

Die APK ist konkret ausgeliefert. Die offene Gesamtmodernisierung und die aufgeführten Nachweisgrenzen werden dadurch nicht als erledigt erklärt; der gesonderte aktuelle QA-Nachlauf ergänzt ausschließlich die tatsächlich geprüften Fälle.
