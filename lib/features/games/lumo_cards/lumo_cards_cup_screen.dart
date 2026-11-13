import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import 'lumo_cards_cup.dart';
import 'lumo_cards_screen.dart';
import 'lumo_cards_bot_policy.dart';

class LumoCardsCupScreen extends StatefulWidget {
  const LumoCardsCupScreen({super.key, required this.appState});
  final LumoAppState appState;
  @override
  State<LumoCardsCupScreen> createState() => _LumoCardsCupScreenState();
}

class _LumoCardsCupScreenState extends State<LumoCardsCupScreen> {
  LearningProfileLease? _owner;
  LumoCardsCupRepository? _repository;
  LumoCardsCup? _cup;
  String? _error;
  bool _opening = false;
  bool get _valid =>
      mounted &&
      _owner != null &&
      widget.appState.isCurrentLearningLease(_owner!);

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onProfileChanged);
    _load();
  }

  void _onProfileChanged() {
    if (!mounted || _owner == null || _valid) return;
    setState(() {
      _cup = null;
      _repository = null;
      _error = 'Das Kinderprofil hat gewechselt. Bitte öffne den Pokal erneut.';
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (!mounted || !widget.appState.isCurrentLearningLease(owner)) return;
      _owner = owner;
      final repository = LumoCardsCupRepository(
          studentId: owner.studentId, grade: widget.appState.state.grade);
      final cup = await repository.load(canWrite: () => _valid);
      if (!_valid) return;
      setState(() {
        _repository = repository;
        _cup = cup;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Dein Pokal konnte noch nicht geladen werden.');
    }
  }

  Future<void> _play() async {
    final cup = _cup;
    final repository = _repository;
    if (!_valid ||
        _opening ||
        cup == null ||
        repository == null ||
        cup.complete) return;
    setState(() => _opening = true);
    final leg = cup.nextRound;
    final opponent = LumoCardsCup.opponents[leg];
    try {
      await Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => LumoCardsScreen(
                appState: widget.appState,
                vsBot: true,
                skipIntro: true,
                sessionSlot: 'cup-${cup.id}-$leg',
                initialDifficulty: opponent.difficulty,
                initialStyle: opponent.style,
                tournamentRound: leg + 1,
                tournamentRounds: 3,
                onRoundCompleted: (roundId, won) async {
                  final saved = await repository.record(
                      cupId: cup.id,
                      round: leg,
                      roundId: roundId,
                      won: won,
                      canWrite: () => _valid);
                  if (!_valid) throw StateError('Cup profile changed');
                  setState(() => _cup = saved);
                },
                continueLabel: 'Zum Pokal',
                onContinue: (routeContext) => Navigator.of(routeContext).pop(),
              )));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _restart() async {
    if (!_valid || _cup == null || _repository == null) return;
    try {
      final next =
          await _repository!.restart(cupId: _cup!.id, canWrite: () => _valid);
      if (_valid)
        setState(() {
          _cup = next;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Der neue Pokal konnte noch nicht gespeichert werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cup = _cup;
    return Scaffold(
      backgroundColor: const Color(0xFF071B3B),
      appBar: AppBar(title: const Text('Lumo Cards · Sternenpokal')),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.emoji_events_rounded,
                size: 90,
                color: cup?.complete == true
                    ? const Color(0xFFFFD56E)
                    : const Color(0xFF7BE5EA)),
            Text(
                cup?.complete == true
                    ? cup!.medal
                    : 'Drei Gegnerstile · ein Pokal',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
                'Spiele drei Runden gegen Lumo. Seine Planung wird mit jeder Runde anspruchsvoller. '
                'Deine Runde bleibt beim Verlassen gespeichert. Am 3D-Tisch gelten dieselben Regeln.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (cup != null)
              for (var index = 0; index < 3; index++)
                Card(
                    color: const Color(0xFF143455),
                    child: ListTile(
                      leading: Icon(
                          index < cup.results.length
                              ? (cup.results[index].won
                                  ? Icons.star_rounded
                                  : Icons.check_circle_outline_rounded)
                              : Icons.style_rounded,
                          color: const Color(0xFFFFD56E)),
                      title: Text(
                          'Runde ${index + 1} · ${LumoCardsCup.opponents[index].style.label}'),
                      subtitle:
                          Text(LumoCardsCup.opponents[index].difficulty.label),
                      trailing: Text(index < cup.results.length
                          ? (cup.results[index].won ? 'Gewonnen' : 'Gespielt')
                          : index == cup.nextRound
                              ? 'Als Nächstes'
                              : 'Danach'),
                    )),
            if (cup?.complete == true) ...[
              const SizedBox(height: 12),
              Text(
                  '${cup!.wins} von 3 Runden gewonnen. Dein Pokal bleibt gespeichert.'),
              const Text(
                  'Die Sterne aus jeder Runde wurden bereits mit dem Rundenergebnis verbucht.'),
            ],
            if (_error != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
            const SizedBox(height: 20),
            if (cup == null)
              FilledButton(
                  onPressed: _error == null ? null : _load,
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                  child: Text(
                      _error == null ? 'Pokal wird geladen …' : 'Erneut laden'))
            else
              FilledButton.icon(
                  onPressed: _opening
                      ? null
                      : cup.complete
                          ? _restart
                          : _play,
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(220, 56)),
                  icon: Icon(cup.complete
                      ? Icons.refresh_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(cup.complete
                      ? 'Neuer Sternenpokal'
                      : 'Runde ${cup.nextRound + 1} spielen')),
          ]),
        ),
      ))),
    );
  }
}
