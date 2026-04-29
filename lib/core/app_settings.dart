class AppSettings {
  const AppSettings({
    this.parentPin = '2468',
    this.dailyGoal = 3,
    this.soundEnabled = true,
    this.voiceEnabled = true,
    this.autoReadEnabled = true,
    this.microphoneEnabled = true,
    this.scannerEnabled = true,
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
