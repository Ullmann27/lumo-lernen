"""Produce an explicitly qualified function matrix from the audited source tree."""
import json
import re
from pathlib import Path

ROOT = Path('docs/audit/2026-10-13')
BASE = 'd7440beaba78992ee36c8f4be1513e6b5006c1f6'
PIN = 'ec96515a2e359d21e9591120fc81dfd15116e81e'
tests = {str(p): p.read_text() for p in Path('test').rglob('*.dart')}
rows = []


def add(name, path, status, route, data, bug, risk, next_step, godot=False):
    repo = 'Ullmann27/lumo-godot' if godot else 'Ullmann27/lumo-lernen'
    selected = [p for p, text in tests.items() if path.removeprefix('lib/') in text]
    if godot:
        selected = [str(p.relative_to('../lumo-godot'))
                    for p in Path('../lumo-godot/scripts/tests').glob('*.gd')
                    if path in p.read_text()]
    rows.append({
        '1_function_and_purpose': name,
        '2_source': {'repository': repo,
                     'branch': 'sol/lumo-1937-kart-quality-2026-10-12' if godot else 'copilot/lumo-1938-integration-follow-up',
                     'commit': PIN if godot else BASE, 'path': path},
        '3_development_status': status,
        '4_home_reachability': route,
        '5_navigation_data_dependencies': data,
        '6_existing_tests_execution': {'direct_references': selected,
             'execution': 'Godot: in dieser Sitzung nicht ausgeführt; alte Nachweise nicht übertragen.' if godot else 'Baseline-Suite d7440be: 1456 PASS/117 SKIP; einzelne Auswahl/Skips im Originalprotokoll prüfen. Neue Deltas brauchen neue Ausführung.'},
        '7_android_runtime': 'Für diesen aktuellen Auftrag nicht neu ausgeführt. Keine APK-/Fold-Freigabe aus Quelle/Widgettest ableiten.',
        '8_missing_connections_bugs': bug,
        '9_integration_risk': risk,
        '10_next_implementation': next_step,
    })


add('App-Start, Profile, adaptive Shell', 'lib/main.dart', 'integriert; Gesamt-Androidabnahme ungeprüft',
    'main → LumoApp → AppShell → HomeContent', 'ProfileRepository/Wallet/Settings; AppShell baut Bereiche aus LumoSection',
    'Keine aktuelle Gesamt-APK-Abnahme; breite/kompakte Layouts einzeln testen', 'hoch bei Ersetzen der Shell/Profilarchitektur', 'Bestehende Architektur erhalten; Update-/Resize-/Relaunchtest')
add('Akademie und Klassenwahl', 'lib/features/teacher_mode/lumo_akademie_screen.dart', 'teilweise integriert',
    'Home Lernen → AppShell.learn → Akademie → _openTopic', 'Ausgewählte Klasse lokal; höhere Klasse → GuidedLearningHub discovery; normale Spezialmodule/Chatfallback',
    'Nicht jedes Topic hat echte Aufgabenroute; PR281 enthält Spenderdeltas', 'mittel; Schulstufen-/Profiltrennung', 'Jedes Topic mit tatsächlichem Navigations- und Generatorfall prüfen')
registry = Path('lib/features/learning_modules/learning_module_registry.dart').read_text()
imports = {Path(p).stem: 'lib/features/learning_modules/' + p for p in re.findall(r"import '([^']+_screen.dart)'", registry)}
for topic, screen in re.findall(r"case '([^']+)':\s*return (\w+)\(", registry):
    snake = re.sub(r'(?<!^)(?=[A-Z])', '_', screen).lower()
    path = imports.get(snake)
    if path is None:
        continue
    add(f'Spezialmodul {topic}: {screen}', path, 'entwickelt und über Registry angeschlossen; Runtime-Abnahme ungeprüft',
        f'Home Lernen → Akademie → Topic {topic} → LearningModuleRegistry → {screen}',
        'LumoAppState; eigene grafische Aufgaben/Hilfen; LearningModuleProgress. Für höhere als Profilklasse wird vorher Discovery gewählt. d1_woerter nutzt bei aktivem Flag vorher Wortcoach.',
        'Kein neues belegtes Moduldefizit durch Inventur; Klasse/Hilfe/Antwort/Speicher für jeden Aufruf prüfen',
        'mittel; didaktischen Spezialrenderer erhalten', 'Kein generisches Ersatzmodul; gezielte Aufgaben-/Foldregression')
