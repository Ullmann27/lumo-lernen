import 'ai_task_cache.dart';
import 'app_settings.dart';
import 'learning_profile_engine.dart';
import 'lumo_ai_proxy_client.dart';
import 'school_exercise_generator.dart';
import 'task_quality_guard.dart';

/// Nachhilfelehrer-Service.
///
/// Liest Schwaechen aus dem LearningProfileEngine, fragt den Lumo-Proxy
/// nach passenden Aufgaben und legt sie im AiTaskCache ab. Wird beim
/// App-Start oder Subject-Eintritt aufgerufen, NICHT bei jeder Aufgabe.
///
/// Pruefung "darf ich generieren?" erfolgt vor jedem Aufruf:
///   - aiProxyEnabled muss true sein
///   - Cache muss < refillThreshold unverbrauchte Aufgaben haben
///   - letzte Generierung > 6 Stunden her ODER Cache leer
///
/// Damit wird verhindert, dass jeder App-Start Geld kostet.
class AiTutorService {
  const AiTutorService({
    LumoAiProxyClient client = const LumoAiProxyClient(),
    AiTaskCache cache = const AiTaskCache(),
  })  : _client = client,
        _cache = cache;

  final LumoAiProxyClient _client;
  final AiTaskCache _cache;

  static const int _refillThreshold = 5; // unter 5 unverbraucht -> nachladen
  static const int _batchSize = 12;
  static const Duration _minRefillGap = Duration(hours: 6);
  static const TaskQualityGuard _guard = TaskQualityGuard();

  /// Generiert bei Bedarf einen Aufgaben-Vorrat fuer das Subject.
  /// Fire-and-forget aufrufbar - kein Crash bei Fehler.
  Future<AiTutorRefillResult> refillIfNeeded({
    required AppSettings settings,
    required LearningProfileEngine profile,
    required String childId,
    required String childName,
    required int grade,
    required String subject,
  }) async {
    if (!settings.aiProxyEnabled) {
      return const AiTutorRefillResult(skipped: true, reason: 'proxy_disabled');
    }
    final fresh = await _cache.freshCount(childId: childId, subject: subject);
    if (fresh >= _refillThreshold) {
      return AiTutorRefillResult(skipped: true, reason: 'cache_full', freshAfter: fresh);
    }
    final lastAt = await _cache.lastGeneratedAt(childId: childId, subject: subject);
    if (lastAt != null && fresh > 0) {
      final gap = DateTime.now().difference(lastAt);
      if (gap < _minRefillGap) {
        return AiTutorRefillResult(skipped: true, reason: 'too_soon', freshAfter: fresh);
      }
    }
    // Schwaechen abfragen - Nachhilfelehrer-Logik
    final weaknesses = profile.weaknessesBySubject();
    final unitsForSubject = weaknesses[subject] ?? <String>[];
    final drafts = await _client.fetchTaskBatch(
      settings: settings,
      subject: subject,
      grade: grade,
      units: unitsForSubject,
      count: _batchSize,
      childName: childName,
    );
    final safeDrafts = drafts
        .where((draft) => _guard.validate(_probeTask(draft, grade, subject, unitsForSubject)))
        .toList(growable: false);
    if (safeDrafts.isEmpty) {
      return const AiTutorRefillResult(skipped: false, reason: 'batch_empty', generated: 0);
    }
    await _cache.saveBatch(
      childId: childId,
      subject: subject,
      drafts: safeDrafts,
    );
    final freshAfter = await _cache.freshCount(childId: childId, subject: subject);
    return AiTutorRefillResult(
      skipped: false,
      reason: 'refilled',
      generated: safeDrafts.length,
      freshAfter: freshAfter,
      focusedUnits: unitsForSubject,
    );
  }

  static LumoTask _probeTask(
    LumoAiTaskDraft draft,
    int grade,
    String subject,
    List<String> focusedUnits,
  ) {
    return LumoTask(
      id: 'ai_probe',
      grade: grade,
      subject: subject,
      unit: focusedUnits.isEmpty ? 'KI Nachhilfe' : focusedUnits.first,
      prompt: draft.prompt,
      answer: draft.answer,
      choices: draft.choices,
      explanation: draft.explanation.isEmpty ? 'Lumo erklärt dir das gleich Schritt für Schritt.' : draft.explanation,
      visual: draft.visual,
      difficulty: grade,
    );
  }

  /// Liefert die naechste verfuegbare Aufgabe aus dem Cache.
  /// Markiert sie sofort als verbraucht.
  Future<LumoAiTaskDraft?> takeNext({
    required String childId,
    required String subject,
  }) async {
    final fresh = await _cache.loadFresh(childId: childId, subject: subject);
    if (fresh.isEmpty) return null;
    final next = fresh.first;
    await _cache.markConsumed(
      childId: childId,
      subject: subject,
      prompt: next.prompt,
    );
    return next;
  }
}

class AiTutorRefillResult {
  const AiTutorRefillResult({
    required this.skipped,
    required this.reason,
    this.generated = 0,
    this.freshAfter = 0,
    this.focusedUnits = const <String>[],
  });

  final bool skipped;
  final String reason;
  final int generated;
  final int freshAfter;
  final List<String> focusedUnits;
}
