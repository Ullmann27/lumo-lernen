// ════════════════════════════════════════════════════════════════════════
//                  LUMO KART - PREMIUM-MENU
// ════════════════════════════════════════════════════════════════════════
//
// Premium-Vorbereitung vor dem Rennen. Zeigt Fahrer-, Kart- und
// Streckenauswahl. Phase 1: nur jeweils ein Eintrag entsperrt. Andere
// werden grau und mit Schloss-Icon dargestellt.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import 'kart_models.dart';
import 'lumo_kart_screen.dart';

class LumoKartMenuScreen extends StatefulWidget {
  const LumoKartMenuScreen({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<LumoKartMenuScreen> createState() => _LumoKartMenuScreenState();
}

class _LumoKartMenuScreenState extends State<LumoKartMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  KartDriverModel _driver = KartCatalog.lumoDriver;
  KartVehicleModel _vehicle = KartCatalog.starterKart;
  KartTrackModel _track = KartCatalog.meadowLap;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _startRace() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LumoKartScreen(
          appState: widget.appState,
          driver: _driver,
          vehicle: _vehicle,
          track: _track,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Hintergrund-Gradient ────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.95),
                    const Color(0xFF0F172A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // ── Hauptinhalt ─────────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _MenuHeader(onBack: () => Navigator.of(context).pop()),
                ),
                SliverToBoxAdapter(
                  child: _HeroBanner(
                    driver: _driver,
                    vehicle: _vehicle,
                    pulse: _pulse,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: 'Fahrer',
                    child: _DriverRow(
                      selected: _driver,
                      onSelected: (d) {
                        if (!d.unlocked) {
                          _showLockedHint(d.name);
                          return;
                        }
                        HapticFeedback.selectionClick();
                        setState(() => _driver = d);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: 'Kart',
                    child: _VehicleRow(
                      selected: _vehicle,
                      onSelected: (v) {
                        if (!v.unlocked) {
                          _showLockedHint(v.name);
                          return;
                        }
                        HapticFeedback.selectionClick();
                        setState(() => _vehicle = v);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MenuSection(
                    title: 'Strecke',
                    child: _TrackRow(
                      selected: _track,
                      onSelected: (t) {
                        if (!t.unlocked) {
                          _showLockedHint(t.name);
                          return;
                        }
                        HapticFeedback.selectionClick();
                        setState(() => _track = t);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: _StartButton(onTap: _startRace),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedHint(String name) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 2),
        content: Text(
          '$name ist bald freischaltbar.',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Lumo Kart Adventure',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 6, color: Color(0x66000000)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero-Banner: grosser Lumo-im-Kart ─────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.driver,
    required this.vehicle,
    required this.pulse,
  });

  final KartDriverModel driver;
  final KartVehicleModel vehicle;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final p = 0.94 + pulse.value * 0.06;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.4 * pulse.value),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Glow
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFEF3C7).withOpacity(0.5),
                            const Color(0xFFFEF3C7).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Kart-Sprite gross rechts
                  Positioned(
                    right: 12,
                    top: 12,
                    bottom: 12,
                    child: Transform.scale(
                      scale: p,
                      child: Image.asset(
                        vehicle.spriteAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_motorsports_rounded,
                          size: 140,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  // Text links
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1),
                          ),
                          child: const Text(
                            'PHASE 1',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 30,
                                color: Colors.white,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFFFEF3C7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section-Wrapper ────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Color(0x66000000))],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Auswahl-Reihen ─────────────────────────────────────────────────────

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.selected, required this.onSelected});
  final KartDriverModel selected;
  final ValueChanged<KartDriverModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: KartCatalog.drivers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = KartCatalog.drivers[i];
          final isSel = d.id == selected.id;
          return _OptionTile(
            label: d.name,
            sublabel: d.species,
            unlocked: d.unlocked,
            selected: isSel,
            onTap: () => onSelected(d),
            content: _DriverPortrait(driver: d),
          );
        },
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.selected, required this.onSelected});
  final KartVehicleModel selected;
  final ValueChanged<KartVehicleModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: KartCatalog.vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final v = KartCatalog.vehicles[i];
          final isSel = v.id == selected.id;
          return _OptionTile(
            label: v.name,
            sublabel: 'Kart',
            unlocked: v.unlocked,
            selected: isSel,
            onTap: () => onSelected(v),
            content: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                v.spriteAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_motorsports_rounded,
                  size: 36,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.selected, required this.onSelected});
  final KartTrackModel selected;
  final ValueChanged<KartTrackModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: KartCatalog.tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = KartCatalog.tracks[i];
          final isSel = t.id == selected.id;
          return _OptionTile(
            label: t.name,
            sublabel: 'Schwierigkeit ${t.difficulty}',
            unlocked: t.unlocked,
            selected: isSel,
            width: 150,
            onTap: () => onSelected(t),
            content: _TrackPreview(track: t),
          );
        },
      ),
    );
  }
}

class _DriverPortrait extends StatelessWidget {
  const _DriverPortrait({required this.driver});
  final KartDriverModel driver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: Image.asset(
            driver.portraitAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _SpeciesEmoji(species: driver.species),
          ),
        ),
      ),
    );
  }
}

class _SpeciesEmoji extends StatelessWidget {
  const _SpeciesEmoji({required this.species});
  final String species;

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiFor(species);
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 28)));
  }

  String _emojiFor(String species) {
    final s = species.toLowerCase();
    if (s.contains('fuchs')) return 'F';
    if (s.contains('hase')) return 'H';
    if (s.contains('elefant')) return 'E';
    if (s.contains('reh')) return 'R';
    if (s.contains('igel')) return 'I';
    return '?';
  }
}

class _TrackPreview extends StatelessWidget {
  const _TrackPreview({required this.track});
  final KartTrackModel track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _themeColors(track.theme),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Image.asset(
          track.previewAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  List<Color> _themeColors(String theme) {
    switch (theme) {
      case 'forest':
        return const [Color(0xFF065F46), Color(0xFF34D399)];
      case 'beach':
        return const [Color(0xFF38BDF8), Color(0xFFFDE68A)];
      case 'meadow':
      default:
        return const [Color(0xFF86EFAC), Color(0xFFFEF3C7)];
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.sublabel,
    required this.unlocked,
    required this.selected,
    required this.content,
    required this.onTap,
    this.width = 104,
  });

  final String label;
  final String sublabel;
  final bool unlocked;
  final bool selected;
  final Widget content;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.55,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(selected ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFCD34D)
                  : Colors.white.withOpacity(0.18),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFCD34D).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: content),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sublabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              if (!unlocked)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.lock_rounded,
                      color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Start-Button ───────────────────────────────────────────────────────

class _StartButton extends StatefulWidget {
  const _StartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFF97316), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text(
                'Rennen starten',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Color(0x66000000))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
