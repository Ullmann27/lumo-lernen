import 'package:flutter/material.dart';
import '../../../theme/lumo_visual_tokens.dart';

/// Separates the evidence to read from the actual question. Both are always
/// visible; this widget has no answer, progress, speech or microphone access.
class ReadingPassageCard extends StatelessWidget {
  const ReadingPassageCard({super.key, required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final split = prompt.lastIndexOf('\n');
    if (split < 0) return Text(prompt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10284C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x88A78BFA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Image.asset('assets/lumo_design/ui/book.webp',
                      width: 26, height: 26, excludeFromSemantics: true),
                  Text('Lies in Ruhe',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC4B5FD))),
                ],
              ),
              const SizedBox(height: 12),
              Text(prompt.substring(0, split),
                  key: const ValueKey('reading-passage'),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 21,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: LumoVisualTokens.white)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(prompt.substring(split + 1),
            key: const ValueKey('reading-question'),
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 23,
                height: 1.3,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ],
    );
  }
}
