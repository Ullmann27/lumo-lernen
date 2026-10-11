import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'lumo_sulafat_client.dart';
import 'lumo_offline_voice_client.dart';
import 'lumo_voice_clips.dart';
import 'lumo_voice_policy.dart';
import 'lumo_wav_audio.dart';

/// Default: Lumo Frei, German F2, local clips and local Android synthesis.
/// The earlier Sulafat recordings and their explicitly selected legacy path
/// are preserved, but never mixed into the free voice or called as a fallback.
/// Keine Android-TTS-Stimme, kein heimlicher Ersatz bei Netzfehlern.
class LumoVoice {
  LumoVoice._internal();
  static final LumoVoice instance = LumoVoice._internal();

  final LumoSulafatClient _client = const LumoSulafatClient();
  final LumoOfflineVoiceClient _offline = const LumoOfflineVoiceClient();
  LumoVoiceIdentity _identity = LumoVoiceIdentity.freeOffline;
  bool _localVoiceLicenseAccepted = false;
  VoiceStyle? _playingStyle;
  bool _enabled = true;
  bool _cloudVoiceEnabled = false;
  String _serverUrl = 'https://lumo-ai-proxy.onrender.com';
  LumoParentSpeechAuthorization? _parentSpeechAuthorization;
  double _playbackRate = 1.0;
  String? lastStartedAudioIdentity;
  int _startedPlaybackCount = 0;
  int _completedPlaybackCount = 0;
  int _speechGeneration = 0;
  int _requestRevision = 0;
  int? _localInferenceGeneration;

  AudioPlayer? _player;
  StreamSubscription<void>? _doneSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _mediaPosition = Duration.zero;
  LumoSpeechCancellation? _pendingRequest;
  Completer<void>? _playbackFinished;
  Future<void> _startup = Future<void>.value();
  int? _playingGeneration;
  Timer? _mouthTicker;
  Stopwatch? _playbackWatch;
  Duration _playbackMax = Duration.zero;
  double Function(Duration)? _mouthEnvelope;

  final ValueNotifier<VoiceStatus> status =
      ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  final ValueNotifier<int> spokenWordRevision = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<double?> clipMouth = ValueNotifier<double?>(null);

  /// Tests koennen Clip-Audio isoliert deaktivieren, niemals eine
  /// unpassende Stimme als Ersatz aktivieren.
  bool clipsEnabled = true;

  bool get isEnabled => _enabled;
  bool get cloudVoiceEnabled => _cloudVoiceEnabled;

  /// Counts confirmed native starts, not requests or historical source labels.
  int get startedPlaybackCount => _startedPlaybackCount;

  /// Only a native completion event increments this, never stop or a timeout.
  int get completedPlaybackCount => _completedPlaybackCount;
  String get selectedVoiceName =>
      _identity == LumoVoiceIdentity.freeOffline ? 'Lumo Frei' : 'Sulafat';
  bool get localVoiceLicenseAccepted => _localVoiceLicenseAccepted;
  LumoVoiceIdentity get identity => _identity;
  Future<bool> localSpeechAvailable() => _offline.available();
  String get selectedLocale => 'de-DE';

  set isEnabled(bool value) {
    _enabled = value;
    if (!value) unawaited(stop());
  }

