import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../core/reward_shop_repository.dart';
import '../core/reward_wallet_repository.dart';
import '../domain/rewards/reward_catalog.dart';
import '../domain/rewards/reward_shop.dart';
import '../features/report/lernbericht_screen.dart';
import '../features/rewards/reward_shop_content.dart' show rewardIcon;
import '../features/shared/widgets/lumo_premium_effects.dart';
import '../theme/lumo_visual_tokens.dart';
import 'design/lumo_design_system.dart';
import 'design/lumo_glass_optics.dart';
import 'fox/lumo_character.dart';
import 'profile/profile_parts.dart';
import '../domain/games/kart_fleet_catalog.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LUMO LERNEN — Profil nach Heinz' Zielbild vom 17.11.2026
//  (docs/design_targets/2026-11-17/profil_handy.jpg)
//
//  Aufbau wie im Bild: Kopf mit Schriftzug, Lumo und Sprechblase · Karte mit
//  Level, Sternen und XP · Abzeichen-Reihe · Lernserie und nächstes Ziel ·
//  Regal „Meine Belohnungen“ · Aktionskarten.
//
//  Jede Zahl stammt aus dem gespeicherten Spielstand:
//    Level, XP, Sterne  → Wallet über den App-Zustand (Level = 1 + XP ÷ 400)
//    Lernprofi          → richtig gelöste Lernaufgaben (Lernprofil, alle Fächer)
//    Spieler:in         → gespeicherte Spielergebnisse (Wallet.gameResultIds)
//    Tüftler:in         → richtig gelöste Aufgaben im Fach Logik
//    Sternensammler     → insgesamt gesammelte Sterne (Wallet.totalEarnedStars)
//    Held:in, Lernserie → Lerntage in Folge (Tagesliste des Lernprofils)
//    Meine Belohnungen  → im Belohnungs-Laden eingelöste Belohnungen
//  Lumos lokale Schal-/Zimmerausstattung hat einen eigenen Home-Einstieg.
//  Ein Geschenk zum Levelaufstieg wird hier nicht als Attrappe gezeigt.
// ═══════════════════════════════════════════════════════════════════════════

const _font = 'Nunito';

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
    this.showWordmark = false,
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

  /// Auf dem Handy trägt der Kopf des Profils den LUMO-Schriftzug wie im
  /// Zielbild; die Shell blendet dort ihre eigene Kopfzeile aus.
  final bool showWordmark;

  /// Titel zum Level wie „Entdecker:in“ im Zielbild. Reine Darstellung:
  /// Level 1–2 Entdecker:in, 3–4 Forscher:in, 5–7 Lernprofi, ab 8
  /// Lern-Meister:in.
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
  const _Badge(
    this.title,
    this.icon,
    this.colors,
    this.current,
    this.steps, {
    this.lockedUntilStarted = false,
  });

  final String title;
  final IconData icon;
  final List<Color> colors;
  final int current;
  final List<int> steps;

  /// Bleibt wie „Held:in“ im Zielbild verschlossen, bis es losgeht.
  final bool lockedUntilStarted;

  bool get started => current > 0;
  bool get locked => lockedUntilStarted && !started;
  int get next =>
      steps.firstWhere((s) => s > current, orElse: () => steps.last);
  String get progress => locked ? '?' : '$current/$next';
}

const _badgeTitleStyle = TextStyle(
  fontFamily: _font,
  color: LumoVisualTokens.white,
  fontSize: 11,
  height: 1.15,
  fontWeight: FontWeight.w800,
);

class _ProfileScreenState extends State<ProfileScreen> {
  List<RedeemedReward> _redeemed = const [];
  int _gamesPlayed = 0;
  int _totalEarnedStars = 0;
  StreamSubscription<RewardWallet>? _walletChanges;
  LearningProfileLease? _rewardOwner;
  List<RedeemedReward> _legacyRedeemed = const [];
  int _rewardLoad = 0;
  late int _profileGeneration;

