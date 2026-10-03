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
  };
}
