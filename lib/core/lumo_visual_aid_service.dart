import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

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
    this.themeKey,
  });

  final String title;
  final String explanation;
  final List<LumoVisualAidStep> steps;
  final String? imageUrl;
  final String source;
  final bool costly;
  final String? themeKey;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}

class LumoVisualAidStep {
  const LumoVisualAidStep({required this.caption, required this.visual});
  final String caption;
  final String visual;
}

class _VisualTheme {
  const _VisualTheme({required this.key, required this.single, required this.plural, required this.emoji, required this.plusVerb, required this.minusVerb, required this.context});
  final String key;
  final String single;
  final String plural;
  final String emoji;
  final String plusVerb;
  final String minusVerb;
  final String context;
}

/// Bildhilfe als letzte Hilfe-Stufe mit Credit-Schutz und Abwechslung.
class LumoVisualAidService {
  const LumoVisualAidService({LumoVisualAidMemory? memory}) : _memory = memory ?? const LumoVisualAidMemory();

  static const Duration _timeout = Duration(seconds: 40);
  final LumoVisualAidMemory _memory;

  static const List<_VisualTheme> _themes = <_VisualTheme>[
    _VisualTheme(key: 'stars', single: 'Stern', plural: 'Sterne', emoji: '⭐', plusVerb: 'funkeln dazu', minusVerb: 'verschwinden am Himmel', context: 'Lumo sammelt Sterne.'),
    _VisualTheme(key: 'blocks', single: 'Baustein', plural: 'Bausteine', emoji: '🧱', plusVerb: 'kommen auf den Turm', minusVerb: 'werden vom Turm weggenommen', context: 'Wir bauen einen Turm.'),
    _VisualTheme(key: 'fish', single: 'Fisch', plural: 'Fische', emoji: '🐟', plusVerb: 'schwimmen dazu', minusVerb: 'schwimmen weg', context: 'Im Teich schwimmen Fische.'),
    _VisualTheme(key: 'cars', single: 'Auto', plural: 'Autos', emoji: '🚗', plusVerb: 'fahren dazu', minusVerb: 'fahren weg', context: 'Auf dem Parkplatz stehen Autos.'),
    _VisualTheme(key: 'flowers', single: 'Blume', plural: 'Blumen', emoji: '🌼', plusVerb: 'wachsen dazu', minusVerb: 'werden gepflückt', context: 'Auf der Wiese wachsen Blumen.'),
    _VisualTheme(key: 'balloons', single: 'Ballon', plural: 'Ballons', emoji: '🎈', plusVerb: 'kommen dazu', minusVerb: 'fliegen weg', context: 'Beim Fest gibt es Ballons.'),
    _VisualTheme(key: 'books', single: 'Buch', plural: 'Bücher', emoji: '📘', plusVerb: 'kommen ins Regal', minusVerb: 'werden aus dem Regal genommen', context: 'Im Regal stehen Bücher.'),
    _VisualTheme(key: 'cookies', single: 'Keks', plural: 'Kekse', emoji: '🍪', plusVerb: 'kommen auf den Teller', minusVerb: 'werden gegessen', context: 'Auf dem Teller liegen Kekse.'),
    _VisualTheme(key: 'bees', single: 'Biene', plural: 'Bienen', emoji: '🐝', plusVerb: 'fliegen dazu', minusVerb: 'fliegen zur Blume weg', context: 'Bei Lumo summen Bienen.'),
    _VisualTheme(key: 'gems', single: 'Schatzstein', plural: 'Schatzsteine', emoji: '💎', plusVerb: 'kommen in die Schatzkiste', minusVerb: 'werden herausgenommen', context: 'In der Schatzkiste liegen Steine.'),
  ];

  bool shouldOffer({required LumoTask task, required int attemptCount, required bool allowHelp}) {
    if (!allowHelp) return false;
    if (attemptCount < 2) return false;
    return _isVisualTask(task);
  }

  bool shouldUsePaidImage({required LumoTask task, required int attemptCount, required bool childRequestedImage, required AppSettings settings}) {
    if (!settings.aiProxyEnabled) return false;
    if (!_isVisualTask(task)) return false;
    return childRequestedImage || attemptCount >= 3;
  }

