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
from os.path import relpath
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
BASE = "6f4a8c4753f4d06d0b392da0789b8162b2faa71b"
NATIVE_PUBLISHED_PIN = "332307fafa2f68a1aa3667d81b7c90d3683c5c45"
CATALOG_PATH = Path(sys.argv[1])
CATALOG = json.loads(CATALOG_PATH.read_text())
HEAD = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
if CATALOG.get('sourceHead') != HEAD:
    raise SystemExit('Catalog is not exported at the current HEAD. Re-run export_learning_catalog_test.dart.')
SOURCES: dict[str, dict] = {}


def source_bytes(path: str) -> bytes:
    """Read sparse evidence from its committed blob without materializing it."""
    file = ROOT / path
    if file.exists():
        return file.read_bytes()
    result = subprocess.run(["git", "show", f"{HEAD}:{path}"], cwd=ROOT,
                            capture_output=True)
    if result.returncode:
        raise FileNotFoundError(path)
    return result.stdout


def source(path: str, symbol: str | None = None) -> dict:
    data = source_bytes(path)
    SOURCES[path] = {"path": path, "sha256": hashlib.sha256(data).hexdigest(),
                     "readFrom": "worktree" if (ROOT / path).exists() else "committed_head_blob"}
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
    return [{"path": path, "status": "present_no_recorded_run_matched"} for path in paths]


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
        "description": "Practical instructions with an existing manual Journal entry, plus linked digital practice/workshops where available. Observation is human; this screen deliberately has no automatic correctness, school-result submission or rewards.",
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
        "evaluation": source("lib/features/photo_lesson/photo_lesson_practice_screen.dart", "_accept("),
        "persistence": source("lib/features/photo_lesson/photo_lesson_session.dart"),
        "description": "OCR prepares checked tasks. PhotoLessonPracticeScreen accepts actual answers through the existing renderer/domain boundary and queues the profile-owned session/evidence. Revealing a solution or an unconfirmed speech proposal is not a correct answer.",
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
      help_text="Instruction, competency and human observation; Journal, linked practice and workshop controls.",
      completion="Manual Journal observation is reachable; no automated completion, grading or rewards for physical observation.", gaps=["activity_evidence_workflow"],
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
      conditions="Visible Core action when assistance is allowed; specialized checked payload or bounded task_card. Assessment screens suppress this assistance entry. Separate native Activity.",
      help_text="Marks assistance; same bound task after return.", completion="Cannot submit answers or award progress.",
      adapters=["NativeLearningActivity", "LearningSceneRequest"], gaps=["native_inline_absent", "async_binding_integration"],
      test_paths=["test/tutoring/native_learning_launch_test.dart", "test/tutoring/native_learning_serialized_contract_test.dart"])
route("scene_place_value", "Stellenwert-Szenenvertrag", "lib/features/learning/scenes/learning_scene_contract.dart",
      CORE, "PlaceValue", "core", ["placeValue"],
      status="contract_consumed_by_core_not_standalone_route",
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
      HOME, "LumoPhotoLessonScreen(", "photo", ["ocr_input", "checked_practice_launch"],
      help_text="Scan analysis prepares checked tasks; the dedicated practice route handles answers and staged assistance.", completion="Scanning itself grants no assessed answer.",
      adapters=["PhotoLessonPractice", "PhotoLessonSession", "ScannedWorkAnalysisEngine"], gaps=[],
      test_paths=["test/photo_lesson_practice_test.dart", "test/photo_lesson_subject_flow_test.dart"])
route("photo_practice", "Foto-Lernheft: tatsächliche Übungen", "lib/features/photo_lesson/photo_lesson_practice_screen.dart",
      "lib/features/photo_lesson/lumo_photo_lesson_screen.dart", "PhotoLessonPracticeScreen(", "photo",
      ["checked_adaptive_answer", "writing_attempt", "editable_confirmed_proposal"],
      help_text="Staged local hints and bound repeat/slower/stop; current-task editable proposals require confirmation.",
      completion="Profile-owned resumable PhotoLessonSession; exact answer/assistance evidence and explicit continuation.",
      adapters=["AdaptiveTaskRenderer", "PhotoLessonSession", "LumoCompanionTaskContext"],
      test_paths=["test/photo_lesson_learning_flow_test.dart", "test/photo_lesson_session_test.dart"])
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
      status="legacy_fallback_not_reached_by_current_catalog_dispatch",
      conditions="Only the final _openTopic fallback constructs this screen. Current unit-card and filtered-tool callers exit through specialist/protected/Core/CrossGrade paths; a constructor reference alone is not an active route.",
      completion="Topic chat/answer generation only: no local TaskResult, accepted-answer storage or reward authority.",
      gaps=["conversation_domain_binding"])
ROUTES[-1]["currentAssessedTaskRoute"] = False
ROUTES[-1]["dispatchReview"] = {
    "method": "Reviewed current callers and catalog branches; not a runtime tour.",
    "unitCaller": source(ACADEMY, "void _beginClearLearningTask("),
    "unitCallerCondition": "Calls _openTopic only after a non-null AcademyTopicUnits.exerciseUnit matches the selected unit. Current subjects then exit via their existing local/protected routes.",
    "toolsCaller": source(ACADEMY, "Widget _tools()"),
    "currentToolsTopicIds": ["d1_schreibcoach", "d1_buchstaben_alle", "d1_woerter", "d2_artikel", "d4_aufsatz"],
    "toolsCondition": "Every current filtered tool has an earlier writing/module/cross-grade return. enableWordMode=true selects the protected word coach; false would select registered WortDiktat, not Teacher.",
    "dispatcher": source(ACADEMY, "void _openTopic("),
    "topicMapping": source("lib/core/curriculum/academy_topic_units.dart", "static String? exerciseUnit("),
    "chatOnlyImplementation": source("lib/features/teacher_mode/lumo_teacher_screen.dart", "Future<void> _ask("),
}
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
route("game:learning_round", "Gemeinsame Lernspiel-Aufgabenfläche", "lib/features/games/mini_games/mini_game_learning_screen.dart",
      "lib/features/games/mini_games/stars_path_game.dart", "MiniGameLearningScreen(", "gameLevel",
      CATALOG["enums"]["GameMiniType"], conditions="49 minigame levels; level 50 dispatches to Quizshow first.",
      help_text="Per-task construction/choice input, scoped proposals, staged help and paused round checkpoints.",
      completion="Existing MiniGameRound and GameProgressRepository plus owner-bound reward callback; original-route and joined native-boundary runs are recorded separately from final release QA.",
      adapters=["MiniGameLearningTask", "MiniGameRound", "GameProgressRepository"],
      gaps=["game_interaction_coverage"])
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
      help_text="Current-question coach with local method hint, repeat/slower/stop and confirmed card selection. The original check button evaluates; the chest retains its three-consecutive-correct rule.",
      gaps=["flame_grade_scope", "game_interaction_coverage"],
      test_paths=["test/games/flame_adventure_flow_test.dart", "test/games/flame_adventure_round_test.dart"])

