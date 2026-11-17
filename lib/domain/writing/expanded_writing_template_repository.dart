import 'writing_domain.dart';
import 'writing_path_geometry.dart';

/// Explicit print-letter traces. Missing symbols remain ungraded free practice;
/// a different letter is never substituted as a supposedly correct template.
class ExpandedWritingTemplateRepository {
  const ExpandedWritingTemplateRepository();

  static const uppercaseLetters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];
  static const numberSymbols = <String>[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
  ];

  /// School print lowercase letters, umlauts and ß (Vierlinien-System).
  static const lowercaseLetters = <String>[
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    'ä', 'ö', 'ü', 'ß',
  ];

  /// Capital umlauts; their dots sit above a slightly lower letter body.
  static const uppercaseUmlauts = <String>['Ä', 'Ö', 'Ü'];

  /// Writing lines for the canvas. Lowercase letters use the four school
  /// lines (top, x-height, base, descender); capitals and digits use the
  /// full box between cap line and base line.
  static WritingLineature lineatureFor(String symbol) {
    final trimmed = symbol.trim();
    if (trimmed.length == 1 && lowercaseLetters.contains(trimmed)) {
      return WritingLineature.fourLines;
    }
    return WritingLineature.capitals;
  }

  WritingTemplate findOrFallback(String symbol, {int grade = 1}) {
    final normalized = symbol.trim();
    // Lowercase writing is different from uppercase writing. Do not silently
    // turn "a" into an "A" template under an unchanged lowercase prompt.
    var paths = _paths[normalized];
    if (paths == null &&
        numberSymbols.contains(normalized) &&
        normalized.length == 2) {
      paths = [
        for (var digit = 0; digit < normalized.length; digit++)
          for (final path in _paths[normalized[digit]]!)
            WritingPathGeometry.transformX(path,
                scale: .46, offset: digit == 0 ? 1 : 53),
      ];
    }
    return WritingTemplate(
      symbol: normalized,
      grade: grade,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: [
        for (var i = 0; i < (paths?.length ?? 0); i++)
          _stroke(i + 1, paths![i]),
      ],
    );
  }

  String symbolForIndex(int index, {bool includeNumbers = true}) {
    final pool = includeNumbers
        ? [...uppercaseLetters, ...numberSymbols]
        : uppercaseLetters;
    return pool[index % pool.length];
  }

  WritingTemplateStroke _stroke(int order, String path) {
    final points = WritingPathGeometry.sample(path);
    return WritingTemplateStroke(
      order: order,
      pathData: path,
      startX: points.first.x,
      startY: points.first.y,
      endX: points.last.x,
      endY: points.last.y,
    );
  }

  static const _paths = <String, List<String>>{
    'A': ['M20 90 L50 10', 'M50 10 L80 90', 'M35 55 L65 55'],
    'B': [
      'M25 12 L25 88',
      'M25 12 L48 12 C82 12 82 50 48 50 L25 50',
      'M25 50 L50 50 C86 50 86 88 50 88 L25 88'
    ],
    'C': ['M78 22 C60 4 22 10 22 50 C22 90 60 96 78 78'],
    'D': ['M25 12 L25 88', 'M25 12 L45 12 C91 12 91 88 45 88 L25 88'],
    'E': ['M27 12 L27 88', 'M27 12 L76 12', 'M27 50 L66 50', 'M27 88 L76 88'],
    'F': ['M27 12 L27 88', 'M27 12 L76 12', 'M27 50 L66 50'],
    'G': ['M78 22 C60 4 22 10 22 50 C22 90 62 98 78 76 L78 54 L55 54'],
    'H': ['M25 12 L25 88', 'M75 12 L75 88', 'M25 50 L75 50'],
    'I': ['M50 12 L50 88', 'M30 12 L70 12', 'M30 88 L70 88'],
    'J': ['M72 12 L72 67 C72 95 25 98 25 68'],
    'K': ['M26 12 L26 88', 'M76 12 L26 53', 'M43 39 L78 88'],
    'L': ['M27 12 L27 88 L77 88'],
    'M': ['M18 90 L18 15', 'M18 15 L50 55', 'M50 55 L82 15', 'M82 15 L82 90'],
    'N': ['M25 88 L25 12', 'M25 12 L75 88', 'M75 88 L75 12'],
    'O': ['M50 12 C12 12 12 88 50 88 C88 88 88 12 50 12'],
    'P': ['M25 12 L25 88', 'M25 12 L48 12 C86 12 86 52 48 52 L25 52'],
    'Q': ['M50 12 C12 12 12 86 50 86 C88 86 88 12 50 12', 'M56 68 L82 92'],
    'R': [
      'M25 12 L25 88',
      'M25 12 L48 12 C86 12 86 50 48 50 L25 50',
      'M48 50 L79 88'
    ],
    'S': ['M77 22 C52 0 18 12 25 36 C30 52 70 48 76 66 C88 96 43 102 22 80'],
    'T': ['M18 12 L82 12', 'M50 12 L50 88'],
    'U': ['M24 12 L24 64 C24 100 76 100 76 64 L76 12'],
    'V': ['M20 12 L50 88', 'M50 88 L80 12'],
    'W': ['M12 12 L30 88 L50 38 L70 88 L88 12'],
    'X': ['M22 12 L78 88', 'M78 12 L22 88'],
    'Y': ['M22 12 L50 50', 'M78 12 L50 50 L50 88'],
    'Z': ['M23 12 L77 12 L23 88 L77 88'],
    '0': ['M50 12 C15 12 15 88 50 88 C85 88 85 12 50 12'],
    '1': ['M33 30 L50 12 L50 88'],
    '2': ['M24 30 C27 5 77 6 77 32 C77 49 51 64 24 88 L79 88'],
    '3': [
      'M26 18 C61 1 87 21 66 44 L49 50 C85 45 91 87 54 89 C39 91 29 86 24 80'
    ],
    '4': ['M65 12 L23 63 L81 63', 'M65 12 L65 89'],
    '5': ['M76 12 L29 12 L26 48 C70 33 91 73 64 87 C47 95 29 87 24 79'],
    '6': ['M74 15 C38 3 15 58 26 78 C42 107 86 84 72 57 C58 35 30 48 26 66'],
    '7': ['M23 12 L78 12 L38 89'],
    '8': [
      'M50 12 C16 12 20 43 50 50 C88 59 82 88 50 88 C18 88 12 59 50 50 C80 43 84 12 50 12'
    ],
    '9': ['M73 43 C78 3 28 4 25 32 C22 59 68 69 73 43 C77 68 61 90 32 88'],
    '∿': ['M10 50 C23 10 37 10 50 50 C63 90 77 90 90 50'],
    // Capital umlauts: letter body 20..90, dots above at y 6..9.
    'Ä': ['M22 90 L50 20', 'M50 20 L78 90', 'M35 63 L65 63', 'M38 6 L38 9', 'M62 6 L62 9'],
    'Ö': ['M50 20 C16 20 16 90 50 90 C84 90 84 20 50 20', 'M38 6 L38 9', 'M62 6 L62 9'],
    'Ü': ['M26 20 L26 66 C26 98 74 98 74 66 L74 20', 'M38 6 L38 9', 'M62 6 L62 9'],
    // Lowercase school print. Lines: top 10, x-height 38, base 70,
    // descender 94. Bowls run counter-clockwise as taught in class 1.
    'a': [_aBowl, 'M66 38 L66 70'],
    'b': ['M34 10 L34 70', _rightBowl],
    'c': ['M65 44 C62 40 56.5 38 50 38 C41.2 38 34 45.2 34 54 C34 62.8 41.2 70 50 70 C56.5 70 62 68 65 64'],
    'd': [_aBowl, 'M66 10 L66 70'],
    'e': ['M34 54 L66 54 C66 45.2 58.8 38 50 38 C41.2 38 34 45.2 34 54 C34 62.8 41.2 70 50 70 C56.5 70 62 68 65 64'],
    'f': ['M63 14 C60 11 56 10 52 10 C46 10 43 14 43 20 L43 70', 'M33 38 L58 38'],
    'g': [_aBowl, 'M66 38 L66 82 C66 90 59 94 50 94 C44 94 39.5 92 36.5 88'],
    'h': ['M34 10 L34 70', 'M34 50 C37 42.5 43 38 50 38 C59 38 66 43 66 52 L66 70'],
    'i': ['M50 38 L50 70', 'M50 24 L50 27'],
    'j': ['M57 38 L57 84 C57 90.5 52 94 46 94 C41.5 94 38 92 36 89', 'M57 24 L57 27'],
    'k': ['M34 10 L34 70', 'M63 38 L34 57', 'M45 50 L66 70'],
    'l': ['M50 10 L50 70'],
    'm': [
      'M24 38 L24 70',
      'M24 48 C26.5 41.5 31 38 37 38 C44 38 49 42 49 49 L49 70',
      'M49 48 C51.5 41.5 56 38 62 38 C69 38 74 42 74 49 L74 70'
    ],
    'n': ['M34 38 L34 70', 'M34 49 C37 42 43 38 50 38 C59 38 66 43 66 52 L66 70'],
    'o': [_oCircle],
    'p': ['M34 38 L34 94', _rightBowl],
    'q': [_aBowl, 'M66 38 L66 94'],
    'r': ['M38 38 L38 70', 'M38 50 C41 42.5 47 38 54 38 C58 38 61 39 64 41'],
    's': ['M64 43 C60.5 39.5 55.5 38 50 38 C42.5 38 37 41.5 37 46.5 C37 52 44 53.5 50 54.5 C57 55.5 64 57.5 64 62.5 C64 67.5 58 70 50 70 C44 70 39 68 35.5 65'],
    't': ['M45 18 L45 62 C45 67.5 48.5 70 53.5 70 C57.5 70 60.5 68.5 63 66', 'M34 38 L60 38'],
    'u': ['M34 38 L34 57 C34 65 40 70 48 70 C56 70 62.5 66 66 59', 'M66 38 L66 70'],
    'v': ['M34 38 L50 70 L66 38'],
    'w': ['M22 38 L35 70 L50 45 L65 70 L78 38'],
    'x': ['M36 38 L64 70', 'M64 38 L36 70'],
    'y': ['M34 38 L50 67', 'M66 38 L41 94'],
    'z': ['M36 38 L64 38 L36 70 L64 70'],
    'ä': [_aBowl, 'M66 38 L66 70', 'M42 25 L42 28', 'M58 25 L58 28'],
    'ö': [_oCircle, 'M42 25 L42 28', 'M58 25 L58 28'],
    'ü': ['M34 38 L34 57 C34 65 40 70 48 70 C56 70 62.5 66 66 59', 'M66 38 L66 70', 'M42 25 L42 28', 'M58 25 L58 28'],
    'ß': ['M34 70 L34 24 C34 15.5 40.5 10 48.5 10 C56.5 10 62.5 15 62.5 22 C62.5 29 56.5 33.5 49.5 34.5 C59.5 35.5 66.5 42 66.5 52 C66.5 63 58.5 70 49.5 70 C45.5 70 42.5 69 39.5 67'],
  };

  static const _aBowl =
      'M66 46 C63 40.5 57 38 50 38 C41.2 38 34 45.2 34 54 C34 62.8 41.2 70 50 70 C57 70 63 67 66 62';
  static const _rightBowl =
      'M34 50 C37 42.5 43 38 50 38 C58.8 38 66 45.2 66 54 C66 62.8 58.8 70 50 70 C43 70 37 66.5 34 62';
  static const _oCircle =
      'M50 38 C41.2 38 34 45.2 34 54 C34 62.8 41.2 70 50 70 C58.8 70 66 62.8 66 54 C66 45.2 58.8 38 50 38';
}

/// Line system drawn under a writing template.
enum WritingLineature {
  /// Cap line, middle and base line for capitals and digits.
  capitals,

  /// Four school lines for lowercase letters: top, x-height, base, descender.
  fourLines,
}
