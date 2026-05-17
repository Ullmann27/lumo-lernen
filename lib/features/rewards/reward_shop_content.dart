import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/reward_shop_repository.dart';
import '../../domain/rewards/reward_shop.dart';

/// Belohnungs-Shop Seite.
/// Kind sieht Sterne + Punkte + verfuegbare Belohnungen.
/// Bei Einloesung muss Eltern-PIN bestaetigt werden.
class RewardShopContent extends StatefulWidget {
  const RewardShopContent({
    super.key,
    required this.appState,
  });

  final LumoAppState appState;

  @override
  State<RewardShopContent> createState() => _RewardShopContentState();
}

class _RewardShopContentState extends State<RewardShopContent> {
  static const _engine = RewardShopEngine();
  static const _repo = RewardShopRepository();
  RewardShopState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  Future<void> _load() async {
    final loaded = await _repo.load(_childId);
    if (!mounted) return;
    setState(() {
      // Wenn der State leer ist, initial Sterne aus der App-State uebernehmen.
      // Bestehende Sterne aus Lern-Aufgaben werden so erstmalig in den Shop importiert.
      if (loaded.availableStars == 0 && widget.appState.state.stars > 0) {
        _state = loaded.copyWith(availableStars: widget.appState.state.stars);
      } else {
        _state = loaded;
      }
      _loading = false;
    });
    if (_state != null) {
      await _repo.save(_childId, _state!);
    }
  }

