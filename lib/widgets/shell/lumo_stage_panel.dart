import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../fox/lumo_home_fox_avatar.dart';

class LumoStagePanel extends StatelessWidget {
  const LumoStagePanel({
    super.key,
    required this.appState,
    required this.onFoxTap,
    this.panelWidth = 320,
    this.compact = false,
  });

  final LumoAppState appState;
  final VoidCallback onFoxTap;
  final double panelWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final st = appState.state;
    final foxHeight = compact ? 210.0 : 265.0;
    final facing = (st.section == LumoSection.exercises ||
            st.section == LumoSection.scanner)
        ? -1.0
        : 1.0;

    return Container(
      width: panelWidth,
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
          SizedBox(height: compact ? 14 : 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            child: _SpeechBubble(text: st.lumoMessage, compact: compact),
          ),
          SizedBox(height: compact ? 10 : 16),
          Expanded(
            child: Center(
              child: LumoHomeFoxAvatar(
                size: foxHeight,
                facingLeft: facing < 0,
                onTap: onFoxTap,
                childName: st.childName,
                stars: st.stars,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: _DailyGoalCard(
              stars: st.stars,
              xp: st.xp,
              level: st.level,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.compact});
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 11 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(compact ? LumoRadius.md : LumoRadius.lg),
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
        maxLines: compact ? 4 : null,
        overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink900,
          height: 1.3,
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
    required this.compact,
  });

  final int stars;
  final int xp;
  final int level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = (stars / 50).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(compact ? LumoRadius.md : LumoRadius.lg),
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
          Text(
            'Lernstand',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Wrap(
            spacing: compact ? 8 : 14,
            runSpacing: 6,
            children: [
              _Stat(label: 'Sterne', value: '$stars', compact: compact),
              _Stat(label: 'XP', value: '$xp', compact: compact),
              _Stat(label: 'Level', value: '$level', compact: compact),
            ],
          ),
          SizedBox(height: compact ? 7 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 5 : 6,
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
  const _Stat({required this.label, required this.value, required this.compact});

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.62),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink700,
        ),
      ),
    );
  }
}