  @override
  void initState() {
    super.initState();
    _profileGeneration = widget.appState.profileGeneration;
    widget.appState.addListener(_profileChanged);
    _load();
    _walletChanges =
        RewardWalletRepository.instance.changes.listen(_applyWallet);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childName != widget.childName ||
        oldWidget.grade != widget.grade) {
      _load();
    }
  }

  @override
  void dispose() {
    _walletChanges?.cancel();
    widget.appState.removeListener(_profileChanged);
    super.dispose();
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
    final ticket = ++_rewardLoad;
    final identity = widget.appState.captureLearningProfile();
    final legacyId = _shopChildId;
    try {
      final owner = await identity;
      final shop = owner.logStudentId == 'self'
          ? await const RewardShopRepository().load(legacyId)
          : const RewardShopState();
      final wallet = await widget.appState.loadRewardShopWallet(lease: owner);
      if (!mounted ||
          ticket != _rewardLoad ||
          owner.generation != widget.appState.profileGeneration) {
        return;
      }
      _rewardOwner = owner;
      _legacyRedeemed = shop.redeemed;
      _applyWallet(wallet);
    } catch (_) {
      // A read failure neither replaces the saved history nor switches its
      // ownership to the profile that happened to become visible meanwhile.
    }
  }

  void _profileChanged() {
    if (!mounted || _profileGeneration == widget.appState.profileGeneration) {
      return;
    }
    _profileGeneration = widget.appState.profileGeneration;
    _rewardOwner = null;
    _legacyRedeemed = const [];
    setState(() => _redeemed = const []);
    _load();
  }

  void _applyWallet(RewardWallet wallet) {
    if (!mounted) return;
    setState(() {
      _gamesPlayed = wallet.gameResultIds.where(_isGameResult).length;
      _totalEarnedStars = wallet.totalEarnedStars;
      final owner = _rewardOwner;
      if (owner != null &&
          owner.generation == widget.appState.profileGeneration) {
        final entries = <RedeemedReward>[..._legacyRedeemed];
        final ids =
            entries.map((v) => v.transactionId).whereType<String>().toSet();
        for (final receipt in wallet.shopRedemptions) {
          if (receipt.ownerId == owner.studentId &&
              ids.add(receipt.transactionId)) {
            entries.add(receipt.historyEntry);
          }
        }
        entries.sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
        _redeemed = entries.take(5).toList();
      }
    });
  }

  static bool _isGameResult(String id) =>
      !id.startsWith('parent:') && !id.startsWith('recognized:');

  bool get _reduceMotion {
    final settings = widget.appState.state.settings;
    return settings.reduceAnimations ||
        settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
  }

  int get _xpInLevel => widget.xp % 400;

  List<_Badge> _badges() {
    final skills = widget.appState.learningSkills().values;
    final correct = skills.fold<int>(0, (sum, s) => sum + s.correct);
    final logic = skills
        .where((s) => s.subject == 'Logik')
        .fold<int>(0, (sum, s) => sum + s.correct);
    // Gesammelte Sterne zählen weiter, auch wenn welche eingelöst wurden.
    // Ältere Spielstände ohne diesen Zähler zeigen mindestens den Kontostand.
    final collected = math.max(_totalEarnedStars, widget.stars);
    return [
      _Badge(
          'Lernprofi',
          Icons.school_rounded,
          const [Color(0xFF4FA2FF), Color(0xFF1B4FC6)],
          correct,
          const [10, 25, 50, 100, 250, 500]),
      _Badge(
          'Spieler:in',
          Icons.sports_esports_rounded,
          const [Color(0xFFB56CFF), Color(0xFF6A2BD0)],
          _gamesPlayed,
          const [1, 5, 10, 25, 50]),
      _Badge(
          'Tüftler:in',
          Icons.task_alt_rounded,
          const [Color(0xFF43DDB2), Color(0xFF0F7F67)],
          logic,
          const [5, 10, 25, 50]),
      _Badge(
          'Sternensammler',
          Icons.star_rounded,
          const [Color(0xFFFFD45E), Color(0xFFDD861A)],
          collected,
          const [10, 50, 100, 250, 500]),
      _Badge(
          'Held:in',
          Icons.shield_rounded,
          const [Color(0xFFFF8A66), Color(0xFFC63A3A)],
          widget.appState.learningStreakDays(),
          const [3, 7, 14, 30],
          lockedUntilStarted: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      // Auf dem geöffneten Fold bleibt die Spalte lesbar schmal.
      final width = math.min(constraints.maxWidth, 760.0);
      final side = (constraints.maxWidth - width) / 2;
      return ListView(
        padding: EdgeInsets.fromLTRB(side, 0, side, 16),
        children: [
          _buildHero(width),
          _buildLevelCard(scale),
          _buildStreakAndGoal(width, scale),
          _buildRewards(scale),
          _buildActions(width, scale),
        ],
      );
    });
    return widget.drawBackground
        ? LumoSceneBackground(
            scene: LumoScene.profile,
            showPlaceholderLabel: false,
            dimmed: true,
            child: content,
          )
        : content;
  }

  // ── Kopf: Schriftzug, Zuspruch, großer Lumo mit Sprechblase ──────────────

  Widget _buildHero(double width) {
    final wide = width >= 600;
    final minHeight = widget.showWordmark
        ? (width * .43).clamp(152.0, 190.0)
        : (width * .30).clamp(132.0, 170.0);
    // Lumo ist ab der Hüfte zu sehen; der Rest verschwindet hinter der Karte.
    const visible = .62;
    final foxSize = ((minHeight - 6) / visible).clamp(200.0, 300.0);
    final foxLeft = math.min(
      width * (wide ? .62 : .57) - foxSize * .47,
      width - 8 - foxSize * .86,
    );
    final textWidth = width * (wide ? .46 : .36) - 2;
    final bubbleWidth = (width * .31).clamp(112.0, 150.0);
    return SizedBox(
      width: double.infinity,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: ClipRect(
            clipper: const _BottomEdgeClipper(),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: foxLeft,
                bottom: -foxSize * (1 - visible),
                child: RepaintBoundary(
                  child: LumoCharacter(
                    pose: LumoDesignFoxPose.thumbWink,
                    size: foxSize,
                    reduceMotion: _reduceMotion,
                    shadow: false,
                    // Antippen: Lumo wackelt kitzlig.
                    onTap: () {},
                  ),
                ),
              ),
            ]),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(14, widget.showWordmark ? 2 : 14, 0, 10),
            child: SizedBox(
              width: textWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showWordmark) ...[
                    const ProfileWordmark(size: 32),
                    const SizedBox(height: 12),
                  ],
                  Transform.rotate(
                    angle: -.045,
                    alignment: Alignment.centerLeft,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Du machst\ndas großartig!',
                        style: TextStyle(
                          fontFamily: _font,
                          color: LumoVisualTokens.white,
                          fontSize: 24,
                          height: 1.04,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Color(0xCC00102E), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: textWidth * .78,
                    height: 8,
                    child: const CustomPaint(painter: ProfileSwoosh()),
                  ),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Jeden Tag ein bisschen schlauer. Weiter so! '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.favorite_border_rounded,
                            size: 14, color: LumoVisualTokens.white),
                      ),
                    ]),
                    style: TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.white,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Color(0xCC00102E), blurRadius: 6)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 4,
          width: bubbleWidth,
          child: Transform.rotate(
            angle: -.06,
            child:
                const ProfileSpeechBubble(text: 'Lernen bringt dich weiter!'),
          ),
        ),
      ]),
    );
  }

  // ── Karte: Avatar, Level, Sterne, XP, „Profil bearbeiten“, Abzeichen ─────

  Widget _buildLevelCard(double scale) {
    final edit = _OutlineButton(
      key: const ValueKey('profile-edit'),
      label: 'Profil\nbearbeiten',
      onTap: () => widget.onSection(LumoSection.settings),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ProfileGlass(
        padding: const EdgeInsets.all(12),
        radius: 24,
        child: LayoutBuilder(builder: (context, constraints) {
          // Schmal oder mit großer Schrift rutscht der Knopf unter die Zeile.
          final wide = constraints.maxWidth / scale >= 310;
          final avatarSize = wide ? 64.0 : 60.0;
          return Column(children: [
            Row(children: [
              _buildAvatar(avatarSize),
              const SizedBox(width: 10),
              Expanded(child: _buildLevelInfo(scale)),
              if (wide) ...[const SizedBox(width: 8), edit],
            ]),
            if (!wide) ...[
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: edit),
            ],
            const SizedBox(height: 12),
            ProfileGlass(
              inset: true,
              radius: 18,
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: _BadgeRow(badges: _badges()),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    final avatar = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1C63C8), Color(0xFF0A2A6E)],
        ),
        border: Border.all(color: LumoVisualTokens.cyanBright, width: 2.6),
        boxShadow: [
          BoxShadow(
              color: LumoVisualTokens.cyan.withValues(alpha: .6),
              blurRadius: 14),
        ],
      ),
      child: ClipOval(
        child: LumoFoxPose(pose: LumoDesignFoxPose.avatar, size: size - 6),
      ),
    );
    return _reduceMotion
        ? avatar
        : LumoGlowPulse(
            color: LumoVisualTokens.cyan,
            minBlur: 6,
            maxBlur: 16,
            child: avatar,
          );
  }

  Widget _buildLevelInfo(double scale) {
    final label = Text(
      '$_xpInLevel / 400 XP',
      style: const TextStyle(
        fontFamily: _font,
        color: LumoVisualTokens.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    );
    final bar =
        ProfileXpBar(value: _xpInLevel / 400, reduceMotion: _reduceMotion);
    return LayoutBuilder(builder: (context, constraints) {
      final beside = constraints.maxWidth / scale >= 148;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Level ${widget.level}',
                style: const TextStyle(
                  fontFamily: _font,
                  color: LumoVisualTokens.white,
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Semantics(
                label: '${widget.stars} Sterne',
                excludeSemantics: true,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(
                    Icons.star_rounded,
                    color: LumoVisualTokens.gold,
                    size: 24,
                    shadows: [
                      Shadow(color: Color(0xAAFFC94A), blurRadius: 10),
                    ],
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.stars}',
                    style: const TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.white,
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                ProfileScreen.levelTitle(widget.level),
                style: const TextStyle(
                  fontFamily: _font,
                  color: LumoVisualTokens.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: ProfilePalette.inset.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: ProfilePalette.neon.withValues(alpha: .35)),
                ),
                child: Text(
                  'Klasse ${widget.grade}',
                  style: const TextStyle(
                    fontFamily: _font,
                    color: LumoVisualTokens.cyanBright,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (beside)
            Row(children: [
              Expanded(child: bar),
              const SizedBox(width: 8),
              label,
            ])
          else ...[
            bar,
            const SizedBox(height: 4),
            label,
          ],
        ],
      );
    });
  }

  // ── Lernserie und nächstes Ziel ──────────────────────────────────────────

  Widget _buildStreakAndGoal(double width, double scale) {
    final streak = _buildStreakCard();
    final goal = _buildGoalCard();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      // Nebeneinander wie im Bild; schmal oder mit großer Schrift untereinander.
      child: width / scale >= 300
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: streak),
                  const SizedBox(width: 8),
                  Expanded(child: goal),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [streak, const SizedBox(height: 8), goal],
            ),
    );
  }

  Widget _buildStreakCard() {
    final streak = widget.appState.learningStreakDays();
    final daily = widget.appState.learningProfileDailyMap();
    final today = DateTime.now();
    final week = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(today.year, today.month, today.day - offset),
    ];
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
    final learned = [for (final day in week) (daily[key(day)] ?? 0) > 0];
    return ProfileGlass(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            ProfileFlame(size: 38, lit: streak > 0),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lernserie',
                    style: TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.white,
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      streak == 1 ? '1 Tag' : '$streak Tage',
                      style: const TextStyle(
                        fontFamily: _font,
                        color: Color(0xFF9BEBFF),
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0x8837D2FD), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 2),
          Text(
            streak > 0 ? 'Stark dran geblieben!' : 'Heute startet deine Serie!',
            style: const TextStyle(
              fontFamily: _font,
              color: LumoVisualTokens.cyanBright,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: 'Lerntage der letzten Woche: '
                '${learned.where((d) => d).length} von 7',
            excludeSemantics: true,
            child: Row(children: [
              for (final lit in learned)
                Expanded(
                  child: Center(
                    child: lit
                        ? const ProfileFlame(size: 19)
                        : Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ProfilePalette.inset.withValues(alpha: .6),
                              border: Border.all(
                                  color:
                                      ProfilePalette.idle.withValues(alpha: .8),
                                  width: 1.4),
                            ),
                          ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final nextLevel = widget.level + 1;
    return ProfileGlass(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ProfileBullseye(size: 32),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nächstes Ziel',
                    style: TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.white,
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Level $nextLevel erreichen',
                    style: const TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.cyanBright,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileXpBar(
                      value: _xpInLevel / 400, reduceMotion: _reduceMotion),
                  const SizedBox(height: 5),
                  Text(
                    '$_xpInLevel / 400 XP',
                    style: const TextStyle(
                      fontFamily: _font,
                      color: LumoVisualTokens.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Statt des Geschenks im Bild: das Abzeichen des nächsten Levels.
            // Ein Geschenk zum Levelaufstieg gibt es in der App nicht.
            ExcludeSemantics(
              child: ProfileHexBadge(
                size: 38,
                colors: const [Color(0xFFFFD45E), Color(0xFFDD861A)],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$nextLevel',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontFamily: _font,
                        color: Colors.white,
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0x99703800), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Meine Belohnungen: eingelöste Belohnungen aus dem Laden ──────────────

  Widget _buildRewards(double scale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ProfileGlass(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: LumoVisualTokens.cyanBright,
                size: 26,
                shadows: [Shadow(color: Color(0xAA37D2FD), blurRadius: 10)],
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Meine Belohnungen',
                  style: TextStyle(
                    fontFamily: _font,
                    color: LumoVisualTokens.white,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Alle Belohnungen anzeigen',
                excludeSemantics: true,
                child: InkWell(
                  key: const ValueKey('profile-rewards-all'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onSection(LumoSection.rewards),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 48),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          'Alle anzeigen',
                          style: TextStyle(
                            fontFamily: _font,
                            color: LumoVisualTokens.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: LumoVisualTokens.white, size: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
            // Das Regal zeigt, was das Kind wirklich hat: Karts, die es durch
            // verdiente Sterne freigeschaltet hat, das nächste Kart als Ziel
            // und im Laden eingelöste Belohnungen.
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _RewardShelf(
                rewards: _redeemed,
                earnedStars: math.max(_totalEarnedStars, widget.stars),
                scale: scale,
              ),
            ),
            if (_redeemed.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4, top: 8),
                child: Text(
                  'Noch nichts eingelöst. Sammle Sterne und such dir im '
                  'Belohnungs-Laden etwas aus!',
                  style: TextStyle(
                    fontFamily: _font,
                    color: LumoVisualTokens.muted,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Aktionskarten: Laden, Profil/Einstellungen, Lernbericht ──────────────

  Widget _buildActions(double width, double scale) {
    final extras = _ActionCard(
      key: const ValueKey('profile-extras'),
      title: 'Extras freischalten',
      text: 'Sammle Sterne und löse sie im Laden ein!',
      colors: const [Color(0xFF8A4BF0), Color(0xFF4B1FA6)],
      leading: Image.asset('assets/lumo_design/icons/ticket_star.webp',
          width: 38, height: 38, excludeFromSemantics: true),
      onTap: () => widget.onSection(LumoSection.rewards),
    );
    // Diese Profilkarte führt zu Klasse und Einstellungen. Die lokale
    // Schal-/Zimmerausstattung hat ihren eigenen Einstieg auf der Startseite.
    final settings = Semantics(
      key: const ValueKey('profile-settings'),
      button: true,
      child: _ActionCard(
        title: 'Dein Profil',
        text: 'Klasse und Einstellungen ansehen',
        colors: const [Color(0xFF1FBFA6), Color(0xFF0B6B5E)],
        leading: Image.asset('assets/lumo_design/ui/settings.webp',
            width: 38, height: 38, excludeFromSemantics: true),
        onTap: () => widget.onSection(LumoSection.settings),
      ),
    );
    final report = Semantics(
      button: true,
      label: 'Mein Lernbericht',
      excludeSemantics: true,
      child: _ActionCard(
        key: const ValueKey('profile-report'),
        title: 'Mein Lernbericht',
        text: 'Was sitzt schon sicher? Wobei hilft Lumo?',
        colors: const [Color(0xFF2372E0), Color(0xFF123E9C)],
        leading: const ProfileIconChip(icon: Icons.insights_rounded, size: 38),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => LernberichtScreen(appState: widget.appState),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nebeneinander wie im Bild, solange die Wörter ganz bleiben.
          if (width / scale >= 350)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: extras),
                  const SizedBox(width: 8),
                  Expanded(child: settings),
                ],
              ),
            )
          else ...[extras, const SizedBox(height: 8), settings],
          const SizedBox(height: 8),
          report,
        ],
      ),
    );
  }
}

/// Schneidet Lumo nur an der Unterkante des Kopfbereichs ab, dort wo die
/// Karte beginnt. Nach oben und zur Seite darf er sich frei bewegen.
class _BottomEdgeClipper extends CustomClipper<Rect> {
  const _BottomEdgeClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-400, -400, size.width + 400, size.height);

  @override
  bool shouldReclip(_BottomEdgeClipper oldClipper) => false;
}

/// Abzeichen-Reihe: wie im Bild fünf nebeneinander, jede Spalte so breit wie
/// ihr Name. Reicht der Platz nicht (schmal, große Schrift), brechen sie um.
class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badges});

  final List<_Badge> badges;

  static const double _hex = 46;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final natural = [
        for (final badge in badges)
          math.max(
                _hex,
                (TextPainter(
                  text: TextSpan(text: badge.title, style: _badgeTitleStyle),
                  textDirection: TextDirection.ltr,
                  textScaler: scaler,
                  maxLines: 1,
                )..layout())
                    .width,
              ) +
              8,
      ];
      final total = natural.fold<double>(0, (sum, w) => sum + w);
      // Passt die Reihe nicht, verteilen sich die Abzeichen gleichmäßig auf
      // Zeilen (fünf → drei und zwei), statt die Namen zu verkleinern.
      final rows = total <= constraints.maxWidth * 1.12
          ? 1
          : (total / constraints.maxWidth).ceil().clamp(2, badges.length);
      final perRow = (badges.length / rows).ceil();
      return Column(mainAxisSize: MainAxisSize.min, children: [
        for (var start = 0; start < badges.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = start;
                  i < math.min(start + perRow, badges.length);
                  i++)
                Expanded(
                  flex: natural[i].round(),
                  child: _BadgeView(badge: badges[i]),
                ),
            ],
          ),
        ],
      ]);
    });
  }
}

