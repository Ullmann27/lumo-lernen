import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Heinz' Fuchs-Posen fuer das neue Design (docs/DESIGN_ASSETS_2026-10-04.md)
/// muessen im App-Bundle liegen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const poses = <String>[
    'fox_kart_wave', 'fox_point_side', 'fox_cheer', 'fox_tablet_thumb',
    'fox_book_point', 'fox_teacher_stick', 'fox_arms_open', 'fox_thumb_wink',
    'fox_avatar', 'fox_trophy_wink',
  ];
  const scenes = <String>[
    'bg/bg_home', 'bg/bg_learn', 'bg/bg_library', 'bg/bg_tests', 'bg/bg_games',
    'bg/bg_profile', 'bg/bg_kart', 'bg/bg_wide', 'logo/logo_lumo', 'logo/logo_lumo_kart',
    'cards/deutsch_hund', 'cards/game_kart', 'cards/game_memory', 'cards/kart_freunde',
    'cards/test_rechnen', 'cards/kart_track',
  ];
  for (final scene in scenes) {
    test('$scene ist gebuendelt', () async {
      final data = await rootBundle.load('assets/lumo_design/$scene.png');
      expect(data.lengthInBytes, greaterThan(10000));
    });
  }
  for (final pose in poses) {
    test('$pose ist gebuendelt', () async {
      final data = await rootBundle.load('assets/lumo_design/fox/$pose.png');
      expect(data.lengthInBytes, greaterThan(10000));
    });
  }
}
