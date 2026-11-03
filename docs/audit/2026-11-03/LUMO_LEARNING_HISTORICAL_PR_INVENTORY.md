# Lumo Lernen – historische PR-Inventur seit Projektstart

Stand: 03.11.2026. GitHub REST `pulls?state=all&per_page=100`, alle fünf Seiten, vom initialen Flutter-PR bis zum aktuellen UX-PR #429. Dies ist eine **vollständige Metadateninventur** aller gefundenen PRs, keine Behauptung über unabhängiges Lesen jeder historischen Codezeile. Exakt freigegebener APK-2004-App-Quellstand: `1f99665c6b2b44f0e88a94264621652c0a9c34e8`. Änderungen in PR #429 sind experimentell und noch nicht veröffentlicht.

## Übersicht

- 405 PRs von #1 bis #429; fehlende Nummern sind Issues oder nicht vorhandene PRs.
- 186 gemergte, 208 offene, 11 geschlossen-unintegrierte PRs.
- **P0:** Direkt scrollbare 14-Register-Navigation ohne zusätzlichen Dropdown-Tap, robuste Fold-Beschriftung, alle alten Routen und 48-dp-Touchziele. Implementierung auf PR #429; unabhängige Flutter-CI noch abnehmen.
- **P0 Schulstufen:** offizielle RIS-/BMB-Lehrplan-Kompetenzen den angezeigten Units und echten Aufgaben zuordnen, nicht nur Generatorformate prüfen. Bisheriges Tutor-Audit dokumentiert 79.200 synthetische Aufgaben / 268 Fach-Themen-Kombinationen und 55 Kombinationen mit weniger als zwölf verschiedenen Aufgaben. Das beweist keine pädagogische Vollständigkeit; Content-Qualität und jahrgangsgerechte Verteilung sind offener Teil des Audits.
- **P1:** Lumo-Tutor-Erklärung, unabhängige Transferkompetenz und Aussprache-/Lese-/Schreibleistungen an tatsächliche Evidenz statt nur Multiple-Choice koppeln. Frühere PRs #301, #299, #416–#425 vergleichen.
- **P1 Design:** #273 Bildassets, #383 3D/Glas-Lernkarten, #389 Kindermenü, #405 Navigation, #423 Memory-2.5D hinsichtlich bereits enthaltener bzw. verbliebener Änderungen prüfen. Keine Layout-Neuschreibung ohne Original-Lumo zu erhalten.
- **P2:** #310 NVIDIA-Cloud-Tutorpilot ist *optional* und nicht die lokale Offline-Kernlogik; nicht ohne Einwilligungs-/Kinderdatenschutzprüfung oder absichtliche Produktentscheidung integrieren.
- **P2 Spiele:** Bauwelt und Memory müssen echte spielbare Fortschritte, Animation, Bedien-/Speicherkontrakte und Kinderverständlichkeit erfüllen; aktuelle Basisscreenshots ersetzen keinen pädagogischen Nutzertest.

## Vollständige Pull-Request-Liste

