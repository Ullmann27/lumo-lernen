class StabilityCheckResult {
  const StabilityCheckResult({
    required this.ok,
    required this.messages,
  });

  final bool ok;
  final List<String> messages;
}

class StabilityMonitor {
  const StabilityMonitor();

  StabilityCheckResult checkRuntimeAssumptions({
    required bool hasShell,
    required bool hasLumoStage,
    required bool hasContent,
    required bool hasFallbackAssets,
  }) {
    final messages = <String>[];
    if (!hasShell) messages.add('AppShell fehlt oder wurde umgangen.');
    if (!hasLumoStage) messages.add('Lumo-Bühne ist nicht sichtbar.');
    if (!hasContent) messages.add('MainContent ist leer.');
    if (!hasFallbackAssets) messages.add('Asset-Fallbacks fehlen.');
    if (messages.isEmpty) messages.add('Stabilitätscheck bestanden.');
    return StabilityCheckResult(ok: messages.length == 1 && messages.first.contains('bestanden'), messages: messages);
  }
}
