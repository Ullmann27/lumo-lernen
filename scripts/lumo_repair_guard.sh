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

# Dart constructor arguments may span lines and include keys before appState.
require_state_constructor() {
  local path="$1" constructor="$2"
  python3 - "$path" "$constructor" <<'PY_CHECK' || fail "Missing state connection: $path -> $constructor"
import re, sys
from pathlib import Path
source = Path(sys.argv[1]).read_text()
for call in re.finditer(re.escape(sys.argv[2]) + r'\s*\(', source):
    depth = 1
    end = call.end()
    while depth and end < len(source):
        depth += (source[end] == '(') - (source[end] == ')')
        end += 1
    arguments = source[call.end():end - 1]
    if re.search(r'\bappState\s*:\s*_appState\b', arguments):
        raise SystemExit(0)
raise SystemExit(1)
PY_CHECK
  echo "ok state connection: $path -> $constructor"
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
require_text lib/main.dart "AppShell(profile: _profile"

require_state_constructor lib/app/app_shell.dart HomeContent
require_state_constructor lib/app/app_shell.dart LumoAkademieScreen
require_state_constructor lib/app/app_shell.dart LearningContent
require_state_constructor lib/app/app_shell.dart ReadingContent
require_state_constructor lib/app/app_shell.dart SettingsContent
require_state_constructor lib/app/app_shell.dart LumoAgentContent
require_text lib/app/app_shell.dart "_requiresLoadedSettings(section)"
require_absent lib/app/app_shell.dart "ParentalGate"
require_absent lib/core/app_settings.dart "parentPin"
require_absent lib/core/settings_repository.dart "setParentPin"
require_text lib/features/rewards/reward_shop_content.dart "ParentApprovalDialog.show("
if rg -n 'ParentPin|ParentalGate|initialParentPin|parentPin|parentRecoveryCode|requiresParentPin' lib; then
  fail "Obsolete access-code gate remains in active application code"
fi
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