GAPS = [
    ("spatial3d_task_integration", "implemented_connections_specialization_and_device_limits", "learning + native scene owners", "Visible task-bound native entries and canonical handoffs are implemented. Many tasks use an exact generic task_card; dedicated spatial manipulatives are not supplied for every family. Targeted mocked-native tests are distinct from complete physical-device/actor interaction proof."),
    ("device_qa", "open", "All", "No current Android/Fold hardware, rotation, audio/mic, large text and 60 FPS sweep across all routes. Widget tests are not hardware proof."),
    ("sentence_answer_leak", "reproduced_open", "c5 renderer owner", "The committed c5 renderer now derives neutral sentence cards from the prompt. The dedicated three-case privacy regression is recorded separately; old baseline failures are historical."),
    ("all_families_interaction", "shared_workflow_implemented_variants_not_exhaustive", "learning integration", "All eight subjects of the 236 catalog families have hub definitions and current-grade unit cards. Loaded Core tasks use the common coach/native entry; specialist/protected dispatch takes precedence where mapped. This is shared workflow coverage, not 236 individually specialized and exhaustively exercised workspaces."),
    ("domain_boundary", "closed_source_contract_implemented", "learning integration", "The canonical bus validates task identity, allowed actions, exam policy and named objects. Proposals remain ungraded until explicit owner confirmation. Existing deterministic checks partly reside in renderer/screen code; that file organization is not missing AI/native authority isolation or a reward API."),
    ("direct_family_selection", "navigation_implemented_exhaustive_ui_run_pending", "navigation integration", "Lesen and Rechtschreibung have actual hub subject entries and normal unit cards. Active speech reading is an additional button. Exact unit dispatch exists; no claim that every one of the 236 family selections and generated variants has been executed in a UI tour."),
    ("module_context_help", "open", "specialist module owner", "All 18 active specialist screens have current-task bindings, staged help and explicit candidate confirmation; 19 actual Academy entry routes were exercised. d1_woerter remains protected and shadowed."),
    ("activity_evidence_workflow", "manual_observation_workflow_implemented", "activities owner", "All 60 practical entries include a reachable Journal observation link; some also link checked digital practice or a native workshop. Automatic physical-observation grading and a formal teacher-submission workflow are not implemented or claimed; manual observation is intentional."),
    ("reference_pattern_scene", "partially_closed", "Chat2/c5", "Six lab modes include the actual pattern workbench and a visible native entry for the exact current task_card. Supported core tasks can additionally use the checked period/sequence/choices pattern adapter; the Lab entry does not claim a specialized native pattern manipulative."),
    ("native_inline_absent", "known_architecture_limit", "Chat1", "Separate Godot activity exists; no inline native platform view in every Flutter task."),
    ("async_binding_integration", "partially_verified", "Chat1 + conversation", "Canonical bus requests are integrated across the reviewed learning surfaces, including the delivered Live/Flame/question coach and Lab native entry. Recorded targeted tests do not establish the final complete Root suite or real microphone lifecycle."),
    ("scene_kind_coverage", "older_director_scope_not_global_native_limit", "scene integration", "Only the older Flutter LearningSceneDirector contract declares placeValue alone. The separate current NativeLearningActivity adapter has 12 descriptor kinds including task_card. The older enum is neither an unconnected current route nor a system-wide one-scene limit; visual enums still do not establish specialized native scenes."),
    ("microphone_runtime", "open", "conversation owner", "Recognition permission, mishearing/correction, stop/pause and actual audio playback require current runtime proof."),
    ("story_all_variants", "dynamic_variant_verification_limit", "story integration", "Story reader, tasks and scoped coach are integrated. Dynamic stored/generated stories cannot be inferred exhaustively from the finite quest catalog; this is a verification boundary, not a missing story connection."),
    ("photo_interactive_answers", "open", "photo integration", "Photo practice now collects and deterministically checks actual responses, stores resumable profile-owned evidence and requires confirmation of editable speech proposals."),
    ("conversation_domain_binding", "closed_not_applicable_to_current_assessed_routes", "conversation owner", "Current learning coaches have canonical task bindings. This legacy inventory entry describes the final Teacher topic-chat fallback: current unit/tool callers do not reach it, and it has no local scored-task/result/reward path. It does not establish an active assessed task without a binding."),
    ("live_participation_vs_mastery", "intentional_evidence_semantics", "live integration", "Delivered Live confirmation keeps the existing word/photo participation and safari matching policy. These records are intentionally distinct from independently verified curriculum mastery; the distinction is not an unimplemented coach connection."),
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
    non_task = (row["authorityRef"] == "none" and identifier not in {"native_explanation", "deutsch_legacy_gap"}) or identifier == "scene_place_value"
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
        "proofStatus": "not_an_independent_task_route" if non_task else "not_proven_in_this_snapshot",
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
    row["directUnitNavigation"] = "source_hub_unit_card_and_exact_dispatch"
    row["dispatchCondition"] = "Matching specialist/protected route first; otherwise Core or voluntary CrossGrade practice. Active reading is an additional route, not the only Lesen entry."
    row["individualFamilyUiTourProven"] = False
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
    final_quiz = row["effectiveRoute"] == "quiz"
    attach([row], "quiz" if final_quiz else game_routes[row["miniType"]],
           "lib/domain/games/game_level_catalog.dart", "quiz" if final_quiz else "gameLevel")
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
    protected.append({**source(relative),
                      "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                      "baselineSha256": hashlib.sha256(baseline).hexdigest(),
                      "unchangedFromBase": path.read_bytes() == baseline})
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
    "schema": "lumo.nextgen.learning.coverage", "version": 2,
    "asOf": "2026-11-15",
    "exportedAtUtc": datetime.now(timezone.utc).isoformat(),
    "sourceBaseline": BASE,
    "localSourceHead": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "scope": {
        "fullModernizationComplete": False, "allTaskVariantsReviewed": False,
        "inventoryMethod": "Executed finite Dart catalogs plus reviewed route dispatch, authority sources and import graph. File hashes fix the actual source snapshot.",
        "inventoryEntrySemantics": "The compatibility field 'routes' contains reviewed inventory entries: active/conditional screens, navigation, contracts, protected routes, and inactive legacy paths. Its length is not a count of currently reachable assessed tasks.",
        "excluded": ["Kart", "native Jungle/Dschungel"],
        "protected": "Writing trainer and journal internals; outer adapters only.",
        "nonCurriculumGames": "Memory, Connect Four, Dice Race and Star Trail retain game rules/rewards; no independent curriculum-answer task is claimed here.",
        "parallelOwnership": "Integrated Root snapshot. Delivered owner and Root checkpoints are recorded separately from their test logs and final release/device gates. No foreign worktree WIP is silently treated as delivered source.",
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
        "missingGeneralAttachments": [],
    },
    "modernComponents": [
        {"name": "LumoLearningModuleFrame", "source": FRAME, "capabilities": ["shared responsive chrome", "calm/reduced motion", "context-bound help"], "limit": "Frame appearance is separate from ModuleTaskScope/Plus task ownership; the latter has an actual 19-route confirmation test."},
        {"name": "Learning manipulatives", "source": "lib/features/learning/lab/learning_manipulatives.dart", "capabilities": ["quantity bridge", "fraction construction", "token ordering", "48dp semantic actions"], "limit": "Six-mode lab and specific task workspaces; not a specialized native model for every curriculum family."},
        {"name": "Schoolbook task widgets", "source": "lib/features/schoolbook/widgets/schoolbook_task_widgets.dart", "capabilities": ["word cards", "quantity/number models", "shared lesson cards"], "limit": "Shared passive cards and actual interactive workspaces are distinct. Sentence-card privacy is fixed and separately rechecked."},
        {"name": "LearningSceneDirector", "source": "lib/features/learning/scenes/learning_scene_contract.dart", "capabilities": ["revision", "allowed inputs", "named objects"], "limit": "Only placeValue scene kind is declared."},
    ],
    "gaps": [{"id": i, "status": s, "owner": o, "description": d} for i, s, o, d in GAPS],
    "verification": {},
    "sourceScreenInventory": screen_inventory,
    "protectedSourceHashes": protected,
    "readOnlyBranchComparisons": comparisons,
    "sources": sorted(SOURCES.values(), key=lambda row: row["path"]),
}

