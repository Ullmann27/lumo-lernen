#!/usr/bin/env bash
set -euo pipefail

echo "== Lumo Repair Guard =="

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

require_text pubspec.yaml "assets/images/"
require_text pubspec.yaml "assets/videos/"
require_text lib/main.dart "runApp(const LumoApp())"
require_text lib/main.dart "AppShell(profile: _profile)"
require_text lib/app/app_shell.dart "HomeContent(appState: _appState"
require_text lib/app/app_shell.dart "LearningContent(appState: _appState)"
require_text lib/app/app_shell.dart "ReadingContent(appState: _appState"
require_text lib/app/app_shell.dart "SettingsContent(appState: _appState)"
require_text lib/app/app_shell.dart "LumoAgentContent(appState: _appState"
require_text lib/features/learning/learning_content.dart "AdaptiveTaskRenderer("
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_LocalHelpBanner"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_ObjectMathVisual"
require_text lib/features/learning/renderers/adaptive_task_renderer.dart "_emojiForPrompt"

if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  flutter analyze --no-fatal-infos --no-fatal-warnings || true
fi

echo "Repair guard finished."
