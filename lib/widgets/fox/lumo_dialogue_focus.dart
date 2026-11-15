import 'package:flutter/material.dart';
import '../../core/lumo_task_dialogue.dart';
import '../../theme/lumo_visual_tokens.dart';
import 'lumo_companion_requests.dart';

/// Highlights an existing learning object. It adds no countable token and
/// consumes no touches. A stale reply or another task cannot illuminate it.
class LumoDialogueFocusTarget extends StatelessWidget {
  const LumoDialogueFocusTarget(
      {super.key, required this.objectId, required this.child});
  final String objectId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final requests = LumoCompanionRequests.instance;
    return ValueListenableBuilder<LumoTaskDialogueReply?>(
      valueListenable: requests.dialogueFocus,
      child: child,
      builder: (_, reply, original) {
        final active = reply != null &&
            reply.targetObjectIds.contains(objectId) &&
            requests.taskContext.value?.dialogue?.containsReply(reply) == true;
        return Stack(fit: StackFit.expand, children: [
          original!,
          if (active)
            IgnorePointer(
                child: DecoratedBox(
              key: ValueKey('lumo-focus-$objectId'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LumoVisualTokens.gold, width: 3),
              ),
            )),
        ]);
      },
    );
  }
}
