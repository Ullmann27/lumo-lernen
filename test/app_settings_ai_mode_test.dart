import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';

void main() {
  group('AppSettings AI learning mode', () {
    test('defaults to chatOnly and disabled proxy', () {
      const settings = AppSettings();

      expect(settings.aiProxyEnabled, isFalse);
      expect(settings.aiLearningMode, AiLearningMode.chatOnly);
      expect(settings.toJson()['aiLearningMode'], 'chatOnly');
    });

    test('AI proxy disallows plaintext HTTP to remote servers', () {
      expect(
        AppSettings.sanitizeProxyUrl('http://example.org/chat'),
        AppSettings.defaultAiProxyUrl,
      );
      expect(
        AppSettings.sanitizeProxyUrl('http://localhost.evil.example/chat'),
        AppSettings.defaultAiProxyUrl,
      );
      expect(
        AppSettings.sanitizeProxyUrl('https://example.org/health'),
        'https://example.org',
      );
      expect(
        AppSettings.sanitizeProxyUrl('http://127.0.0.1:8080/chat'),
        'http://127.0.0.1:8080',
      );
      expect(
        AppSettings.sanitizeProxyUrl('http://localhost:8080/chat'),
        'http://localhost:8080',
      );
    });

    test('persists and restores fullCoach mode', () {
      const settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.fullCoach,
      );

      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored.aiProxyEnabled, isTrue);
      expect(restored.aiLearningMode, AiLearningMode.fullCoach);
    });

    test('falls back safely when stored mode is unknown', () {
      final settings = AppSettings.fromJson(const <String, dynamic>{
        'aiProxyEnabled': true,
        'aiLearningMode': 'unknownFutureMode',
      });

      expect(settings.aiProxyEnabled, isTrue);
      expect(settings.aiLearningMode, AiLearningMode.chatOnly);
    });

    test('copyWith updates mode without changing proxy flag', () {
      const settings = AppSettings(aiProxyEnabled: true);

      final changed = settings.copyWith(aiLearningMode: AiLearningMode.readingHelp);

      expect(changed.aiProxyEnabled, isTrue);
      expect(changed.aiLearningMode, AiLearningMode.readingHelp);
    });
  });
}