# Evidence is read from actual logs. A stored passing run is deliberately not
# promoted to a new run against HEAD, nor summed with overlapping test suites.
EVIDENCE_ROOT = "docs/nextgen/evidence/"
RUN_SPECS = [
    ("module_connections", "chat2_completion_20261115/module_tests.log",
     "owner_sources_integrated", "f23688e76904da9e373ba998843c0bbe41906542", [
         "test/design/all_learning_module_routes_test.dart",
         "test/learning/module_coach_confirmation_test.dart",
         "test/design/learning_adventure_layout_test.dart",
         "test/learning_modules/math_module_progress_test.dart",
         "test/learning_modules/deutsch_sach_module_progress_test.dart",
     ]),
    ("core_guided", "chat2_completion_20261115/core_tests.log",
     "owner_sources_integrated", "daa3e2d867a7de307c721c1f38faff2effe0845e", [
         "test/learning/learning_content_commands_test.dart",
         "test/tutoring/guided_coach_binding_test.dart",
         "test/tutoring/native_learning_launch_test.dart",
         "test/tutoring/guided_lesson_runtime_test.dart",
         "test/tutoring/guided_ten_frame_playback_test.dart",
     ]),
    ("lab_core", "chat2_core_20261115/core_tests.log",
     "earlier_targeted_integration", "24ef7e5d85d142c06ebdb5290bbc06efafa618b6", [
         "test/learning/money_clock_truth_test.dart",
         "test/learning/lumo_quantity_workbenches_test.dart",
         "test/learning/nextgen_lab_boards_test.dart",
         "test/learning_lab_manipulatives_test.dart",
         "test/learning_lab_catalog_test.dart",
         "test/learning_lab_progress_test.dart",
         "test/learning_lab_runtime_test.dart",
         "test/learning_modules/math_module_progress_test.dart",
         "test/learning_modules/deutsch_sach_module_progress_test.dart",
         "test/learning/resumable_lesson_reset_test.dart",
         "test/tutoring/tutor_parent_reset_test.dart",
         "test/design/learning_adventure_layout_test.dart",
         "test/learning/nextgen_lab_bus_integration_test.dart",
         "test/design/all_learning_module_routes_test.dart",
     ]),
    ("reading", "reading_integration_20261115/tests.log",
     "root_targeted_integration", None, [
         "test/reading_buddy_assessment_test.dart",
         "test/reading_active_sentence_view_test.dart",
         "test/reading_writing_content_test.dart",
         "test/lumo_assessment_reading_contract_test.dart",
     ]),
    ("reading_audio_owner", "reading_audio_owner_20261115/tests.log",
     "owner_sources_integrated", "88fcffdd91ea717a5080ad8d61b94fac81191758", [
         "test/reading_audio_owner_regression_test.dart",
         "test/reading_buddy_assessment_test.dart",
         "test/story_entry_navigation_test.dart",
     ]),
    ("photo_thinking", "root_joined_20261115/root-photo-thinking-integrated-tests.log",
     "root_targeted_integration", None, []),
    ("speech_boundary", "root_joined_20261115/root-integrated-stt-check.log",
     "root_targeted_integration", None, []),
    ("native_boundary", "root_joined_20261115/joined-native-boundary-tests-final.log",
     "root_targeted_integration", None, []),
    ("assessment", "assessment-contract/flutter-tests.log",
     "earlier_targeted_integration", None, []),
    ("pattern_navigation", "c5_integration_20261115/integration_tests.log",
     "earlier_targeted_integration", None, []),
    ("minigame_original_routes", "remaining_integration_20261115/mini_game_routes_initial.log",
     "root_original_routes_before_native_followup", None, ["test/games/mini_games_flow_test.dart"]),
    ("lab_native", "lab_native_20261115/tests.log",
     "owner_sources_integrated", "6757f8c2b0758519c44c3606215f2f4fae3fc5a5", [
         "test/learning/lab_native_entry_test.dart",
         "test/learning/nextgen_lab_bus_integration_test.dart",
         "test/learning_lab_runtime_test.dart",
         "test/learning_lab_catalog_test.dart",
     ]),
    ("remaining_native_joined", "remaining_integration_20261115/remaining_native_joined.log",
     "root_targeted_integration_before_final_narrowing", "b193899565110e5c7a26f73520a943b261887e63", []),
    ("game_question_coach", "docs/evidence/lumo-nextgen-game-questions/focused-tests.log",
     "owner_sources_integrated", "ca3f48ef961b4a50e95c6dffca2785d818191842", []),
    ("catalog_export", "coverage_refresh_20261115/catalog_export.log",
     "current_inventory_snapshot", HEAD, ["tools/nextgen/export_learning_catalog_test.dart"]),
    ("sentence_privacy", "coverage_refresh_20261115/sentence_privacy.log",
     "current_inventory_snapshot", HEAD, ["test/learning/sentence_prompt_privacy_test.dart"]),
]


def commit_for_file(path: str) -> str | None:
    value = subprocess.check_output(
        ["git", "log", "-1", "--format=%H", "--", path], cwd=ROOT, text=True).strip()
    return value or None


def read_run(identifier, suffix, scope, tested_commit, explicit_tests):
    path = suffix if suffix.startswith("docs/") else EVIDENCE_ROOT + suffix
    try:
        raw_log = source_bytes(path)
    except FileNotFoundError:
        return {"id": identifier, "status": "log_missing", "log": path,
                "executionScope": scope, "tests": explicit_tests}
    if scope == "current_inventory_snapshot":
        manifest_path = EVIDENCE_ROOT + "coverage_refresh_20261115/runs.json"
        if (ROOT / manifest_path).exists():
            source(manifest_path)
            recorded = next((run for run in json.loads((ROOT / manifest_path).read_text())["runs"]
                             if run["id"] == identifier), None)
            tested_commit = recorded["sourceHead"] if recorded else None
        else:
            tested_commit = None
        if tested_commit != HEAD:
            scope = "previous_inventory_snapshot"
    content = raw_log.decode(errors="replace").replace("\r", "\n")
    matches = re.findall(
        r"\+(\d+)(?:\s+-(\d+))?:[^\n]*?(All tests passed!|Some tests failed\.)", content)
    if not matches:
        return {"id": identifier, "status": "no_completed_result", "log": source(path),
                "executionScope": scope, "tests": explicit_tests}
    passed, failed, verdict = matches[-1]
    logged_tests = set(re.findall(r"(?<![\w])(?:test|tools)/[^\s:\x1b]+\.dart", content))
    test_paths = sorted(set(explicit_tests) | {
        path for path in logged_tests if (ROOT / path).exists()
    })
    for test_path in test_paths:
        source(test_path)
    return {"id": identifier, "status": "passed" if verdict == "All tests passed!" else "failed",
            "passed": int(passed), "failed": int(failed or 0),
            "log": source(path), "logSha256": SOURCES[path]["sha256"],
            "logStorageCommit": commit_for_file(path),
            "executionSourceCommit": tested_commit,
            "executionSourceCommitMeaning": "Post-run source checkpoint, where explicitly known; null is not inferred from the log storage commit.",
            "executionScope": scope, "tests": test_paths,
            "testListCompleteFromRecordedCommand": bool(explicit_tests),
            "androidDeviceRun": False, "realMicrophoneRun": False,
            "currentHeadSuiteRerun": scope == "current_inventory_snapshot"}


runs = [read_run(*spec) for spec in RUN_SPECS]
run_by_id = {run["id"]: run for run in runs}
run_by_id["lab_native"]["integratedAt"] = "a12c0376ba67872c75758fe340734810cb527456"
run_by_id["remaining_native_joined"]["postRunSourceCaveat"] = (
    "The 35-test log precedes one additional safe rejection of case-normalized duplicate choices "
    "in the same delivery. Final CI must rerun the exact integrated source; the earlier interrupted fixture is superseded.")
run_by_id["game_question_coach"].update({
    "integratedAt": "3123d3247775fcdc42a16c2bcc5c51e1ab98c4c9",
    "producerEvidenceCommit": "749de5603d86c45a60ff7e34ef9e69a03fb974d9",
    "rootEvidenceCommit": "9a8aca5196100d6aabb8bc41d827f2ed0e3577e4",
    "limits": "Controlled speech/native transports and logical Flutter viewports; no real microphone, Android FPS or physical Fold proof.",
})

# Use the reviewed module manifest as an assertion, not as stale prose. Every
# current screen hash must still equal the delivered/134-test source snapshot.
module_manifest_path = "docs/nextgen/MODULE_CONNECTIONS.json"
source(module_manifest_path)
module_manifest = json.loads((ROOT / module_manifest_path).read_text())
module_by_route = {}
for module in module_manifest["modules"]:
    source(module["file"])
    if SOURCES[module["file"]]["sha256"] != module["sha256"]:
        raise ValueError(f"Module changed since verified manifest: {module['file']}")
    for identifier in module["routeIds"]:
        module_by_route["module:" + identifier] = module

SCOPE = "lib/features/learning/nextgen/module_task_scope.dart"
READING_COACH = "lib/features/reading/reading_lesson_companion.dart"
QUESTION_COACH = "lib/features/learning/widgets/learning_question_coach.dart"
MINI_GAME = "lib/features/games/mini_games/mini_game_learning_screen.dart"
EXAM_SCOPE = "lib/features/tests/iq/exam_companion_scope.dart"
COACH_BINDING = "lib/features/learning/nextgen/learning_coach_binding.dart"
NATIVE = "lib/domain/tutoring/native_learning_activity.dart"
BUS = "lib/widgets/fox/lumo_companion_requests.dart"
CONTRACT = "lib/core/lumo_learning_session_contract.dart"
for path in [SCOPE, READING_COACH, QUESTION_COACH, MINI_GAME, EXAM_SCOPE,
             COACH_BINDING, BUS, CONTRACT]:
    source(path)

