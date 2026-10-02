class AppSettings {
  /// Standard-Basis-URL fuer den Lumo-AI-Proxy.
  /// Diese URL ist oeffentlich und enthaelt keine Geheimnisse.
  /// Der OpenAI-API-Key liegt ausschliesslich auf dem Render-Server.
  /// Eltern duerfen die URL aendern, aber sie ist standardmaessig
  /// vorausgefuellt, damit Heinz sie nicht jedes Mal eintragen muss.
  static const String defaultAiProxyUrl = 'https://lumo-ai-proxy.onrender.com';

  static const String initialParentPin = '2468';

  const AppSettings({
    this.parentPin = initialParentPin,
    bool? parentPinConfigured,
    this.parentRecoveryCodeHash = '',
    this.dailyGoal = 3,
    this.soundEnabled = true,
    this.voiceEnabled = true,
    this.autoReadEnabled = true,
    this.microphoneEnabled = true,
    this.scannerEnabled = true,
    this.aiProxyEnabled = false,
    this.aiLearningMode = AiLearningMode.chatOnly,
    this.aiProxyUrl = defaultAiProxyUrl,
    this.reduceAnimations = false,
    this.largeText = false,
    this.calmMode = false,
    this.learningMode = LearningMode.normal,
    this.voiceRate = 0.35,
    this.voicePitch = 1.0,
  }) : parentPinConfigured =
           parentPinConfigured ?? (parentPin != initialParentPin);

  final String parentPin;
  final bool parentPinConfigured;
  final String parentRecoveryCodeHash;

  bool get hasParentRecoveryCode =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(parentRecoveryCodeHash);
  final int dailyGoal;
  final bool soundEnabled;
  final bool voiceEnabled;
  final bool autoReadEnabled;
  final bool microphoneEnabled;
  final bool scannerEnabled;
  final bool aiProxyEnabled;
  final AiLearningMode aiLearningMode;
  final String aiProxyUrl;
  final bool reduceAnimations;
  final bool largeText;
  final bool calmMode;
  final LearningMode learningMode;
  final double voiceRate;
  final double voicePitch;

  AppSettings copyWith({
    String? parentPin,
    bool? parentPinConfigured,
    String? parentRecoveryCodeHash,
    int? dailyGoal,
    bool? soundEnabled,
    bool? voiceEnabled,
    bool? autoReadEnabled,
    bool? microphoneEnabled,
    bool? scannerEnabled,
    bool? aiProxyEnabled,
    AiLearningMode? aiLearningMode,
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
      parentPinConfigured: parentPinConfigured ??
          (parentPin != null ? true : this.parentPinConfigured),
      parentRecoveryCodeHash: parentRecoveryCodeHash ?? this.parentRecoveryCodeHash,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      autoReadEnabled: autoReadEnabled ?? this.autoReadEnabled,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      scannerEnabled: scannerEnabled ?? this.scannerEnabled,
      aiProxyEnabled: aiProxyEnabled ?? this.aiProxyEnabled,
      aiLearningMode: aiLearningMode ?? this.aiLearningMode,
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
        'parentPinConfigured': parentPinConfigured,
        'parentRecoveryCodeHash': parentRecoveryCodeHash,
        'dailyGoal': dailyGoal,
        'soundEnabled': soundEnabled,
        'voiceEnabled': voiceEnabled,
        'autoReadEnabled': autoReadEnabled,
        'microphoneEnabled': microphoneEnabled,
        'scannerEnabled': scannerEnabled,
        'aiProxyEnabled': aiProxyEnabled,
        'aiLearningMode': aiLearningMode.name,
        'aiProxyUrl': aiProxyUrl,
        'reduceAnimations': reduceAnimations,
        'largeText': largeText,
        'calmMode': calmMode,
        'learningMode': learningMode.name,
        'voiceRate': voiceRate,
        'voicePitch': voicePitch,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final savedPin = '${json['parentPin'] ?? ''}';
    final validPin = RegExp(r'^\d{4,8}$').hasMatch(savedPin);
    final pin = validPin ? savedPin : initialParentPin;
    // Existing custom PINs are never downgraded by missing/false metadata.
    // Only the old untouched default needs first-time setup.
    final configured = (validPin && pin != initialParentPin) ||
        json['parentPinConfigured'] == true;
    return AppSettings(
      parentPin: pin,
      parentPinConfigured: configured,
      parentRecoveryCodeHash: json['parentRecoveryCodeHash'] is String
          ? json['parentRecoveryCodeHash'] as String
          : '',
      dailyGoal: _intIn(json['dailyGoal'], fallback: 3, allowed: const [3, 5, 10, 15],
      ),
      soundEnabled: _bool(json['soundEnabled'], fallback: true),
      voiceEnabled: _bool(json['voiceEnabled'], fallback: true),
      autoReadEnabled: _bool(json['autoReadEnabled'], fallback: true),
      microphoneEnabled: _bool(json['microphoneEnabled'], fallback: true),
      scannerEnabled: _bool(json['scannerEnabled'], fallback: true),
      aiProxyEnabled: _bool(json['aiProxyEnabled'], fallback: false),
      aiLearningMode: AiLearningModeX.fromName(json['aiLearningMode'] is String ? json['aiLearningMode'] as String : null,
      ),
      aiProxyUrl: _safeProxyUrl(json['aiProxyUrl']),
      reduceAnimations: _bool(json['reduceAnimations'], fallback: false),
      largeText: _bool(json['largeText'], fallback: false),
      calmMode: _bool(json['calmMode'], fallback: false),
      learningMode: LearningModeX.fromName(json['learningMode'] is String ? json['learningMode'] as String : null),
      voiceRate: _doubleRange(json['voiceRate'], fallback: 0.35, min: 0.25, max: 0.55,
      ),
      voicePitch: _doubleRange(json['voicePitch'], fallback: 1.0, min: 0.85, max: 1.18,
      ),
    );
  }

  static bool _bool(dynamic value, {required bool fallback}) =>
      value is bool ? value : fallback;

  static int _intIn(dynamic value, {required int fallback, required List<int> allowed,
  }) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed != null && allowed.contains(parsed)) return parsed;
    return fallback;
  }

  static double _doubleRange(dynamic value, {required double fallback, required double min, required double max,
  }) {
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
    if (uri.userInfo.isNotEmpty) return defaultAiProxyUrl;
    // Eingefuegte Health-Links enthalten oft '?' oder einen Fragment-Anker.
    // Nur der Pfad wird bereinigt; Query und Fragment gehoeren nicht zur Basis.
    final path = _stripWellKnownPaths(uri.path);
    return uri
        .replace(path: path, query: '', fragment: '')
        .toString()
        .replaceAll(RegExp(r'[?#]+$'), '');
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
      for (final suffix in const <String>['/health', '/chat', '/tasks', '/']) {
        if (out.endsWith(suffix) ) {
          out = out.substring(0, out.length - suffix.length);
          changed = true;
        }
      }
    }
    return out;
  }
}

enum AiLearningMode { chatOnly, learningHelp, readingHelp, fullCoach }

extension AiLearningModeX on AiLearningMode {
  static AiLearningMode fromName(String? name) {
    return AiLearningMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AiLearningMode.chatOnly,
    );
  }

  String get label {
    switch (this) {
      case AiLearningMode.chatOnly:
        return 'Nur KI-Chat';
      case AiLearningMode.learningHelp:
        return 'Chat und Aufgabenhilfe';
      case AiLearningMode.readingHelp:
        return 'Chat und Lesehilfe';
      case AiLearningMode.fullCoach:
        return 'Voller Lumo-Coach';
    }
  }

  String get description {
    switch (this) {
      case AiLearningMode.chatOnly:
        return 'Die KI antwortet nur im Chat-Modus.';
      case AiLearningMode.learningHelp:
        return 'Die KI darf Aufgaben kindgerecht erklaeren.';
      case AiLearningMode.readingHelp:
        return 'Die KI darf beim Lesen ruhig coachen.';
      case AiLearningMode.fullCoach:
        return 'Die KI darf Chat, Aufgaben, Lesen, Tests und Scanner unterstuetzen.';
    }
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
