import 'fox/lumo_character.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../core/reward_shop_repository.dart';
import '../core/reward_wallet_repository.dart';
import '../domain/rewards/reward_shop.dart';
import '../theme/lumo_visual_tokens.dart';
import 'design/lumo_design_system.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LUMO LERNEN — Profil nach Heinz' Bild 07
//  Level, Sterne, XP, Abzeichen, Lernserie, nächstes Ziel und eingelöste
//  Belohnungen, alles aus dem echten Spielstand.
// ═══════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.appState,
    required this.onSection,
    required this.childName,
    required this.grade,
    required this.stars,
    required this.xp,
    required this.level,
    this.drawBackground = true,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSection;
  final String childName;
  final int grade;
  final int stars;
  final int xp;
  final int level;

  /// Im App-Rahmen malt die Shell die Szene vollflächig.
  final bool drawBackground;

  /// Titel zum Level wie „Entdecker:in“ in Bild 07.
  static String levelTitle(int level) => switch (level) {
        <= 2 => 'Entdecker:in',
        <= 4 => 'Forscher:in',
        <= 7 => 'Lernprofi',
        _ => 'Lern-Meister:in',
      };

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Ein Abzeichen: aktueller Wert und die nächste Stufe.
class _Badge {
  const _Badge(this.title, this.icon, this.colors, this.current, this.steps);

  final String title;
  final IconData icon;
  final List<Color> colors;
  final int current;
  final List<int> steps;

  bool get started => current > 0;
  int get next =>
      steps.firstWhere((s) => s > current, orElse: () => steps.last);
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<RedeemedReward> _redeemed = const [];
  int _gamesPlayed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _shopChildId {
    final name = widget.childName.trim().isEmpty
        ? 'kind'
        : widget.childName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${name}_${widget.grade}';
  }

  Future<void> _load() async {
    final shop = await const RewardShopRepository().load(_shopChildId);
    final wallet = await RewardWalletRepository.instance.load();
    if (!mounted) return;
    setState(() {
      _redeemed = shop.redeemed.reversed.take(5).toList();
      _gamesPlayed = wallet.gameResultIds.length;
    });
  }

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  List<_Badge> _badges() {
    final skills = widget.appState.learningSkills().values;
    final correct = skills.fold<int>(0, (sum, s) => sum + s.correct);
    final logic = skills
        .where((s) => s.subject == 'Logik')
        .fold<int>(0, (sum, s) => sum + s.correct);
    return [
      _Badge(
          'Lernprofi',
          Icons.school_rounded,
          const [Color(0xFF3A8DFF), Color(0xFF1C4FC4)],
          correct,
          const [10, 25, 50, 100, 250, 500]),
      _Badge(
          'Spieler:in',
          Icons.sports_esports_rounded,
          const [Color(0xFFA35BFF), Color(0xFF6A2BD0)],
          _gamesPlayed,
          const [1, 5, 10, 25, 50]),
      _Badge(
          'Tüftler:in',
          Icons.check_rounded,
          const [Color(0xFF2CC9A0), Color(0xFF0F7F67)],
          logic,
          const [5, 10, 25, 50]),
      _Badge(
          'Sternensammler',
          Icons.star_rounded,
          const [Color(0xFFFFC94A), Color(0xFFE08A1E)],
          widget.stars,
          const [10, 50, 100, 250, 500]),
      _Badge(
          'Held:in',
          Icons.shield_rounded,
          const [Color(0xFFFF7A59), Color(0xFFC63A3A)],
          widget.appState.learningStreakDays(),
          const [3, 7, 14, 30]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildHero(),
        _buildProfileCard(),
        _buildStreakAndGoal(),
        _buildRewards(),
        _buildExtras(),
      ],
    );
    return widget.drawBackground
        ? LumoSceneBackground(
            scene: LumoScene.profile,
            showPlaceholderLabel: false,
            dimmed: true,
            child: content,
          )
        : content;
  }