# These are reviewed adapter edges. The constructor must occur in the actual
# consumer. An imported helper or factory by itself never becomes a UI entry.
ADAPTER_EDGES = [
    ("ModuleTaskScope(", SCOPE),
    ("ReadingLessonCompanion(", READING_COACH),
    ("LearningQuestionCoach(", QUESTION_COACH),
    ("MiniGameLearningScreen(", MINI_GAME),
    ("ExamCompanionScope(", EXAM_SCOPE),
]

# The explicit confirmation controls are inventoried independently of the bus.
# Their presence is source evidence; the recorded tests retain their own scope.
CONFIRM_CONTROLS = {
    CORE: ("learning-answer-candidate", "learning-confirm-candidate"),
    "lib/features/tutoring/guided_lesson_screen.dart": ("guided-candidate-edit", "guided-confirm-candidate"),
    "lib/features/learning/lab/learning_lab_screen.dart": ("lab-answer", "lab-check-answer"),
    SCOPE: ("$keyPrefix-answer-candidate", "$keyPrefix-confirm-candidate"),
    "lib/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart": ("LearningAnswerCandidateCard(", "_boundCandidateConfirmation("),
    READING_COACH: ("reading-lumo-candidate", "reading-lumo-confirm"),
    "lib/features/learning/cross_grade_practice_screen.dart": ("cross-grade-answer-proposal", "cross-grade-proposal-confirm"),
    "lib/features/photo_lesson/photo_lesson_practice_screen.dart": ("photo-answer-proposal", "_confirmProposal"),
    "lib/features/story/lumo_story_reader_screen.dart": ("story-answer-proposal-text", "story-confirm-answer-proposal"),
    MINI_GAME: ("mini-game-answer-proposal", "mini-game-proposal-confirm"),
    QUESTION_COACH: ("game-answer-proposal", "_confirm"),
}

CHILD_TASK_ROUTES = {
    "photo": ["photo_practice"], "quest": ["story_reader"],
    "tests": ["core"], "teacher_assignments": ["core"],
}

EXTRA_ROUTE_TESTS = {
    "core": ["test/learning/learning_content_commands_test.dart"],
    "guided": ["test/tutoring/guided_coach_binding_test.dart", "test/tutoring/guided_ten_frame_playback_test.dart"],
    "lab": ["test/learning/nextgen_lab_bus_integration_test.dart", "test/learning/nextgen_lab_boards_test.dart", "test/learning/lab_native_entry_test.dart"],
    "iq": ["test/iq/nextgen_thinking_flow_test.dart"],
    "cognitive": ["test/iq/nextgen_thinking_flow_test.dart"],
    "game:learning_round": ["test/games/mini_games_flow_test.dart"],
    "cross_grade": ["test/learning/cross_grade_contract_test.dart", "test/learning/remaining_native_entry_test.dart"],
    "photo_practice": ["test/learning/remaining_native_entry_test.dart"],
    "story_reader": ["test/story_nextgen_flow_test.dart", "test/learning/remaining_native_entry_test.dart"],
    "live": ["test/live_pro_question_coach_test.dart", "test/feature_permission_regression_test.dart", "test/games/learning_question_coach_lifecycle_test.dart"],
    "flame_learning": ["test/games/flame_question_coach_test.dart", "test/games/learning_question_coach_lifecycle_test.dart"],
    "cards_learning": ["test/games/learning_question_coach_flow_test.dart", "test/games/learning_question_coach_lifecycle_test.dart"],
    "quiz": ["test/games/learning_question_coach_flow_test.dart", "test/games/learning_question_coach_lifecycle_test.dart"],
}


def effective_sources(row):
    result = [row["target"]["path"]]
    text = (ROOT / result[0]).read_text()
    for constructor, path in ADAPTER_EDGES:
        if path != result[0] and constructor in text:
            result.append(path)
            source(path)
    return result


def actual_native_entry(path):
    text = (ROOT / path).read_text()
    if not re.search(r"\bscene:\s*['\"]learning['\"]", text):
        return None
    if "launchLumo3D(" not in text or "NativeLearningActivity." not in text:
        return None
    keys = re.findall(r"['\"]([^'\"\n]*(?:open-3d|lumo-world)[^'\"\n]*)['\"]", text)
    if not keys and "Mit Lumo in 3D" not in text:
        return None
    symbol = keys[0] if keys else "Mit Lumo in 3D"
    factories = sorted(set(re.findall(r"NativeLearningActivity\.([a-zA-Z]+)\(", text)))
    return {"status": "source_button_and_launch_connected", "source": source(path, symbol),
            "buttonKeys": sorted(set(keys)), "factories": factories,
            "scene": "learning", "inline": False,
            "androidRuntimeVerified": False,
            "doesNotProveAllFamiliesSpecialized3D": True}


capabilities = []
for row in ROUTES:
    identifier = row["id"]
    if identifier in module_by_route:
        module = module_by_route[identifier]
        row["help"] = "Current-task staged help; repeat does not advance the hint; hiding help retains assisted evidence."
        row["adapters"].append("LearningCoachBinding" if identifier == "module:m1_plus10" else "ModuleTaskScope")
        row["reachable"]["status"] = "source_reachable_and_recorded_widget_entry_pass"
        row["reachable"]["recordedRunRefs"] = ["module_connections"]
        row["tests"] += tests("test/design/all_learning_module_routes_test.dart",
                              "test/learning/module_coach_confirmation_test.dart")
        row["gaps"] = [gap for gap in row["gaps"] if gap != "module_context_help"]
    row["tests"] += tests(*EXTRA_ROUTE_TESTS.get(identifier, []))
    seen = set()
    row["tests"] = [test for test in row["tests"] if not (test["path"] in seen or seen.add(test["path"]))]
    for test in row["tests"]:
        refs = [run["id"] for run in runs if run["status"] == "passed" and test["path"] in run["tests"]]
        if refs:
            test["status"] = "passed_in_recorded_targeted_run"
            test["recordedRunRefs"] = refs
            test["currentSnapshotRerun"] = any(run_by_id[ref]["currentHeadSuiteRerun"] for ref in refs)
    paths = effective_sources(row)
    texts = {path: (ROOT / path).read_text() for path in paths}
    binding_paths = [path for path, text in texts.items()
                     if "LearningCoachBinding(" in text or
                     ("LumoCompanionRequests" in text and
                      ("publishTask(" in text or "learningAction.addListener" in text))]
    candidate_controls = []
    for path in paths:
        if path in CONFIRM_CONTROLS:
            edit, confirm = CONFIRM_CONTROLS[path]
            if edit in texts[path] and confirm in texts[path]:
                candidate_controls.append({"editable": source(path, edit),
                                           "confirm": source(path, confirm)})
    native_entries = [entry for path in paths if (entry := actual_native_entry(path))]
    is_exam = identifier in {"tests", "iq", "cognitive"}
    not_task = row["authorityRef"] == "none" and identifier not in {"native_explanation", "deutsch_legacy_gap"}
    protected_route = row["authorityRef"] == "protectedWriting" or identifier == "module:d1_woerter"
    policy = "assessment_limited_repeat_slower_stop_no_hint_or_answer_proposal" if is_exam else (
        "protected_internal_surface" if protected_route else
        "not_a_separate_assessed_task" if not_task else "owner_checked_practice")
    if identifier == "core":
        policy = "practice_help_and_proposals_only; assessment_gates_remove_help_and_proposal"
    cap = {
        "routeRef": identifier, "effectiveSources": paths,
        "childTaskRouteRefs": CHILD_TASK_ROUTES.get(identifier, []),
        "canonicalTaskBinding": {"status": "source_connected" if binding_paths else "not_detected_in_reviewed_route_adapter",
                                 "sources": [source(path) for path in binding_paths]},
        "answerProposal": {"status": "visible_editable_explicit_confirmation_source" if candidate_controls else
                           "disabled_by_assessment_policy" if is_exam else "not_detected_in_reviewed_route_adapter",
                           "controls": candidate_controls, "authorityRef": row["authorityRef"],
                           "unconfirmedProposalIsCorrectAnswer": False},
        "policy": policy,
        "stagedHelp": {"status": "source_level_bound" if any("helpLevel:" in text for text in texts.values()) and not is_exam else
                       "disabled_by_assessment_policy" if is_exam else "see_route_help_and_authority",
                       "doesNotProveEveryHintContentReviewed": True},
        "actions": {"referencedCanonicalActions": sorted({action for text in texts.values()
                    for action in re.findall(r"LumoLearningAction\.([a-zA-Z]+)", text)}),
                    "taskDefinesAllowedActions": any("allowedActions:" in text for text in texts.values()),
                    "stopHandlerSourcePresent": any("case LumoLearningAction.stop:" in text or "onStop:" in text for text in texts.values()),
                    "referencesAreNotAnEffectivePermissionList": True},
        "accessibility": {"minimum48dpEntry": "recorded_module_route_test" if identifier in module_by_route else "not_measured_for_every_control",
                          "calmOrReducedMotionSourceTokens": sorted({token for text in texts.values()
                              for token in ("reduceMotion", "reduceAnimations", "quietMode", "_quiet", "_calm") if token in text}),
                          "completeAccessibilityAudit": False},
        "nativeLearningEntry": {"status": "source_connected" if native_entries else
                                "not_applicable_assessment_assistance" if is_exam else
                                "protected_or_navigation" if protected_route or not_task else
                                "no_learning_scene_button_in_snapshot",
                                "entries": native_entries,
                                "factoryAvailabilityAloneCountsAsReachable": False},
        "lifecycle": {"sourceObserverPresent": any("didChangeAppLifecycleState(" in text for text in texts.values()),
                      "nativePauseAndCandidateTests": "module_connections" if identifier in module_by_route else
                      "core_guided" if identifier in {"core", "guided"} else "see_recorded_route_tests",
                      "physicalFoldResizeProven": False},
        "recordedTestRunRefs": sorted({ref for test in row["tests"] for ref in test.get("recordedRunRefs", [])}),
        "completeTaskBound3DProven": False,
    }
    if identifier in module_by_route:
        cap["verifiedModuleManifest"] = module_manifest_path
        cap["verifiedModuleSourceHashMatches"] = True
    if native_entries:
        row["spatial3D"]["currentRendering"] = "flutter_surface_with_reachable_optional_native_learning_activity"
    if identifier in {"native_explanation", "scene_place_value"}:
        cap["nativeLearningEntry"]["status"] = "descriptor_only_see_core_and_other_consuming_routes"
    if identifier == "teacher_conversation":
        cap["canonicalTaskBinding"]["status"] = "not_applicable_inactive_legacy_topic_chat"
        cap["answerProposal"]["status"] = "no_current_assessed_task_or_result_authority"
        cap["nativeLearningEntry"]["status"] = "not_applicable_inactive_legacy_topic_chat"
    if identifier in CHILD_TASK_ROUTES and not is_exam:
        cap["nativeLearningEntry"]["status"] = "see_child_task_route_not_a_direct_button_on_this_screen"
        cap["nativeLearningEntry"]["childTaskRouteRefs"] = CHILD_TASK_ROUTES[identifier]
    row["capabilityRef"] = identifier
    row["spatial3D"]["requirementsNotYetFullyProvenEndToEnd"] = row["spatial3D"].pop("needed")
    capabilities.append(cap)