add('Generische Mathematik/Deutsch/Sachunterricht/Logik-Aufgaben', 'lib/features/learning/learning_content.dart', 'integriert, Themenvollständigkeit ungeprüft',
    'Home Fach → _startPractice → AppShell.exercises → LearningContent', 'SchoolExerciseGenerator/Renderer; recordLearningAnswer und profile lease',
    'Schulstufen-/Themenkonformität und Wiederholungsfreiheit einzeln prüfen', 'mittel', 'Generatorfälle Klasse1–4 mit offiziellen Kompetenzen vergleichen')
add('Deutsch-Übersicht und Lernen', 'lib/features/deutsch/lumo_deutsch_screen.dart', 'integriert; Geschichtenanschluss fehlt',
    'Home Lernen → Akademie Deutsch → LumoDeutschScreen', 'Lokaler Deutschbereich; ReadingContent für Lesen',
    'Keine direkte freie Geschichtenbibliothek in dieser Basis', 'niedrig für Navigationsdelta', 'Vorhandenen Story-Einstieg aus Spender selektiv anschließen')
add('Aktives Lesen mit Sprachanalyse', 'lib/features/reading/reading_content.dart', 'integriert; aktuelle Stimme/Android ungeprüft',
    'Home Mehr entdecken → Lesen mit Lumo → AppShell.reading → ReadingContent', 'StoryEngine, ReadingAttemptHistory, mikrofonabhängiges aktives Lesen, profilgebundene Erinnerungen',
    'Eigene Vorleseroute ist kein Ersatz für frei erstellte Bibliotheksgeschichten', 'mittel', 'Lesebibliothek separat anschließen; Mikrofon-/Offline-/Berechtigungsfälle prüfen')
add('Freie Geschichtenbibliothek/Favoriten/Filter', 'lib/features/story/lumo_story_library_screen.dart', 'integriert mit indirektem Home-Einstieg',
    'Home Mehr entdecken → Magic Hub → Geschichten → Bibliothek → _createNew/_openStory',
    'LumoStoryLibrary; globaler v1-Speicherschlüssel; Filter nur im Speicher; initialGrade von gradeLevel',
    'Direkter Home-/Deutsch-/Lernpfadeinstieg fehlt; Profilisolierung globaler Bibliothek ungeprüft', 'niedrig Navigation, hoch neue Speicherzuordnung', 'Direktrouten testen; bestehende JSON-Hefte/Metadaten unverändert erhalten')
add('Geschichten-Setup freie/feste Klasse', 'lib/features/story/lumo_story_setup_screen.dart', 'PR284/285 integriert und baseline-getestet',
    'Bibliothek → erste/neue Geschichte → Setup → Überraschung/manuell → Reader',
    'initialGrade ?? Profilklasse, clamp1–4; Lernpfadklasse gesperrt; freie Klasse lokal änderbar',
    'Feste Lernpfadklasse vorhanden, Akademieroute noch nicht angeschlossen', 'niedrig', 'Original Profilklassen-/Lernpfad-/Filtertests unverändert behalten')
add('Geschichten lesen, Übungen, Abschluss', 'lib/features/story/lumo_story_reader_screen.dart', 'technisch fehlerhaft: Speichern vor Erfolg nicht gesichert',
    'Bibliothek/Setup/Quest → Reader → _nextPage/_showFinish',
    'LumoStoryGenerator, Bibliothek, Voice, Sterne/XP; Zusammenfassung mit heuristischem Stamm-Matching',
    'Kein await, Doppelfinishschutz, zuverlässiger Fehlerzustand oder SkillRecord für Verständnisantworten',
    'niedrig für Speichersynchronisierung; mittel für Antwortfachlichkeit/Wallet', 'Task1 kontrollierte Speichertests und minimale Reparatur; danach Antwortdaten separat')
add('Lumo Quest', 'lib/features/story/lumo_quest_hub_screen.dart', 'angeschlossen; Design/Antwortfachlichkeit teilweise',
    'Home Mehr entdecken → Lumo Quest → Quest-Karte → StoryReader', 'LumoQuestLibrary.forGrade; bestehende narrative Aufgaben',
    'Gleiche Reader-Speicher-/Antwortlücken; Design noch cremefarben', 'mittel', 'Reader reparieren, vorhandene Questinhalte erhalten')
add('Lern-DNA', 'lib/domain/learning/learning_dna_engine.dart', 'technisch/fachlich fehlerhaft',
    'Home Einstellungen → Elternbericht → Insight → LearningDnaEngine.compute', 'Aktuell SessionState statt profilgebundener SkillRecord-Daten',
    'Feste positive Werte, künstliche Confidence/Fehlerscores, Heute-Gesamtwert, Sterne als Streak', 'mittel; Eltern dürfen keine erfundene Diagnose erhalten', 'SkillRecord-Zähler/Antwortanzahl benutzen, Null-/kleine Stichproben klar benennen')
