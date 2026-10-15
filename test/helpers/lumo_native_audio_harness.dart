import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Native-platform contract harness, NOT an Android speaker or audio decoder.
/// Reports must name this limitation rather than count simulated playback
/// as an audible device test.
class LumoNativeAudioHarness {
  final calls = <MethodCall>[];
  final retiredTtsCalls = <String>[];
  MockStreamHandlerEventSink? events;
  int nativePositionMs = 0;

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    AudioCache.instance = _PathOnlyAudioCache();
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),
        (call) async {
      retiredTtsCalls.add(call.method);
      throw StateError('A retired voice must never be activated.');
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      calls.add(call);
      if (call.method == 'setSourceUrl' || call.method == 'setSourceBytes') {
        events?.success({'event': 'audio.onPrepared', 'value': true});
      }
      if (call.method == 'getCurrentPosition') return nativePositionMs;
      return null;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (_) async => null);
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers/events/lumo-sulafat'),
      MockStreamHandler.inline(onListen: (_, sink) => events = sink),
    );
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, __) {}),
    );
  }

  void complete() => events!.success({'event': 'audio.onComplete'});
}

class _PathOnlyAudioCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async => Uri.file('/tmp/$fileName');
}
