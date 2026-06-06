// ════════════════════════════════════════════════════════════════════════
// LUMO STREAK CALENDAR — Woche-Raster mit Sternen fuer aktive Tage
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 27: Eyecatcher auf dem Home-Screen, zeigt Tochter sofort
// wie viele Tage diese Woche schon geuebt wurde. Aktive Tage mit Stern in
// Gold, inaktive Tage als Geist-Outline. Heutiger Tag mit blauem Ring +
// kleinem Fuchs darunter wenn schon aktiv.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class LumoStreakWeekCalendar extends StatelessWidget {
  const LumoStreakWeekCalendar({
    super.key,
    required this.dailyActivity,
    this.streakDays = 0,
  });

  /// Map: 'YYYY-MM-DD' -> Anzahl richtiger Antworten an dem Tag.
  final Map<String, int> dailyActivity;

  /// Aktueller Streak in Tagen (fortlaufend bis heute).
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Montag dieser Woche finden (DateTime.weekday: 1=Mo .. 7=So)
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFCD34D).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 2026-06-06 Iter 29: bei langem Streak echter Lumo-Cheer
              // statt nur Flammen-Emoji. Asset-Fehler -> Flammen-Fallback.
              if (streakDays >= 5)
                ClipOval(
                  child: Image.asset(
                    'assets/companion/lumo_cheer.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Text('🔥', style: TextStyle(fontSize: 26)),
                  ),
                )
              else
                const Text('🔥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streakDays > 0
                          ? '$streakDays Tage Streak!'
                          : 'Diese Woche',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                    Text(
                      streakDays >= 5
                          ? 'Du bist auf Feuer!'
                          : streakDays >= 2
                              ? 'Bleib dran!'
                              : 'Heute geht\'s los',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final d in days)
                _DayPill(
                  date: d,
                  isToday: _isSameDay(d, today),
                  activeCount: _activityFor(d),
                  isFuture: d.isAfter(today),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _activityFor(DateTime d) {
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return dailyActivity[key] ?? 0;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.isToday,
    required this.activeCount,
    required this.isFuture,
  });

  final DateTime date;
  final bool isToday;
  final int activeCount;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    final color = active
        ? const Color(0xFFEA580C)
        : isFuture
            ? const Color(0xFFD1D5DB)
            : const Color(0xFFA1A1AA);
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final lbl = labels[date.weekday - 1];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lbl,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isToday ? const Color(0xFF1D4ED8) : LumoColors.ink500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFFFEF3C7)
                : Colors.white.withOpacity(0.55),
            border: Border.all(
              color: isToday
                  ? const Color(0xFF1D4ED8)
                  : active
                      ? const Color(0xFFFCD34D)
                      : const Color(0xFFE5E7EB),
              width: isToday ? 2.4 : 1.4,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFCD34D).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              active ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (active)
          Text(
            '$activeCount',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEA580C),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }
}
