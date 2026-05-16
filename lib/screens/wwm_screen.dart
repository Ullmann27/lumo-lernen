import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wwm_game_state.dart';
import '../services/wwm_question_service.dart';
import '../services/reward_orchestrator.dart';
import '../widgets/lumo_avatar.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bgDark = Color(0xFF0D1B2A);
const _cardDark = Color(0xFF162B40);
const _gold = Color(0xFFC9A000);

class WwmScreen extends StatefulWidget {
  const WwmScreen({super.key});

  @override
  State<WwmScreen> createState() => _WwmScreenState();
}

class _WwmScreenState extends State<WwmScreen> with TickerProviderStateMixin {
  Timer? _revealTimer;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Start a fresh game every time the screen opens
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WwmGameState>().startGame(),
    );
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Answer tap handler ────────────────────────────────────────────────────

  void _onAnswerTap(WwmGameState state, int index) {
    if (state.status != WwmStatus.playing) return;
    if (state.hiddenOptions.contains(index)) return;
    state.selectAnswer(index);
    _revealTimer?.cancel();
    // 1.5 s "thinking" delay before revealing correct / wrong
    _revealTimer = Timer(
      const Duration(milliseconds: 1500),
      state.confirmAnswer,
    );
  }

  void _collectAndPop(WwmGameState state) {
    final xp = state.earnedXP;
    if (xp > 0) context.read<RewardOrchestrator>().addXP(xp);
    Navigator.of(context).pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<WwmGameState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: _bgDark,
        body: SafeArea(child: _buildBody(state)),
      ),
    );
  }

  Widget _buildBody(WwmGameState state) {
    switch (state.status) {
      case WwmStatus.loading:
        return _buildLoading();
      case WwmStatus.error:
        return _buildError(state);
      case WwmStatus.finished:
        return _buildEndScreen(state, result: _GameResult.victory);
      case WwmStatus.wrong:
        return _buildEndScreen(state, result: _GameResult.wrong);
      case WwmStatus.quit:
        return _buildEndScreen(state, result: _GameResult.quit);
      default:
        return _buildGame(state);
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LumoAvatar(size: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: _gold),
            const SizedBox(height: 16),
            const Text(
              'Lumo lädt Fragen…',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(WwmGameState state) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Fehler beim Laden.',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              Text(state.errorMessage ?? '',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.startGame,
                style: ElevatedButton.styleFrom(backgroundColor: _gold),
                child: const Text('Nochmal versuchen'),
              ),
            ],
          ),
        ),
      );

  // ── Main game ─────────────────────────────────────────────────────────────

  Widget _buildGame(WwmGameState state) {
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();
    return Column(
      children: [
        _buildTopBar(state),
        _buildProgressRow(state),
        const SizedBox(height: 6),
        _buildQuestionCard(q),
        const Spacer(),
        _buildAnswerGrid(state, q),
        const SizedBox(height: 12),
        _buildXpDots(state),
        const SizedBox(height: 8),
        if (state.status == WwmStatus.correct)
          _buildContinueBar(state),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(WwmGameState state) {
    final canInteract = state.status == WwmStatus.playing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _jokerChip(
            icon: Icons.looks_two_rounded,
            label: '50:50',
            used: state.joker5050Used,
            onTap: canInteract ? () => state.useJoker5050() : null,
          ),
          const SizedBox(width: 8),
          _jokerChip(
            icon: Icons.phone_rounded,
            label: 'Lumo',
            used: state.jokerPhoneUsed,
            onTap: canInteract ? () => _openPhoneJoker(state) : null,
          ),
          const SizedBox(width: 8),
          _jokerChip(
            icon: Icons.people_rounded,
            label: 'Publikum',
            used: state.jokerAudienceUsed,
            onTap: canInteract ? () => _openAudienceJoker(state) : null,
          ),
          const Spacer(),
          if (canInteract)
            TextButton.icon(
              onPressed: () => _openQuitDialog(state),
              icon: const Icon(Icons.exit_to_app_rounded,
                  color: Colors.white54, size: 18),
              label: const Text('Aufhören',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _jokerChip({
    required IconData icon,
    required String label,
    required bool used,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: used ? null : onTap,
        child: AnimatedOpacity(
          opacity: used ? 0.28 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _gold, width: 1.5),
              borderRadius: BorderRadius.circular(20),
              color: used ? Colors.transparent : _gold.withOpacity(0.12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: used ? Colors.grey : _gold, size: 16),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: used ? Colors.grey : _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  // ── Progress row ──────────────────────────────────────────────────────────

  Widget _buildProgressRow(WwmGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isCurrentSafeLevel)
            const Text('⭐ ',
                style: TextStyle(fontSize: 16)),
          Text(
            'Frage ${state.currentIndex + 1} von 15',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withOpacity(0.6)),
            ),
            child: Text(
              '${state.currentXP} XP',
              style: const TextStyle(
                  color: _gold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (state.securedXP > 0) ...[
            const SizedBox(width: 8),
            Text(
              '🔒 ${state.securedXP} XP',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard(WwmQuestion q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              q.subject.toUpperCase(),
              style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              q.question,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Answer grid (2 × 2) ───────────────────────────────────────────────────

  Widget _buildAnswerGrid(WwmGameState state, WwmQuestion q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _answerBtn(state, q, 0, 'A')),
              const SizedBox(width: 8),
              Expanded(child: _answerBtn(state, q, 1, 'B')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _answerBtn(state, q, 2, 'C')),
              const SizedBox(width: 8),
              Expanded(child: _answerBtn(state, q, 3, 'D')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBtn(
      WwmGameState state, WwmQuestion q, int index, String letter) {
    if (state.hiddenOptions.contains(index)) {
      return const SizedBox(height: 64);
    }

    final isSelected = state.selectedIndex == index;
    final isCorrect = index == q.correctIndex;
    final revealed = state.status == WwmStatus.correct ||
        state.status == WwmStatus.wrong;

    Color bg = _cardDark;
    Color border = _gold;
    Color letterBg = _gold.withOpacity(0.22);

    if (isSelected && state.status == WwmStatus.selected) {
      bg = Colors.orange.shade700;
      border = Colors.orange.shade300;
      letterBg = Colors.orange.shade900;
    } else if (revealed) {
      if (isCorrect) {
        bg = Colors.green.shade800;
        border = Colors.green.shade400;
        letterBg = Colors.green.shade900;
      } else if (isSelected) {
        bg = Colors.red.shade900;
        border = Colors.red.shade400;
        letterBg = Colors.red.shade800;
      }
    }

    Widget btn = GestureDetector(
      onTap: state.status == WwmStatus.playing
          ? () => _onAnswerTap(state, index)
          : null,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            // Letter badge
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  bottomLeft: Radius.circular(32),
                ),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                      color: border,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            // Answer text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  q.options[index],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Pulse animation while in "selected" state
    if (isSelected && state.status == WwmStatus.selected) {
      btn = AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnim.value, child: child),
        child: btn,
      );
    }

    return btn;
  }

  // ── XP ladder dots ────────────────────────────────────────────────────────

  Widget _buildXpDots(WwmGameState state) {
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 15,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final isSafe = WwmGameState.safeIndices.contains(i);
          final isPast = i < state.currentIndex;
          final isCurrent = i == state.currentIndex;
          final isFuture = i > state.currentIndex;

          if (isSafe) {
            return Center(
              child: Text(
                '⭐',
                style: TextStyle(
                    fontSize: isCurrent ? 18 : 12,
                    color: isFuture ? Colors.white24 : null),
              ),
            );
          }

          final size = isCurrent ? 20.0 : 12.0;

          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isPast ? _gold : (isCurrent ? _gold : Colors.white24),
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Continue bar (correct answer only) ───────────────────────────────────

  Widget _buildContinueBar(WwmGameState state) {
    final isSafe = state.isCurrentSafeLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade900.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade400),
            ),
            child: Text(
              isSafe
                  ? '✅ Richtig!  🔒 Sicherheitsstufe erreicht!'
                  : '✅ Richtig!  +${state.currentXP} XP',
              style: TextStyle(
                  color: Colors.green.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          // Explanation
          if (state.currentQuestion?.explanation.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '💡 ${state.currentQuestion!.explanation}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: state.advance,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              state.currentIndex >= 14 ? '🏆 Gewonnen!' : 'Weiter  ➡️',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── End screen ────────────────────────────────────────────────────────────

  Widget _buildEndScreen(WwmGameState state,
      {required _GameResult result}) {
    final xp = state.earnedXP;

    final String emoji;
    final String title;
    final String subtitle;
    final Color bgColor;
    final Color btnColor;
    final Color btnFg;

    switch (result) {
      case _GameResult.victory:
        emoji = '🏆';
        title = 'Superstar!';
        subtitle = 'Du hast alle 15 Fragen richtig beantwortet!';
        bgColor = const Color(0xFF1A1200);
        btnColor = _gold;
        btnFg = Colors.black;
      case _GameResult.wrong:
        emoji = '😢';
        title = 'Leider falsch!';
        subtitle = xp > 0
            ? 'Nicht schlimm – du hattest ${xp} XP gesichert.'
            : 'Nicht schlimm – beim nächsten Mal klappt es!';
        bgColor = const Color(0xFF1A0000);
        btnColor = Colors.red.shade700;
        btnFg = Colors.white;
      case _GameResult.quit:
        emoji = '👋';
        title = 'Gut gemacht!';
        subtitle = xp > 0
            ? 'Du nimmst $xp XP mit!'
            : 'Beim nächsten Mal schaffst du mehr!';
        bgColor = _bgDark;
        btnColor = _gold;
        btnFg = Colors.black;
    }

    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LumoAvatar(size: 120),
              const SizedBox(height: 20),
              Text(emoji,
                  style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (xp > 0) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold, width: 2),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: const TextStyle(
                        color: _gold,
                        fontSize: 38,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => _collectAndPop(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: btnFg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(
                    xp > 0 ? '$xp XP kassieren 🎉' : 'Nochmal spielen',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _openQuitDialog(WwmGameState state) {
    final quitXp = state.currentIndex > 0
        ? math.max(
            state.securedXP, WwmGameState.xpLadder[state.currentIndex - 1])
        : state.securedXP;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _gold, width: 2),
        ),
        title: const Text('Aufhören?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          quitXp > 0
              ? 'Du nimmst $quitXp XP mit.\nWirklich aufhören?'
              : 'Du hast noch keine XP gesichert.\nWirklich aufhören?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Weiterspielen',
                style: TextStyle(color: _gold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              state.quit();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800),
            child: const Text('Aufhören'),
          ),
        ],
      ),
    );
  }

  void _openPhoneJoker(WwmGameState state) {
    // Intentionally fire-and-forget: dialog reacts to state via Consumer
    // ignore: discarded_futures
    state.useJokerPhone();

    showDialog<void>(
      context: context,
      builder: (_) => Consumer<WwmGameState>(
        builder: (ctx, s, __) => AlertDialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _gold, width: 2),
          ),
          title: Row(
            children: const [
              LumoAvatar(size: 44),
              SizedBox(width: 10),
              Text('Lumo sagt…',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: s.phoneHintLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _gold),
                    SizedBox(width: 12),
                    Text('Lumo denkt nach…',
                        style: TextStyle(color: Colors.white70)),
                  ],
                )
              : Text(
                  s.phoneHint ?? '…',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style:
                  ElevatedButton.styleFrom(backgroundColor: _gold),
              child: const Text('Danke, Lumo! 🦊',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAudienceJoker(WwmGameState state) {
    state.useJokerAudience();
    // Capture votes snapshot so dialog never re-animates on unrelated rebuilds
    final votes = List<double>.from(state.audienceVotes);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _gold, width: 2),
        ),
        title: const Text('Publikums-Joker 👥',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: votes.isEmpty
            ? const SizedBox.shrink()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (i) {
                  const labels = ['A', 'B', 'C', 'D'];
                  final pct = votes[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(labels[i],
                              style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct / 100),
                            duration:
                                const Duration(milliseconds: 900),
                            curve: Curves.easeOut,
                            builder: (_, value, __) => Stack(
                              children: [
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          _gold.withOpacity(0.75),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '${pct.toStringAsFixed(0)} %',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _gold),
            child: const Text('Danke!',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

enum _GameResult { victory, wrong, quit }
