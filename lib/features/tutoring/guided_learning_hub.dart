import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import 'guided_lesson_screen.dart';

class GuidedLearningHub extends StatefulWidget {
  const GuidedLearningHub({
    super.key,
    required this.appState,
    required this.discovery,
    this.preferredLessonId,
    this.requestedTopicTitle,
  });
  final LumoAppState appState;
  final bool discovery;
  final String? preferredLessonId;
  final String? requestedTopicTitle;

  @override
  State<GuidedLearningHub> createState() => _GuidedLearningHubState();
}

class _GuidedLearningHubState extends State<GuidedLearningHub> {
  late final int _generation;
  LearningProfileLease? _owner;
  bool _loading = true;
  bool _stale = false;
  String? _error;

  static const _text = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w700);

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    widget.appState.addListener(_changed);
    unawaited(_load());
  }

  void _changed() {
    if (_stale || widget.appState.profileGeneration == _generation) return;
    _stale = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (widget.discovery) await owner.profile.loadDiscovery();
      if (!mounted ||
          _stale ||
          !widget.appState.isCurrentLearningLease(owner)) {
        return;
      }
      setState(() {
        _owner = owner;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || _stale) return;
      setState(() {
        _loading = false;
        _error = 'Deine Lerndaten konnten nicht sicher geladen werden. '
            'Sie bleiben unverändert.';
      });
    }
  }

  bool _allowed(GuidedLesson lesson) =>
      !_loading &&
      !_stale &&
      _owner != null &&
      (widget.discovery
          ? _owner!.profile.canDiscover(lesson.grade)
          : lesson.grade <= widget.appState.state.grade);

  Future<void> _open(GuidedLesson lesson) async {
    if (!_allowed(lesson)) return;
    await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => GuidedLessonScreen(
            appState: widget.appState,
            lesson: lesson,
            discovery: widget.discovery)));
    if (mounted && !_stale) await _load();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.discovery ? 'Mit Lumo Neues entdecken' : 'Lumo erklärt es mir';
    final visible = GuidedLessonCatalog.all.where((lesson) =>
        widget.discovery || lesson.grade <= widget.appState.state.grade);
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        backgroundColor: LumoVisualTokens.night,
        foregroundColor: LumoVisualTokens.white,
        toolbarHeight: 72,
        title: Text(title,
            maxLines: 2,
            style: _text.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
      ),
      body: LumoSceneBackground(
        scene: LumoScene.learning,
        showPlaceholderLabel: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LumoGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          widget.discovery
                              ? 'Neugierig sein darfst du!'
                              : 'Erst verstehen, dann selbst ausprobieren.',
                          style: _text.copyWith(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(
                          widget.discovery
                              ? 'Dein Schulstoff bleibt bei der '
                                  '${widget.appState.state.grade}. Klasse. '
                                  'Entdeckungen bekommen ihren eigenen Lernweg.'
                              : 'Ein Beispiel anschauen, gemeinsam üben, '
                                  'eine neue Aufgabe selbst lösen. '
                                  'Du bestimmst das Tempo.',
                          style: _text),
                      if (widget.requestedTopicTitle != null) ...[
                        const SizedBox(height: 12),
                        Text(
                            widget.preferredLessonId != null
                                ? 'Dein ausgewähltes Thema: ${widget.requestedTopicTitle}. '
                                    'Beginne unten mit seiner Einführung.'
                                : 'Für „${widget.requestedTopicTitle}“ gibt es hier '
                                    'noch keine geführte Einführung. '
                                    'Die tatsächlich verfügbaren Lernwege stehen unten.',
                            style: _text),
                      ],
                      if (_loading) ...[
                        const SizedBox(height: 12),
                        const Text('Dein Lernweg wird geladen…', style: _text),
                      ],
                      if (_stale || _error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                            _stale
                                ? 'Das Kinderprofil wurde gewechselt.'
                                : _error!,
                            style: _text),
                      ],
                      if (!_loading &&
                          !_stale &&
                          _error == null &&
                          widget.discovery &&
                          !_owner!.profile.discovery.enabled) ...[
                        const SizedBox(height: 12),
                        const Text(
                            'Bitte gib das Gerät einer erwachsenen Person. '
                            'Im Elternbereich kann Neues entdecken für '
                            'dieses Profil freigegeben werden.',
                            style: _text),
                      ],
                      if (_owner?.profile.discoveryPermissionPending ==
                          true) ...[
                        const SizedBox(height: 12),
                        const Text(
                            'Die Elternfreigabe ist noch nicht sicher '
                            'gespeichert. Bis dahin bleibt Vorlernen gesperrt.',
                            style: _text),
                      ],
                    ],
                  ),
                ),
                for (final lesson in visible) ...[
                  const SizedBox(height: 16),
                  LumoGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(lesson.title,
                            style: _text.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(lesson.description, style: _text),
                        const SizedBox(height: 8),
                        Text(
                            '${lesson.subject} · Einführung ab der ${lesson.grade}. Schulstufe',
                            style: _text),
                        if (widget.discovery &&
                            _owner?.profile.discovery.topics[lesson.id]
                                    ?.introduced ==
                                true) ...[
                          const SizedBox(height: 8),
                          const Text(
                              'Die Einführung hast du schon angeschaut. '
                              'Du darfst sie jederzeit wiederholen.',
                              style: _text),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          key: ValueKey('guided-open-${lesson.id}'),
                          onPressed: _allowed(lesson)
                              ? () => unawaited(_open(lesson))
                              : null,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(64, 56),
                              backgroundColor: LumoVisualTokens.gold,
                              foregroundColor: const Color(0xFF172844)),
                          icon: Icon(_allowed(lesson)
                              ? Icons.play_arrow_rounded
                              : Icons.family_restroom_rounded),
                          label: Text(
                              _allowed(lesson)
                                  ? 'Mit Lumo anfangen'
                                  : 'Elternfreigabe erforderlich',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                    'Weitere geführte Einführungen werden noch ergänzt. '
                    'Diese Lernwege sind keine vollständige '
                    'Abdeckung aller vier Schulstufen.',
                    style: _text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