/// Sechseck-Abzeichen mit Namen und Fortschritt zur nächsten Stufe.
class _BadgeView extends StatelessWidget {
  const _BadgeView({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final locked = badge.locked;
    // Noch nicht begonnene Abzeichen zeigen gedämpft, was zu holen ist.
    final dimmed = !badge.started && !locked;
    return Semantics(
      container: true,
      label: locked
          ? '${badge.title}: noch nicht begonnen'
          : '${badge.title}: ${badge.current} von ${badge.next}',
      excludeSemantics: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Opacity(
          opacity: dimmed ? .55 : 1,
          child: ProfileHexBadge(
            size: _BadgeRow._hex,
            glow: !locked && !dimmed,
            colors: locked
                ? const [Color(0xFF8E9BB8), Color(0xFF3A4563)]
                : badge.colors,
            child: Icon(
              locked ? Icons.lock_rounded : badge.icon,
              color: Colors.white,
              size: 24,
              shadows: const [Shadow(color: Color(0x66000A24), blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(badge.title, maxLines: 1, style: _badgeTitleStyle),
          ),
        ),
        Text(
          badge.progress,
          style: const TextStyle(
            fontFamily: _font,
            color: Color(0xFFA9DCFF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

/// Eingelöste Belohnungen auf der leuchtenden Plattform, neueste zuerst.
/// Ein Platz im Regal: ein freigeschaltetes Kart, das nächste Kart als Ziel
/// oder eine eingelöste Belohnung.
class _ShelfItem {
  const _ShelfItem.kart(KartFleetEntry this.kart)
      : reward = null,
        missingStars = 0;
  const _ShelfItem.nextKart(KartFleetEntry this.kart, this.missingStars)
      : reward = null;
  const _ShelfItem.reward(RedeemedReward this.reward)
      : kart = null,
        missingStars = 0;

  final KartFleetEntry? kart;
  final RedeemedReward? reward;

  /// Größer als 0 nur beim noch gesperrten nächsten Kart.
  final int missingStars;

  bool get locked => missingStars > 0;
}

class _RewardShelf extends StatelessWidget {
  const _RewardShelf({
    required this.rewards,
    required this.earnedStars,
    required this.scale,
  });

  final List<RedeemedReward> rewards;
  final int earnedStars;
  final double scale;

  static const double _token = 46;
  static const double _stage = 62;

  static (IconData, Color) _art(RedeemedReward reward) {
    for (final item in RewardCatalog.all) {
      if (item.id == reward.itemId) return rewardIcon(item);
    }
    return (Icons.card_giftcard_rounded, LumoVisualTokens.gold);
  }

  /// Zuletzt verdiente Karts zuerst, dann eingelöste Belohnungen, am Ende das
  /// nächste Kart als Ziel. Eine eingelöste Belohnung behält immer einen Platz.
  static List<_ShelfItem> itemsFor({
    required int slots,
    required int earnedStars,
    required List<RedeemedReward> rewards,
  }) {
    final next = KartFleetCatalog.next(earnedStars);
    final karts = KartFleetCatalog.unlocked(earnedStars);
    final free = slots - (next == null ? 0 : 1);
    final kartSlots = math.max(1, free - (rewards.isEmpty ? 0 : 1));
    final items = <_ShelfItem>[
      for (final kart in karts.take(kartSlots)) _ShelfItem.kart(kart),
    ];
    for (final reward in rewards) {
      if (items.length >= free) break;
      items.add(_ShelfItem.reward(reward));
    }
    for (final kart in karts.skip(kartSlots)) {
      if (items.length >= free) break;
      items.add(_ShelfItem.kart(kart));
    }
    if (next != null) {
      items.add(_ShelfItem.nextKart(next, next.unlockStars - earnedStars));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Fünf Plätze wie im Bild; schmal oder mit großer Schrift weniger.
      final slots =
          (constraints.maxWidth / (60 * scale)).floor().clamp(2, 5).toInt();
      final shown = itemsFor(
        slots: slots,
        earnedStars: earnedStars,
        rewards: rewards,
      );
      return CustomPaint(
        painter: ProfileShelfPainter(surfaceY: _stage - 8, slots: slots),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: _stage,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < slots; i++)
                    Expanded(
                      child: i < shown.length
                          ? Center(
                              heightFactor: 1,
                              child: ExcludeSemantics(child: _piece(shown[i])),
                            )
                          : const SizedBox(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < slots; i++)
                  Expanded(
                    child: i < shown.length
                        ? _ShelfLabel(item: shown[i])
                        : const SizedBox(),
                  ),
              ],
            ),
          ]),
        ),
      );
    });
  }

  Widget _piece(_ShelfItem item) {
    final reward = item.reward;
    if (reward != null) {
      if (reward.itemId.startsWith('custom_') && reward.emoji != null) {
        return Container(
            width: _token,
            height: _token,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LumoVisualTokens.gold.withValues(alpha: .20),
                border: Border.all(color: LumoVisualTokens.gold)),
            child: Text(reward.emoji!, style: const TextStyle(fontSize: 27)));
      }
      return ProfileRewardToken(
        icon: _art(reward).$1,
        color: _art(reward).$2,
        size: _token,
      );
    }
    final picture = Image.asset(
      item.kart!.asset,
      key: ValueKey('profile-kart-${item.kart!.id}'),
      height: _stage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (!item.locked) return picture;
    // Das nächste Kart steht als dunkle Silhouette mit Schloss im Regal.
    return Stack(alignment: Alignment.center, children: [
      Opacity(
        opacity: 0.62,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF4F7BE0),
            BlendMode.srcATop,
          ),
          child: picture,
        ),
      ),
      const Icon(
        Icons.lock_rounded,
        color: LumoVisualTokens.white,
        size: 22,
        shadows: [Shadow(color: Color(0xCC0A1440), blurRadius: 6)],
      ),
    ]);
  }
}

class _ShelfLabel extends StatelessWidget {
  const _ShelfLabel({required this.item});