add('Lumo Insight und KI-Auswertung', 'lib/features/parents/lumo_insight_dashboard.dart', 'angeschlossen, Dateninterpretation fehlerhaft',
    'Einstellungen → ParentReportCard → LumoInsightDashboard', 'ErrorBreakdownRepository namensgebunden; AI-Proxy mit Elternsettings',
    'solved als recentCorrect, Help0/Sessions1, unbelegte Wochenereignisse; async Profilwechsel prüfen', 'mittel/hoch bei Profilvermischung', 'Profilgebundene SkillRecord-Gesamtwerte; Elternfreigabe erhalten; Prompt ohne Zeitbehauptungen')
add('Kompetenz-Heatmap', 'lib/features/parents/widgets/lumo_insight_heatmap.dart', 'entwickelt/angeschlossen; Darstellung korrigieren',
    'Insight → LumoInsightHeatmap(entries)', 'DnaSkillEntry score/confidence', 'Prozente ohne Antwortanzahl; helles älteres Design; kleine Stichprobe', 'niedrig Design, mittel Semantik', 'Nach Datenreparatur gezielte dunkle PR281-Optik und echte Stichprobentexte')
add('Finger-Schreibcoach', 'lib/features/writing/lumo_writing_coach_screen.dart', 'entwickelt/angeschlossen; S/C/H/O-Spender ungeprüft',
    'Akademie d1_schreibcoach / Magic Hub / Story-Ende → WritingCoach', 'WritingEngine, geometrische Stroke-Analyse, ProgressRepo, Voice',
    'PR282 bietet tolerant(er)e Erkennung/Fortschaltung; nicht pauschal übertragen', 'mittel; falsch akzeptierte Buchstaben', 'Reale Stroke-Fixtures S/C/H/O und Navigation/Belohnung vor Delta')
add('Wort-Schreibcoach/Diktat', 'lib/features/writing/lumo_writing_word_coach_screen.dart', 'aktiv hinter enableWordMode=true',
    'Akademie d1_woerter → WordCoach vor Registry', 'WritingEngine und Schreibfortschritt; Buchstabenfelder',
    'Handschrift-Toleranz darf Rechtschreibung nicht aufweichen', 'mittel', 'Spenderdelta getrennt mit richtigen/falschen Wörtern testen')
add('ML Kit Digital Ink/Blatt-OCR', 'lib/features/writing/writing_feature_flags.dart', 'nicht aktiviert; keine fertige ML-Abnahme',
    'enableDigitalInkRecognition=false, enableSheetOcr=false; geometrischer Coach läuft unabhängig',
    'Bestehende Flags; kein automatisches Modell-/Online-Aktivieren', 'ML/OCR-Fertigstellung durch Flag allein nicht belegt', 'hoch bei Datenschutz-/Berechtigungsänderung', 'Vorhandenen Coach erhalten; ML-Pfad erst eigenes Prüfprojekt')
add('Lumo-Meister', 'lib/domain/quiz/quiz_show.dart', 'Basis15Fragen; Spender20Fragen entwickelt, nicht integriert',
    'Home Mehr entdecken → Quiz → QuizShowContent; Spielewelt-Direktportal als Spender',
    'QuizQuestionBank, QuizShowState, Joker/Fragen/Sicherheitsstufen', 'Basis15Fragen; PR28220Fragen; Belohnung/Deduplizierung separat prüfen', 'mittel/hoch Wallet/Regeländerung', 'Exakte 20-Fragen-Deltas und vollständige Runde testen')
add('Family-Park-Regel/Elternfreigabe', 'lib/domain/rewards/reward_catalog.dart', 'technisch integriert, Produktregel widersprüchlich',
    'Home Belohnungen → RewardShop → family_park', 'RewardCatalog, Wallet, Elternfreigabe', 'family_park cost30000 an Basis; Auftrag fordert5000', 'mittel; Ausgabe-/Updatekompatibilität', 'PR282-Preisdelta mit Grenzwerten4999/5000 und Elternfreigabe/Dedupe testen')
add('Offline-Stimme/ONNX und Sulafat', 'lib/core/lumo_voice.dart', 'vorhanden/angeschlossen; Hörqualität nicht neu abgenommen',
    'main init / Shell Settings / Lernmodule sprechen über LumoVoice.instance',
    'Native offlineClient, VoicePolicy, Clips, AudioCache, getrennte LegacySulafat-Elternautorisierung',
    'Fehlerstatus/lastError vorhanden; jeder Bildschirm muss ihn verständlich anzeigen; Stimmhörtest offen', 'hoch bei Provider-/Identityersatz', 'Wiederholte/offline Aufgaben plus sichtbare Berechtigungs-/Modellfehler testen; keine neuen Dienste')