document["capabilityMatrix"] = capabilities
document["capabilityMatrixMethod"] = (
    "Reviewed source adapter edges, asserted constructor/control symbols and scene:'learning' launch. "
    "Source-connected is not runtime proof. A game's own native table, a factory-only API, navigation, "
    "or an imported helper is not counted as a native learning button. Recorded runs retain their own scope.")
hub_subjects = sorted(set(re.findall(r"_Subject\(\s*'([^']+)'", source_bytes(HUB).decode())))
family_subjects = sorted({row["subject"] for row in CATALOG["curriculumFamilies"]})
document["familyNavigation"] = {
    "catalogSubjectNames": family_subjects,
    "hubSubjectNames": hub_subjects,
    "missingHubSubjectNames": sorted(set(family_subjects) - set(hub_subjects)),
    "unitCards": source(HUB, "Widget _unitCard("),
    "exactDispatch": source(ACADEMY, "void _beginClearLearningTask("),
    "semantics": "Current-grade catalog units have hub cards; mapped specialist/protected routes take precedence, then Core or voluntary CrossGrade. The extra active-reading button does not replace Lesen unit selection.",
    "everyFamilyUiTourProven": False,
    "everyFamilySpecializedNativeModelProven": False,
}

module_adapter_checks = []
# Pin the delivered bytes, so a fresh remote checkout does not need the
# producer's local-only resolver commit object to reproduce the comparison.
module_adapter_hashes = {
    SCOPE: "4f291593257e70468add023ba448ca8fe2ee071d9bc7feae421bff5c026eec3c",
    COACH_BINDING: "15d92d3249953cfe3e5a062cb0372642eef11690b13da12eb36424bbab5fa8a8",
}
for path, delivered_hash in module_adapter_hashes.items():
    module_adapter_checks.append({"source": source(path),
                                  "recordedDeliveryCommit": "f23688e76904da9e373ba998843c0bbe41906542",
                                  "deliveredSha256": delivered_hash,
                                  "sameBytesAsRecordedDelivery": delivered_hash == SOURCES[path]["sha256"]})

native_text = (ROOT / NATIVE).read_text()
actual_kinds = sorted(set(re.findall(r"NativeLearningActivity\._\(\s*'([^']+)'", native_text)))
document["nativeCompatibility"]["kinds"] += [
    {"kind": "pattern", "entry": "fromTask/fromPattern", "condition": "Checked period/sequence/choices and expected continuation; c5 payload contract, not patternUnit."},
    {"kind": "task_card", "entry": "forTask/fromCompanionContext", "condition": "Bounded exact task prompt, explanation and at most eight choices; no answer/reward field. Companion contexts refuse exams and empty task/prompt."},
]
assert {row["kind"] for row in document["nativeCompatibility"]["kinds"]} == set(actual_kinds)
document["nativeCompatibility"].update({
    "actualKindNames": actual_kinds,
    "kindCount": len(actual_kinds),
    "acceptance": "Specialized adapters verify local payloads; forTask falls back to bounded task_card. The caller must enforce assessment/help policy. A descriptor never awards progress and does not itself establish a visible route entry.",
    "missingGeneralAttachments": [cap["routeRef"] for cap in capabilities
                                  if cap["nativeLearningEntry"]["status"] == "no_learning_scene_button_in_snapshot"],
    "genericTaskCardIsSpecializedSubjectManipulation": False,
})

gap_updates = {
    "sentence_answer_leak": ("closed_recorded_regression" if run_by_id["sentence_privacy"]["status"] == "passed" else "verification_pending", "learning integration", "Neutral prompt-derived cards; the recorded three-case privacy regression covers assessment and hidden-solution mutation. Its executionSourceCommit remains separate from the newest export HEAD."),
    "module_context_help": ("closed_source_and_recorded_widget_runs", "learning integration", "18 active specialist screens / 19 Academy routes: 17 ModuleTaskScope screens plus Plus10; current-task help, visible editable candidate, explicit confirmation and native task_card entry. All current screen hashes match the 134-test delivery manifest."),
    "photo_interactive_answers": ("closed_source_and_recorded_targeted_run", "photo integration", "PhotoLessonPracticeScreen checks actual responses, supports confirmed proposals and profile-owned resumable sessions; scanning/reveal alone grants no correct answer. Its direct native entry is included in the recorded 35-test joined run; final exact-source/device verification remains separate."),
    "reference_pattern_scene": ("partially_closed", "learning/native integration", "All six Lab modes, including the pattern workbench, now have a visible native button for their exact current task_card. The 24-test Lab run checks six entries, pause/return, ungraded candidates, Stop and per-problem assistance. This generic card is not a specialized native pattern manipulative; the separate checked pattern adapter uses period/sequence/choices."),
    "async_binding_integration": ("partially_verified", "Root + conversation", "Recorded tests cover Core/Guided native return, all 19 module entries, Lab native lifecycle, Reading/Photo and the delivered Live/Flame/question coach. The added 24/35/56-test runs are targeted evidence, not a final full-Root or physical microphone result."),
    "game_interaction_coverage": ("partially_verified", "Root + conversation", "49 MiniGame levels use the shared checked task/round surface; level 50 dispatches to Quiz. The 35-test joined run supersedes the interrupted native fixture. The integrated question coach, Cards/Quiz, real Flame callbacks and Live final-transcript confirmation have a separate 56-test passing run. All generated variants and final device behavior remain outside that claim."),
    "flame_grade_scope": ("content_selection_review_open", "learning game integration", "The actual Flame question/chest callbacks and unchanged three-answer streak are tested. The generator still selects from fixed early-grade unit lists; the 56-test coach run does not establish every higher-grade/template fallback."),
}
for gap in document["gaps"]:
    if gap["id"] in gap_updates:
        status, owner, description = gap_updates[gap["id"]]
        gap.update(status=status, owner=owner, description=description)
