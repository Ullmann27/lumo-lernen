import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_settings.dart';
import 'school_exercise_generator.dart';

class LumoVisualAid {
  const LumoVisualAid({
    required this.title,
    required this.explanation,
    required this.steps,
    this.imageUrl,
    this.source = 'local_visual',
    this.costly = false,
  });

  final String title;
  final String explanation;
  final List<LumoVisualAidStep> steps;
  final String? imageUrl;
  final String source;
  final bool costly;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}

class LumoVisualAidStep {
  const LumoVisualAidStep({
    required this.caption,
    required this.visual,
  });

  final String caption;
  final String visual;
}

/// Bildhilfe als letzte Hilfe-Stufe.
///
/// Kosten-Schutz:
/// - KI-Bild wird nur geholt, wenn die Aufgabe wirklich bildfähig ist.
/// - Es braucht mehrere Fehlversuche oder eine ausdrückliche Kinder-Aktion.
/// - Ohne Proxy oder bei Fehler wird nur lokale Emoji-/Text-Visualisierung genutzt.
class LumoVisualAidService {
  const LumoVisualAidService();

  static const Duration _timeout = Duration(seconds: 40);

  bool shouldOffer({
    required LumoTask task,
    required int attemptCount,
    required bool allowHelp,
  }) {
    if (!allowHelp) return false;
    if (attemptCount < 2) return false;
    return _isVisualTask(task);
  }

  bool shouldUsePaidImage({
    required LumoTask task,
    required int attemptCount,
    required bool childRequestedImage,
    required AppSettings settings,
  }) {
    if (!settings.aiProxyEnabled) return false;
    if (!_isVisualTask(task)) return false;
    return childRequestedImage || attemptCount >= 3;
  }

  Future<LumoVisualAid> buildAid({
    required LumoTask task,
    required int grade,
    required int attemptCount,
    required AppSettings settings,
    bool childRequestedImage = false,
  }) async {
    final local = _localAid(task, grade: grade);
    if (!shouldUsePaidImage(
      task: task,
      attemptCount: attemptCount,
      childRequestedImage: childRequestedImage,
      settings: settings,
    )) {
      return local;
    }

    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (baseUri == null) return local;

    final endpoint = _visualEndpoint(baseUri);
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(endpoint).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, dynamic>{
        'grade': grade,
        'subject': task.subject,
        'unit': task.unit,
        'prompt': task.prompt,
        'answer': task.answer,
        'explanation': task.explanation,
        'style': 'child_safe_worksheet_visual',
        'creditGuard': <String, dynamic>{
          'reason': childRequestedImage ? 'child_requested_after_help' : 'repeated_wrong_answers',
          'attemptCount': attemptCount,
          'renderOnlyIfUseful': true,
        },
      }));
      final response = await request.close().timeout(_timeout);
      final raw = await response.transform(utf8.decoder).join().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return local;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return local;
      final imageUrl = decoded['imageUrl']?.toString().trim();
      final explanation = decoded['explanation']?.toString().trim();
      if (imageUrl == null || imageUrl.isEmpty) return local;
      return LumoVisualAid(
        title: local.title,
        explanation: explanation == null || explanation.isEmpty ? local.explanation : explanation,
        steps: local.steps,
        imageUrl: imageUrl,
        source: 'proxy_visual_image',
        costly: true,
      );
    } on TimeoutException {
      return local;
    } on SocketException {
      return local;
    } catch (_) {
      return local;
    } finally {
      client.close(force: true);
    }
  }

  LumoVisualAid _localAid(LumoTask task, {required int grade}) {
    final prompt = task.prompt.trim();
    final answer = task.answer.trim();
    final math = _mathVisual(task);
    if (math != null) return math;

    final subject = task.subject.trim().isEmpty ? 'Lernen' : task.subject.trim();
    return LumoVisualAid(
      title: 'Bildhilfe zu $subject',
      explanation: 'Wir machen die Aufgabe sichtbar. Schau zuerst auf die Frage, dann auf die Antwortkarten.',
      steps: <LumoVisualAidStep>[
        LumoVisualAidStep(caption: 'Die Frage ist:', visual: prompt),
        LumoVisualAidStep(caption: 'Die richtige Lösung ist:', visual: answer),
        const LumoVisualAidStep(caption: 'Lumo-Tipp:', visual: 'Erst lesen, dann lautlos erklären, dann antworten.'),
      ],
    );
  }

  LumoVisualAid? _mathVisual(LumoTask task) {
    final prompt = task.prompt;
    final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(prompt);
    if (plus != null) {
      final a = int.tryParse(plus.group(1) ?? '') ?? 0;
      final b = int.tryParse(plus.group(2) ?? '') ?? 0;
      if (a > 0 && b > 0 && a + b <= 20) {
        return LumoVisualAid(
          title: 'Plus als Bild',
          explanation: 'Plus bedeutet: Es kommt etwas dazu. Wir legen die erste Menge hin und legen dann die zweite Menge dazu.',
          steps: <LumoVisualAidStep>[
            LumoVisualAidStep(caption: 'Erste Menge: $a Äpfel', visual: _items(a)),
            LumoVisualAidStep(caption: 'Plus bedeutet: $b Äpfel kommen dazu', visual: '${_items(a)}  +  ${_items(b)}'),
            LumoVisualAidStep(caption: 'Zusammen sind es ${a + b} Äpfel', visual: _items(a + b)),
          ],
        );
      }
    }

    final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(prompt);
    if (minus != null) {
      final a = int.tryParse(minus.group(1) ?? '') ?? 0;
      final b = int.tryParse(minus.group(2) ?? '') ?? 0;
      if (a > 0 && b > 0 && a <= 20 && a - b >= 0) {
        return LumoVisualAid(
          title: 'Minus als Bild',
          explanation: 'Minus bedeutet: Etwas geht weg. Wir starten mit der ganzen Menge und nehmen dann etwas weg.',
          steps: <LumoVisualAidStep>[
            LumoVisualAidStep(caption: 'Am Anfang sind es $a Äpfel', visual: _items(a)),
            LumoVisualAidStep(caption: 'Minus bedeutet: $b Äpfel gehen weg', visual: '${_items(a)}  −  ${_items(b)}'),
            LumoVisualAidStep(caption: 'Übrig bleiben ${a - b} Äpfel', visual: _items(a - b)),
          ],
        );
      }
    }
    return null;
  }

  String _items(int count) {
    if (count <= 0) return '—';
    return List<String>.filled(count.clamp(0, 20).toInt(), '🍎').join(' ');
  }

  bool _isVisualTask(LumoTask task) {
    final subject = task.subject.toLowerCase();
    final prompt = task.prompt.toLowerCase();
    if (subject.contains('mathe') || subject.contains('mathematik')) return true;
    if (prompt.contains('+') || prompt.contains('-') || prompt.contains('wie viele')) return true;
    if (subject.contains('sachunterricht')) return true;
    if (task.unit.toLowerCase().contains('silben')) return true;
    if (task.unit.toLowerCase().contains('uhr') || task.unit.toLowerCase().contains('geld')) return true;
    return false;
  }

  Uri? _validatedBaseUri(String raw) {
    final clean = AppSettings.sanitizeProxyUrl(raw);
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  Uri _visualEndpoint(Uri baseUri) {
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}visual-aid'
        : baseUri.path.isEmpty
            ? '/visual-aid'
            : '${baseUri.path}/visual-aid';
    return baseUri.replace(path: normalizedPath, query: '');
  }
}