| PR | Status | Titel | Quellzweig |
|---:|---|---|---|
| [#1](https://github.com/Ullmann27/lumo-lernen/pull/1) | open | feat: Bootstrap Lumo Lernen Flutter/Android app from scratch | `copilot/create-lumo-lernen-app` |
| [#4](https://github.com/Ullmann27/lumo-lernen/pull/4) | closed | feat(tasks): use primary word bank in German generator | `feat/primary-word-bank-german-generator` |
| [#5](https://github.com/Ullmann27/lumo-lernen/pull/5) | merged | feat(tasks): wire primary word bank into German exercise generator | `feature-task-generator-20260502` |
| [#6](https://github.com/Ullmann27/lumo-lernen/pull/6) | merged | feat(learn): connect local Nachhilfe Plus engine after 3 attempts | `feature-local-tutor-hints-20260502` |
| [#7](https://github.com/Ullmann27/lumo-lernen/pull/7) | merged | test(tutor): cover decision logic for Nachhilfe Plus engine | `test-local-tutor-engine-20260502` |
| [#8](https://github.com/Ullmann27/lumo-lernen/pull/8) | merged | fix(learn): expand recent task memory and improve dedupe | `fix-recent-task-memory-20260502` |
| [#9](https://github.com/Ullmann27/lumo-lernen/pull/9) | merged | feat(tasks): add session variety guard | `feature-session-variety-guard-20260502` |
| [#10](https://github.com/Ullmann27/lumo-lernen/pull/10) | merged | feat(tasks): apply session variety in primary word bank | `feature-wire-session-variety-20260502` |
| [#11](https://github.com/Ullmann27/lumo-lernen/pull/11) | closed | fix(tasks): restore deterministic primary word bank selections | `fix-red-main-word-bank-variety-20260503` |
| [#12](https://github.com/Ullmann27/lumo-lernen/pull/12) | merged | fix(ci): do not fail debug build when artifact quota is full | `fix-actions-artifact-quota-20260503` |
| [#13](https://github.com/Ullmann27/lumo-lernen/pull/13) | merged | Add modern UI widgets | `feat-modern-lumo-ui-components-20260503` |
| [#14](https://github.com/Ullmann27/lumo-lernen/pull/14) | merged | Add composite UI cards | `feat-modern-lumo-widgets-20260504` |
| [#15](https://github.com/Ullmann27/lumo-lernen/pull/15) | merged | Audit tests and widget exports | `chore-audit-tests-20260503b` |
| [#16](https://github.com/Ullmann27/lumo-lernen/pull/16) | merged | Add recent repository tests | `repo-tests-20260503` |
| [#17](https://github.com/Ullmann27/lumo-lernen/pull/17) | merged | Add German generator tests | `test-german-generator-20260503` |
| [#18](https://github.com/Ullmann27/lumo-lernen/pull/18) | merged | Add didactic task styles | `feat-didactic-task-styles-20260503` |
| [#19](https://github.com/Ullmann27/lumo-lernen/pull/19) | merged | Add didactic style tests | `test-didactic-styles-20260503` |
| [#20](https://github.com/Ullmann27/lumo-lernen/pull/20) | merged | Add speech normalizer | `speech-tools-20260503` |
| [#21](https://github.com/Ullmann27/lumo-lernen/pull/21) | merged | Voice bubble | `voice-bubble-20260503` |
| [#22](https://github.com/Ullmann27/lumo-lernen/pull/22) | merged | Add reading syllable chip | `connect-reading-v2-20260503` |
| [#23](https://github.com/Ullmann27/lumo-lernen/pull/23) | merged | Add active sentence syllable view | `active-sentence-syllables-20260503` |
| [#24](https://github.com/Ullmann27/lumo-lernen/pull/24) | merged | Add learning help policy | `active-sentence-syllables-20260503` |
| [#25](https://github.com/Ullmann27/lumo-lernen/pull/25) | merged | Persist AI learning mode settings | `p5-ai-mode-settings` |
| [#26](https://github.com/Ullmann27/lumo-lernen/pull/26) | merged | Add parent AI policy selector UI | `feat-parents-ai-selector-ui` |
| [#27](https://github.com/Ullmann27/lumo-lernen/pull/27) | merged | Add AI learning policy bridge | `p5-ai-policy-bridge` |
| [#28](https://github.com/Ullmann27/lumo-lernen/pull/28) | merged | Show AI policy selector in parent settings | `feat-settings-ai-selector-visible` |
| [#29](https://github.com/Ullmann27/lumo-lernen/pull/29) | merged | Strengthen learning rescue feedback | `feat-learning-rescue-feedback` |
| [#30](https://github.com/Ullmann27/lumo-lernen/pull/30) | merged | Integrate reading analyzer 2 and text cleaner | `feat-reading-analyzer-integration` |
| [#31](https://github.com/Ullmann27/lumo-lernen/pull/31) | merged | Connect active reading sentence syllable view | `feat-reading-active-sentence-view` |
| [#32](https://github.com/Ullmann27/lumo-lernen/pull/32) | merged | Add AI policy guard | `feat-core-add-ai-policy-guard` |
| [#33](https://github.com/Ullmann27/lumo-lernen/pull/33) | closed | Sync main into fix-v0.3.1-core-stabilization | `main` |
| [#34](https://github.com/Ullmann27/lumo-lernen/pull/34) | merged | Improve German tasks, spelling choices and session variety/quality checks | `codex/find-current-app-status` |
| [#35](https://github.com/Ullmann27/lumo-lernen/pull/35) | merged | fix(build): stabilize quality product sprint branch reward compile path | `copilot/stabilize-existing-feature` |
| [#36](https://github.com/Ullmann27/lumo-lernen/pull/36) | merged | feat(rewards): merge stabilized quality product sprint | `copilot/quality-product-sprint-lumo-lernen` |
| [#37](https://github.com/Ullmann27/lumo-lernen/pull/37) | open | feat(games): add Spiele entry point and modular level-map scaffold | `copilot/check-current-status` |
| [#38](https://github.com/Ullmann27/lumo-lernen/pull/38) | merged | feat(games): add number house mini game | `codex/sprint-8-number-house` |
| [#39](https://github.com/Ullmann27/lumo-lernen/pull/39) | open | feat(games): add lumo jump adventure prototype | `feat-lumo-jump-adventure-prototype` |
| [#40](https://github.com/Ullmann27/lumo-lernen/pull/40) | open | Stabilize PR #39 compile path for Lumo Jump level routing | `copilot/stabilization-pr-39` |
| [#41](https://github.com/Ullmann27/lumo-lernen/pull/41) | open | Stabilize handwriting target parsing for non-canonical writing prompts | `copilot/analyze-and-refactor-code` |
| [#42](https://github.com/Ullmann27/lumo-lernen/pull/42) | open | Spielewelt stabilisiert: alle Level spielbar gemacht und StarsPath-Mechanik entkoppelt/variiert | `copilot/optimiere-spiel-performance-und-code-struktur` |
| [#43](https://github.com/Ullmann27/lumo-lernen/pull/43) | open | Stabilize game progression by wiring all level types to adaptive gameplay and deterministic task mapping | `copilot/optimize-game-code-performance` |
| [#44](https://github.com/Ullmann27/lumo-lernen/pull/44) | open | feat(games): Lumo Jump Adventure Premium Logic (Child-Safe) | `copilot/finalize-lumo-jump-adventure` |
| [#45](https://github.com/Ullmann27/lumo-lernen/pull/45) | open | fix(app): prepare playable lumo jump test build | `copilot/fix-lumo-jump-game` |
| [#46](https://github.com/Ullmann27/lumo-lernen/pull/46) | merged | feat(games): Lumo Jump Adventure – 60-FPS Ticker Engine, Roll/Dash-Mechanik, Spelunky-Gap-Garantie | `copilot/feat-engine-overhaul-timer-replacement` |
| [#47](https://github.com/Ullmann27/lumo-lernen/pull/47) | merged | feat: Animierten Lumo-Fuchs (FoxSprite) vollständig integrieren | `copilot/add-animated-lumo-fox` |
| [#48](https://github.com/Ullmann27/lumo-lernen/pull/48) | open | feat(home+games): autonomer Lumo-Avatar + 5 Weltthemen im Jump-Game | `copilot/transfer-codex-clause-4-6` |
| [#49](https://github.com/Ullmann27/lumo-lernen/pull/49) | open | fix(ci): stabilize APK release workflow | `codex/check-.github/workflows/release-apk.yml` |
| [#50](https://github.com/Ullmann27/lumo-lernen/pull/50) | closed | feat(writing): Schreibcoach Phase 5 + 6 (Wortdiktat + Progress) | `claude/continue-previous-chat-KtY7p` |
| [#51](https://github.com/Ullmann27/lumo-lernen/pull/51) | merged | feat(writing): Phase 5+6 — Wortdiktat + Progress-Tracking + Elternbericht | `claude/phase56-on-main` |
| [#52](https://github.com/Ullmann27/lumo-lernen/pull/52) | merged | fix(writing-canvas): Stroke-Sprung + falsche Bestaetigung beheben | `claude/continue-previous-chat-KtY7p` |
| [#53](https://github.com/Ullmann27/lumo-lernen/pull/53) | merged | feat(diagnose): Crash-Recovery + Fehlerprotokoll im Elternbereich | `claude/continue-previous-chat-KtY7p` |
| [#54](https://github.com/Ullmann27/lumo-lernen/pull/54) | merged | fix: Farb-Quiz + Pizza-Bruch + Reward-Fehler + Canvas-Lifecycle | `claude/continue-previous-chat-KtY7p` |
| [#55](https://github.com/Ullmann27/lumo-lernen/pull/55) | merged | fix: 7 Bugs - Brueche, Uhr-Delay, Geld-Muenzen, Stars-Inflation, Umlaute, TTS, Loop-Safety | `claude/continue-previous-chat-KtY7p` |
| [#56](https://github.com/Ullmann27/lumo-lernen/pull/56) | merged | fix(story+live): Grammar + 30 Tiere Allowlist + Umlaut-Filter + Lade-UI | `claude/continue-previous-chat-KtY7p` |
| [#57](https://github.com/Ullmann27/lumo-lernen/pull/57) | merged | feat(story): Lange Geschichtsbuch-Texte + Zusammenfassungs-Aufgabe mit Lumo-Bewertung | `claude/continue-previous-chat-KtY7p` |
| [#58](https://github.com/Ullmann27/lumo-lernen/pull/58) | merged | fix(home): LumoFreeCompanion-Overlay komplett ausblenden | `claude/continue-previous-chat-KtY7p` |
| [#59](https://github.com/Ullmann27/lumo-lernen/pull/59) | merged | feat(games): Kart raus + Memory + Vier gewinnt + Wuerfel-Wettlauf (Lumo-vs-Kind) | `claude/continue-previous-chat-KtY7p` |
| [#60](https://github.com/Ullmann27/lumo-lernen/pull/60) | merged | fix(ci): smoke_lumo_kart_test entfernt (passt zu Kart-Removal) | `claude/continue-previous-chat-KtY7p` |
| [#61](https://github.com/Ullmann27/lumo-lernen/pull/61) | merged | docs: Konnektoren-Strategie fuer Lumo Lernen | `claude/continue-previous-chat-KtY7p` |
| [#62](https://github.com/Ullmann27/lumo-lernen/pull/62) | merged | design-polish(home): Subject-Tiles mit echten Emojis konsistent machen | `claude/design-polish-subject-tiles` |
| [#63](https://github.com/Ullmann27/lumo-lernen/pull/63) | merged | fix(farben+wuerfel): Artikel, Bilder, Tippe-rot, Overflow + Design | `claude/fix-farben-wuerfel-kaputt` |
| [#64](https://github.com/Ullmann27/lumo-lernen/pull/64) | merged | design-polish(2): Tiere + Wetter + Geld visuell aufwerten | `claude/polish-2-tiere` |
| [#65](https://github.com/Ullmann27/lumo-lernen/pull/65) | merged | fix(crash+tutorial): WordCoach-Absturz + Tutorial erklaert mehr | `claude/fix-wordcoach-crash-tutorial` |
| [#66](https://github.com/Ullmann27/lumo-lernen/pull/66) | merged | feat(update): Ein-Klick-Aktualisierung + stabiler Debug-Keystore | `claude/in-app-update-keystore` |
| [#67](https://github.com/Ullmann27/lumo-lernen/pull/67) | merged | fix(tutorial+writing): Fuchs trifft echte Buttons, Schreiben scrollt nicht mehr | `claude/fix-tutorial-jumps-writing` |
| [#68](https://github.com/Ullmann27/lumo-lernen/pull/68) | merged | fix(update)+feat(profile): Update-Erkennung repariert + Profil zuruecksetzen | `claude/fix-update-detection-profile-reset` |
| [#69](https://github.com/Ullmann27/lumo-lernen/pull/69) | merged | feat(games): Lumo Cards MVP - 2-Spieler-Karten-Duell (Pass-and-Play) | `claude/feat-lumo-cards-mvp` |
| [#70](https://github.com/Ullmann27/lumo-lernen/pull/70) | merged | fix(lumo-cards): Hand sichtbar, Pass-Overlay erscheint, kein Overflow | `claude/fix-lumo-cards-layout` |
| [#71](https://github.com/Ullmann27/lumo-lernen/pull/71) | merged | feat(lumo-cards): Solo-Bot, Lumo-Sprueche, Streak, Karten-Animation | `claude/feat-lumo-cards-solo-bot` |
| [#72](https://github.com/Ullmann27/lumo-lernen/pull/72) | merged | feat(lumo-cards): volles Karten-Set + Super-Sternenregen | `claude/feat-lumo-cards-uno-style` |
| [#73](https://github.com/Ullmann27/lumo-lernen/pull/73) | merged | feat(lumo-cards): Action-Button, Hint-Bubble, Result-Dialog + Asset-Mapping | `claude/feat-lumo-cards-layout-spec` |
| [#74](https://github.com/Ullmann27/lumo-lernen/pull/74) | merged | feat(lumo-cards): saubere Spieler-Avatare aus Heinz' Pack | `claude/feat-lumo-cards-avatars` |
| [#75](https://github.com/Ullmann27/lumo-lernen/pull/75) | merged | feat(lumo-cards): Avatar-Picker am Start + Spieler-Mini-HUD unten | `claude/feat-lumo-cards-avatar-picker` |
| [#76](https://github.com/Ullmann27/lumo-lernen/pull/76) | merged | feat(lumo-cards): Score-Header + LUMO-Call-Button + Farb-Pfeile | `claude/feat-lumo-cards-layout-polish` |
| [#77](https://github.com/Ullmann27/lumo-lernen/pull/77) | merged | feat(lumo-cards): Heinz' eigene Karten-PNGs einbinden (40 + Back) | `claude/feat-lumo-cards-from-sheet` |
| [#78](https://github.com/Ullmann27/lumo-lernen/pull/78) | merged | feat(lumo-cards): Spezialkarten + Hue-Rotation (5 Originale → 14 PNGs) | `claude/feat-lumo-cards-specials` |
| [#79](https://github.com/Ullmann27/lumo-lernen/pull/79) | merged | fix(lumo-cards): Crash + Overflow im Layout reparieren | `claude/fix-lumo-cards-crash-overflow` |
| [#80](https://github.com/Ullmann27/lumo-lernen/pull/80) | merged | fix(lumo-cards): Avatar-Picker beim Start raus (Race-Condition Fix) | `claude/fix-lumo-cards-still-crashes` |
| [#81](https://github.com/Ullmann27/lumo-lernen/pull/81) | merged | fix(lumo-cards): debugNeedsLayout-Crash + Lumo-Logo-Intro | `claude/fix-lumo-cards-debugneeds` |
| [#82](https://github.com/Ullmann27/lumo-lernen/pull/82) | merged | feat(lumo-cards): "DEIN ZUG"/"GEGNER" Turn-Pille im HUD-Asset-Stil | `claude/lumo-cards-hud-polish` |
| [#83](https://github.com/Ullmann27/lumo-lernen/pull/83) | merged | feat(lumo-cards): neue hi-res Karten aus Heinz' Sheets (55 PNGs) | `claude/lumo-cards-new-cards` |
| [#84](https://github.com/Ullmann27/lumo-lernen/pull/84) | merged | fix(lumo-cards): debugNeedsLayout-Crash im Hand-Bereich akribisch repariert | `claude/lumo-cards-hand-crash-fix` |
| [#85](https://github.com/Ullmann27/lumo-lernen/pull/85) | merged | fix(lumo-cards): _dependents.isEmpty Crash beheben (conditional MediaQuery raus) | `claude/lumo-cards-dependents-fix` |
| [#86](https://github.com/Ullmann27/lumo-lernen/pull/86) | merged | refactor(lumo-cards): Karten-Widget vereinfachen + Gegner-Hand + groessere Karten | `claude/lumo-cards-big-refactor` |
| [#87](https://github.com/Ullmann27/lumo-lernen/pull/87) | merged | feat(lumo-cards): Lege-Animation auf Discard + Konfetti bei Sieg | `claude/lumo-cards-animations` |
| [#88](https://github.com/Ullmann27/lumo-lernen/pull/88) | merged | fix(writing): Schreibflaeche bewegt sich nicht mehr, Touch funktioniert | `claude/writing-canvas-touch-fix` |
| [#89](https://github.com/Ullmann27/lumo-lernen/pull/89) | merged | feat(lumo-cards): cleverer Bot + strategische Hints + Warn-Badge | `claude/lumo-cards-smarter` |
| [#90](https://github.com/Ullmann27/lumo-lernen/pull/90) | merged | feat(lumo-cards): Discard-Slide + Draw-Pulse + HUD-Counter-Pulse | `claude/lumo-cards-more-anims` |
| [#91](https://github.com/Ullmann27/lumo-lernen/pull/91) | merged | feat(lumo-cards): N-Spieler-Foundation in den Models (additiv) | `claude/lumo-cards-4-players` |
| [#92](https://github.com/Ullmann27/lumo-lernen/pull/92) | merged | feat(lumo-cards): 3-4 Spieler-Regeln + Test-Suite (PR B, Foundation Schritt 2) | `claude/lumo-cards-multiplayer-rules` |
| [#93](https://github.com/Ullmann27/lumo-lernen/pull/93) | merged | feat(foundation): Tier 1 — Impeller + precacheImage + RepaintBoundary + cacheWidth | `claude/tier1-foundation` |
| [#94](https://github.com/Ullmann27/lumo-lernen/pull/94) | merged | feat(audio): Tier 3 — LumoSound Manager + audioplayers integration | `claude/tier3-audio` |
| [#95](https://github.com/Ullmann27/lumo-lernen/pull/95) | merged | feat(visuals): Tier 4 — statische Matrix4-Perspektive + LumoCardFlip + Spotlight | `claude/tier4-3d-optics` |
| [#96](https://github.com/Ullmann27/lumo-lernen/pull/96) | merged | feat(visuals): Tier 6 — Partikel-Burst bei +2 / +4 | `claude/tier6-card-polish` |
| [#97](https://github.com/Ullmann27/lumo-lernen/pull/97) | merged | docs: Asset-Briefing fuer externe Bild-KI (21 Prompts + Style Guide) | `claude/asset-ai-briefing` |
| [#98](https://github.com/Ullmann27/lumo-lernen/pull/98) | merged | docs: ChatGPT-Megaprompt — alle 23 Lumo-Assets in einem Schwung als ZIP | `claude/chatgpt-megaprompt` |
| [#99](https://github.com/Ullmann27/lumo-lernen/pull/99) | merged | feat(i18n): Foundation — app_de.arb + ChatGPT-Uebersetzungs-Megaprompt | `claude/i18n-foundation` |
| [#100](https://github.com/Ullmann27/lumo-lernen/pull/100) | merged | chore(assets): import Lumo visual, audio, lottie, icon and question packs | `assets/lumo-pack-import` |
| [#101](https://github.com/Ullmann27/lumo-lernen/pull/101) | merged | feat(assets): PR A — zentrale Asset-Pfad-Registry | `feat/asset-registry-pr-a` |
| [#102](https://github.com/Ullmann27/lumo-lernen/pull/102) | merged | feat(assets): PR F — LearningQuestionRepository + 200 JSON-Fragen | `feat/pr-f-learning-questions` |
| [#103](https://github.com/Ullmann27/lumo-lernen/pull/103) | merged | feat(assets): PR B — LumoCompanionPoseImage + Result-Dialog/Denkpause | `feat/pr-b-companion-pose` |
| [#104](https://github.com/Ullmann27/lumo-lernen/pull/104) | merged | feat(assets): PR C — LumoSound auf Asset-Registry + Click-SFX an Buttons | `feat/pr-c-lumo-sound-registry` |
| [#105](https://github.com/Ullmann27/lumo-lernen/pull/105) | merged | feat(assets): PR G — error-SFX bei Tap auf nicht-spielbare Karte | `feat/pr-g-error-sfx` |
| [#106](https://github.com/Ullmann27/lumo-lernen/pull/106) | merged | feat(assets): PR D — Lottie integration mit PNG-Fallback | `feat/pr-d-lottie` |
| [#107](https://github.com/Ullmann27/lumo-lernen/pull/107) | merged | feat(assets): PR E — LumoSvgIcon + flutter_svg + Settings-Icon | `feat/pr-e-svg-icons` |
| [#108](https://github.com/Ullmann27/lumo-lernen/pull/108) | merged | feat(assets): PR H1 — Star-Burst-Lottie bei richtiger Lernfrage | `feat/pr-h1-star-burst` |
| [#109](https://github.com/Ullmann27/lumo-lernen/pull/109) | merged | feat(assets): PR H2 — Lottie-Posen im Result-Dialog | `feat/pr-h2-result-lottie` |
| [#110](https://github.com/Ullmann27/lumo-lernen/pull/110) | merged | feat(assets): PR H3 — Background-Music in Lumo Cards | `feat/pr-h3-music` |
| [#111](https://github.com/Ullmann27/lumo-lernen/pull/111) | merged | feat(audio): PR I — Settings-UI fuer Music/SFX-Toggle | `feat/pr-i-audio-settings` |
| [#112](https://github.com/Ullmann27/lumo-lernen/pull/112) | merged | fix(ci): l10n.yaml aus Repo-Root verschieben (CI-Rescue Hypothese 1) | `fix/ci-rescue-l10n-yaml` |
| [#113](https://github.com/Ullmann27/lumo-lernen/pull/113) | merged | fix(ci): Nuclear - lottie + flutter_svg raus, alle anderen Features bleiben | `fix/ci-nuclear-remove-native-plugins` |
| [#114](https://github.com/Ullmann27/lumo-lernen/pull/114) | merged | feat(home): Lumo 3D Welt Tile - oeffnet Godot-App per Intent + Web-Fallback | `claude/continue-previous-chat-KtY7p` |
| [#115](https://github.com/Ullmann27/lumo-lernen/pull/115) | merged | feat(flutter): lumolernen deep-link intent-filter (Godot-Bridge Gegenstueck) | `claude/continue-previous-chat-KtY7p` |
| [#116](https://github.com/Ullmann27/lumo-lernen/pull/116) | merged | feat(curriculum): Englisch klassen-strukturiert + Science strict + Regression-Test | `claude/continue-previous-chat-KtY7p` |
| [#117](https://github.com/Ullmann27/lumo-lernen/pull/117) | merged | feat(bridge): Deep-Link-Section-Routing vom Godot-Hub (kein neues Plugin) | `claude/continue-previous-chat-KtY7p` |
| [#118](https://github.com/Ullmann27/lumo-lernen/pull/118) | merged | Test-Fixes + 21 vielfaeltige Sachaufgaben-Szenarien (statt 3) | `claude/continue-previous-chat-KtY7p` |
| [#119](https://github.com/Ullmann27/lumo-lernen/pull/119) | merged | feat(curriculum): Rechtschreibung-Pools erweitert | `claude/continue-previous-chat-KtY7p` |
| [#120](https://github.com/Ullmann27/lumo-lernen/pull/120) | merged | feat(visuals): Rechteck-mit-Massen + Lineal + Skala (AT-Lehrplan-konform) | `claude/continue-previous-chat-KtY7p` |
| [#121](https://github.com/Ullmann27/lumo-lernen/pull/121) | merged | feat(parents): Lumo Insight - visuelle Kompetenz-Heatmap (Game-Changer vs LernMax) | `claude/continue-previous-chat-KtY7p` |
| [#122](https://github.com/Ullmann27/lumo-lernen/pull/122) | merged | feat(quest): 4 Lehrplan-Quests - narrative Abenteuer statt Drill | `claude/continue-previous-chat-KtY7p` |
| [#123](https://github.com/Ullmann27/lumo-lernen/pull/123) | merged | feat(ui): LumoMagicBackground durch Home + Settings + Quest + Insight | `claude/continue-previous-chat-KtY7p` |
| [#124](https://github.com/Ullmann27/lumo-lernen/pull/124) | merged | fix(ui): Magic-Theme deutlich sichtbarer (Reality-Fix) | `claude/continue-previous-chat-KtY7p` |
| [#125](https://github.com/Ullmann27/lumo-lernen/pull/125) | merged | feat(ai): KI-Chat im Bottom-Nav + Master-Toggle im Eltern-Bereich | `claude/continue-previous-chat-KtY7p` |
| [#126](https://github.com/Ullmann27/lumo-lernen/pull/126) | merged | feat(connect): Lumo LIVE im Home + Verbindungs-Inventar | `claude/continue-previous-chat-KtY7p` |
| [#127](https://github.com/Ullmann27/lumo-lernen/pull/127) | merged | feat(connect+ai): Mission-Engine + KI-Wochenanalyse + LumoCompanionAgent | `claude/continue-previous-chat-KtY7p` |
| [#128](https://github.com/Ullmann27/lumo-lernen/pull/128) | merged | feat(achievements): 14 Badges + Wall + Live-Unlock-Toast | `claude/continue-previous-chat-KtY7p` |
| [#129](https://github.com/Ullmann27/lumo-lernen/pull/129) | merged | fix(writing): Canvas blockt Scroll-Parent (EagerGestureRecognizer) | `claude/continue-previous-chat-KtY7p` |
| [#130](https://github.com/Ullmann27/lumo-lernen/pull/130) | merged | fix(ui): SwitchListTile-Warning weg (Tablet-Bildschirm) | `claude/continue-previous-chat-KtY7p` |
| [#131](https://github.com/Ullmann27/lumo-lernen/pull/131) | merged | feat(visuals): Iter 16/A - Reaction-Companion + Star-Burst + Empty-Error | `claude/continue-previous-chat-KtY7p` |
| [#132](https://github.com/Ullmann27/lumo-lernen/pull/132) | merged | feat(visuals): Iter 17/A - StageHeader im Quest-Hub + TiltCard auf Quiz | `claude/continue-previous-chat-KtY7p` |
| [#133](https://github.com/Ullmann27/lumo-lernen/pull/133) | merged | feat(visuals): Iter 18+19/B - Visual-Mappings + StoryStage + Feedback-Animation | `claude/continue-previous-chat-KtY7p` |
| [#134](https://github.com/Ullmann27/lumo-lernen/pull/134) | merged | feat(visuals): Iter 19/B4 - FractionPizzaVisual Dual-Mode für Erweitern | `claude/continue-previous-chat-KtY7p` |
| [#135](https://github.com/Ullmann27/lumo-lernen/pull/135) | merged | feat(geometry): Iter 20 - Form-Nachzeichnen-Modul (Demo + Trace) | `claude/continue-previous-chat-KtY7p` |
| [#136](https://github.com/Ullmann27/lumo-lernen/pull/136) | merged | feat: Iter 21+22+23 - Rechentricks-Mentoren + Poster + ABC-Tafel (Mildenberger-Stil) | `claude/continue-previous-chat-KtY7p` |
| [#137](https://github.com/Ullmann27/lumo-lernen/pull/137) | merged | feat(visuals): Iter 24 - Mildenberger-Zwanzigerfeld (modern statt veraltet) | `claude/continue-previous-chat-KtY7p` |
| [#138](https://github.com/Ullmann27/lumo-lernen/pull/138) | merged | feat: Iter 25+26+27 - Hilfen-Variantenreich + Cloud-Solver + Hero-Banner + Streak-Kalender | `claude/continue-previous-chat-KtY7p` |
| [#139](https://github.com/Ullmann27/lumo-lernen/pull/139) | merged | feat: Iter 28 - Cloud-Offline-Titel positiv + Echte Lumo-PNG-Posen statt Emoji | `claude/continue-previous-chat-KtY7p` |
| [#140](https://github.com/Ullmann27/lumo-lernen/pull/140) | merged | feat: Iter 29 - Mehr echte Lumo-PNGs im Home + Akademie | `claude/continue-previous-chat-KtY7p` |
| [#141](https://github.com/Ullmann27/lumo-lernen/pull/141) | merged | feat(visuals): Iter 30 - Lumo's Tagestipp im Home-Dashboard (14 Tipps) | `claude/continue-previous-chat-KtY7p` |
| [#142](https://github.com/Ullmann27/lumo-lernen/pull/142) | merged | feat(visuals): Iter 31 - Premium-Avatar-PNGs für Rechentricks-Mentoren (Mildenberger-Look) | `claude/continue-previous-chat-KtY7p` |
| [#143](https://github.com/Ullmann27/lumo-lernen/pull/143) | merged | feat(update): Iter 32 - Auto-Install für Updates (Ein-Klick, Tablet-Wunsch) | `claude/continue-previous-chat-KtY7p` |
| [#144](https://github.com/Ullmann27/lumo-lernen/pull/144) | merged | feat(games): Iter 33 - Lumo Kart Lern-Rennen (Top-Down-Racing mit Quiz) | `claude/continue-previous-chat-KtY7p` |
| [#145](https://github.com/Ullmann27/lumo-lernen/pull/145) | merged | feat: Iter 34 + 35 - Reading Buddy + Foto-Lektion (Mic + OCR Workflows) | `claude/continue-previous-chat-KtY7p` |
| [#146](https://github.com/Ullmann27/lumo-lernen/pull/146) | merged | feat: Iter 36 + 37 - Lumo Welt (3 Subject-Inseln) + Lumo Journal (eigene Geschichten) | `claude/continue-previous-chat-KtY7p` |
| [#147](https://github.com/Ullmann27/lumo-lernen/pull/147) | merged | fix(ci): release-apk.yml YAML-Syntaxfehler reparieren (Build #242 → 258) | `claude/continue-previous-chat-KtY7p` |
| [#148](https://github.com/Ullmann27/lumo-lernen/pull/148) | merged | fix(visuals): KRITISCH - Leere Akademie + Frage-Cards durch Border-Bug | `claude/continue-previous-chat-KtY7p` |
| [#149](https://github.com/Ullmann27/lumo-lernen/pull/149) | merged | fix(tests): shapeTrace-Templates aus MC-Tests skippen — Heinz' Test-Failures | `claude/continue-previous-chat-KtY7p` |
| [#150](https://github.com/Ullmann27/lumo-lernen/pull/150) | open | feat(voice): kindlichere + waermere Lumo-Stimme | `claude/voice-improvement-fwjkX` |
| [#151](https://github.com/Ullmann27/lumo-lernen/pull/151) | merged | Lumo-Neustart: Lernfehler, Speicherung, aktuelle KI und echte 3D-Spiele | `codex/lumo-restart-school-test-2026-10-02` |
| [#152](https://github.com/Ullmann27/lumo-lernen/pull/152) | merged | Lumo: interaktiven Lernfuchs, Aufgaben und Eltern-PIN überarbeiten | `codex/lumo-school-readiness-followup-2026-10-02` |
| [#153](https://github.com/Ullmann27/lumo-lernen/pull/153) | open | Etappe 1: gespeicherte Lernfragen prüfen und Lumo-Ausgangsstand dokumentieren | `codex/lumo-stage1-audit-44095eb` |
| [#154](https://github.com/Ullmann27/lumo-lernen/pull/154) | open | feat(voice): Stimmenauswahl + wärmere Lumo-Stimme (auf Codex-Stand #152) | `claude/voice-on-codex-followup` |
| [#155](https://github.com/Ullmann27/lumo-lernen/pull/155) | merged | Diagnose tutor provider quota safely and keep APK publication manual | `codex/lumo-tutor-quota-diagnostics-2026-10-03` |
| [#156](https://github.com/Ullmann27/lumo-lernen/pull/156) | merged | Connect learning and native Kart with durable progress and PIN-free Android navigation | `codex/lumo-unified-android-2026-10-03` |
| [#158](https://github.com/Ullmann27/lumo-lernen/pull/158) | closed | fix(android-qa): leeres Semantics-Abbild nicht als fehlendes Bedienelement werten | `claude/qa-empty-semantics-retry` |
| [#159](https://github.com/Ullmann27/lumo-lernen/pull/159) | closed | fix(lernmodule): 8 bestätigte Fehler in Farben, Wetter, Wort-Diktat, Plus, Minus, Zahlen, Tiere | `claude/fix-learning-modules` |
| [#160](https://github.com/Ullmann27/lumo-lernen/pull/160) | closed | fix(spiele): Lumo Jump fällt nach Ducken nicht mehr durch; StarsPath 48/49 Antwort nicht immer oben | `claude/fix-games` |
| [#161](https://github.com/Ullmann27/lumo-lernen/pull/161) | closed | docs(design): Heinz' elf Zielbilder + verbindliche Design-Spezifikation | `claude/design-targets-heinz` |
| [#162](https://github.com/Ullmann27/lumo-lernen/pull/162) | merged | chore: Aufräumen – toter Code, ungenutzte Assets, alte Berichte entfernt | `claude/cleanup` |
| [#163](https://github.com/Ullmann27/lumo-lernen/pull/163) | merged | ci: Flutter für den Copilot-Agenten (copilot-setup-steps) | `claude/copilot-setup-steps` |
| [#164](https://github.com/Ullmann27/lumo-lernen/pull/164) | merged | assets(design): Hintergründe, Logos, Kartenbilder + Lernstruktur-/Geräte-/Denktest-Konzept | `claude/design-assets-part2` |
| [#165](https://github.com/Ullmann27/lumo-lernen/pull/165) | merged | assets(design): neun 3D-Symbole + zehn Lumo-Kart-Zielbilder | `claude/design-icons` |
| [#166](https://github.com/Ullmann27/lumo-lernen/pull/166) | merged | ci: Lumo bei jedem neuen PR-Stand prüfen, auch Drafts | `chatgpt/lumo-change-review-2026-10-04` |
| [#167](https://github.com/Ullmann27/lumo-lernen/pull/167) | open | fix(ci): fehlenden Nachweis-Upload nach #166 vervollständigen | `chatgpt/lumo-ci-evidence-followup-2026-10-04` |
| [#168](https://github.com/Ullmann27/lumo-lernen/pull/168) | open | docs: Heinz' Produktauftrag – Lernfortschritt schaltet Spiele frei, Kart ohne Lernfragen | `chatgpt/lumo-product-brief-2026-10-04` |
| [#169](https://github.com/Ullmann27/lumo-lernen/pull/169) | merged | assets: echten Bildpaket-Download und sichere Empfangsprüfung bereitstellen | `chatgpt/lumo-asset-delivery-2026-10-04` |
| [#171](https://github.com/Ullmann27/lumo-lernen/pull/171) | merged | chore(agents): model-specific Lumo Agent Squad | `chatgpt/lumo-agent-squad-2026-10-04` |
| [#178](https://github.com/Ullmann27/lumo-lernen/pull/178) | merged | [UI Luna] Start/Home mit echten Lumo-Assets gestalten | `copilot/lumo-design-sprint` |
| [#179](https://github.com/Ullmann27/lumo-lernen/pull/179) | open | test(home): tatsächliche Lesbarkeit der Hauptkacheln auf Phone/Fold prüfen | `chatgpt/lumo-home-readability-2026-10-04` |
| [#180](https://github.com/Ullmann27/lumo-lernen/pull/180) | merged | Review learning-state persistence and game unlock paths | `copilot/learning-sonnet-durable-spielefreischaltung` |
| [#181](https://github.com/Ullmann27/lumo-lernen/pull/181) | merged | Keep Home actions readable on narrow screens and at larger text sizes | `copilot/ui-luna-design-sprint-runtime-screens` |
| [#182](https://github.com/Ullmann27/lumo-lernen/pull/182) | merged | Add verified probe APK artifact handoff | `copilot/5979796457-update-integrationsaudit` |
| [#183](https://github.com/Ullmann27/lumo-lernen/pull/183) | open | assets(design): 142 Einzelbilder aus Heinz' zehn Bildtafeln (WebP) | `claude/design-tafeln` |
| [#184](https://github.com/Ullmann27/lumo-lernen/pull/184) | merged | fix(lesen,schreiben): Silbentrennung, echte Rechtschreibung, mehr Texte und Diktatwörter für Klasse 1–4 | `claude/lern-lesen-schreiben` |
| [#185](https://github.com/Ullmann27/lumo-lernen/pull/185) | merged | feat(mathe): Lehrplan Österreich – bis 20 in Klasse 1, bis 100 und Einmaleins in Klasse 2 | `claude/mathe-lehrplan` |
| [#186](https://github.com/Ullmann27/lumo-lernen/pull/186) | open | Design: Start, Lernen, Mathe, Deutsch, Tests, Spielewelt und Profil nach Heinz' Bildern 01–07 | `claude/design-lernen` |
| [#187](https://github.com/Ullmann27/lumo-lernen/pull/187) | merged | Aufgaben: Lumos Abenteuer-Aufgaben für Klasse 1–4 (unbegrenzt, spielerisch) | `claude/aufgaben-abenteuer` |
| [#188](https://github.com/Ullmann27/lumo-lernen/pull/188) | merged | docs(lumo): add 3D game boards and explicit Copilot Pro model lanes | `chatgpt/lumo-game-specs-2026-10-05` |
| [#190](https://github.com/Ullmann27/lumo-lernen/pull/190) | merged | docs(visual): add Fold runtime hard-gate evidence | `chatgpt/visual-gap-fold-2026-10-05` |
| [#191](https://github.com/Ullmann27/lumo-lernen/pull/191) | closed | fix(ui): recover Fold visual fidelity from Heinz device screenshots | `chatgpt/visual-fidelity-recovery-2026-10-05` |
| [#192](https://github.com/Ullmann27/lumo-lernen/pull/192) | open | fix(ui): align real Fold shell with reference 10 | `chatgpt/fold-reference-recovery-2026-10-05` |
| [#193](https://github.com/Ullmann27/lumo-lernen/pull/193) | open | docs(assets): 178+ Lumo AAA-style asset production prompts | `chatgpt/lumo-asset-production-100plus-2026-10-05` |
| [#194](https://github.com/Ullmann27/lumo-lernen/pull/194) | merged | Sichern des Checkpoints und Koordination der Entwicklung | `copilot/checkpoint-sichern-opus-5-5` |
| [#195](https://github.com/Ullmann27/lumo-lernen/pull/195) | open | Opus-Stand 86c5a33 fortsetzen: Test-APK mit reparierter Kart-Geometrie | `codex/opus-86c5a33-test-apk` |
| [#196](https://github.com/Ullmann27/lumo-lernen/pull/196) | merged | Onboarding neu: Lumo Hologlass First-Run statt alter Sequenz | `chatgpt/onboarding-hologlass-2026-10-05` |
| [#197](https://github.com/Ullmann27/lumo-lernen/pull/197) | open | Fold/Responsive: Lumo Lernen + eingebettetes Lumo Kart sauber anpassen | `chatgpt/fold-resize-fix-2026-10-05` |
| [#198](https://github.com/Ullmann27/lumo-lernen/pull/198) | merged | Test-APK: aktuelles Hologlass + Fold + Lumo Kart | `chatgpt/lumo-test-apk-2026-10-05` |
| [#199](https://github.com/Ullmann27/lumo-lernen/pull/199) | merged | Lumo Lern-App Referenzdesign: Aufgaben, Englisch, Curriculum und beweglicher Lumo | `chatgpt/lumo-app-reference-ui-2026-10-06` |
| [#201](https://github.com/Ullmann27/lumo-lernen/pull/201) | merged | Fix Flame Adventure full-round test steering | `chatgpt/flame-round-regression-2026-10-06` |
| [#202](https://github.com/Ullmann27/lumo-lernen/pull/202) | open | Test-APK: Hologlass/Onboarding + validated Kart Stage 2 | `chatgpt/lumo-integrated-apk-2026-10-06` |
| [#204](https://github.com/Ullmann27/lumo-lernen/pull/204) | open | Lern-App Stage 3: Hologlass-Aufgaben, Lehrplan-Coverage 1–4 und 50er Denkprofil | `chatgpt/lumo-learning-curriculum-cognitive-2026-10-06` |
| [#206](https://github.com/Ullmann27/lumo-lernen/pull/206) | open | Lumo Cards: sichere Pause, Lebenszyklus und Wiederaufnahme | `chatgpt/cards-resume-safety-2026-10-06` |
| [#207](https://github.com/Ullmann27/lumo-lernen/pull/207) | open | Lumo: sichere Spielstarts, Fortschritt, echte Fuchs-Icons und geprüfte Test-APK | `chatgpt/3d-launch-lifecycle-2026-10-07` |
| [#208](https://github.com/Ullmann27/lumo-lernen/pull/208) | open | Android: geprüfte APK 0.10.7+1400 und erfolgreiche Updates ab 280/1291/1321 | `chatgpt/install-upgrade-2026-10-07` |
| [#209](https://github.com/Ullmann27/lumo-lernen/pull/209) | open | Android: bestätigte 1321→1400-Aktualisierung mit Profilerhalt und reproduzierter Downgrade-Ablehnung | `chatgpt/android-install-upgrade-2026-10-07` |
| [#210](https://github.com/Ullmann27/lumo-lernen/pull/210) | open | feat: complete learning routes, four creative games and verified visual APK 1601 | `chatgpt/lumo-complete-games-2026-10-07` |
| [#211](https://github.com/Ullmann27/lumo-lernen/pull/211) | open | Android 1503: größere Lumo-Kart-Steuerung für Fold und Action-Icons | `chatgpt/fold-kart-controls-2026-10-07` |
| [#212](https://github.com/Ullmann27/lumo-lernen/pull/212) | open | Lumo Kart: moderner Spieleinstieg und APK-Kandidat 1504 | `chatgpt/kart-video-quality-2026-10-07` |
| [#213](https://github.com/Ullmann27/lumo-lernen/pull/213) | open | APK 1602: App-/Kart-Reparaturen, geprüfte Updates und vollständige Opus-Übergabe | `chatgpt/repair-opus-handoff-2026-10-07` |
| [#214](https://github.com/Ullmann27/lumo-lernen/pull/214) | merged | Lumo Android 1901: Referenzgrafik, vollständige App-Prüfung und Kamerafix | `codex/lumo-reference-app-2026-10-08` |
| [#215](https://github.com/Ullmann27/lumo-lernen/pull/215) | open | APK1901: preserve Kart continuity, driver contact and recognized photo-lesson subjects | `codex/lumo-runtime-apk-2026-10-08` |
| [#216](https://github.com/Ullmann27/lumo-lernen/pull/216) | open | Integrate Lumo graphics, strict race flow and Android APK1905 | `codex/lumo-integrated-runtime-2026-10-08` |
| [#217](https://github.com/Ullmann27/lumo-lernen/pull/217) | merged | Build immutable Lumo1902 cleanly and repair strict Android runtime verification | `codex/lumo-android-surface-qa-2026-10-08` |
| [#218](https://github.com/Ullmann27/lumo-lernen/pull/218) | open | Fix Android probe timing using actual full surfaces and fresh race IDs | `codex/lumo-android-qa-followup-2026-10-08` |
| [#219](https://github.com/Ullmann27/lumo-lernen/pull/219) | open | Android 1904: Pausenswipe reparieren und Lumo-Kart aktualisieren | `codex/lumo-visual-fidelity-2026-10-08` |
| [#220](https://github.com/Ullmann27/lumo-lernen/pull/220) | merged | Make missing ripgrep and source-scan errors fail the repair guard | `codex/lumo-source-guard-qa-2026-10-08` |
| [#221](https://github.com/Ullmann27/lumo-lernen/pull/221) | merged | Integrate tested Lumo runtime, finish physics and complete Android race evidence | `codex/lumo-app-recovery-2026-10-09` |
| [#222](https://github.com/Ullmann27/lumo-lernen/pull/222) | closed | APK 0.12.6+1909: Claude-Fortsetzung mit Aquarium und Prüfstand | `codex/lumo-action-apk-2026-10-09` |
| [#223](https://github.com/Ullmann27/lumo-lernen/pull/223) | merged | APK 1909 fertigstellen: Aquarium, Prüfstand und Android-Bildleser | `codex/lumo-action-android-qa-2026-10-09` |
| [#224](https://github.com/Ullmann27/lumo-lernen/pull/224) | open | Require settled Flutter frames for creative-game return evidence | `codex/lumo-return-frame-recovery-2026-10-09` |
| [#225](https://github.com/Ullmann27/lumo-lernen/pull/225) | open | APK 1910: 1909-Funktionen mit früher Rennspeicherung und Fold-Pausenhintergrund | `codex/lumo-apk-1910-2026-10-09` |
| [#226](https://github.com/Ullmann27/lumo-lernen/pull/226) | open | Lumo Spiele: passende Startbilder, Nunito-Header und ehrliche Ladeanzeige | `codex/lumo-game-entry-polish-2026-10-09` |
| [#227](https://github.com/Ullmann27/lumo-lernen/pull/227) | merged | Claudes Lern-App: eigene Spielebilder und geschützter Lumo-Kart-Ladevorgang | `codex/lumo-claude-game-entry-2026-10-09` |
| [#228](https://github.com/Ullmann27/lumo-lernen/pull/228) | open | Android-Rennende 1908: nachgewiesene Float-Rundung in Host-ACK-Prüfung beheben | `codex/lumo-host-finish-numeric-2026-10-09` |
| [#229](https://github.com/Ullmann27/lumo-lernen/pull/229) | open | Android Kart: echte Host-Ergebnisse trotz JSON-Zeit-Rundung korrekt erkennen | `codex/lumo-host-time-precision-2026-10-09` |
| [#230](https://github.com/Ullmann27/lumo-lernen/pull/230) | open | Lumo Lernen: schärferes Hologlas und einheitliches Lumo Cards Design | `chatgpt/lumo-learning-glass-cards-2026-10-09` |
| [#231](https://github.com/Ullmann27/lumo-lernen/pull/231) | open | Lumo Cards: vollständiger Titel auf schmalem Fold-Querformat-HUD | `chatgpt/lumo-cards-landscape-hud-2026-10-09` |
| [#232](https://github.com/Ullmann27/lumo-lernen/pull/232) | merged | fix(lernen): Denkprofil ohne Platzhalter, ehrliche Denktest-Texte & Audit | `chatgpt/denktest-qualitaet-2026-10-09` |
| [#234](https://github.com/Ullmann27/lumo-lernen/pull/234) | open | feat(lernen): grafische Aufgaben, echter Lernbaum und Fold-Layout ohne App-Umbau | `chatgpt/learning-visual-fold-tree-2026-10-09` |
| [#235](https://github.com/Ullmann27/lumo-lernen/pull/235) | open | feat(lernen): gerenderte 3D-Inseln, Lernbaum-Stufen und Fold-Screenshots | `chatgpt/learning-tree-cinematic-qa-2026-10-09` |
| [#236](https://github.com/Ullmann27/lumo-lernen/pull/236) | open | style(lernen): vier Antwortkacheln einheitlich als 2×2 auf Handy, Fold und Tablet | `chatgpt/learning-tablet-answer-grid-2026-10-09` |
| [#237](https://github.com/Ullmann27/lumo-lernen/pull/237) | open | fix(lernen): fehlende Symbolglyphen in echten Handy-/Fold-Lernansichten | `chatgpt/learning-symbols-ui-2026-10-09` |
| [#238](https://github.com/Ullmann27/lumo-lernen/pull/238) | open | build(android): Lumo Lernen 0.12.10+1917 mit 2×2-Layout und Symbolkorrektur | `chatgpt/lumo-1917-apk-artifact-2026-10-09` |
| [#239](https://github.com/Ullmann27/lumo-lernen/pull/239) | open | fix(lernen): große Zahlenvergleiche auf Handy und Fold ohne rechten Überlauf | `chatgpt/learning-number-compare-responsive-2026-10-09` |
| [#240](https://github.com/Ullmann27/lumo-lernen/pull/240) | open | build(android): APK 1918 mit großer Zahlenkarte, Tablet-Raster und korrigierten Symbolen | `chatgpt/lumo-1918-apk-artifact-2026-10-09` |
| [#241](https://github.com/Ullmann27/lumo-lernen/pull/241) | open | 0.12.12+1919: Lumo-Figur, Kart-Start und geprüfte Antwortzuordnung | `chatgpt/lumo-character-apk-1919-2026-10-09` |
| [#242](https://github.com/Ullmann27/lumo-lernen/pull/242) | open | test(android): Gas-Menüsuche mit Originalbildern reparieren und APK 1919 erneut prüfen | `audit/lumo-1919-gas-recovery-2026-10-09` |
| [#243](https://github.com/Ullmann27/lumo-lernen/pull/243) | open | Build 1920: eigene Lernprofile, sichere Elternzuordnung und geprüfter Lumo-Fuchs | `codex/lumo-next-2026-10-10` |
| [#244](https://github.com/Ullmann27/lumo-lernen/pull/244) | open | Android-Nachweis 1920: echte Elternzuordnung und A/B-Lernstände nach Update | `codex/lumo-profile-android-1920-2026-10-10` |
| [#245](https://github.com/Ullmann27/lumo-lernen/pull/245) | open | Build 1921: überarbeitetes Lumo Kart Hauptmenü im bestehenden Lern-App-Paket | `codex/lumo-kart-premium-apk-1921-2026-10-10` |
| [#246](https://github.com/Ullmann27/lumo-lernen/pull/246) | open | Build 1921: Lumo-Kart-Hauptmenü nach Referenz und Fold-Layout | `codex/lumo-kart-menu-1921-2026-10-10` |
| [#247](https://github.com/Ullmann27/lumo-lernen/pull/247) | open | Designvorlagen: Lumo Cards, Lumo Build und 4 Gewinnt + Sonnet-5.5-Implementierungsauftrag | `design/lumo-cards-build-connect-four-2026-10-10` |
| [#248](https://github.com/Ullmann27/lumo-lernen/pull/248) | open | Lumo: Originalbildarchiv, Design-Bestandsschutz und Sonnet-Entwicklungsauftrag | `codex/lumo-reference-assets-2026-10-10` |
| [#249](https://github.com/Ullmann27/lumo-lernen/pull/249) | open | Lumo 1922: Code-Cleanup, warme Stimme und animiertes Vier Gewinnt | `computer/lumo-cards-connect-four-2026-10-10` |
| [#250](https://github.com/Ullmann27/lumo-lernen/pull/250) | open | Lumo AAA: geprüfte Integration, echte Bildnachweise und Android-Abnahme | `computer/lumo-aaa-integration-2026-10-10` |
| [#251](https://github.com/Ullmann27/lumo-lernen/pull/251) | open | Build 1923: Perplexity Kart Stage2/Fold Fixes in Lumo Lernen APK nach Kontosperre übernehmen | `chatgpt/lumo-aaa-kart-integration-2026-10-10` |
| [#252](https://github.com/Ullmann27/lumo-lernen/pull/252) | open | Build 1924: Nameingabe und ursprüngliche Lumo-Stimme wiederherstellen | `chatgpt/lumo-onboarding-voice-1924-2026-10-10` |
| [#253](https://github.com/Ullmann27/lumo-lernen/pull/253) | open | Schreibcoach: stabile Zeichenfläche, sichtbarer Zielbuchstabe und korrekte Belohnungen | `chatgpt/lumo-writing-stability-2026-10-10` |
| [#255](https://github.com/Ullmann27/lumo-lernen/pull/255) | open | P0: Sulafat als einzige Lumo-Stimme (Stimmprobe = Lern-App) – keine alte Android-TTS | `chatgpt/lumo-sulafat-everywhere-2026-10-10` |
| [#256](https://github.com/Ullmann27/lumo-lernen/pull/256) | open | Grafik-Grundgerüst: Cards quer, Touchflächen, Ruhemodus und Astra-Übergabe | `computer/lumo-visual-foundation-2026-10-10` |
| [#257](https://github.com/Ullmann27/lumo-lernen/pull/257) | open | Lumo-Spiele: gemeinsamer referenzbasierter Gegnerkatalog mit Verfügbarkeitsgrenzen | `computer/lumo-rival-roster-2026-10-10` |
| [#258](https://github.com/Ullmann27/lumo-lernen/pull/258) | open | Lumo Kart: verifizierte 4K-Assetinventur und SOL-6.1-Entwicklungsübergabe | `chatgpt/lumo-kart-assets-handoff-2026-10-10` |
| [#259](https://github.com/Ullmann27/lumo-lernen/pull/259) | open | Build 1928: geprüfter animierter Kart-Einstieg, Fold-Menü und sichere APK-Varianten | `computer/lumo-kart-android-1928-2026-10-11` |
| [#260](https://github.com/Ullmann27/lumo-lernen/pull/260) | open | Lumo Lernen: Verkaufsvorbereitung, Kinder-Sicherheit, Play-Launch und Premium-Plan | `chatgpt/lumo-marktstart-vorbereitung-2026-10-11` |
| [#261](https://github.com/Ullmann27/lumo-lernen/pull/261) | open | Lernmodule: einheitliches Lumo-Design, korrekte Mengen und echte Fold-Bilder | `computer/lumo-learning-adventures-2026-10-11` |
| [#262](https://github.com/Ullmann27/lumo-lernen/pull/262) | open | Lumo Lernen: kostenlose lokale Stimme, geschützter Bestand und Android 1929 | `computer/lumo-education-excellence-2026-10-11` |
| [#263](https://github.com/Ullmann27/lumo-lernen/pull/263) | open | Lernen: Querformat, lesbare Lernflächen und richtige Uhr-Antwortstufen | `astra/lumo-learning-quality-2026-10-11` |
| [#264](https://github.com/Ullmann27/lumo-lernen/pull/264) | open | Android 1929: tatsächlichen Eltern-Prüfpfad reparieren, dieselbe APK nachprüfen | `computer/lumo-android-1929-runtime-repair-2026-10-11` |
| [#265](https://github.com/Ullmann27/lumo-lernen/pull/265) | open | Lumo Lernen: echte Lernbegleitung, geführter Unterricht und getrenntes Vorlernen | `computer/lumo-learning-companion-discovery-2026-10-11` |
| [#266](https://github.com/Ullmann27/lumo-lernen/pull/266) | open | Test-APK 1930: Lernbegleitung, Vorlernen und geprüfte Kart-Integration bündeln | `computer/lumo-android-1930-verified-bundle-2026-10-11` |
| [#267](https://github.com/Ullmann27/lumo-lernen/pull/267) | open | Lumo 1931: wechselnde lokale Hilfe und geführtes Minus über den Zehner | `sol/lumo-adaptive-local-help-2026-10-11` |
| [#268](https://github.com/Ullmann27/lumo-lernen/pull/268) | open | Lumo 1932: profilgebundene Begleitung und angenommene Aufgabenhilfe | `sol/lumo-active-companion-2026-10-11` |
| [#269](https://github.com/Ullmann27/lumo-lernen/pull/269) | open | Lumo 1933: geführte Silben und Blütenpflanzenteile | `sol/lumo-guided-language-nature-2026-10-12` |
| [#270](https://github.com/Ullmann27/lumo-lernen/pull/270) | open | fix(parents): keep profile names out of weekly AI requests and clear the toolbar | `sol/lumo-parent-report-privacy-2026-10-12` |
| [#271](https://github.com/Ullmann27/lumo-lernen/pull/271) | open | Android 1934: Fold-Kart reparieren und kleine Spiele mit Original-/Blendergrafik verfeinern | `sol/lumo-games-fold-1934-2026-10-12` |
| [#272](https://github.com/Ullmann27/lumo-lernen/pull/272) | open | Lumo 1935: Fold-Großtext Rückkehr aus Spielen zuverlässig sichtbar | `sol/lumo-1935-fold-return-2026-10-12` |
| [#273](https://github.com/Ullmann27/lumo-lernen/pull/273) | open | 1936 salvage: 142 design assets | `claude/design-tafeln` |
| [#274](https://github.com/Ullmann27/lumo-lernen/pull/274) | open | 1936 salvage: writing stability | `chatgpt/lumo-writing-stability-2026-10-10` |
| [#275](https://github.com/Ullmann27/lumo-lernen/pull/275) | open | 1936 salvage: learning visual Fold tree | `chatgpt/learning-visual-fold-tree-2026-10-09` |
| [#276](https://github.com/Ullmann27/lumo-lernen/pull/276) | open | 1936 salvage: hologlass learning and cards | `chatgpt/lumo-learning-glass-cards-2026-10-09` |
| [#277](https://github.com/Ullmann27/lumo-lernen/pull/277) | open | 1936 salvage: reading and writing expansion | `chatgpt/lumo-marktstart-vorbereitung-2026-10-11` |
| [#278](https://github.com/Ullmann27/lumo-lernen/pull/278) | open | Lumo 1936: unverbundene Grafikarbeit integrieren und Premium-UI sichtbar machen | `sol/lumo-1936-unified-integration-2026-10-12` |
| [#279](https://github.com/Ullmann27/lumo-lernen/pull/279) | open | feat: Lernvielfalt und wiederhergestellte Kart-Funktionen für 1937 | `sol/lumo-1937-content-kart-2026-10-12` |
| [#280](https://github.com/Ullmann27/lumo-lernen/pull/280) | open | Lumo 1938: geschützte Vollintegration, Lernvertiefung und synchronisierte APK-Nachweise | `chatgpt/lumo-1938-complete-integration-2026-10-12` |
| [#281](https://github.com/Ullmann27/lumo-lernen/pull/281) | open | Lernen nach Schulstufe strukturieren und Chat-Fallback entfernen | `fix/grade-learning-structure-2026-10-12` |
| [#282](https://github.com/Ullmann27/lumo-lernen/pull/282) | open | Lumo Meister + Geschichten-Lernpfad: 20 Fragen, Sterne und Lesen & Verstehen | `sol/lumo-meister-20-stars-2026-10-12` |
| [#284](https://github.com/Ullmann27/lumo-lernen/pull/284) | open | fix(story): Profilklasse für Geschichten übernehmen, freie Wahl erhalten | `perplexity/lumo-1938-integration-2026-10-13-0942` |
| [#285](https://github.com/Ullmann27/lumo-lernen/pull/285) | open | Story-Erstellung übernimmt die Lernpfadklasse | `copilot/lumo-1938-integration-follow-up` |
| [#287](https://github.com/Ullmann27/lumo-lernen/pull/287) | open | CI-Prüfung für PR #285 (identischer Commit, kein Produktcode geändert) | `chatgpt/verify-pr285-flutter-2026-10-13` |
| [#288](https://github.com/Ullmann27/lumo-lernen/pull/288) | open | Geschichten: sicher speichern, weiterlesen und zur Bibliothek zurückkehren | `chatgpt/lumo-story-save-audit-2026-10-13` |
| [#289](https://github.com/Ullmann27/lumo-lernen/pull/289) | open | Lumo-Bestandsaudit: Branches, Funktionen, Assets und Android-Abnahmeplan | `chatgpt/lumo-inventory-2026-10-13` |
| [#290](https://github.com/Ullmann27/lumo-lernen/pull/290) | open | Lern-DNA und Insight: echte Antwortdaten statt erfundener Kompetenzwerte | `chatgpt/lumo-dna-evidence-2026-10-13` |
| [#291](https://github.com/Ullmann27/lumo-lernen/pull/291) | open | Geschichten direkt von Home, Deutsch, Lesen und Lernpfad öffnen | `chatgpt/lumo-story-entry-2026-10-13` |
| [#292](https://github.com/Ullmann27/lumo-lernen/pull/292) | open | PR #291 CI: Kart-Touchziel und Mikrofon-Testvorbedingung korrekt prüfen | `chatgpt/lumo-pr291-ci-regressions-2026-10-13` |
| [#293](https://github.com/Ullmann27/lumo-lernen/pull/293) | open | Mobile Fold-Hochformat: vollständiges scrollbareres Mehr-Menü und Premium-Navigation | `chatgpt/lumo-mobile-navigation-visual-2026-10-13` |
| [#294](https://github.com/Ullmann27/lumo-lernen/pull/294) | open | Lumo Grafikfolge: lokalen Lernhelfer in Original-Fuchs- und Hologlas-Design überführen | `chatgpt/lumo-agent-hologlass-1940-2026-10-14` |
| [#295](https://github.com/Ullmann27/lumo-lernen/pull/295) | open | 1939-Grafiklücke beheben: Geschichtenleser sofort lesbar, neue Story und Bibliothekszugang | `chatgpt/lumo-story-reader-visual-fix-2026-10-14` |
| [#296](https://github.com/Ullmann27/lumo-lernen/pull/296) | open | PR #295 reparieren: Story-Klassenwahl über Semantik statt Altfarben testen | `chatgpt/lumo-pr295-grade-semantic-tests-2026-10-14` |
| [#297](https://github.com/Ullmann27/lumo-lernen/pull/297) | open | 1941: Lumo-Lernhilfe im Hologlas-Design und deutsche Offline-Stimme hörbar machen | `chatgpt/lumo-1941-tutor-voice-hologlass-2026-10-14` |
| [#298](https://github.com/Ullmann27/lumo-lernen/pull/298) | open | 1942 Familien-Updatekanal: kompatible APKs sicher finden und Downloadfortschritt anzeigen | `chatgpt/lumo-1942-family-preview-updates-2026-10-14` |
| [#299](https://github.com/Ullmann27/lumo-lernen/pull/299) | open | 1943 Klassen 1–4: Englisch überall, Sachunterricht korrekt, echte Aufgaben und Menüs prüfen | `chatgpt/lumo-1943-grade-menu-content-audit-2026-10-14` |
| [#300](https://github.com/Ullmann27/lumo-lernen/pull/300) | open | 1944 Fold-Cover: responsive Lernkarten, klassenrichtige Missionen und vollständige Android-QA | `chatgpt/lumo-1944-mobile-learning-qa-2026-10-14` |
| [#301](https://github.com/Ullmann27/lumo-lernen/pull/301) | open | 1945 Lumo Lernen: Große Code-, Lehrplan- und Anti-Wiederholungs-Reparatur | `chatgpt/lumo-1945-question-quality-repair-2026-10-14` |
| [#302](https://github.com/Ullmann27/lumo-lernen/pull/302) | merged | fix(ci): StartHero-Verifikation auf 225 echte Prüfungen synchronisieren | `chatgpt/ci-start-hero-regression-2026-10-15` |
| [#303](https://github.com/Ullmann27/lumo-lernen/pull/303) | merged | fix(ci): Godot-Quellhash und StartHero-Freigabeprüfung aktualisieren | `chatgpt/ci-final-apk-evidence-count-2026-10-15` |
| [#304](https://github.com/Ullmann27/lumo-lernen/pull/304) | merged | ci: pinned Godot-Quellhashes vor langer Native-Pipeline prüfen | `chatgpt/native-source-preflight-2026-10-15` |
| [#305](https://github.com/Ullmann27/lumo-lernen/pull/305) | open | fix(quiz): Lumo bleibt sichtbar und überlappt keine Host- oder Jokerfläche | `chatgpt/lumo-meister-host-safe-area-2026-10-15` |
| [#306](https://github.com/Ullmann27/lumo-lernen/pull/306) | closed | feat(stories): Gemini-Ideen verlustfrei in bestehenden Geschichten-Reader integrieren | `chatgpt/gemini-story-compatibility-2026-10-15` |
| [#307](https://github.com/Ullmann27/lumo-lernen/pull/307) | merged | fix(lernen): Gemini-Verbesserungen ohne bestehende Funktionen zu ersetzen | `chatgpt/gemini-safe-fixes-learning-2026-10-15` |
| [#308](https://github.com/Ullmann27/lumo-lernen/pull/308) | merged | feat(design): premium Lumo Meister quiz stage matching approved visual direction | `chatgpt/lumo-premium-quiz-stage-2026-10-15` |
| [#309](https://github.com/Ullmann27/lumo-lernen/pull/309) | merged | feat(design): nine real 3D learning islands with functional subject routes | `chatgpt/lumo-3d-learning-islands-2026-10-15` |
| [#310](https://github.com/Ullmann27/lumo-lernen/pull/310) | open | feat(ai): NVIDIA Nemotron 3 Ultra – optional consent-gated tutoring pilot | `perplexity/lumo-nvidia-tutor-pilot-2026-10-15` |
| [#311](https://github.com/Ullmann27/lumo-lernen/pull/311) | merged | fix(android-qa): use real current Kart menu caption and Lernen accessibility tab | `chatgpt/kart-qa-real-caption-2026-10-15` |
| [#312](https://github.com/Ullmann27/lumo-lernen/pull/312) | merged | feat(integration): complete Lumo Lernen premium UI + 3D Kart/Bauwelt unified APK candidate | `chatgpt/lumo-lernen-kart-unified-2026-10-15` |
| [#313](https://github.com/Ullmann27/lumo-lernen/pull/313) | open | Parent-controlled class promotion + illustrated grade 1–4 curriculum cards | `chatgpt/lumo-parent-grade-and-subject-icons-2026-10-15` |
| [#314](https://github.com/Ullmann27/lumo-lernen/pull/314) | open | fix(lernen): free 1–4 grade navigation with real independent practice | `chatgpt/resume-claude-cross-grade-practice-2026-10-15` |
| [#315](https://github.com/Ullmann27/lumo-lernen/pull/315) | open | Lumo Lernen: original library scene and Hologlas for free-grade lessons | `chatgpt/lumo-cross-grade-scene-polish-2026-10-15` |
| [#316](https://github.com/Ullmann27/lumo-lernen/pull/316) | open | test(lernen): Speicherfehler beim freien Klassenüben reproduzieren und absichern | `perplexity/lumo-cross-grade-storage-hardening-2026-10-15` |
| [#317](https://github.com/Ullmann27/lumo-lernen/pull/317) | open | fix(lernen): cross-grade storage hydration, validated counters and idempotent save retry | `copilot/fix-pr-316-auto-check` |
| [#319](https://github.com/Ullmann27/lumo-lernen/pull/319) | open | Integrate new Sonnenhafen Godot graphics into unified Lumo Lernen APK | `chatgpt/lumo-sonnenhafen-godot-pin-2026-10-15` |
| [#320](https://github.com/Ullmann27/lumo-lernen/pull/320) | open | Lumo Lernen: sichtbarer Hologlas-Übungsfortschritt mit sicherem Speichern | `chatgpt/lumo-cross-grade-hologlas-progress-safe-2026-10-16` |
| [#321](https://github.com/Ullmann27/lumo-lernen/pull/321) | merged | Lumo 1949: Claude + Astra/Opus lineage, learning Hologlas and newest Kart in one APK | `chatgpt/lumo-1949-all-integrated-2026-10-16` |
| [#322](https://github.com/Ullmann27/lumo-lernen/pull/322) | merged | Lumo 1950: Fold-friendly child navigation, legible modules and original fox design | `chatgpt/lumo-fold-contrast-3d-identity-2026-10-16` |
| [#323](https://github.com/Ullmann27/lumo-lernen/pull/323) | merged | Lumo 1951: echte Buchstaben, sichtbare Schreibspuren und prüfbare Tastatureingabe | `chatgpt/lumo-schreiben-repair-1951-2026-10-16` |
| [#324](https://github.com/Ullmann27/lumo-lernen/pull/324) | open | Lumo 1952: Schreiben kinderfreundlich – ohne 4-%-Sperre, mit direktem Weiter und Ausstieg | `chatgpt/lumo-writing-no-score-child-flow-1952-2026-10-16` |
| [#325](https://github.com/Ullmann27/lumo-lernen/pull/325) | open | Lumo 1954: Opus 1953 übernehmen – Hologlas-Mentoren, Fold-Journal und reale Tests | `chatgpt/opus-1953-mentor-journal-followup-2026-10-16` |
| [#326](https://github.com/Ullmann27/lumo-lernen/pull/326) | open | Lumo 1954 – Astra Fold-Reparatur auf Opus-Basis; vorhandene Lumo-UI unverändert | `chatgpt/lumo-1954-preserve-ui-validation-2026-10-16` |
| [#327](https://github.com/Ullmann27/lumo-lernen/pull/327) | open | Lumo 1955: Originalgrafik bewahren – echte Klicksounds, Haptik und Lumo-Begrüßung anschließen | `chatgpt/lumo-feedback-voice-navigation-1955-2026-10-16` |
| [#328](https://github.com/Ullmann27/lumo-lernen/pull/328) | open | Lumo 1957: Sonnenhafen-3D und sichtbar nachgewiesenes Android-Rennen in der Lern-App | `chatgpt/lumo-1956-sonnenhafen-lookouts-2026-10-16` |
| [#330](https://github.com/Ullmann27/lumo-lernen/pull/330) | merged | Lumo 1958: fertige Story-Erweiterung integrieren, Grafikbestand schützen und Android-APK prüfen | `chatgpt/lumo-1958-visual-story-integration-2026-10-16` |
| [#331](https://github.com/Ullmann27/lumo-lernen/pull/331) | open | Lumo M0: Opus Maven-Reparatur und beweisbarer Flutter→Kart→Rennen Android-Test | `claude/lumo-android-integration-m0-aloove` |
| [#332](https://github.com/Ullmann27/lumo-lernen/pull/332) | open | Lumo 1959: Grafikinventar und robuster echter Kart-Rennstart im Android-Emulator | `chatgpt/lumo-1959-kart-garage-ocr-repair-2026-10-16` |
| [#333](https://github.com/Ullmann27/lumo-lernen/pull/333) | open | Lumo 1961: Hologlas-Lernbilder für Handy und Fold tatsächlich rendern und archivieren | `chatgpt/lumo-1961-cross-grade-fold-visual-proof-2026-10-16` |
| [#334](https://github.com/Ullmann27/lumo-lernen/pull/334) | open | test(profile): Datenerhalt bei Lesefehlern und abgelehnten Writes absichern | `perplexity/lumo-profile-storage-hardening-2026-10-16` |
| [#335](https://github.com/Ullmann27/lumo-lernen/pull/335) | open | Lumo 1962: Kinderprofile vor Datenverlust schützen und fehlgeschlagene Speicherung sichtbar machen | `chatgpt/lumo-1962-profile-non-destructive-persistence-2026-10-16` |
| [#336](https://github.com/Ullmann27/lumo-lernen/pull/336) | open | Lumo 1963: Profile, Hologlas-Fold-Grafik und echtes Kart-APK gemeinsam prüfen | `chatgpt/lumo-1963-integrated-profile-fold-android-2026-10-16` |
| [#337](https://github.com/Ullmann27/lumo-lernen/pull/337) | open | Lumo 1964: ABC-Tafel auf echte Hologlas-Lernwelt umstellen – Fold, Vorlesen und Original-Lumo | `chatgpt/lumo-1964-abc-premium-design-2026-10-16` |
| [#339](https://github.com/Ullmann27/lumo-lernen/pull/339) | open | Lumo 1965: Referenzgrafik als echte spielbare Lumo-Cards-Einstiegswelt integrieren | `chatgpt/lumo-1965-cards-reference-hub-2026-10-16` |
| [#340](https://github.com/Ullmann27/lumo-lernen/pull/340) | open | Lumo 1966: Argon-Befunde validieren – Cards-Routenregression und echte Kart-Fahrtelemetrie | `chatgpt/lumo-1966-cards-route-race-telemetry-2026-10-16` |
| [#341](https://github.com/Ullmann27/lumo-lernen/pull/341) | open | Lumo 1967: Sonnenhafen-3D-Portalkran in neueste Lern-App integrieren und Android neu prüfen | `chatgpt/lumo-1967-sonnenhafen-crane-integrated-2026-10-17` |
| [#342](https://github.com/Ullmann27/lumo-lernen/pull/342) | open | Lumo 1968: echten Audioplayers-EventChannel-Fehler im App-Tour-Screenshot-Test beheben | `chatgpt/lumo-1968-audio-event-channel-capture-2026-10-17` |
| [#343](https://github.com/Ullmann27/lumo-lernen/pull/343) | open | Lumo Stabilisierung: geprüfte 1968-Basis konsolidieren, native Hash-Gates reparieren und Release absichern | `chatgpt/lumo-stabilisierung-2026-10-17` |
| [#345](https://github.com/Ullmann27/lumo-lernen/pull/345) | merged | Lumo Stabilität: Python-Hashfehler ursächlich reparieren und alte Release-Pins versionssicher prüfen | `chatgpt/lumo-stabilisierung-nativehash-fix-2026-10-17` |
| [#346](https://github.com/Ullmann27/lumo-lernen/pull/346) | merged | Stabilisierung: 1954 Android-Tour vor fehlenden APK-Provenienzargumenten schützen | `chatgpt/lumo-stability-1954-provenance-cli-2026-10-17` |
| [#347](https://github.com/Ullmann27/lumo-lernen/pull/347) | merged | Stabilisierung: reales Android-NDK-Archivproblem sicher und begrenzt beheben | `chatgpt/lumo-stability-ndk-unknown-archive-2026-10-17` |
| [#348](https://github.com/Ullmann27/lumo-lernen/pull/348) | merged | Lumo Insight: Elternstatistik auf Smartphone und Fold responsiv gestalten | `chatgpt/lumo-insight-responsive-stats-2026-10-17` |
| [#349](https://github.com/Ullmann27/lumo-lernen/pull/349) | merged | Android-Visueller QA-Wächter: nie wieder leere Flutter-Bildbelege als grün melden | `chatgpt/lumo-flutter-render-readiness-2026-10-17` |
| [#350](https://github.com/Ullmann27/lumo-lernen/pull/350) | merged | Android 1954: tatsächliche Tesseract-OCR-Abhängigkeit installieren und prüfen | `chatgpt/lumo-1954-tesseract-deu-eng-gate-2026-10-17` |
| [#351](https://github.com/Ullmann27/lumo-lernen/pull/351) | merged | Lumo 1969: Neue integrierte APK mit geprüftem Sonnenhafen-3D-Hub | `chatgpt/lumo-1969-godot-hoist-candidate-2026-10-17` |
| [#352](https://github.com/Ullmann27/lumo-lernen/pull/352) | merged | Lumo Lernen: Bento-Icons beim ersten Frame sichtbar statt leerem Ladezustand | `chatgpt/lumo-first-frame-icons-2026-10-17` |
| [#353](https://github.com/Ullmann27/lumo-lernen/pull/353) | merged | Lumo 1970: 3D-Sonnenhafen-Kontakttiefe und lesbare erste Bento-Frames als neue Android-APK | `chatgpt/lumo-1970-godot-grounding-candidate-2026-10-17` |
| [#354](https://github.com/Ullmann27/lumo-lernen/pull/354) | open | fix(profile): unlesbare Profilfelder vor Überschreiben schützen | `perplexity/lumo-profile-schema-guard-2026-10-17` |
| [#355](https://github.com/Ullmann27/lumo-lernen/pull/355) | merged | Lumo 1970 Profilschutz: #354-Feldschema-Guard bytegleich übertragen und vollständig testen | `chatgpt/lumo-1970-profile-field-guard-integrate-2026-10-17` |
| [#356](https://github.com/Ullmann27/lumo-lernen/pull/356) | open | Lumo 1971 ARM64-APK: Profilschutz #354 + geprüfter 1970-Grafikstand gemeinsam versionieren | `chatgpt/lumo-1971-profile-guard-release-candidate-2026-10-17` |
| [#357](https://github.com/Ullmann27/lumo-lernen/pull/357) | open | Lumo 1972: Meilenstein A geprüfte Godot-3D-Physik in Android-Kandidat integrieren | `chatgpt/lumo-milestone-a-1972-integrated-2026-10-17` |
| [#358](https://github.com/Ullmann27/lumo-lernen/pull/358) | open | Lumo 1973: B3 1,85-km-Sonnenhafen mit fünf 3D-Welten in Android integrieren | `chatgpt/lumo-b3-1973-android-candidate-2026-10-17` |
| [#359](https://github.com/Ullmann27/lumo-lernen/pull/359) | open | Lumo 1974: Sonnenhafen-Fahrbahn von Bergen/Felsen freihalten, Küste und Terrain beschleunigen | `chatgpt/lumo-b4-1974-performance-candidate-2026-10-17` |
| [#360](https://github.com/Ullmann27/lumo-lernen/pull/360) | open | Lumo 1975: Android-APK mit bodenbündigem 3D-Starttor und schärferen PBR-Materialien | `chatgpt/lumo-1975-grounded-gate-apk-2026-10-17` |
| [#361](https://github.com/Ullmann27/lumo-lernen/pull/361) | open | Lumo Lernen: Astras abgebrochene App-Skripttests in GitHub reproduzieren | `chatgpt/lumo-astra-app-script-recovery-2026-10-18` |
| [#362](https://github.com/Ullmann27/lumo-lernen/pull/362) | open | Lumo 1976: geprüfte Sonnenhafen-Dunkelfahrt, Kristall-VFX und ruhige Bewegung in Android | `chatgpt/lumo-1976-darkride-crystal-android-2026-10-18` |
| [#363](https://github.com/Ullmann27/lumo-lernen/pull/363) | open | Lumo 1977: Premium-Lernansichten, sieben Spiele, Sprachsteuerung und echte Kristallhöhle | `codex/lumo-1977-premium-learning-2026-10-18` |
| [#364](https://github.com/Ullmann27/lumo-lernen/pull/364) | open | Lumo Spiele: 4 Gewinnt mit sieben erreichbaren Spaltentasten auf schmalem Fold-Display | `chatgpt/lumo-1978-connect-four-fold-controls-2026-10-18` |
| [#365](https://github.com/Ullmann27/lumo-lernen/pull/365) | open | Lumo 1977: original-geprüfte ARM64-APK separat für direkten Download bereitstellen | `chatgpt/lumo-1977-verified-arm64-download-2026-10-18` |
| [#366](https://github.com/Ullmann27/lumo-lernen/pull/366) | open | Lumo 1977: ABC/Fächer-Grafikscreenshots ohne Ahem-Platzhalter, echte Nunito-Schrift und Pixel-QA | `chatgpt/lumo-1977-real-font-screenshot-qa-2026-10-18` |
| [#367](https://github.com/Ullmann27/lumo-lernen/pull/367) | open | Lumo 1978: lesbare Lern-App, faltbares 4 Gewinnt, überprüfte Screenshots und direkte ARM64-APK | `chatgpt/lumo-1978-visual-accessible-release-2026-10-18` |
| [#368](https://github.com/Ullmann27/lumo-lernen/pull/368) | open | Lumo 1978: echte Renn-HUD-Pixel statt falscher OCR-Blockade, Fahrtest bleibt zwingend | `chatgpt/lumo-1978-real-hud-ocr-recovery-2026-10-18` |
| [#369](https://github.com/Ullmann27/lumo-lernen/pull/369) | open | Lumo Lernen: geprüfte Lernatelier-Grundlagen und GPT-6-Übergabe | `codex/lumo-learning-lab-2026-10-18` |
| [#370](https://github.com/Ullmann27/lumo-lernen/pull/370) | open | Lumo Meister: 20-stufige Sternenleiter und Quizshow-Spannung | `chatgpt/lumo-meister-live-stage-2026-10-18` |
| [#371](https://github.com/Ullmann27/lumo-lernen/pull/371) | open | Lumo 1982: 20-Stufen-Quizshow, Moderatorbühne, Musik, Antwort-Spannung und neuer Spieleinstieg | `chatgpt/lumo-1982-meister-show-2026-10-18` |
| [#372](https://github.com/Ullmann27/lumo-lernen/pull/372) | open | LUMO: transparente 3D-Szenen in Story-, Jahreszeiten- und Mathe-Oberflächen anschließen | `chatgpt/lumo-story-scene-art-transparent-2026-10-18` |
| [#373](https://github.com/Ullmann27/lumo-lernen/pull/373) | open | Lumo 1983 – visuelle Quizshow wie freigegebene Studio-Vorlage (Lichter, Bühne, Moderator und Neon-Antworten) | `chatgpt/lumo-1983-quiz-studio-reference-2026-10-18` |
| [#374](https://github.com/Ullmann27/lumo-lernen/pull/374) | open | Lumo Lernatelier: hörbare Erklärungen wiederholen und pausieren (Build-1983-Basis) | `chatgpt/lumo-1984-atelier-voice-replay-2026-10-18` |
| [#375](https://github.com/Ullmann27/lumo-lernen/pull/375) | open | Lumo: vier transparente Szene-Anschlüsse in aktuelle Lern-App integrieren – mit sicherem Fallback | `chatgpt/lumo-scene-art-staged-1984-2026-10-18` |
| [#376](https://github.com/Ullmann27/lumo-lernen/pull/376) | open | Lumo 1984: lernorientierte Szenenanimationen, Sprachbedienung und geprüfter ARM64-Kandidat | `chatgpt/lumo-1984-animated-scenes-android-2026-10-18` |
| [#377](https://github.com/Ullmann27/lumo-lernen/pull/377) | open | Lumo 1985: räumliches Lesen, bedienbare Karten und Kart-Start | `codex/lumo-1985-spatial-reading-2026-10-19` |
| [#378](https://github.com/Ullmann27/lumo-lernen/pull/378) | open | Lesen: Android-Ruhemodus und nicht verratende Buchseiten-Hinweise | `chatgpt/lumo-reading-android-reduced-motion-2026-10-19` |
| [#379](https://github.com/Ullmann27/lumo-lernen/pull/379) | open | Lumo 1986: alle neuen Lern-App-Reparaturen und Lumo-Figuren in einer geprüften Android-APK | `chatgpt/lumo-1986-integrated-reading-release-2026-10-19` |
| [#380](https://github.com/Ullmann27/lumo-lernen/pull/380) | open | Lumo 1987: Denkprofil und Knobeltest visuell vereinen + 36-Rätsel-Entdeckerrunde | `chatgpt/lumo-1987-denkprofil-knobel-unified-2026-10-19` |
| [#381](https://github.com/Ullmann27/lumo-lernen/pull/381) | open | Lumo Cards: fairer, variabler Klassen-Bot · Bauwelt als Vorschau · Play-Gate | `chatgpt/lumo-fair-cards-buildworld-release-gates-2026-10-19` |
| [#382](https://github.com/Ullmann27/lumo-lernen/pull/382) | open | Google Play: separater API-36-App-Bundle-Kanal mit privater Signierung und Sicherheitsprüfungen | `chatgpt/lumo-play-aab-secure-staging-2026-10-19` |
| [#383](https://github.com/Ullmann27/lumo-lernen/pull/383) | open | Lumo 1989: echter Premium-Grafiksprung für neun Lernkarten, Handy und Fold | `chatgpt/lumo-1989-premium-learning-cards-2026-10-19` |
| [#384](https://github.com/Ullmann27/lumo-lernen/pull/384) | open | Lumo 1990: konsistente Premium-UX in Start, Lernen, Spielen, Story und Elternbereich | `chatgpt/lumo-1990-ui-unified-polish-2026-10-19` |
| [#385](https://github.com/Ullmann27/lumo-lernen/pull/385) | open | Lumo 1990: echten Android-Testblocker reparieren und Spiele-Starttasten sichtbar halten | `chatgpt/lumo-1990-integration-hardening-2026-10-19` |
| [#387](https://github.com/Ullmann27/lumo-lernen/pull/387) | open | Lumo 1991: neuester geprüfter Godot-Kart-Stand mit allen Flutter-1990-Neuerungen als gemeinsame Android-APK | `chatgpt/lumo-1991-complete-android-2026-10-20` |
| [#388](https://github.com/Ullmann27/lumo-lernen/pull/388) | open | QA 1991: echtes Sonnenhafen-Zweirundenrennen, Ergebnis, Offline-Belohnung und Replay-Deduplizierung | `chatgpt/lumo-1991-full-race-qa-2026-10-20` |
| [#389](https://github.com/Ullmann27/lumo-lernen/pull/389) | open | Lumo 1992: klare Lernnavigation, Premium-Überarbeitung von Home, LIVE, Mirror, Cosmos und Quest | `chatgpt/lumo-1992-premium-navigation-magic-2026-10-20` |
| [#390](https://github.com/Ullmann27/lumo-lernen/pull/390) | open | Lumo 1992: geführter zweiter Lernversuch | `chatgpt/lumo-1992-second-chance-learning-20261020` |
| [#391](https://github.com/Ullmann27/lumo-lernen/pull/391) | open | Lumo Next Gen: visueller Codex-Masterauftrag und Designreferenzen | `design/lumo-nextgen-visual-brief-20261020` |
| [#392](https://github.com/Ullmann27/lumo-lernen/pull/392) | open | Lumo Lernen Next Gen: echte dunkelblaue Premium-Lernkacheln | `design/lumo-learning-premium-tiles-20261020` |
| [#393](https://github.com/Ullmann27/lumo-lernen/pull/393) | open | Lumo Next Gen: kompakte Glaskacheln reparieren und APK-Regression freigeben | `repair/lumo-nextgen-apk-qa-20261020` |
| [#394](https://github.com/Ullmann27/lumo-lernen/pull/394) | open | Lumo: Astra/Codex-Cloud-Arbeit automatisch sichern – AGENTS + GitHub-Checkpoints | `ops/lumo-codex-checkpoint-protection-20261020` |
| [#395](https://github.com/Ullmann27/lumo-lernen/pull/395) | open | Rettung: ursprünglichen Lumo-Cloud-Stand und 120s-Sicherung erhalten | `checkpoint/lumo-cloud-rescue-20261021-014435` |
| [#396](https://github.com/Ullmann27/lumo-lernen/pull/396) | open | Astra-Rettung: 280dp-Home-Fold korrigieren, Original-Kartgrafik zuverlässig prüfen | `repair/lumo-astra-rescue-home-qa-20261021` |
| [#397](https://github.com/Ullmann27/lumo-lernen/pull/397) | open | Lumo Rechentricks: echte kindgerechte Trick-Werkstatt statt Textwüste | `design/lumo-rechentricks-kindgerechte-trickwerkstatt-20261021` |
| [#398](https://github.com/Ullmann27/lumo-lernen/pull/398) | open | Lumo Next Gen: Astras Mathe-Stand sichern und echten Fuchs-/Kristall-Render prüfen | `repair/lumo-nextgen-math-recovery-20261021` |
| [#399](https://github.com/Ullmann27/lumo-lernen/pull/399) | open | Lumo Next Gen Gesamt-APK: Premium-Glaskarten, Kristallgrafik und Fold-CI-Fix | `design/lumo-full-visual-integration-apk-20261021` |
| [#400](https://github.com/Ullmann27/lumo-lernen/pull/400) | open | Lumo Build 1995: SOL-Kristalle + vollständig geprüfte responsive Kart-Menüs als Android-APK | `chatgpt/lumo-sol-integrated-1995-20261021` |
| [#401](https://github.com/Ullmann27/lumo-lernen/pull/401) | open | Lumo: SOL-Kristalle mit sichtbarer 3D-Tiefe in tatsächliche Mathe-App übernehmen | `chatgpt/lumo-crystal-depth-integration-20261021` |
| [#402](https://github.com/Ullmann27/lumo-lernen/pull/402) | open | Lumo: Linux/Render-first Flutter and Godot Android candidate build | `review/render-first-portable-build-20261022` |
| [#403](https://github.com/Ullmann27/lumo-lernen/pull/403) | open | Lumo QA: historischen Spielebildvergleich auf Builds 1989/1990 begrenzen | `repair/lumo-historical-visual-qa-20261022` |
| [#404](https://github.com/Ullmann27/lumo-lernen/pull/404) | open | Lumo Spielwelt: Lumo Kart + Wer wird Lumo-Meister als gleichwertige Glas-Spielkacheln | `design/lumo-spielwelt-kart-quiz-20261022` |
| [#405](https://github.com/Ullmann27/lumo-lernen/pull/405) | open | Lumo Next Gen: gerettete Sol/Codex-Navigation und profilgetrennte Tagesmissionen prüfen | `codex/lumo-nextgen-navigation-20261023` |
| [#406](https://github.com/Ullmann27/lumo-lernen/pull/406) | open | Lumo NextGen: vier echte Adventure-Tests wieder mit sichtbarer Spielkachel ausführen | `repair/lumo-405-real-adventure-visibility-20261023` |
| [#407](https://github.com/Ullmann27/lumo-lernen/pull/407) | open | Lumo NextGen 1999: Sol-Integration, sichere Quiz-Navigation und Android-Release-Gates | `release/lumo-nextgen-1999-integrated-20261024` |
| [#408](https://github.com/Ullmann27/lumo-lernen/pull/408) | open | Lumo 1999: echten Kart-Portaltext in Android-Emulatortour prüfen | `repair/lumo-1999-native-kart-tour-20261024` |
| [#409](https://github.com/Ullmann27/lumo-lernen/pull/409) | open | fix(lumo1999): 1997 Lernhub im echten Update-Emulatortest bedienen | `repair/lumo-1999-update-learning-hub-20261026` |
| [#410](https://github.com/Ullmann27/lumo-lernen/pull/410) | open | Nachhilfelehrer: drei echte Offline-Erklärwege für Zehner und Einer | `feat/lumo-personal-tutor-place-value-20261028` |
| [#411](https://github.com/Ullmann27/lumo-lernen/pull/411) | open | Lumo 2000 Haupt-App: echter Sonnenhafen-Flug, Wasser/Lava-Höhle und 3-Stufen-Nachhilfe | `integration/lumo-2000-sonnenhafen-tutor-20261028` |
| [#412](https://github.com/Ullmann27/lumo-lernen/pull/412) | open | Lumo Lernbegleiter: selbstständiges, freiwilliges Hilfsangebot nach wiederholten Fehlern | `feat/lumo-proactive-tutor-offer-20261028` |
| [#413](https://github.com/Ullmann27/lumo-lernen/pull/413) | open | Lumo Lernprofil: echter persönlicher Tagesplan aus geprüften Schwächen und Stärken | `feat/lumo-personal-daily-learning-plan-20261028` |
| [#414](https://github.com/Ullmann27/lumo-lernen/pull/414) | open | Lumo Lerngehirn: lokale Alternativszenen und nachprüfbarer selbstständiger Transfer | `feat/lumo-living-intelligence-20261029` |
| [#415](https://github.com/Ullmann27/lumo-lernen/pull/415) | open | Android 2002 veröffentlicht: geprüftes Haupt-App-Update mit lokalem Lerngehirn | `feat/lumo-living-intelligence-2002-20261029` |
| [#416](https://github.com/Ullmann27/lumo-lernen/pull/416) | open | Opus Living World: animierter Original-Lumo mit 11 Zuständen und interaktiver Zehner-Szene | `claude/lumo-living-world-visual-20261029` |
| [#417](https://github.com/Ullmann27/lumo-lernen/pull/417) | open | Living World: Werkstatt-Layout für Fold, 4+4 Zehner und flackerfreie Würfelanimation | `repair/lumo-living-workshop-polish-20261029` |
| [#418](https://github.com/Ullmann27/lumo-lernen/pull/418) | open | Living Intelligence + animierter Original-Lumo: sichere 2002→nächste App-Integration | `integration/lumo-2003-living-intelligence-original-fox-20261029` |
| [#419](https://github.com/Ullmann27/lumo-lernen/pull/419) | open | Lumo Lernen + Lumo Kart 2003: Sols Lernintelligenz, Opus Living Fox und geprüfte Haupt-App-APK | `release/lumo-2003-living-world-20261029` |
| [#421](https://github.com/Ullmann27/lumo-lernen/pull/421) | open | Lumo 2003: geprüfte Haupt-App ohne manuelle APK über bestehenden Update-Button | `release/lumo-2003-family-button-20261029` |
| [#422](https://github.com/Ullmann27/lumo-lernen/pull/422) | open | Lumo 2002: bereits geprüfte APK direkt über vorhandenen App-Update-Button | `release/lumo-2002-family-button-20261029` |
| [#423](https://github.com/Ullmann27/lumo-lernen/pull/423) | open | Lumo Memory 2027: interaktives 2.5D-Premium-Spielbrett auf Build 2003 | `chatgpt/lumo-2027-memory-stage-20261029` |
| [#424](https://github.com/Ullmann27/lumo-lernen/pull/424) | open | Lumo Volksschule 1–4: Fächerzugang, ehrlicher Nachhilfeplan und Vollprüfung aller Aufgabengeneratoren | `repair/lumo-vs-all-subjects-access-20261030` |
| [#425](https://github.com/Ullmann27/lumo-lernen/pull/425) | open | Lumo Lernen 2004: gesamter Volksschul-Tutor und Sonnenhafen-Stunts als Haupt-App-Kandidat | `integration/lumo-2004-full-learning-stunts-20261030` |
| [#426](https://github.com/Ullmann27/lumo-lernen/pull/426) | open | Lumo 2004: echter Update-Nachweis 2003→2004 für Familien-App, Lernstände und Kart | `qa/lumo-2004-real-upgrade-20261031` |
| [#427](https://github.com/Ullmann27/lumo-lernen/pull/427) | open | Lumo 2004 visuelle Vollprüfung: alle 14 Register und 1.–4. Klasse auf Phone und Fold | `qa/lumo-all-registers-grade-1-4-visual-20261031` |
| [#428](https://github.com/Ullmann27/lumo-lernen/pull/428) | open | Release Lumo Lernen + Lumo Kart 2004: geprüfter Familien-Updatekanal | `release/lumo-2004-family-update-20261102` |
| [#429](https://github.com/Ullmann27/lumo-lernen/pull/429) | open | Lumo UX: alle 14 Bereiche ohne Ausklapppfeil direkt in durchgehender Scroll-Leiste | `ux/lumo-scroll-all-sections-20261103` |