document["gaps"] += [
    {"id": "conversation_followup", "status": "closed_source_and_recorded_targeted_run", "owner": "conversation", "description": "Live, 2D Flame and the shared Cards/Quiz coach native entry are integrated in 3123d3247775fcdc42a16c2bcc5c51e1ab98c4c9. Producer ca3f48ef961b4a50e95c6dffca2785d818191842 and evidence 749de5603d86c45a60ff7e34ef9e69a03fb974d9 supply the recorded 56-test run; final current-Root/device QA is separate."},
    {"id": "native_entry_followup", "status": "closed_source_and_recorded_targeted_runs", "owner": "Root", "description": "CrossGrade, Photo, Story and MiniGame direct native entries and scoped handoffs have a recorded 35-test joined run in b193899565110e5c7a26f73520a943b261887e63. Lab adds six exact task_card entries with 24 recorded tests in a12c0376ba67872c75758fe340734810cb527456. One safe duplicate-choice narrowing followed the 35-test run; final CI must check the exact integrated source."},
    {"id": "avatar_reference_followup", "status": "pinned_native_visual_device_review", "owner": "avatar + Root", "description": f"Published native source is pinned to {NATIVE_PUBLISHED_PIN}. This Flutter inventory does not itself prove the final Banane/card-overlap appearance, physical Fold behavior or device performance; no outstanding source delivery is inferred from that missing runtime proof."},
    {"id": "performance_device_gate", "status": "not_satisfied", "owner": "Root", "description": "Reported desktop measurement is 8 FPS, not evidence of 60 FPS. Physical Fold resize/rotation and real microphone operation are unproven."},
]
finding_classes = {
    "spatial3d_task_integration": "implemented_connection_with_specialization_and_device_limits",
    "all_families_interaction": "shared_workflow_and_variant_verification_limit",
    "domain_boundary": "implemented_authority_contract",
    "direct_family_selection": "implemented_navigation_ui_coverage_limit",
    "activity_evidence_workflow": "intentional_manual_observation_workflow",
    "reference_pattern_scene": "generic_native_entry_specialization_limit",
    "native_inline_absent": "intentional_architecture_boundary",
    "scene_kind_coverage": "older_contract_scope_not_global_native_gap",
    "conversation_domain_binding": "inactive_non_assessed_legacy_fallback",
    "live_participation_vs_mastery": "intentional_evidence_semantics",
    "protected_internal_scope": "protected_or_excluded_scope",
    "word_dictation_shadowed": "intentional_current_feature_dispatch",
    "legacy_gap_ambiguity": "unreachable_legacy_content_needs_review_before_enablement",
    "legacy_gap_owner": "unreachable_legacy_writer_needs_review_before_enablement",
    "device_qa": "physical_runtime_evidence_pending",
    "microphone_runtime": "physical_runtime_evidence_pending",
    "performance_device_gate": "physical_runtime_evidence_pending",
    "avatar_reference_followup": "pinned_native_visual_runtime_evidence_pending",
    "story_all_variants": "dynamic_variant_verification_limit",
    "flame_grade_scope": "content_selection_verification_limit_not_confirmed_failure",
    "async_binding_integration": "implemented_targeted_tests_final_integration_evidence_pending",
    "game_interaction_coverage": "implemented_targeted_tests_variants_and_device_evidence_pending",
}
for gap in document["gaps"]:
    gap["classification"] = finding_classes.get(gap["id"],
        "implemented_with_recorded_evidence" if gap["status"].startswith(("closed_", "fixed_")) else "review_specific_status")
document["findingSemantics"] = (
    "'gaps' is a compatibility name for classified findings, not a blanket list of missing functions. "
    "Read classification/status to separate implemented connections, specialized-model limits, intentional "
    "architecture/protection, inactive legacy code and unproven variant/device behavior.")
closed_ids = {gap["id"] for gap in document["gaps"] if gap["status"].startswith(("closed_", "fixed_"))}
for row in ROUTES:
    row["resolvedGapRefs"] = [gap for gap in row["gaps"] if gap in closed_ids]
    row["gaps"] = [gap for gap in row["gaps"] if gap not in closed_ids]
for row in TYPE_COVERAGE:
    row["gaps"] = next(route["gaps"] for route in ROUTES if route["id"] == row["routeRef"])

document["counts"].update({
    "reviewedInventoryEntries": len(ROUTES),
    "reviewedRoutes": len(ROUTES), "screenInventoryFiles": len(screen_inventory),
    "activeSpecialistScreens": len(module_manifest["modules"]),
    "activeSpecialistRoutes": len(module_by_route),
    "protectedShadowedRegistryRoutes": 1,
    "labModes": len(CATALOG["enums"]["LabMode"]),
    "labProblemIds": sum(len(topic["problems"]) for topic in CATALOG["labTopics"]),
    "miniGameLevels": sum(level["effectiveRoute"] == "mini_game" for level in CATALOG["gameLevels"]),
    "quizFinalLevels": sum(level["effectiveRoute"] == "quiz" for level in CATALOG["gameLevels"]),
    "nativeKinds": len(actual_kinds), "protectedByteIdenticalFiles": len(protected),
    "quizDeclaredQuestionIds": len(quiz_ids),
    "cardsBankItems": sum(bundle["count"] for bundle in bundles),
})
document["countSemantics"] = {
    "reviewedInventoryEntries": "All reviewed entries, including contracts/navigation, protected, conditional and inactive legacy paths; not a live-task route total.",
    "reviewedRoutes": "Compatibility alias of reviewedInventoryEntries; never all currently reachable assessed routes.",
    "activeSpecialistRoutes": "Actual specialist Academy entries with recorded widget route checks; separate from the general inventory count.",
}
assert document["counts"]["miniGameLevels"] + document["counts"]["quizFinalLevels"] == len(CATALOG["gameLevels"])
assert len(protected) == 18

product_changes = subprocess.check_output(
    ["git", "status", "--porcelain", "--", "lib", "assets", "android", "pubspec.yaml", "pubspec.lock"],
    cwd=ROOT, text=True).strip()
if product_changes:
    raise SystemExit("Commit/review product source before inventory export; current product worktree is dirty:\n" + product_changes)
document["sourceSnapshot"] = {
    "committedProductHead": HEAD, "productWorkingTreeClean": True,
    "catalogSourceHead": CATALOG["sourceHead"],
    "rawCatalogSha256": hashlib.sha256(CATALOG_PATH.read_bytes()).hexdigest(),
    "exporter": source("tools/nextgen/export_learning_catalog_test.dart"),
    "builder": source("tools/nextgen/build_coverage.py"),
    "publishedNativeSourcePin": NATIVE_PUBLISHED_PIN,
    "finalReleaseSourceCommit": None,
    "releaseStatus": "Root supplies final release SHA, APK provenance and CI/device results after integration.",
}
document["verification"] = {
    "recordedRuns": runs,
    "uniquePassedTestTotal": None,
    "totalNotSummedReason": "Runs overlap and have different source scopes. The counts are separate evidence, not a unique full-suite total.",
    "fullCurrentRootSuitePassed": False,
    "protectedSourceCheck": {"baseline": BASE, "files": len(protected), "byteIdentical": True},
    "moduleScreenManifestHashesMatch": True,
    "moduleAdapterSourceChecks": module_adapter_checks,
    "nativePlatformChannelTestsAreMocked": True,
    "coordinationReports": [
        {"id": "c5_joined_historical", "source": "Root coordination message and remaining-integration README", "status": "historical_failure_superseded_by_targeted_runs", "passed": 44, "failed": 5, "supersededBy": ["remaining_native_joined", "game_question_coach"], "detail": "Four obsolete MiniGame UI expectations plus one Coach compile failure. Preserve history without treating it as the latest test result."},
        {"id": "minigame_ui_followup", "source": "Committed mini_game_routes_initial.log", "status": "recorded_pass", "recordedRunRef": "minigame_original_routes", "passed": 6, "failed": 0, "levelIds": [42, 7, 2, 25, 13], "detail": "Actual original-route task completion, wallet and reopen without duplicate reward. The subsequent native-entry run is recorded separately as remaining_native_joined."},
        {"id": "native_entry_joined_fixture", "source": "Root coordination message and remaining-integration README", "status": "historical_interruption_superseded", "exitCode": 130, "reportedOtherCompletedTests": 27, "supersededBy": "remaining_native_joined", "detail": "The original fixture was intentionally stopped, then corrected; the later 35-test passing run is the targeted evidence. Neither is a full final Root suite."},
        {"id": "desktop_performance", "source": "Root coordination message", "measuredFps": 8, "targetFps": 60, "targetProven": False, "isPhysicalAndroidDevice": False},
    ],
    "openReleaseGates": ["final_exact_source_post_run_narrowing_check",
                         "pinned_native_visual_device_review", "joined_current_root_suite",
                         "measured_60fps", "physical_fold_resize_rotation", "real_microphone_audio_lifecycle",
                         "final_signed_apk_source_pin_and_ci"],
    "hardware": {"physicalFoldVerified": False, "realMicrophoneVerified": False,
                 "allRoutes60FpsVerified": False, "allRoutesAndroidTourVerified": False},
}