  Future<void> _redeem(RewardItem item) async {
    if (_state == null) return;
    if (!_engine.canAfford(_state!, item)) return;
    final requiresParentApproval =
        item.parentApprovalRequired || item.isPremiumReward;
    if (requiresParentApproval) {
      // Eltern-PIN bestaetigen (vereinfacht: zweimal antippen-Modal).
      final confirmed = await _showParentConfirmation(item);
      if (!confirmed || !mounted) return;
    }
    final next = _engine.redeem(_state!, item);
    if (next == null) return;
    setState(() => _state = next);
    await _repo.save(_childId, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF22C55E),
        content: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belohnung "${item.title}" eingelöst! Mama oder Papa erfüllen sie bald.',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showParentConfirmation(RewardItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eltern-Bestätigung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(item.description,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: LumoColors.ink500)),
            const SizedBox(height: 12),
            const Text(
              'Bitte zeige diese Belohnung Mama oder Papa zur Bestätigung.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: LumoColors.ink700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mama/Papa bestätigt'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _state == null) {
      return const Center(child: CircularProgressIndicator(color: LumoColors.orange));
    }
    final state = _state!;
    final now = DateTime.now();
    final season = Season.fromDate(now);
    final available = _engine.availableRewards(now: now);
    final microItems = available.where((r) => r.tier == RewardTier.micro).toList();
    final smallItems = available.where((r) => r.tier == RewardTier.small).toList();
    final mediumItems = available.where((r) => r.tier == RewardTier.medium).toList();
    final bigItems = available.where((r) => r.tier == RewardTier.big).toList();
    final premiumItems = available.where((r) => r.tier == RewardTier.premium).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Saison + Waehrungen
          _ShopHeader(season: season, stars: state.availableStars, points: state.availablePoints),
          const SizedBox(height: 20),
          if (state.testPhotos.isNotEmpty) ...[
            _TestPhotoSummary(testPhotos: state.testPhotos),
            const SizedBox(height: 20),
          ],
          // Mini-Belohnungen
          if (microItems.isNotEmpty) ...[
            _SectionTitle(emoji: '🪄', title: 'Mini-Belohnungen', subtitle: 'Schnelle Belohnungen für kurze Lernrunden'),
            const SizedBox(height: 10),
            ...microItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    item: item,
                    canAfford: _engine.canAfford(state, item),
                    onRedeem: () => _redeem(item),
                  ),
                )),
            const SizedBox(height: 18),
          ],
          // Kleine Belohnungen
          if (smallItems.isNotEmpty) ...[
            _SectionTitle(emoji: '🌟', title: 'Kleine Belohnungen', subtitle: 'Sterne sammeln und einlösen'),
            const SizedBox(height: 10),
            ...smallItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    item: item,
                    canAfford: _engine.canAfford(state, item),
                    onRedeem: () => _redeem(item),
                  ),
                )),
            const SizedBox(height: 18),
          ],
          // Mittlere Belohnungen
          if (mediumItems.isNotEmpty) ...[
            _SectionTitle(emoji: '✨', title: 'Mittlere Belohnungen', subtitle: 'Mit Punkten aus guten Noten'),
            const SizedBox(height: 10),
            ...mediumItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    item: item,
                    canAfford: _engine.canAfford(state, item),
                    onRedeem: () => _redeem(item),
                  ),
                )),
            const SizedBox(height: 18),
          ],
          // Grosse Belohnungen
          if (bigItems.isNotEmpty) ...[
            _SectionTitle(emoji: '🏆', title: 'Große Geschenke', subtitle: 'Für richtig gute Noten'),
            const SizedBox(height: 10),
            ...bigItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    item: item,
                    canAfford: _engine.canAfford(state, item),
                    onRedeem: () => _redeem(item),
                  ),
                )),
            const SizedBox(height: 18),
          ],
          // Premium-Belohnungen
          if (premiumItems.isNotEmpty) ...[
            _SectionTitle(emoji: '👑', title: 'Premium-Belohnungen', subtitle: 'Nur mit Elternfreigabe einlösbar'),
            const SizedBox(height: 10),
            ...premiumItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    item: item,
                    canAfford: _engine.canAfford(state, item),
                    onRedeem: () => _redeem(item),
                  ),
                )),
            const SizedBox(height: 18),
          ],
          if (state.redeemed.isNotEmpty) ...[
            _SectionTitle(emoji: '📜', title: 'Schon eingelöst', subtitle: 'Deine Belohnungs-Historie'),
            const SizedBox(height: 10),
            ...state.redeemed.reversed.take(10).map((r) => _RedeemedRow(entry: r)),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.season, required this.stars, required this.points});
  final Season season;
  final int stars;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _seasonGradient(season),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _seasonGradient(season)[1].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(season.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Text(
                'Belohnungs-Laden ${season.germanLabel}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _CurrencyChip(emoji: '⭐', label: 'Sterne', count: stars, color: const Color(0xFFFFB800))),
              const SizedBox(width: 10),
              Expanded(child: _CurrencyChip(emoji: '💎', label: 'Punkte', count: points, color: const Color(0xFF8B5CF6))),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _seasonGradient(Season s) {
    switch (s) {
      case Season.spring: return const [Color(0xFFFB7185), Color(0xFFE11D48)];
      case Season.summer: return const [Color(0xFFFCD34D), Color(0xFFFB923C)];
      case Season.autumn: return const [Color(0xFFEA580C), Color(0xFF9A3412)];
      case Season.winter: return const [Color(0xFF60A5FA), Color(0xFF2563EB)];
    }
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.emoji, required this.label, required this.count, required this.color});
  final String emoji;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: LumoColors.ink500)),
              Text('$count',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.emoji, required this.title, required this.subtitle});
  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: LumoColors.ink900)),
              Text(subtitle,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700, color: LumoColors.ink500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.item, required this.canAfford, required this.onRedeem});
  final RewardItem item;
  final bool canAfford;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final color = item.currency == RewardCurrency.stars
        ? const Color(0xFFFFB800)
        : const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canAfford
              ? [Colors.white, color.withOpacity(0.08)]
              : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? color.withOpacity(0.30) : LumoColors.ink100,
          width: 1.4,
        ),
        boxShadow: canAfford
            ? [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: canAfford ? [color.withOpacity(0.25), color.withOpacity(0.10)] : const [Color(0xFFE2E8F0), Color(0xFFF1F5F9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: canAfford ? LumoColors.ink900 : LumoColors.ink500)),
                const SizedBox(height: 2),
                Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w700, color: LumoColors.ink500, height: 1.3)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${item.cost} ${item.currency == RewardCurrency.stars ? '⭐' : '💎'}',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: canAfford ? onRedeem : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(canAfford ? 'Einlösen' : 'Noch nicht',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📸', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Deine letzten Tests',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF6D28D9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lastFive.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _noteColor(t.note),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${t.note}',
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.subject,
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.ink700)),
                    ),
                    Text('+${t.pointsAwarded} 💎',
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _noteColor(int n) {
    switch (n) {
      case 1: return const Color(0xFF22C55E);
      case 2: return const Color(0xFF84CC16);
      case 3: return const Color(0xFFFFB800);
      case 4: return const Color(0xFFEA580C);
      default: return const Color(0xFFEF4444);
    }
  }
}

class _RedeemedRow extends StatelessWidget {
  const _RedeemedRow({required this.entry});
  final RedeemedReward entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry.title,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: LumoColors.ink700)),
          ),
          Text('-${entry.cost} ${entry.currency == RewardCurrency.stars ? '⭐' : '💎'}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w900, color: LumoColors.ink500)),
        ],
      ),
    );
  }
}
