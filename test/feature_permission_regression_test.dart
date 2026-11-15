import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/live/lumo_live_pro_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/lumo_photo_lesson_screen.dart';
import 'package:lumo_lernen/widgets/scan_screen.dart';

class _CameraPicker extends ImagePickerPlatform {
  _CameraPicker(this.capturePhoto);

  final Future<String?> Function() capturePhoto;
  final captures = <({ImageSource source, ImagePickerOptions options})>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    captures.add((source: source, options: options));
    final path = await capturePhoto();
    return path == null ? null : XFile(path);
  }
}

// Identify the animal actually shown by the public Safari widget.
const _safariAnimalNames = <String, String>{
  '🦁': 'Loewe',
  '🐘': 'Elefant',
  '🦒': 'Giraffe',
  '🦓': 'Zebra',
  '🐒': 'Affe',
  '🐯': 'Tiger',
  '🐻': 'Baer',
  '🐺': 'Wolf',
  '🦉': 'Eule',
  '🐧': 'Pinguin',
  '🐬': 'Delfin',
  '🦋': 'Schmetterling',
  '🐕': 'Hund',
  '🐈': 'Katze',
  '🐎': 'Pferd',
  '🐄': 'Kuh',
  '🐑': 'Schaf',
  '🐖': 'Schwein',
  '🐊': 'Krokodil',
  '🦏': 'Nashorn',
  '🦛': 'Flusspferd',
  '🦘': 'Kaenguru',
  '🐨': 'Koala',
  '🦥': 'Faultier',
  '🦈': 'Hai',
  '🐳': 'Wal',
  '🦭': 'Robbe',
  '🐻‍❄️': 'Eisbaer',
  '🦌': 'Rentier',
  '🦊': 'Fuchs',
  '🐿️': 'Eichhoernchen',
  '🦔': 'Igel',
  '🐸': 'Frosch',
  '🐢': 'Schildkroete',
  '🦅': 'Adler',
  '🦜': 'Papagei',
  '🐝': 'Biene',
  '🐞': 'Marienkaefer',
};

