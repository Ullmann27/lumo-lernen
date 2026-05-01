class AppSettings {
  /// Standard-Basis-URL fuer den Lumo-AI-Proxy.
  /// Diese URL ist oeffentlich und enthaelt keine Geheimnisse.
  /// Der OpenAI-API-Key liegt ausschliesslich auf dem Render-Server.
  /// Eltern duerfen die URL aendern, aber sie ist standardmaessig
  /// vorausgefuellt, damit Heinz sie nicht jedes Mal eintragen muss.
  static const String defaultAiProxyUrl = 'https://lumo-ai-proxy.onrender.com';

  const AppSettings({
    this.parentPin = '2468',
    this.dailyGoal = 3,
    this.soundEnabled = true,
    this.voiceEnabled = true,
    this.autoReadEnabled = true,
    this.microphoneEnabled = true,
    this.scannerEnabled = true,
    this.aiProxyEnabled = false,
    this.aiProxyUrl = defaultAiProxyUrl,
    this.reduceAnimations = false,
    this.largeText = false,
    this.calmMode = false,
    this.learningMode = LearningMode.normal,
    this.voiceRate = 0.35,
    this.voicePitch = 1.0,
  });

  final String parentPin;
  final int dailyGoal;
  final bool soundEnabled;
  final bool voiceEnabled;
  final bool autoReadEnabled;
  final bool microphoneEnabled;
  final bool scannerEnabled;
  final bool aiProxyEnabled;
  final String aiProxyUrl;
  final bool reduceAnimations;
  final bool largeText;
  final bool calmMode;
  final LearningMode learningMode;
  final double voiceRate;
  final double voicePitch;

  AppSettings copyWith({
    String? parentPin,
    int? dailyGoal,
    bool? soundEnabled,
    bool? voiceEnabled,
    bool? autoReadEnabled,
    bool? microphoneEnabled,
    bool? scannerEnabled,
    bool? aiProxyEnabled,
    String? aiProxyUrl,
    bool? reduceAnimations,
    bool? largeText,
    bool? calmMode,
    LearningMode? learningMode,
    double? voiceRate,
    double? voicePitch,
  }) {
    return AppSettings(
      parentPin: parentPin ?? this.parentPin,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      autoReadEnabled: autoReadEnabled ?? this.autoReadEnabled,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      scannerEnabled: scannerEnabled ?? this.scannerEnabled,
      aiProxyEnabled: aiProxyEnabled ?? this.aiProxyEnabled,
      aiProxyUrl: aiProxyUrl ?? this.aiProxyUrl,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      largeText: largeText ?? this.largeText,
      calmMode: calmMode ?? this.calmMode,
      learningMode: learningMode ?? this.learningMode,
      voiceRate: voiceRate ?? this.voiceRate,
      voicePitch: voicePitch ?? this.voicePitch,
    );
  }

  Map<String, dynamic> toJson() => {
        'parentPin': parentPin,
        'dailyGoal': dailyGoal,
        'soundEnabled': soundEnabled,
        'voiceEnabled': voiceEnabled,
        'autoReadEnabled': autoReadEnabled,
        'microphoneEnabled': microphoneEnabled,
        'scannerEnabled': scannerEnabled,
        'aiProxyEnabled': aiProxyEnabled,
        'aiProxyUrl': aiProxyUrl,
        'reduceAnimations': reduceAnimations,
        'largeText': largeText,
        'calmMode': calmMode,
        'learningMode': learningMode.name,
        'voiceRate': voiceRate,
        'voicePitch': voicePitch,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      parentPin: (json['parentPin'] as String?)?.trim().isNotEmpty == true ? json['parentPin'] as String : '2468',
      dailyGoal: _intIn(json['dailyGoal'], fallback: 3, allowed: const [3, 5, 10, 15]),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      voiceEnabled: json['voiceEnabled'] as bool? ?? true,
      autoReadEnabled: json['autoReadEnabled'] as bool? ?? true,
      microphoneEnabled: json['microphoneEnabled'] as bool? ?? true,
      scannerEnabled: json['scannerEnabled'] as bool? ?? true,
      aiProxyEnabled: json['aiProxyEnabled'] as bool? ?? false,
      aiProxyUrl: _safeProxyUrl(json['aiProxyUrl']),
      reduceAnimations: json['reduceAnimations'] as bool? ?? false,
      largeText: json['largeText'] as bool? ?? false,
      calmMode: json['calmMode'] as bool? ?? false,
      learningMode: LearningModeX.fromName(json['learningMode'] as String?),
      voiceRate: _doubleRange(json['voiceRate'], fallback: 0.35, min: 0.25, max: 0.55),
      voicePitch: _doubleRange(json['voicePitch'], fallback: 1.0, min: 0.85, max: 1.18),
    );
  }

  static int _intIn(dynamic value, {required int fallback, required List<int> allowed}) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed != null && allowed.contains(parsed)) return parsed;
    return fallback;
  }

  static double _doubleRange(dynamic value, {required double fallback, required double min, required double max}) {
    final parsed = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return fallback;
    return parsed.clamp(min, max).toDouble();
  }

  static String _safeProxyUrl(dynamic value) {
    return sanitizeProxyUrl(value?.toString());
  }

  /// Public Helper, den die Settings-UI beim Eingeben aufrufen kann,
  /// damit eine Eltern-Eingabe sofort korrekt gespeichert wird:
  ///   - leer/ungueltig -> defaultAiProxyUrl
  ///   - /health, /chat oder Trailing-Slash am Ende -> entfernt
  static String sanitizeProxyUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return defaultAiProxyUrl;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return defaultAiProxyUrl;
    if (uri.scheme != 'https' && uri.scheme != 'http') return defaultAiProxyUrl;
    return _stripWellKnownPaths(trimmed);
  }

  /// Entfernt bekannte Endpunkt-Pfade aus einer Benutzer-URL,
  /// damit die App nur die Basis-URL speichert.
  ///
  /// Wenn Eltern versehentlich die /health-URL eintragen, wird das
  /// auf die Basis bereinigt - sonst wuerde /health spaeter doppelt
  /// als Chat-URL verwendet.
  /// Wenn Eltern /chat eintragen, wird das ebenfalls weggeschnitten,
  /// damit der Client nicht /chat/chat anhaengt.
  ///
  /// Trailing slashes werden ebenfalls entfernt.
  static String _stripWellKnownPaths(String raw) {
    var out = raw;
    // Wiederholt anwenden, falls /chat/health oder aehnlicher Unsinn drinsteckt
    var changed = true;
    while (changed) {
      changed = false;
      for (final suffix in const <String>['/health', '/chat', '/']) {
        if (out.endsWith(suffix) && out.length > suffix.length) {
          out = out.substring(0, out.length - suffix.length);
          changed = true;
        }
      }
    }
    return out;
  }
}

enum LearningMode { easy, normal, challenge }

extension LearningModeX on LearningMode {
  static LearningMode fromName(String? name) {
    return LearningMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => LearningMode.normal,
    );
  }

  String get label {
    switch (this) {
      case LearningMode.easy:
        return 'Leicht';
      case LearningMode.normal:
        return 'Normal';
      case LearningMode.challenge:
        return 'Herausforderung';
    }
  }

  String get description {
    switch (this) {
      case LearningMode.easy:
        return 'mehr Hilfe, sanftere Aufgaben';
      case LearningMode.normal:
        return 'ausgewogenes Lernen';
      case LearningMode.challenge:
        return 'etwas schwerer und schneller';
    }
  }
}
