import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'star_trail_rules.dart';
import '../../../app/app_state.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/design/lumo_design_system.dart' show LumoDesignFoxPose, LumoScene, LumoSceneBackground;

/// Lumo Sternenpfad: cooperative original route-building card game.
/// Supports phone, Fold and tablet layouts without network calls.
class LumoStarTrailScreen extends StatefulWidget {
  const LumoStarTrailScreen({super.key, this.appState});

  final LumoAppState? appState;

  @override
  State<LumoStarTrailScreen> createState() => _LumoStarTrailScreenState();
}

class _LumoStarTrailScreenState extends State<LumoStarTrailScreen> {
  static const night = Color(0xFF091530);
  static const cyan = Color(0xFF66E7F7);
  static const gold = Color(0xFFFFD981);
  late StarTrailState state;
  bool _rewardGiven = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    state = StarTrailState.begin(
        seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
  }

  void _choose(int index) {
    if (!state.canPlay(index)) return;
    HapticFeedback.selectionClick();
    final next = state.play(index);
    setState(() => state = next);
    // Reward this completed child-session exactly once, including after
    // an immediate restart. The familiar LumoAppState owns all profile data.
    if (next.won && !_rewardGiven && widget.appState != null) {
      _rewardGiven = true;
      // Atomic wallet operation: child-safe stars and XP in one transaction.
      widget.appState!.addRewards(stars: 5, xp: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Scaffold(
      backgroundColor: night,
      appBar: AppBar(
        backgroundColor: night,
        foregroundColor: Colors.white,
        title: const Text('Lumo Sternenpfad',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Neues Spiel',
            onPressed: () => setState(_newGame),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LumoSceneBackground(
        scene: LumoScene.games,
        dimmed: true,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 28, vertical: 14),
                children: [
                  _intro(),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _stat('🏝️', 'Inseln',
                        state.distance.toString() + '/12'),
                    _stat('⭐', 'Sterne',
                        state.stars.toString() + '/6'),
                    _stat('💡', 'Licht',
                        state.light.toString()),
                    _stat('🧩', 'Zug',
                        state.turn.toString() + '/16'),
                  ]),
                  const SizedBox(height: 18),
                  _board(compact),
                  const SizedBox(height: 16),
                  Text(
                    state.finished
                        ? state.won
                            ? 'Hurra! Zusammen habt ihr den Sternenhafen erreicht.'
                            : 'Das Ziel war knapp. Deine neue Reise wartet!'
                        : 'Baue 12 Inseln und sammle 6 Sterne. '
                          'Eine Sternlaterne ist immer verfügbar. '
                          'Für besondere Sprünge brauchst du Licht.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE3F2FF),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (state.finished)
                    _finish()
                  else ...[
                    const Text('WÄHLE DEINE NÄCHSTE KARTE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: gold,
                            letterSpacing: 1,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < state.choices.length; i++)
                          _card(i, compact),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF304A78).withOpacity(.8),
          border: Border.all(color: cyan.withOpacity(.5)),
          boxShadow: const [
            BoxShadow(color: Color(0x6646DFF4), blurRadius: 24),
          ],
        ),
        child: Row(
          children: [
            LumoCharacter(
              pose: LumoDesignFoxPose.spielweltCards,
              size: 90,
              reduceMotion: MediaQuery.disableAnimationsOf(context) ||
                  (widget.appState?.state.settings.reduceAnimations ?? false) ||
                  (widget.appState?.state.settings.calmMode ?? false),
              intro: true,
              idleHops: true,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemeinsam über die Wolken!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Du und Lumo baut einen leuchtenden Weg. '
                      'Kein Zeitdruck, kein Gegeneinander.',
                      style: TextStyle(color: Color(0xFFD1ECF9))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _stat(String emoji, String title, String value) => Container(
        constraints: const BoxConstraints(minWidth: 128, minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(.1),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(color: Color(0xFFC9D9F2), fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
          ]),
        ]),
      );

  Widget _board(bool compact) => Semantics(
        label: 'Zwölf 3D-artige Inselkacheln, davon ' +
            state.distance.toString() +
            ' bereits gebaut',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [
              Color(0xFF185C8B), Color(0xFF222D68), Color(0xFF11294C),
            ]),
            border: Border.all(color: cyan.withOpacity(.5)),
            boxShadow: const [
              BoxShadow(color: Color(0x6646DFF4), blurRadius: 24),
            ],
          ),
          child: Column(
            children: [
              const Text('DEIN WEG DURCH DIE STERNENWELT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: cyan,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, box) {
                final gap = compact ? 6.0 : 10.0;
                final width = (box.maxWidth - 3 * gap) / 4;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap + 7,
                  children: [
                    for (var i = 0; i < StarTrailState.goalDistance; i++)
                      _island(i, width, compact),
                  ],
                );
              }),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: state.distance / StarTrailState.goalDistance,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(cyan),
              ),
            ],
          ),
        ),
      );

  Widget _island(int index, double width, bool compact) {
    final completed = index < state.distance;
    final current = index == state.distance;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      width: width,
      height: compact ? 65 : 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: completed
            ? [const Color(0xFF82FFD7), const Color(0xFF25A4C4)]
            : current
                ? [gold, const Color(0xFFFA9955)]
                : [const Color(0xFF33598A), const Color(0xFF20365C)]),
        border: Border.all(color: Colors.white54),
        boxShadow: [
          BoxShadow(
            color: completed
                ? cyan.withOpacity(.35)
                : current
                    ? gold.withOpacity(.45)
                    : Colors.black26,
            blurRadius: completed || current ? 15 : 5,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(current ? '🦊' : completed ? '✨' : '☁️',
            style: TextStyle(fontSize: compact ? 23 : 31)),
        Text((index + 1).toString(),
            style: TextStyle(
                color: completed || current ? night : Colors.white,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _card(int index, bool compact) {
    final choice = state.choices[index];
    final usable = state.canPlay(index);
    return Semantics(
      button: true,
      enabled: usable,
      label: choice.name + ': ' + choice.description,
      child: SizedBox(
        width: compact ? 106 : 175,
        height: compact ? 168 : 197,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: usable ? () => _choose(index) : null,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: LinearGradient(colors: usable
                    ? [const Color(0xFF4675CE), const Color(0xFF253669)]
                    : [const Color(0xFF45445B), const Color(0xFF262941)]),
                border: Border.all(color: usable ? cyan : Colors.white24),
                boxShadow: usable
                    ? const [BoxShadow(color: Color(0x6636DBF5), blurRadius: 14)]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(choice.symbol,
                      style: TextStyle(fontSize: compact ? 32 : 45)),
                  Text(choice.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  Text(choice.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFD8ECFF), fontSize: 11)),
                  if (!usable)
                    const Text('Zu wenig Licht',
                        style: TextStyle(color: gold, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _finish() => Column(children: [
        Text(state.won ? '🏆' : '🌟',
            style: const TextStyle(fontSize: 55)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => setState(_newGame),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Noch eine Sternenreise'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(230, 54),
            backgroundColor: cyan,
            foregroundColor: night,
          ),
        ),
      ]);
}