  final _ShelfItem item;

  @override
  Widget build(BuildContext context) {
    final reward = item.reward;
    final String title;
    final String detail;
    final String spoken;
    if (reward != null) {
      final date = '${reward.redeemedAt.day}.${reward.redeemedAt.month}.';
      title = reward.title;
      detail = '($date)';
      spoken = '${reward.title}, eingelöst am $date';
    } else if (item.locked) {
      title = item.kart!.name;
      detail = 'Noch ${item.missingStars}';
      spoken = 'Nächstes Kart ${item.kart!.name}, noch ${item.missingStars} '
          '${item.missingStars == 1 ? 'Stern' : 'Sterne'}';
    } else {
      title = item.kart!.name;
      detail = '(Kart)';
      spoken = 'Kart ${item.kart!.name}, freigeschaltet';
    }
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            title,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _font,
              color: item.locked
                  ? const Color(0xFFA9DCFF)
                  : LumoVisualTokens.white,
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          // Der Stern ist ein Symbol: die Schrift hat kein Sternzeichen.
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    color: item.locked
                        ? LumoVisualTokens.gold
                        : const Color(0xFFA9DCFF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.locked)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.star_rounded,
                      color: LumoVisualTokens.gold, size: 13),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label.replaceAll('\n', ' '),
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B58BE).withValues(alpha: .85),
                    const Color(0xFF0C2F80).withValues(alpha: .9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF8ADFFF).withValues(alpha: .9),
                    width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: ProfilePalette.neon.withValues(alpha: .28),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: _font,
                        color: LumoVisualTokens.white,
                        fontSize: 12.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        color: LumoVisualTokens.white, size: 20),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Farbige Aktionskarte mit Bild, Text und rundem Pfeil wie im Zielbild.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.title,
    required this.text,
    required this.colors,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String text;
  final List<Color> colors;
  final Widget leading;
  final VoidCallback onTap;

  static const double _chevron = 24;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.lerp(colors.first, Colors.white, .5)!
                    .withValues(alpha: .85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: .42),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: LumoGlassOptics(
                radius: 18,
                accent: Color.lerp(colors.first, Colors.white, .6)!,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Row(children: [
                      leading,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: _font,
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Rechts bleibt Platz für den runden Pfeil.
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: _chevron + 2),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontFamily: _font,
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: ProfileChevron(size: _chevron),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
