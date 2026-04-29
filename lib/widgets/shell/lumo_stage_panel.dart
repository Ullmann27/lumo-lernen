import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class LumoStagePanel extends StatefulWidget {
  const LumoStagePanel({
    super.key,
    required this.appState,
    required this.onFoxTap,
  });

  final LumoAppState appState;
  final VoidCallback onFoxTap;

  @override
  State<LumoStagePanel> createState() => _LumoStagePanelState();
}

class _LumoStagePanelState extends State<LumoStagePanel>
    with TickerProviderStateMixin {

  late final AnimationController _breath = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _sway = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 5000),
  )..repeat(reverse: true);

  late final AnimationController _aura = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _hop = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 480),
  );

  @override
  void dispose() {
    _breath.dispose();
    _sway.dispose();
    _aura.dispose();
    _hop.dispose();
    super.dispose();
  }

  Color get _auraColor {
    final accent = widget.appState.state.focusedAccent;
    if (accent != null) return Color(accent);
    switch (widget.appState.state.mood) {
      case LumoMood.celebrate: return LumoColors.gold;
      case LumoMood.comfort:   return LumoColors.blue;
      case LumoMood.think:     return LumoColors.purple;
      case LumoMood.wave:      return LumoColors.teal;
      default:                 return LumoColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState.state;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LumoColors.stageBg1, LumoColors.stageBg2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.xl),
        border: Border.all(color: Colors.white.withOpacity(.6), width: 1.5),
        boxShadow: LumoShadow.stage,
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ── Speech Bubble ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SpeechBubble(text: st.lumoMessage),
          ),
          const SizedBox(height: 16),

          // ── Lumo Fox Stage ───────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                _hop.forward(from: 0);
                widget.onFoxTap();
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_breath, _sway, _aura, _hop]),
                builder: (context, _) {
                  final breathScale = 1 + 0.022 * _breath.value;
                  final swayRot = math.sin(_sway.value * math.pi * 2) * 0.018;
                  final hopY = -math.sin(_hop.value * math.pi) * 22;
                  final aura = 0.5 + 0.5 * _aura.value;

                  final facing = (st.section == LumoSection.exercises ||
                      st.section == LumoSection.scanner)
                      ? -1.0 : 1.0;

                  return Transform.translate(
                    offset: Offset(0, hopY),
                    child: Transform.rotate(
                      angle: swayRot,
                      child: Transform.scale(
                        scale: breathScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Aura glow
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _auraColor.withOpacity(.28 * aura),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            // Shadow
                            Positioned(
                              bottom: 8,
                              child: Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  gradient: RadialGradient(colors: [
                                    Colors.black.withOpacity(.16),
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            ),
                            // Fox
                            Transform(
                              transform: Matrix4.identity()
                                ..scale(facing, 1.0),
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/lumo_fox.png',
                                height: 230,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _FallbackFox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Daily Goal Card ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: _DailyGoalCard(
              stars: st.stars,
              xp: st.xp,
              level: st.level,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink900,
          height: 1.35,
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.stars,
    required this.xp,
    required this.level,
  });
  final int stars;
  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lernstand',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(emoji: '⭐', value: '$stars'),
              _Stat(emoji: '🏅', value: 'XP $xp'),
              _Stat(emoji: '💎', value: 'Level $level'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: LinearProgressIndicator(
              value: (stars / 50).clamp(0.0, 1.0),
              minHeight: 6,
              color: LumoColors.orange,
              backgroundColor: LumoColors.orange.withOpacity(.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.value});
  final String emoji;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink700,
        ),
      ),
    ]);
  }
}

class _FallbackFox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LumoColors.orange, LumoColors.orangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.xl),
      ),
      child: const Center(
        child: Text('🦊', style: TextStyle(fontSize: 80)),
      ),
    );
  }
}