void main() {
  final sensorCalls = <MethodCall>[];
  late Future<String?> Function() capturePhoto;
  late ImagePickerPlatform originalPicker;
  late _CameraPicker camera;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              microphoneEnabled: false,
              scannerEnabled: false,
              voiceEnabled: false)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    sensorCalls.clear();
    capturePhoto = () async => null;
    originalPicker = ImagePickerPlatform.instance;
    camera = _CameraPicker(() => capturePhoto());
    ImagePickerPlatform.instance = camera;
    for (final channel in const [
      MethodChannel('plugin.csdcorp.com/speech_to_text'),
      MethodChannel('plugins.flutter.io/image_picker')
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        sensorCalls.add(call);
        return true;
      });
    }
  });
  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    for (final channel in const [
      MethodChannel('plugin.csdcorp.com/speech_to_text'),
      MethodChannel('plugins.flutter.io/image_picker')
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
    LumoVoice.instance.isEnabled = true;
  });

  Future<LumoAppState> openPhotoQuiz(WidgetTester tester,
      {bool cameraAllowed = true,
      bool microphoneAllowed = false,
      RewardWalletRepository? walletRepository}) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(AppSettings(
        microphoneEnabled: microphoneAllowed,
        scannerEnabled: cameraAllowed,
        voiceEnabled: false,
      ).toJson()),
    });
    late LumoAppState state;
    await tester.runAsync(() async {
      state = LumoAppState(walletRepository: walletRepository);
      await state.ensureSettingsLoaded();
      await state.loadLearningProfile();
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.dispose();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
        MaterialApp(home: LumoLiveProScreen(appState: state)));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Foto-Quiz').first);
    await tester.pump(const Duration(milliseconds: 100));
    return state;
  }

  Future<void> settleLocalOperations(WidgetTester tester) async {
    // Profile/settings Futures were loaded in runAsync. Allow their real event
    // loop to finish between frames, as in the existing module progress tests.
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pump();
  }

  Future<void> pressAction(WidgetTester tester, String label) async {
    final action = find.widgetWithText(ElevatedButton, label);
    expect(tester.widget<ElevatedButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await settleLocalOperations(tester);
  }

  Finder capturedImage() => find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is FileImage);

  Future<void> deliverFinalSpeech(WidgetTester tester, String words) async {
    // Exercise the locked speech_to_text 7.5.0 platform protocol. The real
    // listener and screen callbacks remain installed by the visible button.
    const codec = StandardMethodCodec();
    final dispatch = tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'plugin.csdcorp.com/speech_to_text',
      codec.encodeMethodCall(MethodCall('textRecognition', jsonEncode({
        'alternates': [
          {'recognizedWords': words, 'confidence': 1.0},
        ],
        'resultType': 2,
      }))),
      null,
    );
    await tester.pump();
    final response = await dispatch;
    expect(response, isNotNull,
        reason: 'The real plugin must receive the native recognition event.');
    expect(codec.decodeEnvelope(response!), isNull);
  }

  void expectNoMicrophone() {
    expect(
        sensorCalls.where(
            (call) => call.method == 'initialize' || call.method == 'listen'),
        isEmpty);
  }

  testWidgets('Live word magic offers explanations without a picture promise',
      (tester) async {
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await tester.tap(find.text('Wort-Magie').first);
    await settleLocalOperations(tester);

    expect(find.text('Sag ein Wort - ich erkläre es!'), findsWidgets);
    expect(find.text('Sag mir ein Wort und ich erkläre es dir!'), findsOneWidget);
    expect(find.textContaining('ich male'), findsNothing);
    expect(find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage), findsNothing);
    expect(camera.captures, isEmpty);
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live safari displays its existing animal and advances the round',
      (tester) async {
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await tester.tap(find.text('Tier-Safari').first);
    await settleLocalOperations(tester);

    final animal = find.byWidgetPredicate((widget) =>
        widget is Text && widget.style?.fontSize == 112);
    expect(find.text('Welches Tier siehst du? Sag mir den Namen!'), findsOneWidget);
    expect(find.text('0 von 1'), findsOneWidget);
    expect(animal, findsOneWidget);
    expect(tester.widget<Text>(animal).data, isNotEmpty);
    await tester.ensureVisible(animal);
    await tester.pump();
    expect(animal.hitTestable(), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await settleLocalOperations(tester);
    expect(find.text('0 von 2'), findsOneWidget);
    expect(animal, findsOneWidget);
    expect(tester.widget<Text>(animal).data, isNotEmpty);
    await tester.tap(find.text('Foto-Quiz').first);
    await settleLocalOperations(tester);
    expect(animal, findsNothing);
    expect(find.text('Foto machen'), findsOneWidget);
    expect(camera.captures, isEmpty);
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live photo quiz checks camera consent before capture',
      (tester) async {
    final state = await openPhotoQuiz(tester, cameraAllowed: false);
    final rewards = (state.state.stars, state.state.xp);
    await pressAction(tester, 'Foto machen');

    expect(find.textContaining('Die Kamera ist ausgeschaltet.'), findsOneWidget);
    expect(camera.captures, isEmpty);
    expectNoMicrophone();
    expect(capturedImage(), findsNothing);
    expect((state.state.stars, state.state.xp), rewards);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Foto machen'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live photo quiz cancellation keeps capture ready without rewards',
      (tester) async {
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await pressAction(tester, 'Foto machen');

    expect(camera.captures, hasLength(1));
    expect(camera.captures.single.source, ImageSource.camera);
    expect(camera.captures.single.options.maxWidth, 800);
    expect(camera.captures.single.options.imageQuality, 60);
    expect(capturedImage(), findsNothing);
    expect(find.text('Antwort sprechen'), findsNothing);
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    await pressAction(tester, 'Foto machen');
    expect(camera.captures, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live photo quiz recovers from a native camera rejection',
      (tester) async {
    capturePhoto = () async {
      throw PlatformException(code: 'camera_access_denied');
    };
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await pressAction(tester, 'Foto machen');

    expect(camera.captures, hasLength(1));
    expect(find.text('Das Foto hat nicht geklappt. Probier nochmal!'),
        findsOneWidget);
    expect(capturedImage(), findsNothing);
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Foto machen'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live photo quiz offers a spoken answer only after a real photo',
      (tester) async {
    final photo = File('assets/lumo_design/fox/fox_avatar.png').absolute;
    expect(photo.existsSync(), isTrue);
    capturePhoto = () async => photo.path;
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await pressAction(tester, 'Foto machen');

    expect(camera.captures, hasLength(1));
    expect(capturedImage(), findsOneWidget);
    final image = tester.widget<Image>(capturedImage()).image as FileImage;
    expect(image.file.path, photo.path);
    expect(find.text('Was siehst du da auf dem Foto?'), findsOneWidget);
    expect(find.text('Antwort sprechen'), findsOneWidget);
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);

    await pressAction(tester, 'Antwort sprechen');
    expect(find.textContaining('Das Mikrofon ist ausgeschaltet.'), findsOneWidget);
    expect(camera.captures, hasLength(1));
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live photo quiz discards a pending capture after a mode round trip',
      (tester) async {
    final pending = Completer<String?>();
    capturePhoto = () => pending.future;
    addTearDown(() {
      if (!pending.isCompleted) pending.complete();
    });
    final state = await openPhotoQuiz(tester);
    final rewards = (state.state.stars, state.state.xp);
    await pressAction(tester, 'Foto machen');
    expect(camera.captures, hasLength(1));
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Foto machen'))
            .onPressed,
        isNull);

    await tester.tap(find.text('Wort-Magie').first);
    await tester.pump();
    await tester.tap(find.text('Foto-Quiz').first);
    await tester.pump();
    pending.complete(File('assets/lumo_design/fox/fox_avatar.png').absolute.path);
    await settleLocalOperations(tester);

    expect(capturedImage(), findsNothing);
    expect(find.text('Antwort sprechen'), findsNothing);
    expect(find.text('Was siehst du da auf dem Foto?'), findsNothing);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Foto machen'))
            .onPressed,
        isNotNull);
    expect(camera.captures, hasLength(1));
    expectNoMicrophone();
    expect((state.state.stars, state.state.xp), rewards);
    expect(tester.takeException(), isNull);
  });


  for (final transition in [
    'profile change',
    'lease reset',
    'mode round trip',
  ]) {
    testWidgets(
        'Live photo quiz rejects a delayed camera error after $transition',
        (tester) async {
      final pending = Completer<String?>();
      capturePhoto = () => pending.future;
      addTearDown(() {
        if (!pending.isCompleted) pending.complete();
      });
      final state = await openPhotoQuiz(tester);
      await pressAction(tester, 'Foto machen');
      expect(camera.captures, hasLength(1));
      late LearningProfileLease previousOwner;
      await tester.runAsync(() async {
        previousOwner = await state.captureLearningProfile();
      });
      expect(state.isCurrentLearningLease(previousOwner), isTrue);

      if (transition == 'profile change') {
        await tester.runAsync(() async {
          await state.school.setActiveStudent('photo-next-owner');
          await state.loadLearningProfile();
        });
        expect(state.isCurrentLearningLease(previousOwner), isFalse);
        late LearningProfileLease currentOwner;
        await tester.runAsync(() async {
          currentOwner = await state.captureLearningProfile();
        });
        expect(currentOwner.studentId, isNot(previousOwner.studentId));
        expect(state.isCurrentLearningLease(currentOwner), isTrue);
      } else if (transition == 'lease reset') {
        await tester.runAsync(() async {
          expect(await state.resetTutorObservations(lease: previousOwner), isTrue);
          await state.loadLearningProfile();
        });
        late LearningProfileLease currentOwner;
        await tester.runAsync(() async {
          currentOwner = await state.captureLearningProfile();
        });
        expect(currentOwner.studentId, previousOwner.studentId);
        expect(state.isCurrentLearningLease(previousOwner), isFalse);
        expect(state.isCurrentLearningLease(currentOwner), isTrue);
      } else {
        await tester.tap(find.text('Wort-Magie').first);
        await tester.pump();
        await tester.tap(find.text('Foto-Quiz').first);
        await tester.pump();
        expect(state.isCurrentLearningLease(previousOwner), isTrue);
      }
      await settleLocalOperations(tester);
      final rewards = (state.state.stars, state.state.xp);
      expect(
          tester.widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Foto machen')).onPressed,
          isNull,
          reason: 'The original picker still owns its pending capture.');
      pending.completeError(PlatformException(code: 'camera_access_denied'));
      await settleLocalOperations(tester);

      expect(find.text('Das Foto hat nicht geklappt. Probier nochmal!'),
          findsNothing,
          reason: 'An old context cannot report its late camera error here.');
      expect(capturedImage(), findsNothing);
      expect(find.text('Antwort sprechen'), findsNothing);
      expect((state.state.stars, state.state.xp), rewards);
      expectNoMicrophone();
      expect(
          tester.widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Foto machen')).onPressed,
          isNotNull,
          reason: 'The settled old operation releases its own busy state.');

      final retry = Completer<String?>();
      capturePhoto = () => retry.future;
      addTearDown(() {
        if (!retry.isCompleted) retry.complete();
      });
      await pressAction(tester, 'Foto machen');
      expect(camera.captures, hasLength(2));
      expect(
          tester.widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Foto machen')).onPressed,
          isNull,
          reason: 'The new operation retains its own pending state.');
      await settleLocalOperations(tester);
      expect(camera.captures, hasLength(2));
      retry.completeError(PlatformException(code: 'camera_access_denied'));
      await settleLocalOperations(tester);
      expect(find.text('Das Foto hat nicht geklappt. Probier nochmal!'),
          findsOneWidget,
          reason: 'A failure belonging to the current context is still reported.');
      expect(
          tester.widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Foto machen')).onPressed,
          isNotNull);
      expect((state.state.stars, state.state.xp), rewards);
      expectNoMicrophone();
      expect(tester.takeException(), isNull);
    });
  }

  for (final pro in [true]) {
    testWidgets(
        'Live ${pro ? 'Pro' : ''} opens without initializing microphone; denied tap stays local',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      await state.ensureSettingsLoaded();
      await tester.pumpWidget(MaterialApp(
          home: LumoLiveProScreen(appState: state)));
      await tester.pump(const Duration(seconds: 1));
      expect(sensorCalls.where((call) => call.method == 'initialize'), isEmpty);
      await tester.tap(find.text('Sprechen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Das Mikrofon ist ausgeschaltet.'),
          findsOneWidget);
      expect(
          sensorCalls.where(
              (call) => call.method == 'initialize' || call.method == 'listen'),
          isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Photo lesson checks saved camera consent before opening the scanner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    await state.ensureSettingsLoaded();
    await tester
        .pumpWidget(MaterialApp(home: LumoPhotoLessonScreen(appState: state)));
    await tester.pump();
    await tester.tap(find.text('Foto aufnehmen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ScanScreen), findsNothing);
    expect(
        find.textContaining('Die Kamera ist ausgeschaltet.'), findsOneWidget);
    expect(sensorCalls.where((call) => call.method == 'pickImage'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    expect(tester.takeException(), isNull);
  });

  for (final correct in [true, false]) {
    for (final continuation in [
      'word magic',
      'safari round trip',
      'unchanged safari',
      'profile change',
    ]) {
      testWidgets(
          'Live safari ${correct ? 'correct' : 'wrong'} answer keeps its delayed continuation bound during $continuation',
          (tester) async {
        final wallet = RewardWalletRepository();
        final state = await openPhotoQuiz(tester,
            microphoneAllowed: true, walletRepository: wallet);
        final messenger = tester.binding.defaultBinaryMessenger;
        const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
        messenger.setMockMethodCallHandler(speech, (call) async {
          sensorCalls.add(call);
          return switch (call.method) {
            'initialize' || 'listen' => true,
            'locales' => <String>['de_AT:Deutsch (Österreich)'],
            'stop' || 'cancel' => null,
            _ => throw StateError('Unexpected speech call: ${call.method}'),
          };
        });
        await tester.tap(find.text('Tier-Safari').first);
        await settleLocalOperations(tester);
        final animal = find.byWidgetPredicate((widget) =>
            widget is Text && widget.style?.fontSize == 112);
        await tester.ensureVisible(animal);
        await tester.pump();
        expect(animal.hitTestable(), findsOneWidget);
        final name = _safariAnimalNames[tester.widget<Text>(animal).data];
        expect(name, isNotNull,
            reason: 'Answer the actual visible animal, not a private state.');
        expect(find.text('0 von 1'), findsOneWidget);
        late LearningProfileLease owner;
        await tester.runAsync(() async {
          owner = await state.captureLearningProfile();
        });
        expect(state.isCurrentLearningLease(owner), isTrue);

        await pressAction(tester, 'Sprechen');
        final listens = sensorCalls.where((call) => call.method == 'listen');
        expect(listens, hasLength(1));
        expect((listens.single.arguments as Map)['onDevice'], isTrue);
        await deliverFinalSpeech(tester, correct ? name! : 'ein blaues Fahrrad');
        await settleLocalOperations(tester);
        expect((state.state.stars, state.state.xp), (0, 0),
            reason: 'Final speech remains an unconfirmed candidate.');
        final confirm = find.widgetWithText(OutlinedButton, 'Antwort bestätigen');
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await settleLocalOperations(tester);
        final feedback = correct
            ? 'Richtig! Das ist ein $name!'
            : 'Hmm, nicht ganz. Es ist ein $name. Versuch noch eins!';
        expect(find.text(feedback), findsOneWidget);
        expect(find.text('${correct ? 1 : 0} von 1'), findsOneWidget);
        await tester.runAsync(state.flushRewards);
        final earned = correct ? (2, 10) : (0, 0);
        expect((wallet.snapshot.stars, wallet.snapshot.xp), earned);
        expect((state.state.stars, state.state.xp), earned);

        // A correct answer opens the real reward route. Dismiss that route
        // through its visible content before touching the underlying modes.
        // These 550 ms remain below both the 2200 and 2500 ms continuations.
        await tester.pump(const Duration(milliseconds: 200));
        if (correct) {
          final reward = find.text('+10 XP');
          expect(reward.hitTestable(), findsOneWidget);
          await tester.tap(reward);
          await tester.pump();
        }
        // Cross the default 300 ms reverse transition, not its exact boundary.
        await tester.pump(const Duration(milliseconds: 350));
        // Finish the route's post-animation removal before reading the
        // underlying screen; this does not advance the Safari timer.
        await tester.pump();
        expect(find.text('+10 XP'), findsNothing);
        expect(find.text('${correct ? 1 : 0} von 1'), findsOneWidget);

        if (continuation == 'word magic' ||
            continuation == 'safari round trip') {
          final mode = find.text('Wort-Magie').first;
          expect(mode.hitTestable(), findsOneWidget);
          await tester.tap(mode);
          await tester.pump();
          expect(find.text('Sag mir ein Wort und ich erkläre es dir!'),
              findsOneWidget);
          if (continuation == 'safari round trip') {
            await tester.tap(find.text('Tier-Safari').first);
            await tester.pump();
            expect(find.text('0 von 1'), findsOneWidget);
          }
        } else if (continuation == 'profile change') {
          await tester.runAsync(() async {
            await state.school.setActiveStudent('safari-next-owner');
            await state.loadLearningProfile();
          });
          expect(state.isCurrentLearningLease(owner), isFalse);
        }
        final beforeDelay = (state.state.stars, state.state.xp);
        await tester.pump(const Duration(seconds: 3));
        await settleLocalOperations(tester);

        if (continuation == 'word magic') {
          expect(find.text('Sag mir ein Wort und ich erkläre es dir!'),
              findsOneWidget);
          expect(find.text('Welches Tier siehst du? Sag mir den Namen!'),
              findsNothing);
          expect(animal, findsNothing);
        } else if (continuation == 'safari round trip') {
          expect(find.text('0 von 1'), findsOneWidget,
              reason: 'An old response cannot advance a newly entered Safari.');
          expect(animal, findsOneWidget);
        } else if (continuation == 'profile change') {
          expect(find.text('${correct ? 1 : 0} von 1'), findsOneWidget);
          expect(find.text(feedback), findsOneWidget,
              reason: 'The old profile cannot start a new question here.');
          expect(find.text('Welches Tier siehst du? Sag mir den Namen!'),
              findsNothing);
        } else {
          expect(find.text('${correct ? 1 : 0} von 2'), findsOneWidget,
              reason: 'The same mode and owner must still advance exactly once.');
          expect(find.text('Welches Tier siehst du? Sag mir den Namen!'),
              findsOneWidget);
          expect(animal, findsOneWidget);
          expect(find.text(feedback), findsNothing);
        }
        await tester.runAsync(state.flushRewards);
        expect((state.state.stars, state.state.xp), beforeDelay);
        expect((wallet.snapshot.stars, wallet.snapshot.xp), earned,
            reason: 'The delayed continuation must not award another reward.');
        expect(camera.captures, isEmpty);
        expect(sensorCalls.where((call) => call.method == 'listen'), hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
