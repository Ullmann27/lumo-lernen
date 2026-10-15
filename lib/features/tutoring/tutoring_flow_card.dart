import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/progress_recommendation_service.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

/// A real, optional next step using the current child's existing local records.
/// The card does not infer attempts from errors, diagnose a child, manufacture
/// mastery, grant discovery access, or promise unimplemented games and rewards.
class TutoringFlowCard extends StatefulWidget {
  const TutoringFlowCard({
    super.key,
    required this.appState,
    required this.onStartTutoring,
    required this.onStartGuidedLearning,
  });

  final LumoAppState appState;
  final ValueChanged<LearningActivityRecommendation> onStartTutoring;
  final FutureOr<void> Function(GuidedLesson?) onStartGuidedLearning;

  @override
  State<TutoringFlowCard> createState() => _TutoringFlowCardState();
}

class _TutoringFlowCardState extends State<TutoringFlowCard> {
  final _lumo = LumoCharacterController();
  LearningProfileLease? _owner;
  LearningActivityRecommendation? _recommendation;
  late int _generation;
  int _request = 0;
  bool _loading = true;
  bool _refreshQueued = false;
  bool _reasonOpen = false;
  bool _retrying = false;
  bool _openingGuided = false;
  String? _error;
  String? _saveError;
  String? _activityError;

