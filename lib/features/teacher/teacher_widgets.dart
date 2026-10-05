import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';

const kTeacherLabel = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w900,
    color: LumoVisualTokens.white);

const kTeacherMuted = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: Color(0xFFD6E8FF));

/// Dunkles Glas-Panel im LUMO-Stil für den Lehrerbereich.
class TeacherPanel extends StatelessWidget {
  const TeacherPanel({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xD90B2A5C),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x8837D2FD)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(title, style: kTeacherLabel.copyWith(fontSize: 17))),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

/// Großer leuchtender Knopf (mind. 48 dp hoch).
class TeacherButton extends StatelessWidget {
  const TeacherButton(
      {super.key, required this.label, required this.icon, required this.onTap, this.filled = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: filled
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF63E4FF), Color(0xFF1E7FE0)])
                  : null,
              color: filled ? null : const Color(0xB30B2A5C),
              border: Border.all(
                  color: filled
                      ? const Color(0xFFBDF4FF)
                      : const Color(0x8837D2FD),
                  width: 1.6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: kTeacherLabel.copyWith(fontSize: 14)),
              ),
            ]),
          ),
        ),
      );
}

/// Fragt einen kurzen Text ab (Vorname, Klassenname …). Gibt null bei Abbruch.
Future<String?> askText(BuildContext context,
    {required String title, required String hint}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B2A5C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xCC53DDFD), width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: kTeacherLabel.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('teacher-text-input'),
            controller: controller,
            autofocus: true,
            maxLength: 24,
            style: kTeacherLabel.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: kTeacherMuted,
              counterStyle: kTeacherMuted,
              filled: true,
              fillColor: const Color(0x33FFFFFF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TeacherButton(
                    label: 'Abbrechen',
                    icon: Icons.close_rounded,
                    filled: false,
                    onTap: () => Navigator.of(ctx).pop())),
            const SizedBox(width: 10),
            Expanded(
                child: TeacherButton(
                    label: 'Speichern',
                    icon: Icons.check_rounded,
                    onTap: () => Navigator.of(ctx).pop(controller.text))),
          ]),
        ]),
      ),
    ),
  );
}