add('KI/Foto-Hilfe und Elternberechtigungen', 'lib/core/lumo_ai_proxy_client.dart', 'vorhanden/angeschlossen; App-/Serververtragsdelta prüfen',
    'Home optionale KI-/Foto-/Live-Einstiege; Elternsettings → FeaturePermission',
    'LumoAiProxyClient + server/lumo-ai-proxy; FeaturePermissions; kein Backgroundcall im Insight',
    'Auditzweig besitzt getrennte Transportfixes; nicht mit Story-Speichern bündeln', 'hoch Kinderdaten/Onlinekosten', 'Eigene KI-Transport- und Consenttests, kein kostenpflichtiges Aktivieren')
add('Spielewelt/Freischaltungen', 'lib/features/games/games_content.dart', 'entwickelt/angeschlossen; Profilidentität prüfen',
    'Home Spielen → AppShell.games → GamesContent → Spieleportale',
    'GameUnlockService/RewardWallet; GameProgressRepository; _childId aus Name+Klasse',
    'Namens-/Klassenidentität kann zwei Kinder/Wechsel berühren; keine neue Migration ohne Test', 'hoch bei Speicherzuordnung', 'Gleichnamige Kinder/Klassenwechsel und vorhandene Unlocks testen')

game_paths = {
 'Lumo Cards': 'lib/features/games/lumo_cards/lumo_cards_game_screen.dart',
 'Vier Gewinnt': 'lib/features/games/connect_four/lumo_connect_four_game.dart',
 'Memory': 'lib/features/games/memory/lumo_memory_game.dart',
}
for name, path in game_paths.items():
    if not Path(path).exists():
        candidates = list(Path('lib/features/games').rglob('*memory*dart')) if name == 'Memory' else list(Path('lib/features/games/lumo_cards').glob('*screen.dart'))
        path = str(candidates[0]) if candidates else path
    add(name, path, 'vorhanden und über Spieleportale erreichbar; Gesamtrunde neu ungeprüft',
        'Home Spielen → GamesContent → GamePortalSection → gewähltes Spiel',
        'Bestehende Regeln, Gegner/Animationen, Progress/Wallet; Cards hat Session-Recovery',
        'Keine neue Fehlfunktion allein durch Inventur behauptet; Relaunch/Zurück/Doppelauszahlung separat', 'mittel', 'Vorhandene vollständige Runde und Recoverytests prüfen statt Neuentwicklung')

