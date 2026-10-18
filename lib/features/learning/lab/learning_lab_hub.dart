import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/learning_journey.dart';
import '../../../core/progress_repository.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'learning_lab_catalog.dart';
import 'learning_lab_screen.dart';

/// Reachable learning worlds with honest, stored skill explanations.
class LearningLabHub extends StatefulWidget {
  const LearningLabHub({super.key, required this.appState});
  final LumoAppState appState;
  @override
  State<LearningLabHub> createState() => _LearningLabHubState();
}

class _LearningLabHubState extends State<LearningLabHub> {
  bool _loading = true;
  String? _error;
  int? _generation;
  Map<String, JourneySkill> _records = const {};

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_watchProfile);
    unawaited(_reload());
  }

  void _watchProfile() {
    if (_generation != null &&
        _generation != widget.appState.profileGeneration && mounted) {
      _generation = null;
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    final generation = widget.appState.profileGeneration;
    _generation = generation;
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      await owner.profile.loadJourney();
      if (!mounted || generation != widget.appState.profileGeneration ||
          !widget.appState.isCurrentLearningLease(owner)) return;
      setState(() {
        _records = owner.profile.journey.records;
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == widget.appState.profileGeneration) {
        setState(() {
          _loading = false;
          _error = 'Dein Lernstand konnte nicht geladen werden. Bitte erneut versuchen.';
        });
      }
    }
  }

  Future<void> _open(LabTopic topic) async {
    if (topic.minimumGrade > widget.appState.state.grade) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LearningLabScreen(
        appState: widget.appState, topic: topic)),
    );
    if (mounted) unawaited(_reload());
  }

  @override
  Widget build(BuildContext context) {
    final topics = LabCatalog.forGrade(widget.appState.state.grade);
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        title: const Text('Lumos Lernatelier'),
        foregroundColor: LumoVisualTokens.white,
        backgroundColor: LumoVisualTokens.night,
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: LumoVisualTokens.white)),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('lab-hub-retry'),
                    onPressed: () => unawaited(_reload()),
                    child: const Text('Erneut versuchen')),
                ])))
            : ListView(
                key: const ValueKey('learning-lab-worlds'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  const Text('Entdecken, bauen, selbst verstehen',
                      style: TextStyle(color: LumoVisualTokens.white,
                          fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Lumo zeigt dir zuerst ein Beispiel. Danach baust du selbst und prüfst, was du ohne Hilfe kannst.',
                    style: TextStyle(color: LumoVisualTokens.muted,
                        fontSize: 15, height: 1.4)),
                  const SizedBox(height: 16),
                  for (final topic in topics) ...[
                    Builder(builder: (context) {
                      final record = _records[SkillRecord.makeId(
                          topic.subject, topic.unit)];
                      return Card(
                        color: const Color(0xFF123659),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF40739A))),
                        child: InkWell(
                          key: ValueKey('lab-topic-' + topic.id),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _open(topic),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topic.title,
                                    style: const TextStyle(
                                      color: LumoVisualTokens.white,
                                      fontSize: 20, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 7),
                                Text(topic.goal,
                                    style: const TextStyle(
                                      color: LumoVisualTokens.muted,
                                      fontSize: 15)),
                                const SizedBox(height: 10),
                                Text(record?.statusLabel ?? 'Neu entdecken',
                                    style: const TextStyle(
                                      color: LumoVisualTokens.cyanBright,
                                      fontSize: 16, fontWeight: FontWeight.w900)),
                                if (record != null) ...[
                                  const SizedBox(height: 6),
                                  Text(record.recommendationReason(DateTime.now()),
                                    style: const TextStyle(
                                        color: LumoVisualTokens.white,
                                        fontSize: 13, height: 1.35)),
                                ],
                                const SizedBox(height: 10),
                                const Align(alignment: Alignment.centerRight,
                                  child: Icon(Icons.arrow_forward_rounded,
                                    color: LumoVisualTokens.cyanBright)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    widget.appState.removeListener(_watchProfile);
    super.dispose();
  }
}
