import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../theme/lumo_visual_tokens.dart';
import 'parent_task_practice_screen.dart';
import 'parent_task_workspace_controller.dart';

/// No extra Home choice exists until this child has an authored task or receipt.
class ParentTasksEntryCard extends StatefulWidget {
  const ParentTasksEntryCard({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ParentTasksEntryCard> createState() => _ParentTasksEntryCardState();
}

class _ParentTasksEntryCardState extends State<ParentTasksEntryCard> {
  late final _controller = ParentTaskWorkspaceController(widget.appState);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ParentTaskPracticeScreen(appState: widget.appState)));
    if (mounted) await _controller.reload();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.current ||
              _controller.workspace?.hasChildContent != true) {
            return const SizedBox.shrink();
          }
          final count = _controller.workspace!.tasks.length;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: LumoVisualTokens.glass,
              child: InkWell(
                key: const ValueKey('parent-tasks-home-entry'),
                borderRadius: BorderRadius.circular(16),
                onTap: _controller.ready ? _open : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 72),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.family_restroom_rounded,
                            color: LumoVisualTokens.gold),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Aufgaben von deinen Eltern',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17)),
                              const SizedBox(height: 4),
                              Text(
                                  _controller.workspace!.activeAttempt != null
                                      ? 'Deine Elternaufgabe fortsetzen'
                                      : '$count ${count == 1 ? 'eigene Aufgabe' : 'eigene Aufgaben'} zum Üben',
                                  style: const TextStyle(
                                      color: LumoVisualTokens.muted)),
                            ])),
                        const SizedBox(width: 8),
                        const Icon(Icons.play_circle_fill_rounded,
                            color: LumoVisualTokens.cyanBright, size: 36),
                      ])),
                ),
              ),
            ),
          );
        },
      );
}
