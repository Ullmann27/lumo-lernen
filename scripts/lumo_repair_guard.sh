#!/usr/bin/env bash
set -euo pipefail

echo "== Lumo Zero-Defect Repair Guard =="

fail() {
  echo "REPAIR-GUARD-FAIL: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [ -f "$path" ] || fail "Missing required file: $path"
  echo "ok file: $path"
}

require_text() {
  local path="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$path" || fail "Missing connection in $path: $pattern"
  echo "ok connection: $path -> $pattern"
}

require_absent() {
  local path="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$path"; then
    fail "Forbidden fragile path in $path: $pattern"
  fi
  echo "ok absent: $path -> $pattern"
}

mkdir -p assets/images assets/videos dist

require_file pubspec.yaml
require_file lib/main.dart
require_file lib/app/app_shell.dart
require_file lib/app/app_state.dart
require_file lib/features/home/home_content.dart
require_file lib/features/learning/learning_content.dart
require_file lib/features/learning/renderers/adaptive_task_renderer.dart
require_file lib/features/reading/reading_content.dart
require_file lib/features/settings/settings_content.dart
require_file lib/features/agent/lumo_agent_content.dart
require_file lib/widgets/shell/left_navigation.dart
require_file lib/widgets/shell/lumo_stage_panel.dart
require_file lib/core/lumo_voice.dart
require_file lib/core/lumo_speech_listener.dart
require_file lib/core/ai_tutor_service.dart
require_file lib/core/lumo_tutor_engine.dart
require_file lib/core/reading_v2_pronunciation_analyzer.dart

require_text pubspec.yaml "assets/images/"
require_text pubspec.yaml "assets/videos/"
require_text lib/main.dart "WidgetsFlutterBinding.ensureInitialized()"
require_text lib/main.dart "runApp(const LumoApp())"
require_text lib/main.dart "try {"
require_text lib/main.dart "profile = null"
require_text lib/main.dart "AppShell(profile: _profile)"

require_text lib/app/app_shell.dart "HomeContent(appState: _appState"
require_text lib/app/app_shell.dart "LumoAkademieScreen(appState: _appState)"
require_text lib/app/app_shell.dart "LearningContent(appState: _appState)"
require_text lib/app/app_shell.dart "ReadingContent(appState: _appState"
require_text lib/app/app_shell.dart "SettingsContent(appState: _appState)"
require_text lib/app/app_shell.dart "LumoAgentContent(appState: _appState"
require_text lib/app/app_shell.dart "ParentalGate.show(context)"
require_text lib/app/app_shell.dart "ScanScreen("

require_text lib/app/app_state.dart "loadLearningProfile"
require_text lib/app/app_state.dart "recordLearningAnswer"
require_text lib/app/app_state.dart "analyzeScannedWork"
require_text lib/app/app_state.dart "wrongAnswer"
require_text lib/app/app_state.dart "errors >= 2"

require_text lib/features/learning/learning_content.dart "AiTutorService"
require_text lib/features/learning/learning_content.dart "LumoTutorEngine"
require_text lib/features/learning/learning_content.dart "AdaptiveTaskRenderer("
require_text lib/features/learning/learning_content.dart "_buildTutorHint"
require_text lib/features/learning/learning_content.dart "_localTutorEngine.buildLocalFallback"
require_text lib/features/learning/learning_content.dart "_allowHelp"

require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_LocalHelpBanner"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_ObjectMathVisual"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_emojiForPrompt"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_operationFromTask"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "VisualType.dots"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "QuantityDotsVisual"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "wrongAnswers"

require_text lib/features/reading/reading_content.dart "ReadingV2PronunciationAnalyzer"
require_text lib/features/reading/reading_content.dart "LumoSpeechListener"
require_text lib/features/reading/reading_content.dart "ReadingActiveSentenceView"
require_text lib/features/reading/reading_content.dart "_speech.startListening"
require_text lib/features/reading/reading_content.dart "_speech.cancel()"
require_text lib/features/reading/reading_content.dart "_speech.dispose()"
require_text lib/features/reading/reading_content.dart "_listenTimer?.cancel()"

require_absent .github/workflows/android-debug-apk.yml "actions/upload-artifact"
require_absent .github/workflows/android-debug-apk.yml "CreateArtifact"
require_text .github/workflows/android-debug-apk.yml "Repair guard"
require_text .github/workflows/android-debug-apk.yml "bash scripts/lumo_repair_guard.sh"

if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  flutter analyze --no-fatal-infos --no-fatal-warnings || true
fi

echo "Zero-Defect Repair Guard finished."