  static const _body = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: LumoVisualTokens.white);

  bool get _current =>
      !_loading &&
      _error == null &&
      _owner != null &&
      widget.appState.isCurrentLearningLease(_owner!) &&
      _recommendation?.grade == widget.appState.state.grade.clamp(1, 4);

  GuidedLesson? get _lesson {
    final recommendation = _recommendation;
    if (!_current || recommendation == null) return null;
    return GuidedLessonCatalog.schoolIntroduction(
        subject: recommendation.subject,
        unit: recommendation.unit,
        grade: recommendation.grade);
  }

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    widget.appState.addListener(_changed);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant TutoringFlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState == widget.appState) return;
    oldWidget.appState.removeListener(_changed);
    widget.appState.addListener(_changed);
    _generation = widget.appState.profileGeneration;
    _clear();
    unawaited(_load());
  }

  void _clear() {
    _request++;
    _owner = null;
    _recommendation = null;
    _loading = true;
    _reasonOpen = false;
    _retrying = false;
    _openingGuided = false;
    _error = null;
    _saveError = null;
    _activityError = null;
  }

  void _changed() {
    if (_generation != widget.appState.profileGeneration) {
      _generation = widget.appState.profileGeneration;
      // Disable old callbacks synchronously, before a new profile can paint.
      _clear();
      unawaited(_load());
    } else if (_owner != null &&
        widget.appState.isCurrentLearningLease(_owner!)) {
      _recommend();
    }
    _queueRefresh();
  }

  void _queueRefresh() {
    if (_refreshQueued || !mounted) return;
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      if (mounted) setState(() {});
    });
  }

  void _recommend() {
    final owner = _owner;
    if (owner == null || !widget.appState.isCurrentLearningLease(owner)) return;
    final next = const ProgressRecommendationService().recommend(
        grade: widget.appState.state.grade, skills: owner.profile.skills);
    if (_recommendation?.unit != next.unit ||
        _recommendation?.subject != next.subject) {
      _reasonOpen = false;
    }
    _recommendation = next;
  }

  Future<void> _load() async {
    final request = ++_request;
    final app = widget.appState;
    try {
      final owner = await app.captureLearningProfile();
      await app.prepareLearningLease(owner);
      if (!mounted ||
          request != _request ||
          app != widget.appState ||
          !app.isCurrentLearningLease(owner)) {
        return;
      }
      _owner = owner;
      _recommend();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || request != _request || app != widget.appState) return;
      setState(() {
        _loading = false;
        _error = 'Deine Lerndaten konnten nicht sicher geladen werden. '
            'Wir ändern oder löschen sie nicht.';
      });
    }
  }

  bool _matches(
          LearningProfileLease owner, LearningActivityRecommendation shown) =>
      _current &&
      !_retrying &&
      !_openingGuided &&
      identical(owner, _owner) &&
      identical(shown, _recommendation);

  void _practice(
      LearningProfileLease owner, LearningActivityRecommendation shown) {
    if (_matches(owner, shown)) widget.onStartTutoring(shown);
  }

  Future<void> _guided(LearningProfileLease owner,
      LearningActivityRecommendation shown, GuidedLesson? lesson) async {
    if (!_matches(owner, shown)) return;
    setState(() {
      _openingGuided = true;
      _activityError = null;
    });
    try {
      // Keep the real section transition. A second pointer event must not
      // start another fade or push a second course route.
      await widget.onStartGuidedLearning(lesson);
    } catch (_) {
      if (mounted && identical(_owner, owner)) {
        _activityError = 'Der Bildkurs konnte nicht geöffnet werden. '
            'Deine Lerndaten bleiben erhalten. Bitte versuche es erneut.';
      }
    } finally {
      if (mounted && identical(_owner, owner)) {
        setState(() => _openingGuided = false);
      }
    }
  }

  Future<void> _retrySave(
      LearningProfileLease owner, LearningActivityRecommendation shown) async {
    if (!_matches(owner, shown)) return;
    setState(() {
      _retrying = true;
      _saveError = null;
    });
    try {
      // Retry the accepted write, never record another answer or reward.
      await widget.appState.flushLearningProgress(lease: owner);
    } catch (_) {
      if (mounted && identical(_owner, owner)) {
        _saveError = 'Noch nicht gespeichert. Dein Lernstand bleibt erhalten. '
            'Du kannst es erneut versuchen.';
      }
    } finally {
      if (mounted && identical(_owner, owner)) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  void dispose() {
    _request++;
    widget.appState.removeListener(_changed);
    _lumo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final lesson = _lesson;
    final settings = widget.appState.state.settings;
    final quiet = settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    return LumoGlassCard(
      key: const ValueKey('tutoring-real-learning-path'),
      surfaceOpacity: .9,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (largeText)
              _header()
            else
              Row(
                children: [
                  LumoCharacter(
                      pose: LumoDesignFoxPose.bookPoint,
                      size: 100,
                      intro: false,
                      idleHops: false,
                      reduceMotion: quiet,
                      controller: _lumo),
                  const SizedBox(width: 14),
                  Expanded(child: _header()),
                ],
              ),
            const SizedBox(height: 18),
            if (_loading)
              const Text('Dein Lernweg wird geladen…', style: _body)
            else if (_error != null) ...[
              Text(_error!,
                  key: const ValueKey('tutoring-read-error'), style: _body),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('tutoring-read-retry'),
                style: _goldButton(),
                onPressed: () {
                  setState(_clear);
                  unawaited(_load());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
            ] else if (recommendation != null && _current)
              LayoutBuilder(builder: (context, constraints) {
                final suggestion = _suggestion(recommendation);
                final activities = _activities(lesson);
                final evidence = _evidence(recommendation);
                if (constraints.maxWidth >= 680 && !largeText) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              suggestion,
                              const SizedBox(height: 14),
                              evidence,
                            ],
                          )),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: activities),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    suggestion,
                    const SizedBox(height: 14),
                    activities,
                    const SizedBox(height: 18),
                    evidence,
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lumos Lernweg',
              style: _body.copyWith(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Kleine Schritte. Du wählst das Tempo.', style: _body),
        ],
      );

  Widget _suggestion(LearningActivityRecommendation recommendation) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(recommendation.title,
              style: _body.copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF123B65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: LumoVisualTokens.cyan.withValues(alpha: .5)),
            ),
            child: Text(
                '${recommendation.subject} · '
                '${recommendation.unit}',
                key: const ValueKey('tutoring-recommended-topic'),
                style: _body.copyWith(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Text(recommendation.message, style: _body),
        ],
      );

  Widget _evidence(LearningActivityRecommendation recommendation) {
    final owner = _owner!;
    final pending = owner.profile.hasUnsavedChanges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          pending
              ? 'Ein Lernstand ist noch nicht sicher gespeichert. '
                  'Dieser Vorschlag ist vorläufig.'
              : recommendation.evidenceAttempts == 0
                  ? 'Für diesen Vorschlag gibt es noch keine passenden '
                      'gespeicherten Antworten.'
                  : 'Grundlage: ${recommendation.evidenceAttempts} '
                      'gespeicherte Antworten zu diesem Thema.',
          key: const ValueKey('tutoring-real-evidence'),
          style: _body.copyWith(fontSize: 16, color: LumoVisualTokens.muted),
        ),
        if (pending) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('tutoring-save-retry'),
            onPressed: _retrying || _openingGuided
                ? null
                : () => unawaited(_retrySave(owner, recommendation)),
            style: _outlineButton(),
            icon: const Icon(Icons.save_rounded),
            label: Text(
                _retrying ? 'Wird gespeichert…' : 'Speichern erneut versuchen'),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 10),
            Text(_saveError!, style: _body),
          ],
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('tutoring-reason-toggle'),
            style: TextButton.styleFrom(
                foregroundColor: LumoVisualTokens.cyanBright,
                minimumSize: const Size(64, 56),
                textStyle: _body.copyWith(fontSize: 17)),
            onPressed: () {
              if (!_matches(owner, recommendation)) return;
              setState(() => _reasonOpen = !_reasonOpen);
              if (_reasonOpen) _lumo.think();
            },
            icon: Icon(_reasonOpen
                ? Icons.expand_less_rounded
                : Icons.info_outline_rounded),
            label: Text(
                _reasonOpen ? 'Begründung einklappen' : 'Warum dieses Thema?'),
          ),
        ),
        if (_reasonOpen) ...[
          const SizedBox(height: 6),
          Text(
              pending
                  ? 'Noch nicht alle erfassten Lernereignisse sind sicher '
                      'gespeichert. Dieser Vorschlag ist keine feste '
                      'Bewertung deiner Fähigkeiten.'
                  : recommendation.reason,
              key: const ValueKey('tutoring-real-reason'),
              style: _body),
          const SizedBox(height: 8),
          const Text(
              'Das ist ein Vorschlag, keine Bewertung von dir. '
              'Du darfst ein anderes Thema wählen.',
              style: _body),
        ],
      ],
    );
  }

  Widget _activities(GuidedLesson? lesson) {
    final owner = _owner!;
    final recommendation = _recommendation!;
    final enabled = _current && !_retrying && !_openingGuided;
    final available = GuidedLessonCatalog.all
        .where((course) => course.grade <= widget.appState.state.grade)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lesson != null) ...[
          Text('Bildkurs: ${lesson.title}',
              style: _body.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('${lesson.steps.length} Kursschritte, in deinem Tempo.',
              style: _body.copyWith(fontSize: 16)),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('tutoring-guided-start'),
            onPressed: enabled
                ? () => unawaited(_guided(owner, recommendation, lesson))
                : null,
            style: _goldButton(),
            icon: const Icon(Icons.school_rounded),
            label: Text(
                _openingGuided ? 'Kurs wird geöffnet…' : 'Mit Lumo verstehen'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('tutoring-practice-start'),
            onPressed: enabled ? () => _practice(owner, recommendation) : null,
            style: _outlineButton(),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Zum Thema üben'),
          ),
        ] else ...[
          FilledButton.icon(
            key: const ValueKey('tutoring-practice-start'),
            onPressed: enabled ? () => _practice(owner, recommendation) : null,
            style: _goldButton(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Empfohlenes Thema üben'),
          ),
          const SizedBox(height: 18),
          const Text('Geführte Themen entdecken', style: _body),
          const SizedBox(height: 8),
          Text(
              available == 1
                  ? 'Eine geführte Einführung ist für deinen '
                      'Schulstoff verfügbar.'
                  : '$available geführte Einführungen sind für '
                      'deinen Schulstoff verfügbar.',
              style: _body.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('tutoring-guided-start'),
            onPressed: enabled
                ? () => unawaited(_guided(owner, recommendation, lesson))
                : null,
            style: _outlineButton(),
            icon: const Icon(Icons.auto_stories_rounded),
            label: Text(_openingGuided
                ? 'Kurse werden geöffnet…'
                : 'Bildkurse anschauen'),
          ),
        ],
        const SizedBox(height: 10),
        const Text('Keine Pflicht. Du kannst jederzeit etwas anderes lernen.',
            style: _body),
        if (_activityError != null) ...[
          const SizedBox(height: 10),
          Text(_activityError!,
              key: const ValueKey('tutoring-navigation-error'), style: _body),
        ],
      ],
    );
  }

  ButtonStyle _goldButton() => FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: LumoVisualTokens.gold,
        foregroundColor: const Color(0xFF172844),
        textStyle: _body.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
      );

  ButtonStyle _outlineButton() => OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        foregroundColor: LumoVisualTokens.white,
        backgroundColor: const Color(0xFF123454),
        side: BorderSide(color: LumoVisualTokens.cyan.withValues(alpha: .75)),
        textStyle: _body.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
      );
}
