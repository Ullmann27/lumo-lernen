// ════════════════════════════════════════════════════════════════════════
// LUMO PREMIUM SHOWCASE — Vitrine fuer alle Premium-Komponenten
// ════════════════════════════════════════════════════════════════════════
// Aufrufbar aus den Settings als "Design-Vorschau".
// Heinz kann hier sehen wie die Premium-UI wirkt bevor sie auf die
// Hauptscreens angewendet wird.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';
import '../../widgets/premium/premium.dart';

class LumoPremiumShowcaseScreen extends StatelessWidget {
  const LumoPremiumShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoTokens.colors.creme,
      body: LumoMagicBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                    LumoTokens.space16,
                    LumoTokens.space8,
                    LumoTokens.space16,
                    LumoTokens.space64),
                children: [
                  // Header
                  LumoStageHeader(
                    greeting: 'Premium UI ✨',
                    subtitle: 'Lumo Magic Stage Showcase',
                    stars: 142,
                    streak: 7,
                    level: 5,
                  ),
                  const SizedBox(height: LumoTokens.space24),

                  // Hero Cards (Spielewelt-Stil)
                  _SectionLabel(text: 'Hero Cards'),
                  const SizedBox(height: LumoTokens.space12),
                  LumoAnimatedPageShell(
                    child: LumoHeroCard(
                      title: 'Lumo Jump',
                      subtitle: 'Springe durch die Wolken',
                      icon: Icons.flight_takeoff_rounded,
                      gradient: LumoTokens.colors.heroOrange,
                      glowColor: LumoTokens.colors.lumoOrange,
                      badge: 'NEU',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: LumoTokens.space12),
                  LumoAnimatedPageShell(
                    delay: const Duration(milliseconds: 100),
                    child: LumoHeroCard(
                      title: 'Lumo Kart',
                      subtitle: 'Rasend schnell ueber die Strecke',
                      icon: Icons.directions_car_rounded,
                      gradient: LumoTokens.colors.heroLila,
                      glowColor: LumoTokens.colors.lumoLila,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: LumoTokens.space24),

                  // Premium Cards
                  _SectionLabel(text: 'Premium Cards'),
                  const SizedBox(height: LumoTokens.space12),
                  Row(
                    children: [
                      Expanded(
                        child: LumoPremiumCard(
                          onTap: () {},
                          padding:
                              const EdgeInsets.all(LumoTokens.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.calculate_rounded,
                                  color: LumoTokens.colors.lumoOrange,
                                  size: 32),
                              const SizedBox(height: LumoTokens.space8),
                              Text('Mathe',
                                  style: LumoTokens.typo.titleLarge),
                              Text('Plus, Minus, Mal',
                                  style: LumoTokens.typo.bodySmall.copyWith(
                                      color: LumoTokens.colors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: LumoTokens.space12),
                      Expanded(
                        child: LumoPremiumCard(
                          onTap: () {},
                          padding:
                              const EdgeInsets.all(LumoTokens.space16),
                          glow: LumoTokens.colors.gold,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  color: LumoTokens.colors.lumoLila,
                                  size: 32),
                              const SizedBox(height: LumoTokens.space8),
                              Text('Lesen',
                                  style: LumoTokens.typo.titleLarge),
                              Text('Buchstaben & Wörter',
                                  style: LumoTokens.typo.bodySmall.copyWith(
                                      color: LumoTokens.colors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LumoTokens.space24),

                  // Progress Rings
                  _SectionLabel(text: 'Fortschritts-Ringe'),
                  const SizedBox(height: LumoTokens.space12),
                  LumoPremiumCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            LumoProgressRing(
                              value: 0.65,
                              size: 70,
                              gradient: LumoTokens.colors.heroOrange,
                              center: Text('65%',
                                  style: LumoTokens.typo.titleMedium),
                            ),
                            const SizedBox(height: LumoTokens.space4),
                            Text('Mathe',
                                style: LumoTokens.typo.labelMedium),
                          ],
                        ),
                        Column(
                          children: [
                            LumoProgressRing(
                              value: 0.92,
                              size: 70,
                              gradient: LumoTokens.colors.heroSuccess,
                              center: Text('92%',
                                  style: LumoTokens.typo.titleMedium),
                            ),
                            const SizedBox(height: LumoTokens.space4),
                            Text('Tiere',
                                style: LumoTokens.typo.labelMedium),
                          ],
                        ),
                        Column(
                          children: [
                            LumoProgressRing(
                              value: 0.32,
                              size: 70,
                              gradient: LumoTokens.colors.heroLila,
                              center: Text('32%',
                                  style: LumoTokens.typo.titleMedium),
                            ),
                            const SizedBox(height: LumoTokens.space4),
                            Text('Lesen',
                                style: LumoTokens.typo.labelMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LumoTokens.space24),

                  // Empty/Error States
                  _SectionLabel(text: 'Empty & Error States'),
                  const SizedBox(height: LumoTokens.space12),
                  LumoEmptyErrorState.cloud(onAction: () {}),
                  const SizedBox(height: LumoTokens.space12),
                  const LumoEmptyErrorState.empty(),
                  const SizedBox(height: LumoTokens.space24),

                  // Reward Burst Trigger
                  _SectionLabel(text: 'Reward Burst'),
                  const SizedBox(height: LumoTokens.space12),
                  LumoPremiumCard(
                    onTap: () => showLumoRewardBurst(
                      context,
                      stars: 3,
                      xp: 25,
                      message: 'Super gemacht!',
                    ),
                    gradient: LumoTokens.colors.heroGold,
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 32),
                        const SizedBox(width: LumoTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Test-Belohnung zeigen',
                                  style: LumoTokens.typo.titleLarge
                                      .copyWith(color: Colors.white)),
                              Text('Tippen fuer Sterne-Animation',
                                  style: LumoTokens.typo.bodyMedium
                                      .copyWith(
                                          color: Colors.white
                                              .withOpacity(0.85))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LumoTokens.space24),

                  // Glass Panel
                  _SectionLabel(text: 'Glass Panel'),
                  const SizedBox(height: LumoTokens.space12),
                  LumoGlassPanel(
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: LumoTokens.colors.lumoLila, size: 32),
                        const SizedBox(width: LumoTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Glas-Panel mit Blur',
                                  style: LumoTokens.typo.titleLarge),
                              Text(
                                  'Glasmorphism mit BackdropFilter - Premium-Effekt',
                                  style: LumoTokens.typo.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: LumoTokens.space64),
                ],
              ),
              // Back button
              Positioned(
                top: LumoTokens.space8,
                left: LumoTokens.space8,
                child: IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: LumoTokens.shadows.softCard,
                    ),
                    padding: const EdgeInsets.all(LumoTokens.space8),
                    child: Icon(Icons.arrow_back_rounded,
                        color: LumoTokens.colors.textDark),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Floating Action Dock Demo
              LumoFloatingActionDock(
                actions: [
                  LumoDockAction(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Belohnung',
                    onTap: () => showLumoRewardBurst(context,
                        stars: 1, xp: 5, message: 'Geschenk!'),
                    gradient: LumoTokens.colors.heroLila,
                    badgeCount: 3,
                  ),
                  LumoDockAction(
                    icon: Icons.help_outline_rounded,
                    label: 'Lumo-Hilfe',
                    onTap: () {},
                    gradient: LumoTokens.colors.heroGold,
                  ),
                  LumoDockAction(
                    icon: Icons.play_arrow_rounded,
                    label: 'Spielen',
                    onTap: () {},
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: LumoTokens.space4),
      child: Text(
        text,
        style: LumoTokens.typo.labelSmall.copyWith(
          color: LumoTokens.colors.textMuted,
        ),
      ),
    );
  }
}
