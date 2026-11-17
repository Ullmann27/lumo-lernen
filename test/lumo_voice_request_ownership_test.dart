import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'each accepted request retires the previous owner before preparation awaits',
      () async {
    final voice = LumoVoice.instance;
    final savedEnabled = voice.isEnabled;
    final savedClips = voice.clipsEnabled;
    voice.clipsEnabled = false;
    await voice.configure(enabled: true, localVoiceLicenseAccepted: false);
    try {
      final initial = voice.requestRevision;
      final first =
          voice.speakAndWait('Erster Text ohne freigegebene Synthese.');
      final firstOwner = voice.requestRevision;
      expect(firstOwner, initial + 1);
      final second =
          voice.speakAndWait('Zweiter Text vor dem ersten Ladeabschluss.');
      expect(voice.requestRevision, firstOwner + 1);
      final stop = voice.stop();
      expect(voice.requestRevision, firstOwner + 2);
      await Future.wait([first, second, stop]);
      expect(voice.requestRevision, firstOwner + 2,
          reason:
              'Old completion cannot reacquire shared transport ownership.');
    } finally {
      voice.clipsEnabled = savedClips;
      voice.isEnabled = savedEnabled;
      await voice.stop();
    }
  });

  test('empty or disabled speech does not claim another page transport',
      () async {
    final voice = LumoVoice.instance;
    voice.isEnabled = false;
    final before = voice.requestRevision;
    await voice.speakAndWait('Der Ton ist ausgeschaltet.');
    await voice.speakAndWait('');
    expect(voice.requestRevision, before);
    voice.isEnabled = true;
  });
}