  Future<LumoVisualAid> buildAid({required LumoTask task, required int grade, required int attemptCount, required AppSettings settings, required String childId, String childName = 'Kind', bool childRequestedImage = false}) async {
    final theme = await _themeFor(childId: childId, task: task, attemptCount: attemptCount);
    final local = _localAid(task, theme: theme, childName: childName, attemptCount: attemptCount);
    await _memory.remember(childId: childId, themeKey: theme.key);

    if (!shouldUsePaidImage(task: task, attemptCount: attemptCount, childRequestedImage: childRequestedImage, settings: settings)) return local;

    final baseUri = _validatedBaseUri(settings.aiProxyUrl);
    if (baseUri == null) return local;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(_visualEndpoint(baseUri)).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, dynamic>{
        'grade': grade,
        'childName': childName,
        'subject': task.subject,
        'unit': task.unit,
        'prompt': task.prompt,
        'answer': task.answer,
        'explanation': task.explanation,
        'visualTheme': <String, dynamic>{'key': theme.key, 'object': theme.plural, 'emoji': theme.emoji, 'context': theme.context},
        'style': 'child_safe_step_by_step_worksheet_visual',
        'mustAvoid': const <String>['same image as previous task', 'unrelated decorative picture', 'text-only poster', 'photorealistic child'],
        'creditGuard': <String, dynamic>{'reason': childRequestedImage ? 'child_requested_after_help' : 'repeated_wrong_answers', 'attemptCount': attemptCount, 'renderOnlyIfUseful': true},
      }));
      final response = await request.close().timeout(_timeout);
      final raw = await response.transform(utf8.decoder).join().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return local;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return local;
      final imageUrl = decoded['imageUrl']?.toString().trim();
      final explanation = decoded['explanation']?.toString().trim();
      if (imageUrl == null || imageUrl.isEmpty) return local;
      return LumoVisualAid(title: local.title, explanation: explanation == null || explanation.isEmpty ? local.explanation : explanation, steps: local.steps, imageUrl: imageUrl, source: 'proxy_visual_image', costly: true, themeKey: theme.key);
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

  Future<_VisualTheme> _themeFor({required String childId, required LumoTask task, required int attemptCount}) async {
    final recent = await _memory.recentThemes(childId: childId);
    final seed = _stableSeed('${task.subject}|${task.unit}|${task.prompt}|${task.answer}|$attemptCount|$childId');
    final rotated = List<_VisualTheme>.from(_themes);
    rotated.sort((a, b) => ((_stableSeed(a.key) + seed) % 997).compareTo((_stableSeed(b.key) + seed) % 997));
    for (final theme in rotated) {
      if (!recent.contains(theme.key)) return theme;
    }
    return rotated.first;
  }

  int _stableSeed(String value) {
    var hash = 17;
    for (final code in value.codeUnits) {
      hash = (hash * 37 + code) & 0x7fffffff;
    }
    return hash;
  }

  LumoVisualAid _localAid(LumoTask task, {required _VisualTheme theme, required String childName, required int attemptCount}) {
    final math = _mathVisual(task, theme: theme, childName: childName, attemptCount: attemptCount);
    if (math != null) return math;
    final subject = task.subject.trim().isEmpty ? 'Lernen' : task.subject.trim();
    final tone = attemptCount >= 3 ? 'Wir wechseln die Erklärung. Du musst es nicht sofort können.' : 'Wir machen die Aufgabe sichtbar.';
    return LumoVisualAid(
      title: 'Bildhilfe zu $subject',
      explanation: '$tone Schau zuerst auf die Frage, dann auf die Lösungsidee.',
      themeKey: theme.key,
      steps: <LumoVisualAidStep>[
        LumoVisualAidStep(caption: 'Die Frage ist:', visual: task.prompt.trim()),
        LumoVisualAidStep(caption: 'Lumos Bildidee:', visual: '${theme.context} ${theme.emoji}'),
        LumoVisualAidStep(caption: 'Die richtige Lösung ist:', visual: task.answer.trim()),
        const LumoVisualAidStep(caption: 'Lumo-Tipp:', visual: 'Erst lesen, dann lautlos erklären, dann antworten.'),
      ],
    );
  }

  LumoVisualAid? _mathVisual(LumoTask task, {required _VisualTheme theme, required String childName, required int attemptCount}) {
    final firstName = childName.trim().isEmpty ? 'du' : childName.trim().split(RegExp(r'\s+')).first;
    final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(task.prompt);
    if (plus != null) {
      final a = int.tryParse(plus.group(1) ?? '') ?? 0;
      final b = int.tryParse(plus.group(2) ?? '') ?? 0;
      if (a > 0 && b > 0 && a + b <= 20) {
        final total = a + b;
        return LumoVisualAid(
          title: 'Plus als Bild: ${theme.plural}',
          explanation: _plusExplanation(theme, firstName, attemptCount),
          themeKey: theme.key,
          steps: <LumoVisualAidStep>[
            LumoVisualAidStep(caption: '1. Zuerst liegen da $a ${_noun(theme, a)}.', visual: _items(theme, a)),
            LumoVisualAidStep(caption: '2. Plus heißt: $b ${_noun(theme, b)} ${theme.plusVerb}.', visual: '${_items(theme, a)}  +  ${_items(theme, b)}'),
            LumoVisualAidStep(caption: '3. Jetzt zählst du alles zusammen: $total ${_noun(theme, total)}.', visual: _items(theme, total)),
          ],
        );
      }
    }
    final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(task.prompt);
    if (minus != null) {
      final a = int.tryParse(minus.group(1) ?? '') ?? 0;
      final b = int.tryParse(minus.group(2) ?? '') ?? 0;
      if (a > 0 && b > 0 && a <= 20 && a - b >= 0) {
        final left = a - b;
        return LumoVisualAid(
          title: 'Minus als Bild: ${theme.plural}',
          explanation: _minusExplanation(theme, firstName, attemptCount),
          themeKey: theme.key,
          steps: <LumoVisualAidStep>[
            LumoVisualAidStep(caption: '1. Am Anfang sind es $a ${_noun(theme, a)}.', visual: _items(theme, a)),
            LumoVisualAidStep(caption: '2. Minus heißt: $b ${_noun(theme, b)} ${theme.minusVerb}.', visual: '${_items(theme, a)}  −  ${_items(theme, b)}'),
            LumoVisualAidStep(caption: '3. Übrig bleiben $left ${_noun(theme, left)}.', visual: _items(theme, left)),
          ],
        );
      }
    }
    return null;
  }

  String _plusExplanation(_VisualTheme theme, String firstName, int attemptCount) {
    final variants = <String>[
      'Plus bedeutet dazu. ${theme.context} Erst hast du eine Menge, dann kommt noch eine Menge dazu.',
      '$firstName, stell dir vor: Du legst nicht weg, sondern legst mehr dazu. Darum wird die Zahl größer.',
      'Bei Plus werden zwei Gruppen zu einer gemeinsamen Gruppe. Danach zählst du alle ${theme.plural}.',
    ];
    return variants[attemptCount % variants.length];
  }

  String _minusExplanation(_VisualTheme theme, String firstName, int attemptCount) {
    final variants = <String>[
      'Minus bedeutet weg. ${theme.context} Du startest mit einer Menge und nimmst etwas davon weg.',
      '$firstName, bei Minus wird die Menge kleiner, weil etwas nicht mehr dabei ist.',
      'Bei Minus schaust du: Was war am Anfang da? Was geht weg? Was bleibt übrig?',
    ];
    return variants[attemptCount % variants.length];
  }

  String _noun(_VisualTheme theme, int count) => count == 1 ? theme.single : theme.plural;

  String _items(_VisualTheme theme, int count) {
    if (count <= 0) return '—';
    return List<String>.filled(count.clamp(0, 20).toInt(), theme.emoji).join(' ');
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
    final normalizedPath = baseUri.path.endsWith('/') ? '${baseUri.path}visual-aid' : baseUri.path.isEmpty ? '/visual-aid' : '${baseUri.path}/visual-aid';
    return baseUri.replace(path: normalizedPath, query: '');
  }
}

class LumoVisualAidMemory {
  const LumoVisualAidMemory();
  static const int _limit = 8;
  String _key(String childId) => 'lumo_visual_aid_recent_${childId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  Future<List<String>> recentThemes({required String childId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key(childId)) ?? const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> remember({required String childId, required String themeKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = List<String>.from(prefs.getStringList(_key(childId)) ?? const <String>[]);
      recent.remove(themeKey);
      recent.add(themeKey);
      while (recent.length > _limit) {
        recent.removeAt(0);
      }
      await prefs.setStringList(_key(childId), recent);
    } catch (_) {}
  }
}
