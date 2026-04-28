import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../common/lumo_surface_card.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subtitle,
    this.progress,
    this.useCircular = false,
  });

  final Widget icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color accentColor;
  final double? progress;
  final bool useCircular;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress?.clamp(0.0, 1.0).toDouble();
    return LumoSurfaceCard(
      width: 168,
      height: 104,
      radius: LumoRadius.kpi,
      padding: const EdgeInsets.all(14),
      shadowColor: accentColor,
      color: Colors.white.withOpacity(.86),
      child: Row(
        children: [
          SizedBox(width: 34, height: 34, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.kpiLabel.copyWith(color: accentColor)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.kpiValue),
                if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LumoColors.mutedText)),
                if (normalizedProgress != null) ...[
                  const SizedBox(height: 8),
                  useCircular
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(value: normalizedProgress, strokeWidth: 4, color: accentColor, backgroundColor: accentColor.withOpacity(.13)))
                      : ClipRRect(borderRadius: BorderRadius.circular(LumoRadius.pill), child: LinearProgressIndicator(value: normalizedProgress, minHeight: 7, color: accentColor, backgroundColor: accentColor.withOpacity(.13))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
