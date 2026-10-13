import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:lumo_lernen/features/settings/parent_report_card.dart';

const _name = 'FiktivNurLokal';
const _boundary = ValueKey('parent-privacy-capture');

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 35; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final dashboard in [true, false]) {
    for (final enabled in [true, false]) {
      testWidgets(
          '${dashboard ? 'Insight' : 'Elternbericht'}: '
          '${enabled ? 'request omits local name' : 'disabled AI never connects'}',
          (tester) async {
        final requests = <Map<String, dynamic>>[];
        var clientsCreated = 0;
        await HttpOverrides.runZoned(() async {
          tester.view.physicalSize = const Size(430, 932);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final app = LumoAppState();
          addTearDown(app.dispose);
          await tester.runAsync(() async {
            app.update(app.state.copyWith(childName: _name, grade: 2));
            app.updateSettings(AppSettings(
                aiProxyEnabled: enabled,
                aiProxyUrl: 'https://offline.invalid',
                voiceEnabled: false,
                autoReadEnabled: false,
                soundEnabled: false,
                reduceAnimations: true,
                calmMode: true));
            await app.loadLearningProfile();
            if (enabled) {
              for (var topic = 0; topic < 8; topic++) {
                for (var answer = 0; answer < 10; answer++) {
                  await app.recordLearningAnswer(
                      subject: 'Mathematik',
                      unit: 'Thema $topic',
                      correct: answer < 7,
                      requireSaved: true);
                }
              }
            }
          });
          await tester.pumpWidget(MaterialApp(
              home: RepaintBoundary(
                  key: _boundary,
                  child: dashboard
                      ? LumoInsightDashboard(appState: app)
                      : Scaffold(
                          body: SingleChildScrollView(
                              child: ParentReportCard(appState: app))))));
          await _frames(tester);
          expect(requests, isEmpty,
              reason: 'Reports must never send in the background.');
          expect(clientsCreated, 0);
          final directory =
              Platform.environment['LUMO_PARENT_PRIVACY_CAPTURES'];
          if (directory != null && dashboard && enabled) {
            final boundary = tester
                .renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              try {
                final bytes =
                    await image.toByteData(format: ui.ImageByteFormat.png);
                final file = File('$directory/insight-local-profile-name.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }
          if (dashboard) {
            final greeting = find.textContaining(_name);
            expect(greeting, findsOneWidget);
            expect(
                tester.getRect(greeting).top,
                greaterThan(
                    tester.getRect(find.text('🦊 Lumo Insight')).bottom),
                reason: 'The local greeting must remain below the toolbar.');
          }
          final button =
              find.text(dashboard ? 'KI fragen' : 'KI-Analyse anfordern');
          expect(button, findsOneWidget);
          await tester.ensureVisible(button);
          await tester.tap(button);
          await _frames(tester);
          expect(tester.takeException(), isNull);
          if (!enabled) {
            expect(requests, isEmpty);
            expect(clientsCreated, 0);
          } else {
            expect(requests, hasLength(1));
            final payload = requests.single;
            expect(payload['context'], 'parent_advisor');
            expect(payload['childProfile'], {'grade': 2});
            expect(payload['history'], isEmpty);
            expect(payload['message'],
                contains('Gesamt: 80 Antworten, 56 richtig, 24 falsch'));
            expect(payload['message'], contains('ohne abgegrenzten Zeitraum'));
            expect(payload['message'],
                contains('Keine Aussagen über heute, diese Woche'));
            for (var topic = 0; topic < 8; topic++) {
              expect(
                  payload['message'],
                  contains(
                      'Mathematik / Thema $topic: 70% · 7 von 10 Antworten richtig'));
            }
            expect(
                (payload['message'] as String).length, lessThanOrEqualTo(1200));
            expect(jsonEncode(payload), isNot(contains(_name)),
                reason:
                    'The profile name belongs only in the local parent UI.');
          }
          expect(app.state.childName, _name);
        }, createHttpClient: (_) {
          clientsCreated++;
          return _Client(requests);
        });
      });
    }
  }
  for (final dashboard in [true, false]) {
    testWidgets(
        '${dashboard ? 'Insight' : 'Elternbericht'} discards a delayed AI reply after profile switch',
        (tester) async {
      final requests = <Map<String, dynamic>>[];
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await HttpOverrides.runZoned(() async {
        final app = LumoAppState();
        addTearDown(app.dispose);
        await tester.runAsync(() async {
          app.updateSettings(AppSettings(
              aiProxyEnabled: true,
              aiProxyUrl: 'https://offline.invalid',
              voiceEnabled: false,
              reduceAnimations: true));
          await app.school.setActiveStudent('delayed-dna-a');
          await app.loadLearningProfile();
        });
        await tester.pumpWidget(MaterialApp(
            home: dashboard
                ? LumoInsightDashboard(appState: app)
                : Scaffold(
                    body: SingleChildScrollView(
                        child: ParentReportCard(appState: app)))));
        await _frames(tester);
        await tester.ensureVisible(
            find.text(dashboard ? 'KI fragen' : 'KI-Analyse anfordern'));
        await tester
            .tap(find.text(dashboard ? 'KI fragen' : 'KI-Analyse anfordern'));
        await _frames(tester);
        expect(requests, hasLength(1));
        expect(find.text('Gemeinsam kurze Aufgaben üben.'), findsNothing);
        await tester.runAsync(() async {
          await app.school.setActiveStudent('delayed-dna-b');
          await app.loadLearningProfile();
          gate.complete();
        });
        await _frames(tester);
        expect(find.text('Gemeinsam kurze Aufgaben üben.'), findsNothing,
            reason:
                'A reply for the previous child must never appear in the current report.');
        expect(find.text(dashboard ? 'KI fragen' : 'KI-Analyse anfordern'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      }, createHttpClient: (_) => _Client(requests, gate: gate));
    });
  }
}

class _Client implements HttpClient {
  _Client(this.requests, {this.gate});
  final Completer<void>? gate;
  final List<Map<String, dynamic>> requests;
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    if (url.scheme != 'https' ||
        url.host != 'offline.invalid' ||
        url.path != '/chat') {
      throw StateError('Unexpected endpoint: $url');
    }
    return _Request(requests, gate: gate);
  }

  @override
  set connectionTimeout(Duration? value) {}
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.requests, {this.gate});
  final Completer<void>? gate;
  final List<Map<String, dynamic>> requests;
  final _body = StringBuffer();
  @override
  HttpHeaders get headers => _Headers();
  @override
  void write(Object? value) => _body.write(value);
  @override
  Future<HttpClientResponse> close() async {
    requests.add(jsonDecode(_body.toString()) as Map<String, dynamic>);
    if (gate != null) await gate!.future;
    return _Response();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream.value(utf8.encode(jsonEncode({
        'reply': 'Gemeinsam kurze Aufgaben üben.',
        'source': 'offline_test',
      }))).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
