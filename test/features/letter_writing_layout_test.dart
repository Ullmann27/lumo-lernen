import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/letter_writing_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Buchstaben schreiben (Akademie): kein Überlauf auf dem Handy (412 dp,
/// Fold außen) und auf dem Fold innen, auch mit großer Schrift.
const _topic = LearningTopic(
  id: 'd1_buchstaben_alle',
  title: 'Alle Buchstaben A-Z',
  icon: Icons.edit_rounded,
  gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  shortDesc: 'Alle 26 Buchstaben üben',
  isWriting: true,
  writingChars: ['A', 'B', 'M'],
);
const _subject = LearningSubject(
  id: 'deutsch1',
  name: 'Deutsch',
  color: Color(0xFF8B5CF6),
  icon: Icons.menu_book_rounded,
  topics: [_topic],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(360, 740),
    const Size(412, 892),
    const Size(829, 690),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('${size.width.toInt()}×${size.height.toInt()} Schrift ×$scale: '
          'Vorschau und Schreibfläche ohne Überlauf', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState(walletRepository: RewardWalletRepository());
        addTearDown(app.dispose);
        // Große Schrift gilt für alle Seiten, auch die Schreibfläche.
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                size: size,
                disableAnimations: true,
                textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: LetterWritingScreen(
              appState: app, topic: _topic, subject: _subject),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'Vorschau');
        final start = find.text('Jetzt schreiben üben');
        await tester.ensureVisible(start);
        await tester.pump();
        await tester.tap(start);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull, reason: 'Schreibfläche');
        expect(
            find.byWidgetPredicate((w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_StrokesPainter'),
            findsOneWidget,
            reason: 'Die Schreibfläche ist offen');
        final skip = find.text('Überspringen → Nächster Buchstabe');
        if (skip.evaluate().isNotEmpty) {
          expect(tester.getSize(skip).height, greaterThan(0));
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
