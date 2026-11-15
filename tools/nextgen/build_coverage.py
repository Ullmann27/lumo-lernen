#!/usr/bin/env python3
"""Join an actual Dart catalog export with reviewed route/authority evidence.

Usage: python3 tools/nextgen/build_coverage.py /absolute/catalog.json
Run from the repository root. This writes documentation, never student data.
The output deliberately does not treat a registered enum, import, or old test
file as proof of a working route, assessed learning, or completed modernization.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
BASE = "6f4a8c4753f4d06d0b392da0789b8162b2faa71b"
CATALOG = json.loads(Path(sys.argv[1]).read_text())
SOURCES: dict[str, dict] = {}


def source(path: str, symbol: str | None = None) -> dict:
    data = (ROOT / path).read_bytes()
    SOURCES[path] = {"path": path, "sha256": hashlib.sha256(data).hexdigest()}
    result = {"path": path}
    if symbol:
        content = data.decode()
        if symbol not in content:
            raise ValueError(f"Missing source symbol: {path}: {symbol}")
        result["symbol"] = symbol
        result["line"] = content[:content.index(symbol)].count("\n") + 1
    return result


def tests(*paths: str) -> list[dict]:
    for path in paths:
        source(path)
    return [{"path": path, "status": "present_not_run_in_this_review"} for path in paths]


SHELL = "lib/app/app_shell.dart"
ACADEMY = "lib/features/teacher_mode/lumo_akademie_screen.dart"
HUB = "lib/features/sections/lumo_learning_hub.dart"
HOME = "lib/features/home/home_content.dart"
CORE = "lib/features/learning/learning_content.dart"
RENDERER = "lib/features/learning/renderers/adaptive_task_renderer.dart"
ADAPTER = "lib/features/learning/adapters/legacy_lumo_task_adapter.dart"
GENERATOR = "lib/core/school_exercise_generator.dart"
REGISTRY = "lib/features/learning_modules/learning_module_registry.dart"
PROGRESS = "lib/features/learning_modules/learning_module_progress.dart"
FRAME = "lib/widgets/design/lumo_learning_module_frame.dart"
GAMES = "lib/features/games/games_content.dart"

AUTHORITIES = {
    "core": {
        "evaluation": source(RENDERER, "_pick("),
        "acceptanceAndPersistence": source(CORE, "_completeAnswer("),
        "description": "Existing local task answer/evaluator feeds TaskResult, adaptive/reward/feedback engines and profile-bound app recording. Renderer callbacks do not create a second progress store.",
    },
    "module": {
        "evaluation": "Each specialist screen compares against its current local task; see its route source.",
        "acceptanceAndPersistence": source(PROGRESS, "saveAnswer("),
        "description": "Existing queued profile-owner saves, retry without duplicate reward, separate assisted/discovery evidence and completion bonus.",
    },
    "plus10": {
        "evaluation": source("lib/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart", "_saveAnswer("),
        "description": "Existing custom owner-bound answer/reward and finish-retry path, not LearningModuleProgress.",
    },
    "crossGrade": {
        "evaluation": source("lib/features/learning/cross_grade_practice_screen.dart", "_answer("),
        "description": "Local answer comparison; first incorrect attempt gets a second chance. Separate practice namespace, no enrolled-grade, XP or wallet mutation.",
    },
    "activity": {
        "evaluation": None,
        "source": source("lib/features/learning/curriculum_activities_screen.dart"),
        "description": "Practical instructions only. No automatic correctness, school evidence, completion recording or rewards; observation remains a human task.",
    },
    "lab": {
        "evaluation": source("lib/features/learning/lab/learning_lab_catalog.dart", "bool accepts("),
        "acceptanceAndPersistence": source("lib/features/learning/lab/learning_lab_screen.dart"),
        "description": "Local model/answer checks. Building records assisted observation; recall/transfer use existing module progress. Reflection is not an extra correct answer.",
    },
    "guided": {
        "evaluation": source("lib/domain/tutoring/guided_lesson_catalog.dart", "bool accepts("),
        "acceptanceAndPersistence": source("lib/features/tutoring/guided_lesson_screen.dart"),
        "description": "Step-specific deterministic acceptance, guided/independent evidence distinct; discovery has separate progress and no school/wallet rewards.",
    },
    "reading": {
        "evaluation": source("lib/features/reading/reading_content.dart", "recordLearningAnswer("),
        "description": "Accepted speech attempt ledger drives reading progress; ambiguous recognition must not be treated as a proven deficit. Microphone/runtime-device QA remains open.",
    },
    "readingBuddy": {
        "evaluation": source("lib/features/reading/lumo_reading_buddy_screen.dart"),
        "description": "Reading participation and local comprehension answers are separate; the existing comprehension correctIndex and module progress remain authoritative.",
    },
    "story": {
        "evaluation": source("lib/features/story/lumo_story_reader_screen.dart", "_onAnswer("),
        "summaryEvaluation": source("lib/core/lumo_story_summary_scoring.dart"),
        "description": "Existing page exercises, whole-book comprehension and summary evaluation; completion and summary rewards retain existing exactly-once storage rules.",
    },
    "photo": {
        "source": source("lib/features/photo_lesson/photo_lesson_practice.dart"),
        "description": "OCR analysis selects practice cards; the screen reveals a solution, not a graded child answer. No assessed progress from a reveal.",
    },
    "iq": {
        "evaluation": source("lib/core/iq/iq_test_session.dart"),
        "persistence": source("lib/core/iq/iq_test_repository.dart"),
        "description": "Existing local puzzle session and repository. No claim of standardized diagnostic validation.",
    },
    "cognitive": {
        "evaluation": source("lib/core/cognitive_profile_scorer.dart"),
        "persistence": source("lib/core/cognitive_profile_repository.dart"),
        "description": "Existing five-domain local profile scoring. No claim of standardized diagnostic validation.",
    },
    "gameLevel": {
        "persistence": source("lib/core/game_progress_repository.dart"),
        "description": "Each mini-game checks its own task and saves its level result. Keep level IDs and existing game rewards distinct from school mastery.",
    },
    "cards": {
        "evaluation": source("lib/features/games/lumo_cards/lumo_cards_game_controller.dart"),
        "bank": source("lib/features/games/lumo_cards/learning_question_repository.dart"),
        "description": "Current-grade Denkpause answer checked by existing card controller. Grades 1/2 use bundles; grades 3/4 use checked math templates.",
    },
    "quiz": {
        "evaluation": source("lib/domain/quiz/quiz_show.dart"),
        "persistence": source("lib/features/quiz/quiz_show_repository.dart"),
        "description": "Existing answer lock/reveal, jokers, round ownership and one-time game reward. Native table is a presentation path for the same round.",
    },
    "flame": {
        "evaluation": source("lib/features/games/flame/lumo_jump_game.dart", "_showQuestion("),
        "description": "Existing exact choice comparison for question blocks and three-answer chest streak; own game reward ledger. This is the 2D Flame learning game, not the excluded native Jungle.",
    },
    "live": {
        "evaluation": source("lib/features/live/lumo_live_pro_screen.dart"),
        "description": "Word/photo participation rewards and heuristic safari speech matching are existing behavior; they are not reliable independently assessed subject mastery.",
    },
    "protectedWriting": {
        "source": source("lib/features/writing/writing_feature_flags.dart"),
        "description": "Existing writing evaluator/progress and journal internals remain untouched. Only outer routing/adapters may be added.",
    },
    "none": {"evaluation": None, "description": "Navigation, reference or conversational support; not an independently assessed task."},
}

ROUTES: list[dict] = []


def route(identifier: str, title: str, target: str, entry: str, symbol: str,
          authority: str, task_types: list[str], *, status="source_reachable",
          conditions="", help_text="", completion="", adapters=(), gaps=(), test_paths=()):
    ROUTES.append({
        "id": identifier, "idSemantics": "inventory_route_id_not_persisted_task_id",
        "title": title, "target": source(target),
        "entry": source(entry, symbol),
        "reachable": {"status": status, "conditions": conditions,
                      "runtimeExhaustive": False},
        "taskTypes": task_types, "authorityRef": authority,
        "help": help_text, "completion": completion,
        "adapters": list(adapters), "tests": tests(*test_paths),
        "gaps": list(gaps) + ["device_qa"],
    })


route("academy", "Akademie / Klassen- und Fachauswahl", ACADEMY, SHELL,
      "case LumoSection.learn:", "none", ["navigation"],
      conditions="Selected grade is separate from enrolled grade.",
      adapters=["LearningNavigation"], test_paths=["test/design/modern_learning_navigation_test.dart"])
route("core", "Reguläre Aufgaben", CORE, SHELL, "LearningContent(", "core",
      ["multipleChoice", "numberLine", "dotGroups", "tenOnes", "writingCanvas", "shapeTrace"],
      help_text="TaskHintService stages 1–3, tutor support, optional native/scened explanation. No help in test or schoolwork.",
      completion="Quick practice 10; exercise set 20; test 10; schoolwork 30; tutoring 8. Existing completion/test result storage.",
      adapters=["LegacyLumoTaskAdapter", "AdaptiveTaskRenderer", "NativeLearningActivity", "LumoCompanionTaskContext"],
      gaps=["sentence_answer_leak", "all_families_interaction", "domain_boundary", "direct_family_selection"],
      test_paths=["test/learning/learning_exact_selection_test.dart", "test/learning_answer_reward_test.dart",
                  "test/learning_profile_isolation_test.dart", "test/learning_test_session_result_test.dart",
                  "test/learning/sentence_prompt_privacy_test.dart"])
route("cross_grade", "Freiwilliges Üben anderer Klassen", "lib/features/learning/cross_grade_practice_screen.dart",
      ACADEMY, "CrossGradePracticeScreen(", "crossGrade", ["generated_choice"],
      conditions="Only a different selected grade; namespaced local practice progress.",
      help_text="Second-chance hint and existing scene explanation.", completion="Open practice; no official reward completion.",
      adapters=["CrossGradeVisualScene", "ExerciseFactory"], gaps=["all_families_interaction"],
      test_paths=["test/cross_grade_second_chance_test.dart", "test/cross_grade_practice_storage_hardening_test.dart"])
route("activities", "Praktische Fachaufträge", "lib/features/learning/curriculum_activities_screen.dart",
      ACADEMY, "CurriculumActivitiesScreen(", "activity", ["creative_observation", "oral_practice", "physical_activity"],
      conditions="Five practical subjects via hub; Deutsch/Englisch/Sachunterricht via tools in this branch.",
      help_text="Instruction, competency and human evidence description.",
      completion="No automated completion or rewards.", gaps=["activity_evidence_workflow"],
      test_paths=["test/design/learning_registered_routes_test.dart"])
route("lab", "Lernlabor", "lib/features/learning/lab/learning_lab_screen.dart",
      "lib/features/learning/lab/learning_lab_hub.dart", "LearningLabScreen(", "lab",
      CATALOG["enums"]["LabMode"], help_text="Five task-specific hints; example/build/recall/transfer/reflection.",
      completion="Existing assisted/model observation and independent answer pipeline.",
      adapters=["QuantityBridgeBoard", "FractionBuildBoard", "LearningTokenWorkbench", "LearningModuleProgress"],
      gaps=["reference_pattern_scene"], test_paths=["test/learning_lab_manipulatives_test.dart", "test/learning_lab_progress_test.dart", "test/learning_lab_runtime_test.dart"])
route("lab_hub", "Auswahl im Lernlabor", "lib/features/learning/lab/learning_lab_hub.dart",
      ACADEMY, "LearningLabHub(", "none", ["lab_selection"], adapters=["LabCatalog"])
route("guided", "Geführte Lektionen / Entdecker-Modus", "lib/features/tutoring/guided_lesson_screen.dart",
      "lib/features/tutoring/guided_learning_hub.dart", "GuidedLessonScreen(", "guided",
      CATALOG["enums"]["GuidedAnswerKind"],
      help_text="Lesson-specific examples, simpler practice, deterministic answer-kind guidance.",
      completion="Seven-step lessons; school/discovery evidence remains separate.",
      adapters=["GuidedLessonCatalog", "NativeLearningActivity", "LearningModuleProgress"],
      test_paths=["test/tutoring/guided_lesson_runtime_test.dart", "test/tutoring/guided_lesson_evidence_test.dart"])
route("guided_hub", "Auswahl geführter Lektionen", "lib/features/tutoring/guided_learning_hub.dart",
      ACADEMY, "GuidedLearningHub(", "none", ["guided_selection"], adapters=["GuidedLessonCatalog"])
route("native_explanation", "Native Lernszene", "lib/domain/tutoring/native_learning_activity.dart",
      CORE, "_openNativeLearning(", "none", ["native_illustration"],
      conditions="Only compatible checked tasks; optional separate native Activity, not an inline Flutter figure.",
      help_text="Marks assistance; same bound task after return.", completion="Cannot submit answers or award progress.",
      adapters=["NativeLearningActivity", "LearningSceneRequest"], gaps=["native_inline_absent", "async_binding_integration"],
      test_paths=["test/tutoring/native_learning_launch_test.dart", "test/tutoring/native_learning_serialized_contract_test.dart"])
route("scene_place_value", "Stellenwert-Szenenvertrag", "lib/features/learning/scenes/learning_scene_contract.dart",
      CORE, "PlaceValue", "core", ["placeValue"],
      help_text="Explore/construct/explain/done under existing director.",
      adapters=["LearningSceneDirector", "LearningSceneRequest", "LearningSceneEvent"],
      gaps=["scene_kind_coverage", "async_binding_integration"],
      test_paths=["test/learning/lumo_place_value_workshop_test.dart", "test/learning/lumo_place_value_transfer_test.dart"])
route("reading", "Aktives Vorlesen", "lib/features/reading/reading_content.dart", SHELL,
      "ReadingContent(", "reading", ["spoken_sentence"],
      help_text="Syllable/word support, repeated attempts, listening feedback.", completion="Sentence progress and reading completion.",
      adapters=["VoiceReadingEvaluator", "ReadingAttemptHistory"], gaps=["microphone_runtime"],
      test_paths=["test/reading_active_sentence_view_test.dart", "test/reading_writing_content_test.dart"])
route("reading_buddy", "Reading Buddy", "lib/features/reading/lumo_reading_buddy_screen.dart", HOME,
      "LumoReadingBuddyScreen(", "readingBuddy", ["reading_text", "comprehension_choice"],
      completion="24 fixed text IDs; reading and comprehension evidence distinct.", gaps=["microphone_runtime"],
      test_paths=["test/reading_buddy_assessment_test.dart"])
route("story_library", "Geschichtenbibliothek und Erstellung", "lib/features/story/lumo_story_library_screen.dart",
      ACADEMY, "LumoStoryLibraryScreen(", "none", ["story_selection", "story_generation"],
      adapters=["LumoStoryLibrary"], test_paths=["test/story_entry_navigation_test.dart", "test/story_library_grade_filter_test.dart"])
route("story_setup", "Neue Lerngeschichte", "lib/features/story/lumo_story_setup_screen.dart",
      "lib/features/story/lumo_story_library_screen.dart", "LumoStorySetupScreen(", "none", ["story_generation"],
      test_paths=["test/story_setup_learning_path_grade_test.dart"])
route("story_reader", "Geschichten, Buchfragen, Zusammenfassung", "lib/features/story/lumo_story_reader_screen.dart",
      "lib/features/story/lumo_story_library_screen.dart", "LumoStoryReaderScreen(", "story",
      CATALOG["enums"]["StoryExerciseType"] + ["book_comprehension", "written_summary"],
      help_text="Retry and evidence-page hints; summary evaluated by existing local scoring.",
      completion="Stored story completion; once-only summary rewards.", gaps=["story_all_variants"],
      test_paths=["test/story_answer_retry_test.dart", "test/story_book_evidence_hint_test.dart", "test/story_summary_reward_integrity_test.dart", "test/story_completion_storage_test.dart"])
route("quest", "Vier narrative Lernabenteuer", "lib/features/story/lumo_quest_hub_screen.dart",
      HOME, "LumoQuestHubScreen(", "story", ["story_exercise"],
      conditions="Selected grade plus adjacent grades per existing quest filter.",
      adapters=["LumoQuestLibrary", "LumoStoryReaderScreen"], test_paths=["test/story_book_adventure_test.dart"])
route("photo", "Foto-Lernheft", "lib/features/photo_lesson/lumo_photo_lesson_screen.dart",
      HOME, "LumoPhotoLessonScreen(", "photo", ["ocr_practice_card", "answer_reveal"],
      help_text="Existing scan analysis and explanation.", completion="Reveal is not a correct answer.",
      adapters=["PhotoLessonPractice", "ScannedWorkAnalysisEngine"], gaps=["photo_interactive_answers"],
      test_paths=["test/photo_lesson_practice_test.dart", "test/photo_lesson_subject_flow_test.dart"])
route("tests", "Fachtests und gemischter Lerncheck", "lib/features/tests/lumo_tests_screen.dart",
      SHELL, "LumoTestsScreen(", "core", ["subject_test", "mixed_test"],
      help_text="Test mode disables hints and retries.", completion="10 questions and existing TestResultRepository.",
      adapters=["LearningContent"], gaps=["sentence_answer_leak"],
      test_paths=["test/learning_test_session_result_test.dart"])
route("iq", "Logische Denkaufgaben / IQ-Bereich", "lib/features/tests/iq_test_screen.dart",
      "lib/features/tests/lumo_tests_screen.dart", "IqTestScreen(", "iq", CATALOG["enums"]["IqArea"],
      completion="Start, area intro, puzzle, save, result and review.",
      test_paths=["test/iq/iq_test_screen_test.dart"])
route("cognitive", "Fünf kognitive Aufgabenbereiche", "lib/features/tests/cognitive_profile_screen.dart",
      "lib/features/tests/lumo_tests_screen.dart", "CognitiveProfileScreen(", "cognitive", CATALOG["enums"]["CognitiveDomain"],
      completion="50 questions per grade; 200 current fixed question IDs.",
      test_paths=["test/cognitive_profile_test.dart", "test/cognitive_profile_premium_ui_test.dart"])
route("teacher_assignments", "Zugewiesene Schulaufgaben", "lib/features/teacher/student_assignments_card.dart",
      HOME, "StudentAssignmentsCard(", "core", ["assigned_existing_task"],
      adapters=["LearningContent", "SchoolAttempt"], test_paths=["test/design/legacy_learning_assignment_test.dart"])
route("teacher_conversation", "Themenbegleitung", "lib/features/teacher_mode/lumo_teacher_screen.dart",
      ACADEMY, "LumoTeacherScreen(", "none", ["conversation"],
      conditions="Fallback after dedicated exact module/task routing; no teacher-model authority over correctness.",
      gaps=["conversation_domain_binding"])
route("live", "Live-Wortmagie, Foto-Quiz, Safari", "lib/features/live/lumo_live_pro_screen.dart",
      HOME, "LumoLiveProScreen(", "live", ["wordMagic", "photoQuiz", "safari"],
      gaps=["live_participation_vs_mastery", "microphone_runtime"])
route("abc_reference", "ABC-Tafel", "lib/features/learning/lumo_abc_tafel_screen.dart",
      HOME, "LumoAbcTafelScreen(", "none", ["reference_poster"])
route("math_reference", "Rechentricks-Tafel", "lib/features/learning/lumo_rechentricks_poster_screen.dart",
      HOME, "LumoRechentricksPosterScreen(", "none", ["reference_poster"])
route("word_coach", "Wort-Schreibtrainer", "lib/features/writing/lumo_writing_word_coach_screen.dart",
      ACADEMY, "LumoWritingWordCoachScreen(", "protectedWriting", ["word_handwriting"],
      conditions="enableWordMode=true shadows legacy d1_woerter registry screen.",
      adapters=["outer_only"], gaps=["protected_internal_scope"])
route("writing_coach", "Schreibtrainer", "lib/features/writing/lumo_writing_coach_screen.dart",
      ACADEMY, "LumoWritingCoachScreen(", "protectedWriting", ["handwriting"],
      adapters=["outer_only"], gaps=["protected_internal_scope"])
route("letter_writing", "Buchstaben schreiben", "lib/features/teacher_mode/letter_writing_screen.dart",
      ACADEMY, "LetterWritingScreen(", "protectedWriting", ["letter_handwriting"],
      adapters=["outer_only"], gaps=["protected_internal_scope"])
route("cross_grade_writing", "Freiwilliger Aufsatz", "lib/features/learning/cross_grade_writing_screen.dart",
      ACADEMY, "CrossGradeWritingScreen(", "protectedWriting", ["free_writing"],
      conditions="Other selected fourth grade; independent local draft.", adapters=["outer_only"], gaps=["protected_internal_scope"])
route("journal", "Journal", "lib/features/journal/lumo_journal_screen.dart",
      HOME, "LumoJournalScreen(", "protectedWriting", ["journal_entry"],
      adapters=["outer_only"], gaps=["protected_internal_scope"])
route("deutsch_legacy_gap", "Alte Deutsch-Lückensätze", "lib/features/deutsch/lumo_deutsch_screen.dart",
      "lib/features/deutsch/deutsch_gap_sentences.dart", "DeutschGapSentences", "none", ["gap_sentence"],
      status="unreachable_from_main_import_graph",
      conditions="Not imported/called by current app routes. Existing local five-question flow only.",
      help_text="Some prompts allow more than one sensible option; do not reconnect without content/owner review.",
      completion="Existing direct recordLearningAnswer and addRewards would require owner/assistance review.",
      gaps=["legacy_gap_ambiguity", "legacy_gap_owner"], test_paths=["test/deutsch_gap_sentence_test.dart"])

MODULE_ROWS = [
    ("m1_plus10", "plus_bis_10", 30, ["addition"], "three_stage"),
    ("m1_minus10", "minus_bis_10", 30, ["subtraction"], "one_local_hint"),
    ("m1_zahlen10", "zahlen_bis_10", 12, ["zaehlen", "nachfolger", "groesser"], "frame_only"),
    ("m1_formen", "formen", 12, ["shape_identification"], "frame_only"),
    ("s1_tiere", "tiere", 30, ["bildZeigen", "lautRaten", "lebensraum"], "frame_only"),
    ("s1_farben", "farben", 30, ["farbeZuObjekt", "objektZuFarbe"], "frame_only"),
    ("m2_uhr", "uhr_lernen", 8, ["clock_reading"], "frame_only"),
    ("m2_geld", "geld", 30, ["zaehlen", "muenzeFinden"], "frame_only"),
    ("m2_zahlen100", "zahlen_bis_100", 12, ["nachfolger", "vorgaenger", "vergleich", "zehnerEiner"], "frame_only"),
    ("d2_artikel", "artikel_lernen", 12, ["der_die_das"], "frame_only"),
    ("d2_mehrzahl", "mehrzahl", 30, ["plural"], "frame_only"),
    ("s2_jahreszeiten", "jahreszeiten", 30, ["bildErraten", "hinweisErraten"], "frame_only"),
    ("s2_wetter", "wetter", 30, ["bildErraten", "kleidungWaehlen", "hinweisErraten"], "frame_only"),
    ("s2_verkehr", "verkehr", 30, ["traffic_choice"], "frame_only"),
    ("d3_wortarten", "wortarten", 30, ["wortKategorisieren", "kategorieFinden"], "frame_only"),
    ("d3_zeitformen", "zeitformen", 30, ["satzKategorisieren", "satzAuswaehlen"], "frame_only"),
    ("d1_woerter", "wort_diktat", None, ["dictation_self_rating"], "reveal_and_self_rating"),
    ("m2_einmaleins", "einmaleins", 12, ["multiplication_partial"], "one_local_hint"),
    ("m3_einmaleins_voll", "einmaleins", 12, ["multiplication_full"], "one_local_hint"),
    ("m4_bruch", "bruchrechnen", 8, ["fraction_choice"], "frame_only"),
]
assert {m[0] for m in MODULE_ROWS} == set(CATALOG["registeredModuleIds"])
for module_id, directory, count, modes, hint in MODULE_ROWS:
    path = f"lib/features/learning_modules/{directory}/{directory}_screen.dart"
    status = "shadowed_by_word_coach" if module_id == "d1_woerter" else "source_reachable"
    route("module:" + module_id, module_id, path, REGISTRY, f"case '{module_id}':",
          "plus10" if module_id == "m1_plus10" else "module", modes, status=status,
          conditions=("Added academy tool in this branch; enrolled and selected grade 1 only." if module_id == "s1_farben"
                      else "Enrolled-grade academy topic; other grades use cross-grade practice."),
          help_text=hint, completion=f"{count if count is not None else 'sessionWords.length'} tasks; existing finish/bonus flow.",
          adapters=["LumoLearningModuleFrame", "LearningModuleProgress" if module_id != "m1_plus10" else "custom_plus10_owner_save"],
          gaps=(["module_context_help"] if hint == "frame_only" else []) +
               (["word_dictation_shadowed"] if module_id == "d1_woerter" else []),
          test_paths=["test/learning_modules/learning_module_progress_test.dart"])
    ROUTES[-1]["persistedTopicId"] = module_id
    ROUTES[-1]["tasksPerRound"] = count
    if module_id == "d1_woerter":
        ROUTES[-1]["authorityCaveat"] = "A child self-rates revealed writing; this is not verified ink recognition."
    if module_id == "m1_plus10":
        ROUTES[-1]["presentationCaveat"] = "Shared module frame only on compact branch; immersive layout is separate."

for slug, cls, modes in [
    ("stars_path", "StarsPathGame", ["starsPath"]),
    ("number_house", "NumberHouseGame", ["numberHouse"]),
    ("color_boxes", "ColorBoxesGame", ["colorBoxes"]),
    ("letter_fill", "LetterFillGame", ["letterFill"]),
    ("lesson_trail", "LessonTrailGame", ["numberPath", "wordForest", "mixedQuiz"]),
]:
    route("game:" + slug, cls, f"lib/features/games/mini_games/{slug}_game.dart",
          GAMES, cls + "(", "gameLevel", modes,
          completion="Existing five-question game round and level-result/reward policy.",
          gaps=["game_interaction_coverage"],
          test_paths=["test/games/mini_games_flow_test.dart", "test/games/game_round_regression_test.dart"])
route("cards_learning", "Lumo-Cards-Denkpausen", "lib/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart",
      "lib/features/games/lumo_cards/lumo_cards_screen.dart", "LumoLearningCardOverlay(", "cards", ["current_grade_choice"],
      help_text="Existing question hint.", adapters=["LearningQuestionRepository"],
      gaps=["game_interaction_coverage"], test_paths=["test/games/cards_learning_grade_test.dart", "test/learning_question_repository_test.dart"])
route("quiz", "Lumo-Meister-Quizshow", "lib/features/quiz/quiz_show_content.dart",
      GAMES, "QuizShowContent(", "quiz", ["quiz_choice", "final_logic"],
      help_text="Three existing jokers, including local Lumo hint.", completion="20 questions, lock/reveal/result and once-only round reward.",
      gaps=["game_interaction_coverage"], test_paths=["test/quiz_question_bank_test.dart", "test/quiz_show_live_ladder_lockin_test.dart", "test/quiz_native_roundtrip_lifecycle_test.dart"])
route("flame_learning", "2D-Flame-Lernblöcke und Truhenaufgaben", "lib/features/games/flame/lumo_jump_game.dart",
      GAMES, "LumoJumpFlameScreen(", "flame", ["math_question_block", "german_question_block", "three_answer_chest"],
      help_text="Existing answer sheet retry; no staged subject hint engine.",
      gaps=["flame_grade_scope", "game_interaction_coverage"],
      test_paths=["test/games/flame_adventure_flow_test.dart", "test/games/flame_adventure_round_test.dart"])

GAPS = [
    ("spatial3d_task_integration", "open", "Chat1 + Chat2 + native scene owner", "No route in this snapshot has proof of the full requested task-bound 3D actor/object interaction. Flutter 2D cards, shadows, manipulative widgets and an optional native launch do not establish that completion criterion."),
    ("device_qa", "open", "All", "No current Android/Fold hardware, rotation, audio/mic, large text and 60 FPS sweep across all routes. Widget tests are not hardware proof."),
    ("sentence_answer_leak", "reproduced_open", "c5 renderer owner", "SchoolbookFallbackVisual builds unassisted Satz bauen word cards from correctAnswer. Three new regressions fail on this source: practice, exam, hidden-answer perturbation."),
    ("all_families_interaction", "open", "Chat2/c5", "236 registered curriculum families do not imply 236 modern interactive workspaces. Each actual interaction still needs coverage."),
    ("domain_boundary", "open", "Chat1 + Chat2", "Correctness is currently partly computed in UI renderers. New agent/native proposals must enter the existing checked owner callback, never a reward action."),
    ("direct_family_selection", "open", "navigation integration", "Reading hub opens active speech reading; Rechtschreibung has no standalone subject tile. Generator families can appear in mixed sessions; exact family selection was not exercised for all 236."),
    ("module_context_help", "open", "specialist module owner", "Sixteen distinct module screens have no local staged help state. Shared frame help only works with a matching current companion task context, which cannot be inferred from the frame's presence."),
    ("activity_evidence_workflow", "open", "activities owner", "All 60 practical entries are reachable after local route fixes; no observation submission/teacher feedback completion flow exists in this screen."),
    ("reference_pattern_scene", "open", "Chat2/c5", "Baseline lab has five modes and no separate pattern mode. Existing pattern questions do not prove the requested interactive periodic-group reference scene."),
    ("native_inline_absent", "known_architecture_limit", "Chat1", "Separate Godot activity exists; no inline native platform view in every Flutter task."),
    ("async_binding_integration", "open", "Chat1 + conversation", "Shared v1 session/task/revision/context/cancel envelope is a contract; end-to-end callback ownership is not proven by this catalog."),
    ("scene_kind_coverage", "open", "scene integration", "Presenter contract exposes only placeValue; all 28 visual enums must not be described as native task scenes."),
    ("microphone_runtime", "open", "conversation owner", "Recognition permission, mishearing/correction, stop/pause and actual audio playback require current runtime proof."),
    ("story_all_variants", "open", "story integration", "Stored/generated stories have dynamic IDs and content. Finite quest catalog does not enumerate every story variant."),
    ("photo_interactive_answers", "open", "photo integration", "Practice cards reveal answers; they do not collect/check a child's response."),
    ("conversation_domain_binding", "open", "conversation owner", "Conversation needs the active task snapshot and domain-owned feedback rather than independent correctness claims."),
    ("live_participation_vs_mastery", "open", "live integration", "Word/photo participation reward and safari fuzzy matching must remain distinguishable from verified learning evidence."),
    ("protected_internal_scope", "excluded_internal_changes", "outer adapters only", "Writing trainer and journal internals preserved; no claim of internal modernization."),
    ("legacy_gap_ambiguity", "open", "content review", "Legacy gap bank has multiple sensible options: Hund spielt im Haus/Garten; Vogel sitzt auf dem Tisch/Ast. It was not reconnected."),
    ("legacy_gap_owner", "open", "learning owner", "Unreachable legacy gap screen directly records/rewards; profile-owner and assisted-evidence integration needs review before enabling it."),
    ("word_dictation_shadowed", "known_route_shadow", "outer adapters only", "d1_woerter is registered but current academy opens protected word coach first. Registry count does not equal active module screen count."),
    ("game_interaction_coverage", "open", "learning game integration", "Learning overlays/mini-games use independent screens; modernizing AdaptiveTaskRenderer alone does not modernize them."),
    ("flame_grade_scope", "open", "learning game integration", "Flame requests grade-dependent tasks using a fixed early-grade unit list; exact grade/template fallback behavior needs focused review."),
    ("colours_route", "fixed_locally_tested", "learning agent", "s1_farben now opens through existing academy tools for enrolled grade 1; module/task IDs and data unchanged."),
    ("activity_routes", "fixed_locally_tested", "learning agent", "20 existing language/science practical catalog items now have three tool entries; selected grade stays separate from profile grade."),
]

for row in ROUTES:
    identifier = row["id"]
    non_task = row["authorityRef"] == "none" and identifier not in {"native_explanation", "deutsch_legacy_gap"}
    rendering = "flutter_2d_task_surface"
    if identifier == "native_explanation":
        rendering = "native_3d_optional_separate_activity"
    elif identifier in {"core", "guided"}:
        rendering = "flutter_2d_with_compatible_optional_native_explanation"
    elif identifier == "lab":
        rendering = "flutter_2d_material_manipulation"
    elif identifier == "scene_place_value":
        rendering = "abstract_director_and_flutter_place_value_workshop"
    elif identifier == "flame_learning":
        rendering = "flame_2d_world_and_flutter_question_sheet"
    elif row["authorityRef"] == "protectedWriting":
        rendering = "protected_existing_surface_outer_adapter_only"
    elif non_task:
        rendering = "navigation_reference_or_conversation"
    row["spatial3D"] = {
        "currentRendering": rendering,
        "fullTaskBound3DProven": False,
        "proofStatus": "not_applicable_to_navigation" if non_task else "not_proven_in_this_snapshot",
        "inlineNativeView": False,
        "optionalLaunchCountsAsFullCoverage": False,
        "needed": [] if non_task else ["current_task_named_objects", "domain_checked_input_path", "actor_target_binding", "calm_and_accessible_spatial_controls", "runtime_proof"],
    }
    if not non_task and row["authorityRef"] != "protectedWriting":
        row["gaps"].append("spatial3d_task_integration")


def attach(rows, route_ref, source_path, authority, adapters=()):
    source(source_path)
    for row in rows:
        row.update({"routeRef": route_ref, "source": source_path,
                    "reachable": "see_route_conditions", "authorityRef": authority,
                    "adapters": list(adapters), "tests": "see_route_tests",
                    "gaps": "see_route_gaps"})


attach(CATALOG["curriculumFamilies"], "core", GENERATOR, "core", ["LegacyLumoTaskAdapter", "AdaptiveTaskRenderer"])
for row in CATALOG["curriculumFamilies"]:
    row["allGeneratedVariantsEnumerated"] = False
    row["directUnitNavigation"] = "not_individually_verified" if row["subject"] in {"Lesen", "Rechtschreibung"} else "source_catalog_hub"
attach(CATALOG["mathTemplates"], "core", "lib/core/math_task_templates.dart", "core")
attach(CATALOG["germanTemplates"], "core", "lib/core/german_task_templates.dart", "core")
attach(CATALOG["practicalActivities"], "activities", "lib/core/curriculum/primary_activity_catalog.dart", "activity")
attach(CATALOG["labTopics"], "lab", "lib/features/learning/lab/learning_lab_catalog.dart", "lab")
attach(CATALOG["guidedLessons"], "guided", "lib/domain/tutoring/guided_lesson_catalog.dart", "guided")
attach(CATALOG["readingTexts"], "reading_buddy", "lib/features/reading/reading_text_library.dart", "readingBuddy")
attach(CATALOG["quests"], "quest", "lib/core/lumo_quest_library.dart", "story")
attach(CATALOG["cognitiveQuestions"], "cognitive", "lib/core/cognitive_profile_generator.dart", "cognitive")
game_routes = {mode: "game:" + slug for slug, modes in {
    "stars_path": ["starsPath"], "number_house": ["numberHouse"],
    "color_boxes": ["colorBoxes"], "letter_fill": ["letterFill"],
    "lesson_trail": ["numberPath", "wordForest", "mixedQuiz"],
}.items() for mode in modes}
for row in CATALOG["gameLevels"]:
    attach([row], game_routes[row["miniType"]], "lib/domain/games/game_level_catalog.dart", "gameLevel")
for row in CATALOG["academyTopics"]:
    task_route = "core"
    if row["id"] == "d3_geschichten": task_route = "story_library"
    elif row["id"] == "d1_woerter": task_route = "word_coach"
    elif row["id"] in {"d1_schreibcoach", "d4_aufsatz"}: task_route = "writing_coach"
    elif row["isWriting"]: task_route = "letter_writing"
    elif row["registeredModule"]: task_route = "module:" + row["id"]
    row["enrolledGradeRouteRef"] = task_route
    row["otherGradeRouteRef"] = "story_library" if row["id"] == "d3_geschichten" else "cross_grade_writing" if row["id"] == "d4_aufsatz" else "cross_grade"
    row["reachable"] = "source_topic_dispatch_not_each_tile_executed"
    row["source"] = ACADEMY

TYPE_COVERAGE = []
enum_routes = {
    "LabMode": "lab", "GuidedLessonConcept": "guided", "GuidedAnswerKind": "guided",
    "TutoringStepType": "guided", "StoryExerciseType": "story_reader",
    "IqArea": "iq", "CognitiveDomain": "cognitive",
}
for enum, values in CATALOG["enums"].items():
    for value in values:
        route_ref = game_routes[value] if enum == "GameMiniType" else enum_routes.get(enum, "core")
        coverage_route = next(row for row in ROUTES if row["id"] == route_ref)
        evidence = "declared"
        if enum == "TaskType":
            evidence = "adapter_emitted" if value in {"multipleChoice", "numberLine", "dotGroups", "tenOnes", "writingCanvas", "shapeTrace"} else "declared_without_independent_legacy_adapter_emission"
        elif enum == "LearningMode":
            evidence = "core_session_used" if value in {"practice", "tutoring", "subjectTest", "exam"} else "declared_without_current_core_session_selection"
        TYPE_COVERAGE.append({"enum": enum, "type": value, "evidence": evidence,
                              "routeRef": route_ref, "reachable": "see_catalog_and_route",
                              "authorityRef": coverage_route["authorityRef"],
                              "adapters": coverage_route["adapters"],
                              "tests": "see_route_tests", "gaps": coverage_route["gaps"],
                              "allVariantsTested": False})

# Actual finite asset keys, where present. Source locations are never invented
# as persisted task IDs when the old model has no ID field.
bundles = []
for path in sorted((ROOT / "assets/learning_questions").glob("*.json")):
    relative = str(path.relative_to(ROOT))
    source(relative)
    rows = json.loads(path.read_text())
    bundles.append({"path": relative, "routeRef": "cards_learning", "count": len(rows),
                    "items": [{"sourceIndex": i, "persistedId": item.get("id")}
                              for i, item in enumerate(rows)]})
quiz_path = "lib/domain/quiz/quiz_question_bank.dart"
quiz_ids = re.findall(r"\bid:\s*'([^']+)'", (ROOT / quiz_path).read_text())
source(quiz_path)
gap_path = "lib/features/deutsch/deutsch_gap_sentences.dart"
gap_text = (ROOT / gap_path).read_text()
source(gap_path)
legacy_gaps = [{"sourceIndex": i, "persistedId": None, "before": before,
                "routeRef": "deutsch_legacy_gap", "reachable": False}
               for i, before in enumerate(re.findall(r"\bbefore:\s*'([^']+)'", gap_text))]

# Import graph distinguishes genuinely dead libraries from constructor-only
# or conditional routes. It is NOT a proof that an imported screen is reachable.
dart_files = {str(p.relative_to(ROOT)): p for p in (ROOT / "lib").rglob("*.dart")}
graph = {}
for relative, path in dart_files.items():
    dependencies = []
    for uri in re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)['\"]", path.read_text()):
        if uri.startswith("package:lumo_lernen/"):
            child = "lib/" + uri.removeprefix("package:lumo_lernen/")
        elif ":" not in uri:
            child_path = (path.parent / uri).resolve()
            child = str(child_path.relative_to(ROOT)) if child_path.is_relative_to(ROOT) else ""
        else:
            continue
        if child in dart_files: dependencies.append(child)
    graph[relative] = dependencies
visited = set()
queue = ["lib/main.dart"]
while queue:
    item = queue.pop()
    if item in visited: continue
    visited.add(item)
    queue.extend(graph.get(item, []))
prefixes = ["lib/features/" + name + "/" for name in [
    "learning", "learning_modules", "tutoring", "reading", "story", "photo_lesson",
    "tests", "deutsch", "writing", "journal", "teacher_mode", "live", "quiz",
]] + ["lib/features/games/mini_games/"]
screen_inventory = []
for path in sorted(dart_files):
    if not any(path.startswith(p) for p in prefixes): continue
    if not path.endswith(("_screen.dart", "_content.dart", "_game.dart", "_hub.dart")): continue
    refs = [r["id"] for r in ROUTES if r["target"]["path"] == path]
    screen_inventory.append({"path": path, "mainImportGraph": path in visited,
                             "routeRefs": refs, "manualRouteStatus": "reviewed_above" if refs else "not_a_separate_reviewed_task_route"})
    source(path)

protected = []
protected_paths = set()
for folder in ["lib/features/writing", "lib/domain/writing", "lib/features/journal"]:
    protected_paths.update((ROOT / folder).rglob("*.dart"))
protected_paths.update((ROOT / "lib/core").glob("writing*.dart"))
protected_paths.add(ROOT / "lib/features/teacher_mode/letter_writing_screen.dart")
protected_paths.add(ROOT / "lib/features/learning/renderers/writing_task_renderer.dart")
for path in sorted(protected_paths):
    relative = str(path.relative_to(ROOT))
    baseline = subprocess.check_output(["git", "show", f"{BASE}:{relative}"], cwd=ROOT)
    protected.append({**source(relative), "unchangedFromBase": path.read_bytes() == baseline})
assert all(row["unchangedFromBase"] for row in protected)
for path in [HUB, "lib/features/learning/learning_navigation.dart", ADAPTER, FRAME,
             "lib/domain/tutoring/native_learning_activity.dart",
             "lib/domain/learning/lumo_learning_domain.dart",
             "lib/domain/learning_intelligence/learning_scene_contract.dart"]:
    source(path)

known_gap_ids = {row[0] for row in GAPS}
assert all(set(route["gaps"]) <= known_gap_ids for route in ROUTES)
route_ids = {row["id"] for row in ROUTES}
assert len(route_ids) == len(ROUTES)
assert all(row["routeRef"] in route_ids for key in ["curriculumFamilies", "gameLevels", "practicalActivities", "cognitiveQuestions"] for row in CATALOG[key])

NAVIGATION_RUN_SOURCES = {
    ACADEMY: "5ceab0a49d111211925a4f06cf0bf62f708936b5f675f00007627c8e3111f015",
    FRAME: "d4be5baa82cc4c7982f3ca6d42d3a4a3448bb708b3ba89b350de7663ca824598",
    "lib/features/learning_modules/farben/farben_screen.dart": "10d64f776d14ab589d103cb380249903ae6cccb67de2397c66ca19bc3d5d62b2",
    "lib/features/learning/curriculum_activities_screen.dart": "461db0fb4451881971d28df29e59237ff359d75f3c7d242e7921a9c0c9879298",
    "test/design/learning_registered_routes_test.dart": "eb279936476419ebd5348f09a032a8f91a9505980e81aeb2f90901628c359c5d",
}
PRIVACY_RUN_SOURCES = {
    RENDERER: "c9f0c4a7dad865884216a03558bc5da9329c8ea4fc20a811c7230876cc5e1c22",
    "test/learning/sentence_prompt_privacy_test.dart": "300cd10de14737d336208cac70a281ceccffaeb325f9d139bd2f91ec71891f4a",
}


def recorded_run_matches(expected):
    return all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == checksum
               for p, checksum in expected.items())


comparisons = []
for worktree in [
    "/workspace/scratch/a29874a14fb8/lumo-lernen",
    "/workspace/scratch/9d27dabbe274/lumo-lernen",
    "/workspace/scratch/2f607e7664ce/lumo-lernen",
    "/workspace/scratch/c5a7dadab95f/lumo-lernen",
    "/workspace/scratch/ea41c7b116ac/lumo-lernen",
]:
    root = Path(worktree)
    if not root.exists():
        comparisons.append({"path": worktree, "status": "unavailable_not_assumed"})
        continue
    try:
        head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
        branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=root, text=True).strip()
    except subprocess.CalledProcessError:
        comparisons.append({"path": worktree, "status": "not_readable_not_assumed"})
        continue
    same, changed, absent = [], [], []
    for relative, own in sorted(SOURCES.items()):
        if not relative.startswith("lib/"): continue
        other = root / relative
        if not other.exists(): absent.append(relative)
        elif hashlib.sha256(other.read_bytes()).hexdigest() == own["sha256"]: same.append(relative)
        else: changed.append(relative)
    comparisons.append({"path": worktree, "branch": branch, "head": head,
                        "readOnly": True, "sameReviewedLibraryFiles": len(same),
                        "changedReviewedLibraryFiles": changed,
                        "missingReviewedLibraryFiles": absent,
                        "scope": "Current reviewed library-file corpus only; foreign worktrees may remain active. Not a merge or their QA result."})

document = {
    "schema": "lumo.nextgen.learning.coverage", "version": 1,
    "asOf": "2026-11-15",
    "exportedAtUtc": datetime.now(timezone.utc).isoformat(),
    "sourceBaseline": BASE,
    "localSourceHead": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "scope": {
        "fullModernizationComplete": False, "allTaskVariantsReviewed": False,
        "inventoryMethod": "Executed finite Dart catalogs plus reviewed route dispatch, authority sources and import graph. File hashes fix the actual source snapshot.",
        "excluded": ["Kart", "native Jungle/Dschungel"],
        "protected": "Writing trainer and journal internals; outer adapters only.",
        "nonCurriculumGames": "Memory, Connect Four, Dice Race and Star Trail retain game rules/rewards; no independent curriculum-answer task is claimed here.",
        "parallelOwnership": "c5 owns AdaptiveTaskRenderer/interactive workspace/shared frame/mini-games; 2f owns LearningContent and 18 specialist modules. This inventory contains only this worktree's source until an explicit integrated regeneration.",
        "persistedIds": "Existing catalog IDs are copied unchanged. Inventory route IDs/sourceIndex are documentation keys, not new storage identifiers.",
    },
    "counts": {key: len(value) for key, value in CATALOG.items() if isinstance(value, list)},
    "authorities": AUTHORITIES, "routes": ROUTES, "catalogs": CATALOG,
    "typeCoverage": TYPE_COVERAGE,
    "additionalBanks": {"cards": bundles, "quizQuestionIds": quiz_ids,
                        "quizSource": quiz_path, "legacyGapSentences": legacy_gaps,
                        "generatedCoreIds": {"source": GENERATOR, "allIdsEnumerable": False,
                                             "adapter": ADAPTER, "preservation": "legacyId retained; current TaskInstance identity not changed"}},
    "nativeCompatibility": {
        "source": "lib/domain/tutoring/native_learning_activity.dart",
        "acceptance": "Checked payload and answer must match; null means retain existing Flutter renderer. These kinds are not a map of every family to a 3D lesson.",
        "kinds": [
            {"kind": "english_objects", "entry": "fromTask", "condition": "Only NativeEnglishVocabulary.illustrationFor mappings."},
            {"kind": "addition", "entry": "fromTask", "condition": "Integer a 0..10, b 1..10, sum <=20; checked task answer equals sum."},
            {"kind": "equal_groups", "entry": "fromTask/fromLesson", "condition": "a,b each 1..6; checked multiplication or guided equalGroups step."},
            {"kind": "equal_sharing", "entry": "fromTask", "condition": "b 2..6; a divisible by b, b<=a<=36 and quotient<=6; checked answer."},
            {"kind": "subtract_ten", "entry": "fromTask/fromLesson", "condition": "a<=20, 1<=b<=a and checked difference; corresponding guided subtraction step."},
            {"kind": "bridge_ten", "entry": "fromLesson", "condition": "a,b 1..9 and sum>10; guided bridgeTen step."},
            {"kind": "bridge_hundred", "entry": "fromTask/fromLesson", "condition": "a 100..890 and b 10..90 in multiples of ten; a%100+b>=100 and checked sum."},
            {"kind": "fraction_parts", "entry": "fromTask/fromLesson", "condition": "Denominator2..12 and positive selected parts within the whole; checked fraction addition or guided parts."},
            {"kind": "syllables", "entry": "fromTask/fromLesson", "condition": "2..5 syllables join the actual word (<=24 characters); task route verifies syllable count."},
            {"kind": "plant_parts", "entry": "fromLesson", "condition": "Guided plantParts concept only; current plant part."},
        ],
        "missingGeneralAttachments": ["specialist_modules_except_plus_context", "cross_grade_all_families", "reading_and_comprehension", "story_exercises_and_summary", "photo_practice", "practical_activities", "iq_and_cognitive", "cards_quiz_and_learning_minigames", "patterns_reference_scene"],
    },
    "modernComponents": [
        {"name": "LumoLearningModuleFrame", "source": FRAME, "capabilities": ["shared responsive chrome", "calm/reduced motion", "context-bound help"], "limit": "Frame presence does not establish a current task context or staged hint."},
        {"name": "Learning manipulatives", "source": "lib/features/learning/lab/learning_manipulatives.dart", "capabilities": ["quantity bridge", "fraction construction", "token ordering", "48dp semantic actions"], "limit": "Baseline lab only; not all task families."},
        {"name": "Schoolbook task widgets", "source": "lib/features/schoolbook/widgets/schoolbook_task_widgets.dart", "capabilities": ["word cards", "quantity/number models", "shared lesson cards"], "limit": "Mostly passive outside specific workspaces; neutral prompt privacy regression currently fails."},
        {"name": "LearningSceneDirector", "source": "lib/features/learning/scenes/learning_scene_contract.dart", "capabilities": ["revision", "allowed inputs", "named objects"], "limit": "Only placeValue scene kind is declared."},
    ],
    "gaps": [{"id": i, "status": s, "owner": o, "description": d} for i, s, o, d in GAPS],
    "verification": {
        "catalogExport": {"status": "executed", "tool": "tools/nextgen/export_learning_catalog_test.dart", "meaning": "Actual finite source catalog enumeration; not UI/device approval."},
        "localNavigation": {"recordedStatus": "passed", "recordedSourceHead": "dde93af23f84b7c5074c66cbc9a673b9bcf35a71", "recordedSourceHashes": NAVIGATION_RUN_SOURCES, "reviewedSourcesStillMatch": recorded_run_matches(NAVIGATION_RUN_SOURCES), "tests": 3, "path": "test/design/learning_registered_routes_test.dart", "conditions": ["412x915", "calm mode", "no navigation rewards", "enrolled/selected grade separation", "48dp entry rows"], "hardware": False},
        "sentencePrivacy": {"recordedStatus": "failed_reproduced", "recordedSourceHashes": PRIVACY_RUN_SOURCES, "reviewedSourcesStillMatch": recorded_run_matches(PRIVACY_RUN_SOURCES), "tests": 3, "passed": 0, "path": "test/learning/sentence_prompt_privacy_test.dart", "source": RENDERER},
        "otherTests": "Listed test paths exist; they have not been rerun by this coverage review.",
        "nativeOrPhysicalDeviceRun": False,
    },
    "sourceScreenInventory": screen_inventory,
    "protectedSourceHashes": protected,
    "readOnlyBranchComparisons": comparisons,
    "sources": sorted(SOURCES.values(), key=lambda row: row["path"]),
}
for component in document["modernComponents"]:
    source(component["source"])
document["sources"] = sorted(SOURCES.values(), key=lambda row: row["path"])
output = ROOT / "docs/nextgen/COVERAGE.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"output": str(output), "routes": len(ROUTES),
                  "screenFiles": len(screen_inventory), "sources": len(SOURCES),
                  "counts": document["counts"], "modernizationComplete": False}, ensure_ascii=False))