  Widget _buildHero() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .42).clamp(150.0, 240.0);
      final foxSize = height * 1.18;
      final Widget fox = LumoCharacter(
        pose: LumoDesignFoxPose.thumbWink,
        size: foxSize,
        reduceMotion: _reduceMotion,
        // Antippen: Lumo wackelt kitzlig.
        onTap: () {},
      );
      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            right: width * .08,
            bottom: -foxSize * .08,
            child: RepaintBoundary(child: fox),
          ),
          Positioned(
            left: 14,
            top: height * .2,
            width: width * .5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: -.05,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Du machst\ndas großartig!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 26,
                        height: 1.05,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0xAA000000), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'Jeden Tag ein bisschen schlauer. Weiter so! '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(Icons.favorite_border_rounded,
                          size: 15, color: LumoVisualTokens.white),
                    ),
                  ]),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Color(0xAA000000), blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            top: 4,
            width: width * .26,
            child: Transform.rotate(
              angle: -.06,
              child: const LumoHeroBubble(
                text: 'Lernen bringt dich weiter!',
                handwritten: true,
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildProfileCard() {
    final xpInLevel = widget.xp % 400;
    final edit = _OutlineButton(
      key: const ValueKey('profile-edit'),
      label: 'Profil\nbearbeiten',
      onTap: () => widget.onSection(LumoSection.settings),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        radius: 24,
        child: LayoutBuilder(builder: (context, constraints) {
          // Schmal oder mit großer Schrift rutscht der Knopf unter die Zeile.
          final wide = constraints.maxWidth /
                  MediaQuery.textScalerOf(context).scale(1) >=
              330;
          return Column(children: [
            Row(children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LumoVisualTokens.cyan, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                        color: LumoVisualTokens.cyan.withOpacity(.55),
                        blurRadius: 16),
                  ],
                ),
                child: const ClipOval(
                  child: ColoredBox(
                    color: LumoVisualTokens.glass,
                    child:
                        LumoFoxPose(pose: LumoDesignFoxPose.avatar, size: 70),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          'Level ${widget.level}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          color: LumoVisualTokens.gold, size: 24),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.stars}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ]),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          ProfileScreen.levelTitle(widget.level),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: LumoVisualTokens.glassRow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Klasse ${widget.grade}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: LumoVisualTokens.cyanBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _XpBar(
                      value: xpInLevel / 400,
                      label: '$xpInLevel / 400 XP',
                      reduceMotion: _reduceMotion,
                    ),
                  ],
                ),
              ),
              if (wide) ...[const SizedBox(width: 8), edit],
            ]),
            if (!wide) Align(alignment: Alignment.centerRight, child: edit),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              decoration: BoxDecoration(
                color: LumoVisualTokens.navigation.withOpacity(.55),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: LumoVisualTokens.cyan.withOpacity(.25)),
              ),
              child: Row(children: [
                for (final badge in _badges())
                  Expanded(child: _BadgeView(badge: badge)),
              ]),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildStreakAndGoal() {
    final streak = widget.appState.learningStreakDays();
    final daily = widget.appState.learningProfileDailyMap();
    final today = DateTime.now();
    final week = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(today.year, today.month, today.day - offset),
    ];
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
    final xpInLevel = widget.xp % 400;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: LumoGlassCard(
              padding: const EdgeInsets.all(10),
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF9A2E), size: 34),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lernserie',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: LumoVisualTokens.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              streak == 1 ? '1 Tag' : '$streak Tage',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                color: LumoVisualTokens.cyanBright,
                                fontSize: 22,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  Text(
                    streak > 0
                        ? 'Stark dran geblieben!'
                        : 'Heute startet deine Serie!',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Lerntage der letzten Woche',
                    child: Row(children: [
                      for (final day in week)
                        Expanded(
                          child: (daily[key(day)] ?? 0) > 0
                              ? const Icon(Icons.local_fire_department_rounded,
                                  color: Color(0xFFFFB13B), size: 18)
                              : const Icon(Icons.circle_outlined,
                                  color: Color(0xFF8D9BB8), size: 15),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LumoGlassCard(
              padding: const EdgeInsets.all(10),
              radius: 20,
              child: Stack(children: [
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Opacity(
                    opacity: .95,
                    child: Image.asset(
                        'assets/lumo_design/icons/treasure_chest.png',
                        width: 54,
                        height: 54),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.track_changes_rounded,
                          color: LumoVisualTokens.cyanBright, size: 26),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nächstes Ziel',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ]),
                    Text(
                      'Level ${widget.level + 1} erreichen',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.cyanBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 46),
                      child: _XpBar(
                        value: xpInLevel / 400,
                        label: '$xpInLevel / 400 XP',
                        reduceMotion: _reduceMotion,
                        stacked: true,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRewards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LumoGlassCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: LumoVisualTokens.cyanBright, size: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Meine Belohnungen',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                key: const ValueKey('profile-rewards-all'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onSection(LumoSection.rewards),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      'Alle anzeigen',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: LumoVisualTokens.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: LumoVisualTokens.white, size: 18),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (_redeemed.isEmpty)
              const Text(
                'Noch nichts eingelöst. Sammle Sterne und such dir im '
                'Belohnungs-Laden etwas aus!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Row(children: [
                for (final reward in _redeemed)
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [
                            Color(0xFF2E7BE0),
                            Color(0xFF0B2A5A),
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: LumoVisualTokens.cyan.withOpacity(.4),
                                blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.card_giftcard_rounded,
                            color: LumoVisualTokens.gold, size: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: LumoVisualTokens.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                  ),
                for (var i = _redeemed.length; i < 5; i++)
                  const Expanded(child: SizedBox()),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildExtras() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(children: [
        Expanded(
          child: _ExtraTile(
            key: const ValueKey('profile-extras'),
            title: 'Extras freischalten',
            text: 'Sammle Sterne und löse sie im Belohnungs-Laden ein!',
            icon: Icons.confirmation_number_rounded,
            colors: const [Color(0xFF7A3FE0), Color(0xFF4B1FA6)],
            onTap: () => widget.onSection(LumoSection.rewards),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _ExtraTile(
            title: 'Dein Avatar',
            text: 'Neue Outfits und Accessoires – bald verfügbar.',
            icon: Icons.checkroom_rounded,
            colors: [Color(0xFF14A08D), Color(0xFF0B6B5E)],
          ),
        ),
      ]),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({
    required this.value,
    required this.label,
    required this.reduceMotion,
    this.stacked = false,
  });

  final double value;
  final String label;
  final bool reduceMotion;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 10,
          backgroundColor: const Color(0xFF0B2A52),
          valueColor:
              const AlwaysStoppedAnimation<Color>(LumoVisualTokens.cyanBright),
        ),
      ),
    );
    final text = Text(
      label,
      style: const TextStyle(
        fontFamily: 'Nunito',
        color: LumoVisualTokens.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [bar, const SizedBox(height: 4), text],
      );
    }
    return Row(children: [
      Expanded(child: bar),
      const SizedBox(width: 8),
      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: text)),
    ]);
  }
}

/// Sechseck-Abzeichen wie in Bild 07; ohne Fortschritt grau mit Schloss.
class _BadgeView extends StatelessWidget {
  const _BadgeView({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    // Wie im Bild: Held:in bleibt bis zur ersten Lernserie verschlossen,
    // die anderen zeigen gedämpft, was als Nächstes zu holen ist.
    final locked = !badge.started && badge.title == 'Held:in';
    final dimmed = !badge.started && !locked;
    return Semantics(
      label: locked
          ? '${badge.title}: noch nicht begonnen'
          : '${badge.title}: ${badge.current} von ${badge.next}',
      excludeSemantics: true,
      child: Column(children: [
        Opacity(
          opacity: dimmed ? .5 : 1,
          child: SizedBox(
            width: 50,
            height: 54,
            child: ClipPath(
              clipper: _HexagonClipper(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: locked
                        ? const [Color(0xFF6B7690), Color(0xFF3A4258)]
                        : badge.colors,
                  ),
                ),
                child: Icon(locked ? Icons.lock_rounded : badge.icon,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            badge.title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: LumoVisualTokens.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          locked ? '?' : '${badge.current}/${badge.next}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: LumoVisualTokens.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final point = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0E3D86).withOpacity(.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LumoVisualTokens.cyanBright),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: LumoVisualTokens.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: LumoVisualTokens.white, size: 20),
            ]),
          ),
        ),
      );
}

class _ExtraTile extends StatelessWidget {
  const _ExtraTile({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  final String title;
  final String text;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.3)),
              boxShadow: [
                BoxShadow(color: colors.first.withOpacity(.4), blurRadius: 12),
              ],
            ),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 22),
            ]),
          ),
        ),
      );
}
