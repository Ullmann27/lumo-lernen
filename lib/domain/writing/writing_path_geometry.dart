import 'dart:math' as math;

/// Geometry shared by the displayed trace and its evaluation (M/L/C/Q paths).
class WritingPathGeometry {
  static List<math.Point<double>> sample(String data) {
    final tokens = RegExp(r'[MLCQ]|-?\d+(?:\.\d+)?')
        .allMatches(data)
        .map((m) => m.group(0)!)
        .toList();
    final result = <math.Point<double>>[];
    var index = 0;
    var current = const math.Point<double>(0, 0);
    double read() => double.parse(tokens[index++]);
    try {
      while (index < tokens.length) {
        final command = tokens[index++];
        if (command == 'M') {
          current = math.Point(read(), read());
          result.add(current);
        } else if (command == 'L') {
          final end = math.Point(read(), read());
          final start = current;
          final steps = (start.distanceTo(end) / 2).ceil().clamp(1, 1000);
          for (var step = 1; step <= steps; step++) {
            final t = step / steps;
            result.add(math.Point(start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t));
          }
          current = end;
        } else if (command == 'C' || command == 'Q') {
          final start = current;
          final first = math.Point(read(), read());
          final second = math.Point(read(), read());
          final end = command == 'C' ? math.Point(read(), read()) : second;
          for (var step = 1; step <= 48; step++) {
            final t = step / 48;
            final u = 1 - t;
            result.add(command == 'C'
                ? math.Point(
                    u * u * u * start.x +
                        3 * u * u * t * first.x +
                        3 * u * t * t * second.x +
                        t * t * t * end.x,
                    u * u * u * start.y +
                        3 * u * u * t * first.y +
                        3 * u * t * t * second.y +
                        t * t * t * end.y)
                : math.Point(
                    u * u * start.x + 2 * u * t * first.x + t * t * end.x,
                    u * u * start.y + 2 * u * t * first.y + t * t * end.y));
          }
          current = end;
        } else {
          return const [];
        }
      }
    } catch (_) {
      return const [];
    }
    return result;
  }

  static String transformX(String path,
      {required double scale, required double offset}) {
    var coordinate = 0;
    return path.replaceAllMapped(RegExp(r'-?\d+(?:\.\d+)?'), (match) {
      final value = double.parse(match.group(0)!);
      final transformed =
          coordinate++ % 2 == 0 ? value * scale + offset : value;
      return transformed.toStringAsFixed(3);
    });
  }

  static List<math.Point<double>> resample(List<math.Point<double>> points,
      {int count = 64}) {
    if (points.isEmpty) return const [];
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + points[i - 1].distanceTo(points[i]));
    }
    final length = cumulative.last;
    if (length == 0) return List.filled(count, points.first);
    var segment = 1;
    return List.generate(count, (i) {
      final distance = length * i / (count - 1);
      while (segment < points.length - 1 && cumulative[segment] < distance) {
        segment++;
      }
      final start = points[segment - 1];
      final end = points[segment];
      final span = cumulative[segment] - cumulative[segment - 1];
      final t = span == 0 ? 0.0 : (distance - cumulative[segment - 1]) / span;
      return math.Point(
          start.x + (end.x - start.x) * t, start.y + (end.y - start.y) * t);
    });
  }
}
