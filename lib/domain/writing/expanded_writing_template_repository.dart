import 'writing_domain.dart';

/// Expanded symbol repository for the writing system.
///
/// The precise handcrafted templates can be added gradually. Until then this
/// repository provides deterministic fallback stroke models for A-Z and 0-20,
/// so writing tasks do not collapse back to only the letter A.
class ExpandedWritingTemplateRepository {
  const ExpandedWritingTemplateRepository();

  static const List<String> uppercaseLetters = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const List<String> numberSymbols = <String>[
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
  ];

  WritingTemplate findOrFallback(String symbol, {int grade = 1}) {
    final normalized = symbol.trim().isEmpty ? 'A' : symbol.trim().toUpperCase();
    final base = const WritingTemplateRepository().find(normalized, grade: grade);
    if (base != null) return base;

    if (uppercaseLetters.contains(normalized)) {
      return _letterFallback(normalized, grade: grade);
    }

    if (numberSymbols.contains(normalized)) {
      return _numberFallback(normalized, grade: grade);
    }

    return const WritingTemplateRepository().find('A', grade: grade)!;
  }

  String symbolForIndex(int index, {bool includeNumbers = true}) {
    final pool = includeNumbers
        ? <String>[...uppercaseLetters, ...numberSymbols]
        : uppercaseLetters;
    return pool[index % pool.length];
  }

