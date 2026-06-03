// Test fuer den Deep-Link-Router. Die Bridge vom Godot-Hub
// (lumolernen://open?section=...) muss die richtige LumoSection
// ergeben - sonst landet das Kind nach dem Bridge-Sprung nicht im
// vorgesehenen Bereich.

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/deep_link_router.dart';

void main() {
  group('DeepLinkRouter.parseInitialSection', () {
    test('null/leer/Slash ergibt null (kein Deep-Link)', () {
      expect(DeepLinkRouter.parseInitialSection(null), isNull);
      expect(DeepLinkRouter.parseInitialSection(''), isNull);
      expect(DeepLinkRouter.parseInitialSection('/'), isNull);
    });

    test('fremdes Schema wird ignoriert (kein Routing-Hijack)', () {
      expect(
        DeepLinkRouter.parseInitialSection('https://google.com/?section=learn'),
        isNull,
      );
      expect(
        DeepLinkRouter.parseInitialSection('lumo3d://open?section=learn'),
        isNull,
      );
    });

    test('lumolernen ohne section ergibt null (App startet am Home)', () {
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open'),
        isNull,
      );
    });

    test('section=learn -> LumoSection.learn', () {
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=learn'),
        LumoSection.learn,
      );
    });

    test('section ist case-insensitive', () {
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=LEARN'),
        LumoSection.learn,
      );
    });

    test('deutsche und englische Aliase greifen', () {
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=lernen'),
        LumoSection.learn,
      );
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=cards'),
        LumoSection.games,
      );
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=spiele'),
        LumoSection.games,
      );
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=reading'),
        LumoSection.reading,
      );
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=lesen'),
        LumoSection.reading,
      );
    });

    test('unbekannte section ergibt null (App startet normal)', () {
      expect(
        DeepLinkRouter.parseInitialSection('lumolernen://open?section=fluxkompensator'),
        isNull,
      );
    });
  });
}