godot_entries = [
 ('Embedded Godot Start/Rückkehr', 'scripts/app/scene_router.gd', 'Flutter Spielportal → nativer Host → boot → SceneRouter; goto home/games/learn → HostBridge.return_to_app', 'HostBridge, SceneRouter, LaunchOptions, ACK/Walletvertrag'),
 ('Kart Rennablauf/Physik/Drift/Items/Finish', 'scripts/games/kart_island.gd', 'Flutter Kart → eingebetteter Godot boot → kart_island → Rennen/Resultat → HostBridge', 'Powertrain/Fleet/Katalog/World; aktuelle Rückwärts-/Finish-Reparatur aus Pin65 erhalten'),
 ('Kart Flotte und Garage', 'scripts/games/kart_garage_menu.gd', 'Kart-Menü → Garage → Auswahlkarte/Werkstatt → zurück zum Rennstart', 'KartVehicle/Fleet/Workshop, Touch-Dragweiterleitung und responsive Spalten'),
 ('Lumo-Fahrer/Fell und Rig', 'scripts/games/kart_vehicle.gd', 'Garage/Rennszene → KartVehicle → LumoAnimationAdapter → RiggedActor', 'Lumo-Animated-Mobile.glb, CharacterFinish, FurGeometry, Animationsadapter'),
 ('Räumliche Kartwelt/Streckendetails', 'scripts/games/kart_world.gd', 'KartIsland → KartWorld/Katalog/Stage', 'Geometrie/Multimesh/Licht/Aquarium/Partikel; keine statische Artworkstrecke als Runtime ausgeben'),
 ('Fold Touchsteuerung', 'scripts/games/kart_touch_action.gd', 'KartIsland HUD → TouchAction/Gas/Bremse/Drift/Item', 'Mehrfingerinput, SafeArea, Resize; Smartphone/Fold getrennte Touchgrößen'),
 ('Kreative Bauwelt', 'scripts/creative/build_world.gd', 'Flutter Spieleportal → native SceneRouter build → build_world.tscn', 'Originale kreative Laternen-/KistenGLBs und Bau-/Speicher-/Rewardvertrag'),
 ('Schatzsuche', 'scripts/creative/treasure_world.gd', 'Flutter Spieleportal → native SceneRouter treasure → treasure_world.tscn', 'Kreative Welt, Quests, Treffer-/Abschluss-/Hostvertrag'),
 ('Puzzle', 'scripts/creative/puzzle_world.gd', 'Flutter Spieleportal → native SceneRouter puzzle → puzzle_world.tscn', 'Vorhandene Puzzleassets/Bewegung/Ergebnis/Rücknavigation'),
 ('Rhythmus', 'scripts/creative/rhythm_world.gd', 'Flutter Spieleportal → native SceneRouter rhythm → rhythm_world.tscn', 'Audio-/Timing-/Ergebnisvertrag'),
 ('Jump/Stars', 'scripts/games/jump_islands.gd', 'Flutter Spieleportal → native jump/stars; lokale Flamealternativen separat', 'Vorhandene Physik/Hindernisse/Hostresultate'),
 ('Godot Stimme', 'scripts/systems/audio_manager.gd', 'Autoload AudioManager → Spiel-/Lernereignisse/Hostvoice', 'Vorhandene Sulafat-/WAV-Manifeste, Hash-/Modellprüfung; alte Branches kein Komplettspender'),
]
for name, path, route, data in godot_entries:
    if not (Path('../lumo-godot') / path).exists():
        matches = list(Path('../lumo-godot/scripts').rglob(Path(path).name))
        if matches:
            path = str(matches[0].relative_to('../lumo-godot'))
    add(name, path, 'am geschützten Pin entwickelt/verdrahtet; neue Runtime ungeprüft', route, data,
        'Nicht in dieser Sitzung neu gestartet; vollständige Laufzeit/Referenzbewegung/Gerätleistung offen',
        'hoch bei Runtime-Pin-/Physik-/Hostwechsel', 'Godot4.6.3-Szenen-/Headless-/GLprüfungen separat, dann ausdrückliche Pinintegration', True)

covered = {row['2_source']['path'] for row in rows}
for path in sorted(Path('lib/features').rglob('*.dart')):
    p = str(path)
    if p in covered or not (p.endswith('_screen.dart') or p.endswith('_content.dart')):
        continue
    add('Weitere vorhandene Oberfläche: ' + path.stem, p, 'ungeprüft; Datei-/Importbestand belegt',
        'Konkrete Klick-/Callbackkette noch einzeln abnehmen; Importindex allein genügt nicht',
        'Abhängigkeiten siehe aktueller Quellcode/Importindex',
        'Kein Fehler oder verlorenes Feature ohne Navigationstest behauptet', 'noch zu bestimmen',
        'Konkreten Hauptmenüaufruf bis zur Aktion verfolgen, Widget-/Runtimebeleg nachtragen')

(ROOT / 'feature-matrix.json').write_text(json.dumps(rows, indent=2, ensure_ascii=False) + '\n')
lines = ['# Lumo Bestandsmatrix', '',
         'Ausgangs-SHA: App `' + BASE + '`, Godot `' + PIN + '`. Jede Zeile enthält zehn Pflichtfelder in `feature-matrix.json`. Diese lesbare Tabelle kürzt Quellen und Testdetails; neue Android-Ausführung ist bei **allen** Zeilen nicht erteilt.', '',
         '| Funktion/Zweck | Quelle | Stand | Erreichbarkeit/Datenfluss | Teststand | Befund | Risiko/Nächste Maßnahme |',
         '|---|---|---|---|---|---|---|']
for row in rows:
    source = row['2_source']
    cells = [row['1_function_and_purpose'], source['repository'] + ' `' + source['path'] + '`',
             row['3_development_status'], row['4_home_reachability'] + '; ' + row['5_navigation_data_dependencies'],
             str(len(row['6_existing_tests_execution']['direct_references'])) + ' direkte Testdateireferenzen; Ausführung/Skips siehe JSON/CI',
             row['8_missing_connections_bugs'], row['9_integration_risk'] + '; ' + row['10_next_implementation']]
    lines.append('| ' + ' | '.join(c.replace('|', '/') for c in cells) + ' |')
(ROOT / 'BESTANDSMATRIX.md').write_text('\n'.join(lines) + '\n')
print(f'{len(rows)} qualified feature rows')