  WritingTemplate _letterFallback(String symbol, {required int grade}) {
    final code = symbol.codeUnitAt(0);
    final variant = code % 6;
    final strokes = switch (variant) {
      0 => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M24 86 L50 14', startX: 24, startY: 86, endX: 50, endY: 14, directionLabel: 'up-right'),
          WritingTemplateStroke(order: 2, pathData: 'M50 14 L76 86', startX: 50, startY: 14, endX: 76, endY: 86, directionLabel: 'down-right'),
          WritingTemplateStroke(order: 3, pathData: 'M35 56 L65 56', startX: 35, startY: 56, endX: 65, endY: 56, directionLabel: 'right'),
        ],
      1 => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M28 88 L28 14', startX: 28, startY: 88, endX: 28, endY: 14, directionLabel: 'up'),
          WritingTemplateStroke(order: 2, pathData: 'M28 14 L68 14', startX: 28, startY: 14, endX: 68, endY: 14, directionLabel: 'right'),
          WritingTemplateStroke(order: 3, pathData: 'M28 52 L62 52', startX: 28, startY: 52, endX: 62, endY: 52, directionLabel: 'right'),
          WritingTemplateStroke(order: 4, pathData: 'M28 88 L72 88', startX: 28, startY: 88, endX: 72, endY: 88, directionLabel: 'right'),
        ],
      2 => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M70 22 C28 14 20 50 28 70 C38 94 68 86 76 72', startX: 70, startY: 22, endX: 76, endY: 72, directionLabel: 'curve'),
        ],
      3 => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M28 88 L28 14', startX: 28, startY: 88, endX: 28, endY: 14, directionLabel: 'up'),
          WritingTemplateStroke(order: 2, pathData: 'M28 14 L72 88', startX: 28, startY: 14, endX: 72, endY: 88, directionLabel: 'down-right'),
          WritingTemplateStroke(order: 3, pathData: 'M72 88 L72 14', startX: 72, startY: 88, endX: 72, endY: 14, directionLabel: 'up'),
        ],
      4 => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M28 14 L72 88', startX: 28, startY: 14, endX: 72, endY: 88, directionLabel: 'down-right'),
          WritingTemplateStroke(order: 2, pathData: 'M72 14 L28 88', startX: 72, startY: 14, endX: 28, endY: 88, directionLabel: 'down-left'),
        ],
      _ => const <WritingTemplateStroke>[
          WritingTemplateStroke(order: 1, pathData: 'M26 18 L50 86', startX: 26, startY: 18, endX: 50, endY: 86, directionLabel: 'down-right'),
          WritingTemplateStroke(order: 2, pathData: 'M74 18 L50 86', startX: 74, startY: 18, endX: 50, endY: 86, directionLabel: 'down-left'),
        ],
    };

    return WritingTemplate(
      symbol: symbol,
      grade: grade,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: strokes,
    );
  }

  WritingTemplate _numberFallback(String symbol, {required int grade}) {
    if (symbol.length > 1) {
      final left = _singleDigitFallback(symbol[0], grade: grade, xOffset: -18);
      final right = _singleDigitFallback(symbol[1], grade: grade, xOffset: 18);
      return WritingTemplate(
        symbol: symbol,
        grade: grade,
        viewBoxWidth: 100,
        viewBoxHeight: 100,
        strokes: <WritingTemplateStroke>[...left.strokes, ...right.strokes],
      );
    }
    return _singleDigitFallback(symbol, grade: grade);
  }

  WritingTemplate _singleDigitFallback(String symbol, {required int grade, double xOffset = 0}) {
    WritingTemplateStroke s(int order, String path, double sx, double sy, double ex, double ey, String dir) {
      return WritingTemplateStroke(
        order: order,
        pathData: path,
        startX: (sx + xOffset).clamp(5.0, 95.0),
        startY: sy,
        endX: (ex + xOffset).clamp(5.0, 95.0),
        endY: ey,
        directionLabel: dir,
      );
    }

    final strokes = switch (symbol) {
      '0' => <WritingTemplateStroke>[s(1, 'M50 12 C25 12 20 35 20 50 C20 75 35 90 50 90 C75 90 80 65 80 50 C80 25 65 12 50 12', 50, 12, 50, 12, 'round')],
      '1' => <WritingTemplateStroke>[s(1, 'M50 18 L50 90', 50, 18, 50, 90, 'down')],
      '2' => <WritingTemplateStroke>[s(1, 'M28 30 C40 12 76 18 70 42', 28, 30, 70, 42, 'curve'), s(2, 'M70 42 L30 88', 70, 42, 30, 88, 'down-left'), s(3, 'M30 88 L76 88', 30, 88, 76, 88, 'right')],
      '3' => <WritingTemplateStroke>[s(1, 'M28 20 L74 20', 28, 20, 74, 20, 'right'), s(2, 'M74 20 L48 52', 74, 20, 48, 52, 'down-left'), s(3, 'M48 52 C80 52 78 90 34 84', 48, 52, 34, 84, 'curve')],
      '4' => <WritingTemplateStroke>[s(1, 'M70 88 L70 16', 70, 88, 70, 16, 'up'), s(2, 'M70 16 L25 62', 70, 16, 25, 62, 'down-left'), s(3, 'M25 62 L80 62', 25, 62, 80, 62, 'right')],
      '5' => <WritingTemplateStroke>[s(1, 'M75 18 L32 18', 75, 18, 32, 18, 'left'), s(2, 'M32 18 L28 48', 32, 18, 28, 48, 'down'), s(3, 'M28 48 C72 42 82 90 40 88', 28, 48, 40, 88, 'curve')],
      '6' => <WritingTemplateStroke>[s(1, 'M72 20 C30 26 22 80 54 88', 72, 20, 54, 88, 'curve'), s(2, 'M54 88 C88 78 72 45 36 54', 54, 88, 36, 54, 'curve')],
      '7' => <WritingTemplateStroke>[s(1, 'M26 18 L78 18', 26, 18, 78, 18, 'right'), s(2, 'M78 18 L38 90', 78, 18, 38, 90, 'down-left')],
      '8' => <WritingTemplateStroke>[s(1, 'M50 16 C24 18 24 48 50 50 C76 52 76 84 50 86 C24 84 24 54 50 50 C76 46 76 18 50 16', 50, 16, 50, 16, 'round')],
      '9' => <WritingTemplateStroke>[s(1, 'M52 16 C22 26 34 58 68 48', 52, 16, 68, 48, 'curve'), s(2, 'M68 48 C72 72 56 88 32 86', 68, 48, 32, 86, 'curve')],
      _ => <WritingTemplateStroke>[s(1, 'M50 18 L50 90', 50, 18, 50, 90, 'down')],
    };

    return WritingTemplate(
      symbol: symbol,
      grade: grade,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: strokes,
    );
  }
}