  Future<void> configure({
    bool? enabled,
    double? rate,
    double? pitch,
    bool? cloudVoiceEnabled,
    String? voiceServerUrl,
    LumoParentSpeechAuthorization? parentSpeechAuthorization,
    bool? localVoiceLicenseAccepted,
    LumoVoiceIdentity? identity,
  }) async {
    if (identity != null && identity != _identity) {
      await stop();
      _identity = identity;
    }
    if (localVoiceLicenseAccepted != null) {
      final revoked = _localVoiceLicenseAccepted && !localVoiceLicenseAccepted;
      _localVoiceLicenseAccepted = localVoiceLicenseAccepted;
      if (revoked) await stop();
    }
    if (enabled != null) {
      _enabled = enabled;
      if (!enabled) await stop();
    }
    if (rate != null) {
      // Real speed control for BOTH pre-recorded and generated audio.
      // The device-specific TTS voice (and its pitch controls) is removed.
      _playbackRate = (rate / 0.35).clamp(0.70, 1.60).toDouble();
      try {
        await _player?.setPlaybackRate(_playbackRate);
      } catch (_) {}
    }
    // Pitch is retained as a call parameter for older callers/settings.
    // We do not pretend it changes prerecorded Sulafat voice identity.
    if (cloudVoiceEnabled != null) {
      final revoked = _cloudVoiceEnabled && !cloudVoiceEnabled;
      _cloudVoiceEnabled = cloudVoiceEnabled;
      // Saving an unchanged offline preference (e.g. while changing tempo)
      // must not stop an original recording. Actual revocation cancels audio.
      if (revoked) {
        _parentSpeechAuthorization = null;
        if (_identity == LumoVoiceIdentity.sulafatOriginal) await stop();
      }
    }
    if (voiceServerUrl != null && voiceServerUrl.trim().isNotEmpty) {
      _serverUrl = voiceServerUrl.trim();
    }
    if (parentSpeechAuthorization != null) {
      _parentSpeechAuthorization = parentSpeechAuthorization;
    }
  }

  /// Call on parent logout/revocation. No credential survives as a preference.
  Future<void> clearParentSpeechAuthorization() async {
    _parentSpeechAuthorization = null;
    if (_cloudVoiceEnabled && _identity == LumoVoiceIdentity.sulafatOriginal) {
      await stop();
    }
  }

  @visibleForTesting
  static VoiceStyle suggestedStyle(String text) {
    final s = text.trim().toLowerCase();
    if (s.isEmpty || s.length > 140) return VoiceStyle.warm;
    if (RegExp(
            r'^(super|toll gemacht|genau richtig|wow|bravo|klasse|stark|genial|perfekt|wahnsinn|voll richtig|mega|spitze|ich bin stolz)')
        .hasMatch(s)) {
      return VoiceStyle.celebrate;
    }
    if (RegExp(
            r'^(fast|knapp daneben|hmm|nicht ganz|kein problem|das war fast|du schaffst|das war schwierig|ruhig)')
        .hasMatch(s)) {
      return VoiceStyle.comfort;
    }
    if (RegExp(r'^(hallo|hi!|guten morgen|schön dich zu sehen)').hasMatch(s)) {
      return VoiceStyle.greeting;
    }
    if (s.endsWith('?')) return VoiceStyle.question;
    if (RegExp(r'^(schau|hier ist|lass uns|probier|zuerst|bei plus|bei minus)')
        .hasMatch(s)) {
      return VoiceStyle.explain;
    }
    return VoiceStyle.warm;
  }

  AudioPlayer _ensurePlayer() {
    final player = _player ??= AudioPlayer(playerId: 'lumo-sulafat');
    if (_positionSubscription == null) {
      player.positionUpdater = TimerPositionUpdater(
        interval: const Duration(milliseconds: 50),
        getPosition: player.getCurrentPosition,
      );
      _positionSubscription = player.onPositionChanged.listen((position) {
        if (status.value == VoiceStatus.speaking) _mediaPosition = position;
      });
    }
    _doneSubscription ??= player.onPlayerComplete.listen((_) {
      if (status.value == VoiceStatus.speaking ||
          status.value == VoiceStatus.paused) {
        _finishAudio(completed: true);
      }
    });
    return player;
  }

