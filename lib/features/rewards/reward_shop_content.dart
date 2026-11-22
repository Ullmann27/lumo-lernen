import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/reward_shop_repository.dart';
import '../../core/reward_shop_session.dart';
import '../../domain/rewards/reward_shop.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_motion.dart';
import '../../widgets/parent_approval_dialog.dart';

/// Belohnungs-Shop Seite.
/// Kind sieht Sterne + Punkte + verfuegbare Belohnungen.
/// Familienbelohnungen werden gemeinsam mit einer erwachsenen Person bestätigt.
class RewardShopContent extends StatefulWidget {
  const RewardShopContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<RewardShopContent> createState() => _RewardShopContentState();
}

class _RewardShopContentState extends State<RewardShopContent> {
  static const _engine = RewardShopEngine();
  late final RewardShopSession _session;
  bool _redeeming = false;
  CustomRewardCategory? _category;

  RewardShopState? get _state => _session.ready ? _session.state : null;

  @override
  void initState() {
    super.initState();
    _session = RewardShopSession(widget.appState)..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    _session.dispose();
    super.dispose();
  }

  Future<void> _redeem(RewardItem item, {RewardShopRedemption? pending}) async {
    final owner = _session.owner;
    if (_state == null ||
        _redeeming ||
        _session.busy ||
        owner == null ||
        (pending == null && _session.pending.isNotEmpty)) {
      return;
    }
    setState(() => _redeeming = true);
    try {
      _session.validateOwner(owner);
      if (!_engine.canAfford(_state!, item, level: _session.wallet!.level)) {
        return;
      }
      final receipt = pending ??
          RewardShopRepository.createRedemption(
              ownerId: owner.studentId, item: item);
      final needsApproval = pending != null ||
          item.parentApprovalRequired ||
          item.isPremiumReward;
      if (needsApproval) {
        final confirmed = await ParentApprovalDialog.show(
          context,
          rewardTitle: item.title,
          costLabel:
              '${item.cost} ${item.currency == RewardCurrency.stars ? 'Sterne' : 'Punkte'}',
        );
        if (!confirmed || !mounted) return;
      }
      _session.validateOwner(owner);
      final committed = await _session.redeem(receipt, lease: owner);
      if (!committed || !mounted || !_session.isCurrent(owner)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF22C55E),
          content: Row(
            children: [
              Icon(rewardIcon(item).$1, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belohnung "${receipt.title}" eingelöst! Mama oder Papa erfüllen sie bald.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(RewardShopSession.messageFor(error))));
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  RewardItem _pendingItem(RewardShopRedemption value) => RewardItem(
      id: value.itemId,
      title: value.title,
      emoji: value.emoji,
      description: value.description,
      cost: value.cost,
      currency: RewardCurrency.stars,
      seasons: const [],
      minLevel: value.minLevel,
      revision: value.itemRevision,
      category: value.category,
      parentApprovalRequired: true);

  @override
  Widget build(BuildContext context) {
    if (_session.loading) {
      return const Center(
        child: CircularProgressIndicator(color: LumoColors.orange),
      );
    }
    if (_state == null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_session.error ??
                    'Der Belohnungs-Laden konnte nicht geladen werden.'),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _session.load,
                    child: const Text('Erneut laden')),
              ])));
    }
    final state = _state!;
    final now = DateTime.now();
    final season = Season.fromDate(now);
    final all = _engine.availableRewards(
        now: now, customRewards: _session.profile!.currentDefinitions);
    final available = all.where((item) => !item.isCustom).toList();
    final custom = all.where((item) => item.isCustom).toList();
    final enabled = !_redeeming &&
        !_session.busy &&
        _session.pending.isEmpty &&
        !widget.appState.backupBusy;
    final microItems =
        available.where((r) => r.tier == RewardTier.micro).toList();
    final smallItems =
        available.where((r) => r.tier == RewardTier.small).toList();
    final mediumItems =
        available.where((r) => r.tier == RewardTier.medium).toList();
    final bigItems = available.where((r) => r.tier == RewardTier.big).toList();
    final premiumItems =
        available.where((r) => r.tier == RewardTier.premium).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Saison + Waehrungen
          _ShopHeader(
            season: season,
            stars: state.availableStars,
            points: state.availablePoints,
          ),
          const SizedBox(height: 20),
          if (_session.error != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_session.error!,
                    key: const ValueKey('reward-shop-error'),
                    style: const TextStyle(color: LumoVisualTokens.white))),
          for (final receipt in _session.pending)
            Card(
              key: ValueKey('reward-pending-${receipt.transactionId}'),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${receipt.title} · ${receipt.cost} Sterne',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text(
                            'Diese bestätigte Einlösung wartet noch auf den Abschluss. '
                            'Ein erneuter Versuch verwendet denselben Beleg.'),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _redeeming || _session.busy
                                ? null
                                : () => _redeem(_pendingItem(receipt),
                                    pending: receipt),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 48)),
                            child: const Text('Einlösung abschließen')),
                      ])),
            ),
          if (custom.isNotEmpty) ...[
            const _SectionTitle(
                icon: Icons.card_giftcard_rounded,
                color: Color(0xFFFFC94D),
                title: 'Deine Familiengutscheine',
                subtitle: 'Von deinen Erwachsenen für dich festgelegt'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(
                  label: const Text('Alle'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null)),
              for (final category in CustomRewardCategory.values)
                if (custom.any((v) => v.category == category))
                  ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category)),
            ]),
            const SizedBox(height: 10),
            for (final item in custom
                .where((v) => _category == null || v.category == _category))
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                      key: ValueKey('reward-card-${item.id}'),
                      item: item,
                      canAfford: _engine.canAfford(state, item,
                          level: _session.wallet!.level),
                      balance: state.availableStars,
                      enabled: enabled,
                      lockedLabel: _session.wallet!.level < item.minLevel
                          ? 'Ab Level ${item.minLevel}'
                          : null,
                      onRedeem: () => _redeem(item))),
            const SizedBox(height: 18),
          ],
          if (state.testPhotos.isNotEmpty) ...[
            _TestPhotoSummary(testPhotos: state.testPhotos),
            const SizedBox(height: 20),
          ],
          // Mini-Belohnungen
          if (microItems.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              color: Color(0xFF7DE3FF),
              title: 'Mini-Belohnungen',
              subtitle: 'Schnelle Belohnungen für kurze Lernrunden',
            ),
            const SizedBox(height: 10),
            ...microItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardCard(
                  item: item,
                  canAfford: _engine.canAfford(state, item),
                  enabled: enabled,
                  balance: item.currency == RewardCurrency.stars
                      ? state.availableStars
                      : state.availablePoints,
                  onRedeem: () => _redeem(item),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          // Kleine Belohnungen
          if (smallItems.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.star_rounded,
              color: Color(0xFFFFC94D),
              title: 'Kleine Belohnungen',
              subtitle: 'Sterne sammeln und einlösen',
            ),
            const SizedBox(height: 10),
            ...smallItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardCard(
                  item: item,
                  canAfford: _engine.canAfford(state, item),
                  enabled: enabled,
                  balance: item.currency == RewardCurrency.stars
                      ? state.availableStars
                      : state.availablePoints,
                  onRedeem: () => _redeem(item),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          // Mittlere Belohnungen
          if (mediumItems.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.diamond_rounded,
              color: Color(0xFFB79BFF),
              title: 'Mittlere Belohnungen',
              subtitle: 'Mit Punkten aus guten Noten',
            ),
            const SizedBox(height: 10),
            ...mediumItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardCard(
                  item: item,
                  canAfford: _engine.canAfford(state, item),
                  enabled: enabled,
                  balance: item.currency == RewardCurrency.stars
                      ? state.availableStars
                      : state.availablePoints,
                  onRedeem: () => _redeem(item),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          // Grosse Belohnungen
          if (bigItems.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.emoji_events_rounded,
              color: Color(0xFFFFB84D),
              title: 'Große Geschenke',
              subtitle: 'Für richtig gute Noten',
            ),
            const SizedBox(height: 10),
            ...bigItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardCard(
                  item: item,
                  canAfford: _engine.canAfford(state, item),
                  enabled: enabled,
                  balance: item.currency == RewardCurrency.stars
                      ? state.availableStars
                      : state.availablePoints,
                  onRedeem: () => _redeem(item),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          // Premium-Belohnungen
          if (premiumItems.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.workspace_premium_rounded,
              color: Color(0xFFFFD86B),
              title: 'Premium-Belohnungen',
              subtitle: 'Nur mit Elternfreigabe einlösbar',
            ),
            const SizedBox(height: 10),
            ...premiumItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RewardCard(
                  item: item,
                  canAfford: _engine.canAfford(state, item),
                  enabled: enabled,
                  balance: item.currency == RewardCurrency.stars
                      ? state.availableStars
                      : state.availablePoints,
                  onRedeem: () => _redeem(item),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (state.redeemed.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.history_rounded,
              color: Color(0xFF8FB4D9),
              title: 'Schon eingelöst',
              subtitle: 'Deine Belohnungs-Historie',
            ),
            const SizedBox(height: 10),
            ...state.redeemed.reversed
                .take(10)
                .map((r) => _RedeemedRow(entry: r)),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// Passendes Symbol und Farbe je Belohnung (statt Emoji, das je nach Gerät
/// unterschiedlich oder gar nicht dargestellt wird).
(IconData, Color) rewardIcon(RewardItem item) {
  const food = Color(0xFFFF9E57);
  const time = Color(0xFF5FE1FF);
  const creative = Color(0xFFFF7FC8);
  const outing = Color(0xFF63E6A6);
  const premium = Color(0xFFFFD86B);
  switch (item.emoji) {
    case '🎨':
      return (Icons.palette_rounded, creative);
    case '⏰':
      return (Icons.timer_rounded, time);
    case '⭐':
      return (Icons.star_rounded, premium);
    case '🍬':
      return (Icons.cookie_rounded, food);
    case '📖':
      return (Icons.auto_stories_rounded, time);
    case '🍫':
      return (Icons.cake_rounded, food);
    case '🎠':
    case '🎢':
      return (Icons.attractions_rounded, outing);
    case '🌙':
      return (Icons.bedtime_rounded, time);
    case '🥪':
      return (Icons.lunch_dining_rounded, food);
    case '✂️':
      return (Icons.content_cut_rounded, creative);
    case '🍝':
      return (Icons.restaurant_rounded, food);
    case '🎬':
    case '🎥':
      return (Icons.movie_rounded, creative);
    case '🍕':
      return (Icons.local_pizza_rounded, food);
    case '📚':
      return (Icons.menu_book_rounded, time);
    case '🏊':
      return (Icons.pool_rounded, outing);
    case '🍦':
      return (Icons.icecream_rounded, food);
    case '🦓':
      return (Icons.pets_rounded, outing);
    case '👨‍👧':
    case '👩‍👧':
      return (Icons.family_restroom_rounded, outing);
    case '🧸':
      return (Icons.toys_rounded, creative);
    case '🧱':
      return (Icons.view_module_rounded, creative);
    case '🌟':
      return (Icons.auto_awesome_rounded, premium);
    case '🗺️':
      return (Icons.map_rounded, outing);
    case '🎁':
      return (Icons.card_giftcard_rounded, premium);
  }
  return (Icons.card_giftcard_rounded, premium);
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.season,
    required this.stars,
    required this.points,
  });
  final Season season;
  final int stars;
  final int points;

  @override
  Widget build(BuildContext context) {
    final accent = _seasonAccent(season);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 520;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
      final starChip = _CurrencyChip(
          icon: Icons.star_rounded,
          label: 'Sterne',
          count: stars,
          color: const Color(0xFFFFC94D));
      final pointChip = _CurrencyChip(
          icon: Icons.diamond_rounded,
          label: 'Punkte',
          count: points,
          color: const Color(0xFFB79BFF));
      final chest = Image.asset(
        'assets/lumo_design/icons/treasure_chest.png',
        width: wide ? 150 : 104,
        height: wide ? 150 : 104,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => Icon(Icons.redeem_rounded,
            size: wide ? 110 : 80, color: const Color(0xFFFFD86B)),
      );
      return Container(
        key: const ValueKey('reward-shop-header'),
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xF0123A68), accent, .18)!,
              const Color(0xF2081B3C),
            ],
          ),
          border: Border.all(
              color: LumoVisualTokens.cyan.withValues(alpha: .45), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: .22),
                blurRadius: 28,
                spreadRadius: -6),
            const BoxShadow(
                color: Color(0x44000000),
                blurRadius: 18,
                offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: accent.withValues(alpha: .55)),
                          ),
                          child: Text(
                            'Saison ${season.germanLabel}'.toUpperCase(),
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                                color: Color.lerp(accent, Colors.white, .35)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Belohnungs-Laden',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: wide ? 30 : 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05)),
                      const SizedBox(height: 4),
                      const Text(
                          'Sammle Sterne beim Lernen und tausche sie hier ein.',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: LumoVisualTokens.muted,
                              height: 1.25)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Schatztruhe mit weichem Leuchten im Hintergrund.
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFFD86B).withValues(alpha: .30),
                      const Color(0xFFFFD86B).withValues(alpha: 0),
                    ]),
                  ),
                  child:
                      Padding(padding: const EdgeInsets.all(10), child: chest),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Kontostand über die volle Breite; bei großer Schrift untereinander.
            if (largeText)
              Wrap(spacing: 10, runSpacing: 10, children: [starChip, pointChip])
            else
              Row(children: [
                Expanded(child: starChip),
                const SizedBox(width: 10),
                Expanded(child: pointChip),
              ]),
          ],
        ),
      );
    });
  }

  Color _seasonAccent(Season s) {
    switch (s) {
      case Season.spring:
        return const Color(0xFFFF7FA8);
      case Season.summer:
        return const Color(0xFFFFC94D);
      case Season.autumn:
        return const Color(0xFFFF9E57);
      case Season.winter:
        return const Color(0xFF7DD3FF);
    }
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC071A38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .55), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: .20),
              blurRadius: 14,
              spreadRadius: -4)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: .45),
                color.withValues(alpha: .08)
              ]),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: LumoVisualTokens.muted)),
              // Zählt vom alten zum neuen echten Stand.
              LumoAnimatedValue(
                value: count.toDouble(),
                builder: (context, v) => Text('${v.round()}',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.05)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color.lerp(const Color(0xE6071A38), color, .16),
            border: Border.all(color: color.withValues(alpha: .5)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        // Schatten halten die Titel über der hellen Szene lesbar.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.white,
                  shadows: [Shadow(color: Color(0xE603122E), blurRadius: 10)],
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xF2FFFFFF),
                  shadows: [
                    Shadow(color: Color(0xE603122E), blurRadius: 8),
                    Shadow(color: Color(0x9903122E), offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    super.key,
    required this.item,
    required this.canAfford,
    required this.balance,
    required this.onRedeem,
    this.enabled = true,
    this.lockedLabel,
  });
  final RewardItem item;
  final bool canAfford;
  final int balance;
  final VoidCallback onRedeem;
  final bool enabled;
  final String? lockedLabel;

  @override
  Widget build(BuildContext context) {
    final currency = item.currency == RewardCurrency.stars
        ? const Color(0xFFFFC94D)
        : const Color(0xFFB79BFF);
    final (icon, tint) = rewardIcon(item);
    final progress =
        item.cost <= 0 ? 1.0 : (balance / item.cost).clamp(0.0, 1.0).toDouble();
    final missing = (item.cost - balance).clamp(0, item.cost);
    final unit = item.currency == RewardCurrency.stars ? 'Sterne' : 'Punkte';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canAfford
              ? <Color>[
                  Color.lerp(const Color(0xEE0F3260), tint, .22)!,
                  const Color(0xF0081D3D)
                ]
              : const <Color>[Color(0xE00F2C55), Color(0xE0081B3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canAfford
              ? tint.withValues(alpha: .7)
              : LumoVisualTokens.cyan.withValues(alpha: .25),
          width: canAfford ? 1.6 : 1.1,
        ),
        boxShadow: [
          if (canAfford)
            BoxShadow(
                color: tint.withValues(alpha: .25),
                blurRadius: 20,
                spreadRadius: -6),
          const BoxShadow(
              color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leuchtendes Medaillon mit dem Symbol der Belohnung.
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                tint.withValues(alpha: canAfford ? .55 : .28),
                tint.withValues(alpha: canAfford ? .14 : .06),
              ]),
              border: Border.all(
                  color: tint.withValues(alpha: canAfford ? .9 : .4),
                  width: 1.5),
              boxShadow: canAfford
                  ? [
                      BoxShadow(
                          color: tint.withValues(alpha: .45),
                          blurRadius: 16,
                          spreadRadius: -2)
                    ]
                  : null,
            ),
            child: item.isCustom
                ? Center(
                    child:
                        Text(item.emoji, style: const TextStyle(fontSize: 28)))
                : Icon(icon,
                    size: 30,
                    color:
                        canAfford ? Colors.white : tint.withValues(alpha: .85)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                        height: 1.15)),
                const SizedBox(height: 3),
                Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.muted,
                        height: 1.3)),
                if (item.category != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '${item.category!.label} · ab Level ${item.minLevel}',
                          style:
                              const TextStyle(color: LumoVisualTokens.muted))),
                const SizedBox(height: 10),
                // Fortschritt zur Belohnung aus dem echten Kontostand.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LumoAnimatedValue(
                    value: progress,
                    builder: (context, v) => LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: const Color(0x55203C66),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          canAfford ? tint : currency),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: currency.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                        border:
                            Border.all(color: currency.withValues(alpha: .45)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            item.currency == RewardCurrency.stars
                                ? Icons.star_rounded
                                : Icons.diamond_rounded,
                            size: 15,
                            color: currency),
                        const SizedBox(width: 4),
                        Text('${item.cost}',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: currency)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: canAfford
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: LumoPressable(
                                radius: 99,
                                glowColor: tint,
                                child: FilledButton.icon(
                                  onPressed: enabled ? onRedeem : null,
                                  icon: const Icon(Icons.redeem_rounded,
                                      size: 18),
                                  label: const Text('Einlösen'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: tint,
                                    foregroundColor: const Color(0xFF07152E),
                                    minimumSize: const Size(48, 48),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    textStyle: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            )
                          : Text(lockedLabel ?? 'Noch $missing $unit',
                              key: ValueKey('reward-missing-${item.id}'),
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: LumoVisualTokens.muted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestPhotoSummary extends StatelessWidget {
  const _TestPhotoSummary({required this.testPhotos});
  final List<TestPhotoEntry> testPhotos;

  @override
  Widget build(BuildContext context) {
    final lastFive = testPhotos.reversed.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xE31D2F69), Color(0xE30C214A)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x99C4B5FD), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_rounded,
                  color: Color(0xFFC4B5FD), size: 22),
              SizedBox(width: 8),
              Text(
                'Deine letzten Tests',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lastFive.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _noteColor(t.note),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${t.note}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.subject,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.diamond_rounded,
                      size: 14, color: Color(0xFFB79BFF)),
                  const SizedBox(width: 3),
                  Text(
                    '+${t.pointsAwarded}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB79BFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _noteColor(int n) {
    switch (n) {
      case 1:
        return const Color(0xFF22C55E);
      case 2:
        return const Color(0xFF84CC16);
      case 3:
        return const Color(0xFFFFB800);
      case 4:
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFFEF4444);
    }
  }
}

class _RedeemedRow extends StatelessWidget {
  const _RedeemedRow({required this.entry});
  final RedeemedReward entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Color(0xFF4ADE80),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.title,
              key: ValueKey(
                  'reward-history-${entry.transactionId ?? entry.itemId}'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
          Icon(
              entry.currency == RewardCurrency.stars
                  ? Icons.star_rounded
                  : Icons.diamond_rounded,
              size: 14,
              color: LumoVisualTokens.muted),
          const SizedBox(width: 3),
          Text(
            '-${entry.cost}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