def markdown(doc):
    counts = doc["counts"]
    lines = [
        "# Lernabdeckung – belegter integrierter Quellstand", "",
        f"**Produkt-Snapshot: `{HEAD}`. `fullModernizationComplete` bleibt `false`.**",
        "Diese Matrix inventarisiert den ausgeführten Dart-Katalog, Einstiegsketten, fachliche Antwortgrenzen und vorhandene Testprotokolle. Ihre Einträge umfassen aktive und bedingte Lernwege, Navigation, Verträge, geschützte sowie inaktive Legacy-Pfade; ihre Gesamtzahl ist keine Zahl aktuell erreichbarer bewerteter Aufgaben. Sie ist keine Geräte- oder Releasefreigabe. [COVERAGE.json](COVERAGE.json) enthält IDs, Quellenhashes, klassifizierte Einträge, Typen, Adapter und Nachweisgrenzen.", "",
        "## Tatsächlich erfasster Umfang", "",
        "| Bestand | Umfang |", "|---|---:|",
        f"| Geprüfte Inventareinträge / Screen-Dateien | {len(ROUTES)} / {len(screen_inventory)} |",
        f"| Klassen-/Fach-/Einheitskombinationen | {counts['curriculumFamilies']} |",
        f"| Mathe- / Deutsch-Templates | {counts['mathTemplates']} / {counts['germanTemplates']} |",
        f"| Akademie-Themen | {counts['academyTopics']} |",
        f"| Registry / aktive Modul-Einstiege / aktive Modul-Screens | {counts['registeredModuleIds']} / {counts['activeSpecialistRoutes']} / {counts['activeSpecialistScreens']} |",
        f"| Praktische Aktivitäten | {counts['practicalActivities']} |",
        f"| Lernlabor-Modi / feste Problem-IDs | {counts['labModes']} / {counts['labProblemIds']} |",
        f"| Geführte Lektionen | {counts['guidedLessons']} |",
        f"| Lernspielkatalog / MiniGame-Level / abschließendes Quiz-Level | {counts['gameLevels']} / {counts['miniGameLevels']} / {counts['quizFinalLevels']} |",
        f"| Reading-Buddy-Texte / feste Quests | {counts['readingTexts']} / {counts['quests']} |",
        f"| Kognitive Fragen / deklarierte Quiz-IDs / Kartenbank-Einträge | {counts['cognitiveQuestions']} / {counts['quizDeclaredQuestionIds']} / {counts['cardsBankItems']} |",
        f"| Native Adapter-Kinds / bytegleiche geschützte Dateien | {counts['nativeKinds']} / {counts['protectedByteIdenticalFiles']} |", "",
        "Die sechs Labormodi sind **bridge, word, english, nature, fraction, pattern**. `d1_woerter` bleibt durch den geschützten Wort-Schreibcoach überlagert; die zwei Einmaleins-Einstiege teilen einen Screen. Level 50 öffnet gemäß `GamesContent` das Quiz und ist kein MiniGame-Level. Dynamische Aufgabenvarianten und gespeicherte Geschichten haben keine vollständige endliche ID-Liste; `routeRef` und `sourceIndex` sind Dokumentationsschlüssel.", "",
        "Die acht Fächer der 236 Katalogfamilien sind im aktuellen Hub vorhanden, einschließlich **Lesen und Rechtschreibung**. Themenkarten rufen die exakte Einheit über `_beginClearLearningTask` auf; passende Spezial-/Schreibmodule haben Vorrang, danach folgen Core oder freiwilliges CrossGrade. Aktives Vorlesen ist ein zusätzlicher Einstieg. Für eine im Core geladene Übungsaufgabe bestehen gemeinsamer Coach und sichtbarer Native-Einstieg, soweit Hilfe erlaubt ist. Daraus folgt weder eine fehlende Anbindung aller Familien noch eine vollständige spezialisierte 3D-/Geräteabnahme jeder Variante.", "",
        "## Anschlüsse und ihre Grenzen", "",
        "| Lernfläche | Aktueller Quellstand und belegte Grenze |", "|---|---|",
        "| Reguläre Aufgaben | Kanonischer Kontext, gestufte Hilfe, bearbeitbarer Sprachkandidat und explizite Prüfung; sichtbarer Native-Einstieg mit `forTask` und begrenzter `task_card`-Rückfallebene. Prüfungsmodi sperren Hilfe und Vorschläge. |",
        "| 18 Fachmodule / 19 Einstiege | 17 `ModuleTaskScope`-Screens plus Plus10; fachlicher bestehender Antwortcallback, Bestätigung der aktuellen Aufgabe, native `task_card`-Schaltfläche. Alle Screen-Hashes stimmen mit der 134-Test-Lieferung überein. Das ist kein eigener räumlicher Fachmodell-Nachweis für jedes Modul. |",
        "| Lernlabor | Alle sechs Modi besitzen `lab-open-3d` für die exakte aktuelle native `task_card`. 24 Tests prüfen unter anderem sechs Einstiege, Hilfe vor I/O, native Pause/Rückkehr, ungewerteten Kandidaten, Stop und unverdeckte Schrittbindung. Die vorhandenen Lab-Modelle bleiben die Fachautorität; kein eigener nativer Manipulativ-Renderer je Modus. |",
        "| Geführte Lektionen | Aktueller Schritt, gestufte Hilfe, bestätigungspflichtiger Kandidat, native spezielle Szene oder `task_card`. Native-Rückkehr, Pause und veraltete Bestätigungen sind im gezielten Lauf enthalten. |",
        "| Lesen / Reading Buddy | Gemeinsamer `ReadingLessonCompanion`, native Lernschaltfläche, getrennte Lese-/Verständnisbewertung; ein früherer 25-Test-Lauf und separat 23 Tests zum aktuellen Audio-Owner-Nachtrag. Überlappende Tests werden nicht addiert. Echtes Mikrofon und Gerät bleiben offen. |",
        "| Foto-Lernheft | OCR führt in `PhotoLessonPracticeScreen`; echte Antworten, bestätigte Vorschläge und `PhotoLessonSession`. Anzeigen/Scannen allein vergibt keine richtige Antwort. Der direkte Native-Einstieg gehört zum aufgezeichneten gemeinsamen 35-Test-Lauf. |",
        "| Story / Quiz / Cards / 49 MiniGame-Level | Eigene Fach-/Controllergrenzen bleiben bestehen. Die direkten Story-/MiniGame-Native-Einstiege sind im 35-Test-Lauf enthalten. Der integrierte Quiz-/Cards-Coach hat einen sichtbaren nativen Aufgaben-Einstieg; Coach-Auswahl, bestehende Fachprüfung und Belohnungsgrenzen werden im separaten 56-Test-Lauf geprüft. |",
        "| IQ / kognitives Profil | `ExamCompanionScope`: begrenzte Wiederholen/Langsamer/Stopp-Aktionen; keine Lösungshilfe oder KI-Antwortvorgabe im Test. Keine diagnostische Standardisierung behauptet. |",
        "| Praxisaufträge | 60 vorhandene Aktivitäten mit erreichbarem Einstieg „Beobachtung im Journal festhalten“, teilweise ergänzter digitaler Übung oder Werkstatt. Die menschliche Beobachtung wird bewusst nicht automatisch gewertet; ein eigener formaler Lehrer-Abgabeablauf wird nicht behauptet. |",
        "| Live / 2D Flame | Gelieferter gemeinsamer Coach mit nativer Aufgabenkarte und bestätigungspflichtigen Vorschlägen. Der 56-Test-Lauf umfasst echte Flame-Frage-/Truhen-Callbacks sowie Live-Finaltranskript, Stop, Modus-/Profilwechsel und Berechtigungsgrenzen. Teilnahme-/Safari-Bewertung bleibt von geprüfter Fachleistung getrennt; keine neue Physik- oder reale Mikrofontour behauptet. |", "",
        f"Die **{len(actual_kinds)} nativen Kinds** lauten: " + ", ".join(f"`{kind}`" for kind in actual_kinds) + ".",
        "`pattern` verwendet den geprüften `period/sequence/choices`-Vertrag. Die generische `task_card` trägt begrenzten Prompt und Auswahlmöglichkeiten ohne Lösungs-/Belohnungsfeld. Eine Factory, eine importierte Klasse oder der eigene native Spieltisch beweist keinen erreichbaren Lernbutton. `capabilityMatrix` verlangt passende Verbraucher, sichtbare Steuerung und `scene: 'learning'`; eine getrennte optionale Activity beweist außerdem keine vollständige aufgabengebundene 3D-Modernisierung.", "",
        "## Bedeutung der klassifizierten Befunde", "",
        "- **Implementiert:** Der kanonische Bus prüft Aufgabenidentität, erlaubte Aktionen, Prüfungsgrenzen und Objektkennungen. Ein Sprachvorschlag bleibt bis zur Owner-Bestätigung ungewertet. Dass bestehende deterministische Vergleiche teilweise in Renderer-/Screen-Dateien stehen, bedeutet keine fehlende Autoritätsgrenze.",
        "- **Architektur und Spezialisierung:** Das alleinige `placeValue` im älteren Flutter-Director begrenzt nicht die zwölf aktuellen nativen Descriptor-Kinds. Exakte generische Karten, spezialisierte Manipulative und vollständige Gerätebelege sind getrennte Aussagen.",
        "- **Inaktiver Teacher-Restfallback:** Die einzige Konstruktion von `LumoTeacherScreen` steht am Ende von `_openTopic`. Der aktuelle Unit-Caller ruft ihn nur nach vorhandener Einheitszuordnung auf; die aktuellen Atelier-Werkzeuge werden vorher durch Schreibcoach, Buchstabenschreiben, Wortcoach/Registry, Artikel oder Aufsatz abgefangen. Dieser Themenchat besitzt keinen lokalen TaskResult-/Antwort-/Belohnungspfad und ist kein aktuell erreichbarer bewerteter Lernweg ohne kanonische Bindung.",
        "- **Schutz und Nachweisgrenzen:** Geschützte Schreib-/Journalinternas, eingeschränkte Prüfungshilfe sowie die Trennung von Live-Teilnahme und Fachleistung sind beabsichtigt. Noch nicht durchgespielte Varianten oder nicht physisch gemessene Geräteabläufe sind keine allein aus dem Inventar ableitbaren Funktionsfehler. JSON-Feld `gaps` bleibt aus Kompatibilität bestehen; `classification` und `status` bestimmen seine Bedeutung.", "",
        "## Aufgezeichnete Prüfungen", "",
        "Die folgenden Zahlen stammen aus den eingecheckten oder mit dieser Matrix neu erzeugten Protokollen. Unterschiedliche Quellstände und überlappende Suiten werden nicht zu einer vermeintlichen Gesamtsumme addiert. `logStorageCommit` ist getrennt vom ausdrücklich bekannten Ausführungsstand erfasst.", "",
        "| Lauf | Ergebnis | Ausführungsumfang | Protokoll |", "|---|---:|---|---|",
    ]
    for run in runs:
        log_path = run["log"]["path"] if isinstance(run["log"], dict) else run["log"]
        result = f"{run.get('passed', '?')} bestanden / {run.get('failed', '?')} fehlgeschlagen" if run["status"] in {"passed", "failed"} else run["status"]
        lines.append(f"| `{run['id']}` | {result} | `{run['executionScope']}` | [{Path(log_path).name}]({relpath(log_path, 'docs/nextgen')}) |")
    lines += ["",
        "Die Satz-Privacy-Neuprüfung ersetzt die alte Behauptung eines offenen Lösungslecks. Unverknüpfte Testdateien tragen `present_no_recorded_run_matched`; verknüpfte Dateien `passed_in_recorded_targeted_run`. Beide Zustände sind von einem frischen vollständigen Root-Lauf getrennt.", "",
        "## Sichtbar offene Freigaben", "",
        "- Der frühere C5-Lauf 44/5 und die abgebrochene erste native Fixture bleiben Fehlerhistorie. Der korrigierte gemeinsame Native-Lauf hat **35/35**, der gelieferte Frage-Coach **56/56**, der neue Lab-Anschluss **24/24** aufgezeichnete Erfolge. Sie ersetzen die alten Pending-Aussagen für diese gezielten Bereiche, ergeben zusammen aber keinen vollständigen aktuellen Root-Testlauf.",
        "- Die 35-Test-Lieferung `b193899565110e5c7a26f73520a943b261887e63` enthält nach diesem Lauf noch eine enge Ablehnung mehrdeutiger normalisierter Auswahlwerte. Die finale CI muss deshalb den exakten integrierten Quellstand einschließlich dieser Verschärfung prüfen. Live, 2D Flame und der Quiz-/Cards-Coach sind in `3123d3247775fcdc42a16c2bcc5c51e1ab98c4c9` integriert; ihre Producer-/Test-Provenienz ist im JSON getrennt erfasst.",
        f"- Der veröffentlichte native Quell-Pin lautet **`{NATIVE_PUBLISHED_PIN}`**. Dieser Flutter-Bestand allein belegt nicht die finale Banane-/Kartenoptik auf einem Gerät. Die gemeldete Desktopmessung beträgt **8 FPS**; sie belegt keine 60 FPS. Physischer Fold, Rotation/Größenwechsel, reale Mikrofon-/Audioabläufe und die vollständige Android-Tour sind offen.",
        "- Die alten Deutsch-Lückensätze bleiben ohne App-Einstieg, weil mehrdeutiger Inhalt und direkte Belohnungsbuchung noch überprüft werden müssen. Exakte UI-Auswahl aller 236 Generatorfamilien und jede generierte Variante sind nicht durchgespielt.",
        f"- **18 geschützte Schreib-/Journaldateien sind bytegleich** zu `{BASE}`; Einzelhashes stehen in JSON. Kart und nativer Dschungel bleiben ausgeschlossen. Der eigenständige 2D-Flame-Lernpfad bleibt im Inventar.",
        "- Finaler Release-SHA, signierte APK-Provenienz, CI-Ergebnis und Download werden von Root nach Integration ergänzt. Aus dieser Bestandsaufnahme folgt keine neue APK-Freigabe.", "",
        "## Reproduktion", "", "```bash",
        "flock --close /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \\",
        "  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test --no-pub \\",
        "  tools/nextgen/export_learning_catalog_test.dart \\",
        "  --dart-define=LUMO_CATALOG_OUTPUT=/tmp/lumo-learning-catalog.json",
        "python3 tools/nextgen/build_coverage.py /tmp/lumo-learning-catalog.json", "```", "",
        "Der Builder verweigert einen Katalog mit abweichendem HEAD, uncommittete Produktquellen und veränderte verifizierte Modul-Screen-Hashes. Der neue Produktstand muss daher zuerst integriert und erneut exportiert werden. Quellen, Testprotokolle und Teamberichte haben bewusst unterschiedliche Evidenzstufen.", "",
    ]
    return "\n".join(lines)

for component in document["modernComponents"]:
    source(component["source"])
document["sources"] = sorted(SOURCES.values(), key=lambda row: row["path"])
output = ROOT / "docs/nextgen/COVERAGE.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n")
(output.parent / "COVERAGE.md").write_text(markdown(document))
print(json.dumps({"output": str(output), "reviewedInventoryEntries": len(ROUTES),
                  "screenFiles": len(screen_inventory), "sources": len(SOURCES),
                  "counts": document["counts"], "modernizationComplete": False}, ensure_ascii=False))