  Future<void> speak(
    String text, {
    VoiceStyle style = VoiceStyle.warm,
    bool waitForCompletion = false,
    bool freshLocalAudio = false,
  }) async {
    if (!_enabled || text.trim().isEmpty) return;
    // Preflight is independent of the playing generation. Missing offline
    // task audio must not cut a valid praise/welcome recording in mid-sentence.
    final revision = ++_requestRevision;
    final profile = _identity;
    final effectiveStyle =
        style == VoiceStyle.warm ? suggestedStyle(text) : style;
    int? generation;
    try {
      if (profile == LumoVoiceIdentity.freeOffline) {
        await LumoVoiceClips.ensureFreeLoaded();
      } else {
        await LumoVoiceClips.ensureLoaded();
      }
      final original = clipsEnabled && !freshLocalAudio
          ? (profile == LumoVoiceIdentity.freeOffline
              ? LumoVoiceClips.freeLookup(text)
              : LumoVoiceClips.lookup(text))
          : null;
      if (!_enabled || revision != _requestRevision) return;
      if (profile == LumoVoiceIdentity.freeOffline &&
          original == null &&
          !_localVoiceLicenseAccepted) {
        _reportUnavailable(
          'Für diesen Satz gibt es noch keine passende lokale Aufnahme. '
          'Neue Texte können nach Bestätigung der kostenlosen Sprachlizenz '
          'im Elternbereich direkt auf diesem Gerät gesprochen werden.',
        );
        return;
      }
      if (profile == LumoVoiceIdentity.sulafatOriginal &&
          original == null &&
          !_cloudVoiceEnabled) {
        _reportUnavailable(
          'Für diesen Satz gibt es noch keine Originalaufnahme. '
          'Der Text bleibt lesbar. Neue Sulafat-Sätze benötigen eine '
          'Online-Stimmenfreigabe im Elternbereich.',
        );
        return;
      }
      String? parentAuthorization;
      if (profile == LumoVoiceIdentity.sulafatOriginal && original == null) {
        final authorize = _parentSpeechAuthorization;
        if (authorize != null) {
          try {
            parentAuthorization = await authorize().timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            );
          } catch (_) {
            // Session errors never expose a token or cause a text upload.
          }
        }
        if (!_enabled || !_cloudVoiceEnabled || revision != _requestRevision) {
          return;
        }
        if (!LumoSulafatClient.hasParentAuthorization(parentAuthorization)) {
          _reportUnavailable(
              const LumoSpeechAuthorizationUnavailable().userMessage);
          return;
        }
      }
      // An automatically advancing lesson may ask its next question before
      // the previous feedback has finished. Do not cut praise/comfort/welcome.
      // stop(), navigation, mute or a newer request invalidate this wait.
      if (profile == LumoVoiceIdentity.freeOffline &&
          effectiveStyle == VoiceStyle.question &&
          const {VoiceStyle.celebrate, VoiceStyle.comfort, VoiceStyle.greeting}
              .contains(_playingStyle)) {
        final finished = _playbackFinished;
        if (finished != null) await finished.future;
        if (!_enabled || profile != _identity || revision != _requestRevision) {
          return;
        }
      }
      generation = ++_speechGeneration;
      await _stopPlayback();
      if (!_enabled || generation != _speechGeneration) return;
      _playingStyle = effectiveStyle;
      lastError.value = null;
      status.value = VoiceStatus.preparing;
      if (original != null) {
        final end = Completer<void>();
        await _play(
          AssetSource(original.assetSource),
          generation,
          duration: original.duration,
          mouth: original.mouthAt,
          onFinished: end,
          identity: profile == LumoVoiceIdentity.freeOffline
              ? 'Lumo Frei / F2 / lokale Aufnahme ${original.id}.m4a'
              : null,
        );
        if (waitForCompletion) await end.future;
        return;
      }
      final operation = profile == LumoVoiceIdentity.freeOffline
          ? _speakLocal(text, effectiveStyle, generation)
          : _speakDynamic(text, effectiveStyle, generation,
              parentAuthorization: parentAuthorization!);
      if (waitForCompletion) {
        await operation;
      } else {
        unawaited(operation);
      }
    } catch (e) {
      if (!_enabled ||
          (generation == null
              ? revision != _requestRevision
              : generation != _speechGeneration)) {
        return;
      }
      _reportUnavailable(
          '$selectedVoiceName-Audio konnte nicht gestartet werden.');
    }
  }

  Future<void> _speakLocal(
      String text, VoiceStyle style, int generation) async {
    final cleaned = LumoVoicePolicy.prepare(text);
    // Segmentation is a pure shared helper, not a Sulafat/provider call.
    final fragments = LumoSulafatClient.segments(cleaned, limit: 180);
    for (final fragment in fragments) {
      if (!_enabled ||
          !_localVoiceLicenseAccepted ||
          _identity != LumoVoiceIdentity.freeOffline ||
          generation != _speechGeneration) {
        return;
      }
      try {
        _localInferenceGeneration = generation;
        late final Uint8List audio;
        try {
          audio = await _offline.synthesize(
            text: fragment,
            style: style.name,
            localLicenseAccepted: _localVoiceLicenseAccepted,
          );
        } finally {
          if (_localInferenceGeneration == generation) {
            _localInferenceGeneration = null;
          }
        }
        if (!_enabled || generation != _speechGeneration) return;
        final pcm = LumoWavAudio.parse(audio);
        final end = Completer<void>();
        await _play(BytesSource(audio), generation,
            duration: pcm.duration,
            mouth: pcm.mouthAt,
            onFinished: end,
            identity: 'Lumo Frei / F2 / lokale Synthese');
        await end.future;
        if (lastError.value != null) return;
      } catch (error) {
        if (!_enabled || generation != _speechGeneration) return;
        _reportUnavailable(error is LumoOfflineSpeechException
            ? error.userMessage
            : 'Die lokale Lumo-Stimme konnte diesen Satz nicht vorlesen. '
                'Der Text bleibt lesbar.');
        return;
      }
    }
  }

  void _reportUnavailable(String message) {
    lastError.value = message;
    final validAudioPending = _playingGeneration != null &&
        (status.value == VoiceStatus.speaking ||
            status.value == VoiceStatus.paused ||
            status.value == VoiceStatus.preparing);
    if (!validAudioPending) {
      status.value = VoiceStatus.error;
    }
  }

  Future<void> _speakDynamic(String text, VoiceStyle style, int generation,
      {required String parentAuthorization}) async {
    final cleaned = LumoVoicePolicy.prepare(text);
    final fragments = LumoSulafatClient.segments(cleaned);
    for (final fragment in fragments) {
      if (!_enabled || !_cloudVoiceEnabled || generation != _speechGeneration) {
        return;
      }
      try {
        final cancellation = LumoSpeechCancellation();
        _pendingRequest = cancellation;
        final audio = await _client.synthesize(
          text: fragment,
          style: style.name,
          baseUrl: _serverUrl,
          parentAuthorization: parentAuthorization,
          cancellation: cancellation,
        );
        if (identical(_pendingRequest, cancellation)) _pendingRequest = null;
        if (!_enabled ||
            !_cloudVoiceEnabled ||
            generation != _speechGeneration) {
          return;
        }
        final pcm = LumoWavAudio.parse(audio);
        final end = Completer<void>();
        await _play(BytesSource(audio), generation,
            duration: pcm.duration, mouth: pcm.mouthAt, onFinished: end);
        // The playback watchdog measures active time, not time spent paused.
        // A wall-clock timeout would silently end a deliberately paused lesson.
        await end.future;
        if (lastError.value != null) return;
      } catch (e) {
        if (!_enabled || generation != _speechGeneration) return;
        // No Android fallback, even if the provider, network or cache fails.
        lastError.value = switch (e) {
          LumoSpeechHttpException() => e.userMessage,
          LumoSpeechAuthorizationUnavailable() => e.userMessage,
          _ => 'Sulafat ist derzeit nicht erreichbar. '
              'Bitte Online-Stimme im Elternbereich und die Serververbindung prüfen.',
        };
        status.value = VoiceStatus.error;
        return;
      }
    }
  }

  Future<void> speakAndWait(String text,
          {VoiceStyle style = VoiceStyle.warm}) =>
      speak(text, style: style, waitForCompletion: true);

  Future<void> _play(
    Source source,
    int generation, {
    required Duration duration,
    double Function(Duration)? mouth,
    Completer<void>? onFinished,
    String? identity,
  }) async {
    await _serializeNative(() async {
      try {
        await _playReady(source, generation,
            duration: duration,
            mouth: mouth,
            onFinished: onFinished,
            identity: identity);
      } catch (_) {
        if (onFinished != null && !onFinished.isCompleted) {
          onFinished.complete();
        }
        _finishAudio(generation: generation);
        rethrow;
      }
    });
  }

  Future<void> _serializeNative(Future<void> Function() action) async {
    // Startup and pause/resume share one short native-operation queue.
    // stop() stays independent: muting must never wait for native preparation.
    final previous = _startup;
    final ready = Completer<void>();
    _startup = ready.future;
    try {
      await previous;
      await action();
    } finally {
      ready.complete();
    }
  }

  Future<void> _playReady(
    Source source,
    int generation, {
    required Duration duration,
    double Function(Duration)? mouth,
    Completer<void>? onFinished,
    String? identity,
  }) async {
    void completeCancelled() {
      if (onFinished != null && !onFinished.isCompleted) {
        onFinished.complete();
      }
    }

    if (!_enabled || generation != _speechGeneration) {
      completeCancelled();
      return;
    }
    final player = _ensurePlayer();
    _playbackFinished = onFinished;
    _playingGeneration = generation;
    _mediaPosition = Duration.zero;
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1);
    if (!_enabled || generation != _speechGeneration) {
      completeCancelled();
      _finishAudio(generation: generation);
      return;
    }
    await player.play(source);
    if (!_enabled || generation != _speechGeneration) {
      await player.stop();
      completeCancelled();
      _finishAudio(generation: generation);
      return;
    }
    try {
      await player.setPlaybackRate(_playbackRate);
    } catch (_) {}
    if (!_enabled || generation != _speechGeneration) {
      await player.stop();
      completeCancelled();
      _finishAudio(generation: generation);
      return;
    }
    lastStartedAudioIdentity = identity ??
        (source is AssetSource
            ? 'Originalaufnahme ${source.path.split('/').last}'
            : 'Sulafat / ${LumoSulafatClient.referenceProfile} / ${LumoSulafatClient.referenceModel}');
    ++_startedPlaybackCount;
    status.value = VoiceStatus.speaking;
    clipMouth.value = 0;
    _playbackWatch = Stopwatch()..start();
    _mouthEnvelope = mouth;
    _playbackMax = Duration(
      // Slowest supported rate also covers a tempo change during playback.
      milliseconds: (duration.inMilliseconds / 0.70).ceil() + 400,
    );
    _startMouthTicker(player, generation);
  }

  void _startMouthTicker(AudioPlayer player, int generation) {
    _mouthTicker?.cancel();
    _mouthTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (generation != _speechGeneration) {
        t.cancel();
        return;
      }
      if ((_playbackWatch?.elapsed ?? Duration.zero) > _playbackMax) {
        unawaited(_serializeNative(() async {
          if (generation == _speechGeneration) {
            try {
              await player.stop();
            } catch (_) {}
          }
        }));
        lastError.value = 'Die vollständige Wiedergabe wurde nicht bestätigt. '
            'Bitte Vorlesen erneut starten.';
        _finishAudio(generation: generation);
        return;
      }
      // The timer only samples the native media position. Silence in the
      // waveform closes the mouth; no sine-wave animation or fake word events.
      clipMouth.value = _mouthEnvelope?.call(_mediaPosition) ?? 0;
    });
  }

  /// Pauses the same native source without seeking, regenerating or uploading.
  Future<void> pause() async {
    final generation = _playingGeneration;
    if (generation == null || status.value != VoiceStatus.speaking) return;
    await _serializeNative(() async {
      if (!_enabled ||
          generation != _speechGeneration ||
          generation != _playingGeneration ||
          status.value != VoiceStatus.speaking) {
        return;
      }
      final player = _player!;
      try {
        await player.pause();
        if (!_enabled ||
            generation != _speechGeneration ||
            generation != _playingGeneration) {
          // A native callback can finish after mute/navigation cancelled it.
          await player.stop();
          return;
        }
        _playbackWatch?.stop();
        _mouthTicker?.cancel();
        _mouthTicker = null;
        clipMouth.value = 0;
        status.value = VoiceStatus.paused;
      } catch (_) {
        if (generation == _speechGeneration) {
          lastError.value = 'Die Lumo-Aufnahme konnte nicht pausiert werden.';
        }
      }
    });
  }

  /// Continues at the native media position. A cancelled source cannot resume.
  Future<void> resume() async {
    final generation = _playingGeneration;
    if (generation == null || status.value != VoiceStatus.paused) return;
    await _serializeNative(() async {
      if (!_enabled ||
          generation != _speechGeneration ||
          generation != _playingGeneration ||
          status.value != VoiceStatus.paused) {
        return;
      }
      final player = _player!;
      try {
        await player.resume();
        if (!_enabled ||
            generation != _speechGeneration ||
            generation != _playingGeneration) {
          await player.stop();
          return;
        }
        _playbackWatch?.start();
        clipMouth.value = 0;
        status.value = VoiceStatus.speaking;
        _startMouthTicker(player, generation);
      } catch (_) {
        if (generation == _speechGeneration) {
          lastError.value =
              'Die Lumo-Aufnahme konnte nicht fortgesetzt werden.';
        }
      }
    });
  }

  void _finishAudio({int? generation, bool completed = false}) {
    if (generation != null && generation != _playingGeneration) return;
    if (completed && _playingGeneration != null) ++_completedPlaybackCount;
    _playingGeneration = null;
    _playingStyle = null;
    _mouthTicker?.cancel();
    _mouthTicker = null;
    _playbackWatch?.stop();
    _playbackWatch = null;
    _mouthEnvelope = null;
    clipMouth.value = null;
    if (_playbackFinished != null && !_playbackFinished!.isCompleted) {
      _playbackFinished!.complete();
    }
    _playbackFinished = null;
    if (status.value == VoiceStatus.speaking ||
        status.value == VoiceStatus.paused) {
      status.value =
          lastError.value == null ? VoiceStatus.idle : VoiceStatus.error;
    }
  }

  Future<void> _stopPlayback() async {
    _pendingRequest?.cancel();
    _pendingRequest = null;
    final cancelLocal = _localInferenceGeneration != null;
    _localInferenceGeneration = null;
    final localCancellation =
        cancelLocal ? _offline.cancel() : Future<void>.value();
    _finishAudio();
    try {
      await _player?.stop();
    } catch (_) {}
    if (status.value != VoiceStatus.error) status.value = VoiceStatus.idle;
    await localCancellation;
  }

  Future<void> stop() async {
    ++_requestRevision;
    ++_speechGeneration;
    await _stopPlayback();
    status.value = VoiceStatus.idle;
  }

  /// The active identity supplies this sample; old original binaries stay intact.
  Future<void> test() => speak(
        'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!',
        style: VoiceStyle.greeting,
      );
}

/// Beendet Lumos Sprechen, sobald eine Seite verlassen oder ersetzt wird,
/// damit alter Text nicht auf der nächsten Seite weiterläuft.
class LumoVoiceRouteObserver extends NavigatorObserver {
  LumoVoiceRouteObserver({LumoVoice? voice})
      : _voice = voice ?? LumoVoice.instance;

  final LumoVoice _voice;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopForPage(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopForPage(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopForPage(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stopForPage(oldRoute);
  }

  void _stopForPage(Route<dynamic> route) {
    // Dialoge und Bottom-Sheets (z. B. Lumo-Gespräch) steuern ihr Sprechen selbst.
    if (route is! PageRoute) return;
    // Auch eine noch laufende Online-Synthese abbrechen, bevor sie auf
    // einer anderen Seite versehentlich abgespielt werden koennte.
    unawaited(_voice.stop());
  }
}

enum VoiceStyle { warm, greeting, explain, celebrate, comfort, question }

enum LumoVoiceIdentity { freeOffline, sulafatOriginal }

enum VoiceStatus { idle, preparing, speaking, paused, error }
