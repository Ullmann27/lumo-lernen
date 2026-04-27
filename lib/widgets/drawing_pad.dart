import 'package:flutter/material.dart';

class DrawingPad extends StatefulWidget {
  const DrawingPad({
    super.key,
    this.height = 260,
    this.hint = 'Schreibe oder zeichne hier mit dem Finger.',
  });

  final double height;
  final String hint;

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  final List<Offset?> points = <Offset?>[];

  void _add(Offset point) {
    setState(() => points.add(point));
  }

  void _endStroke() {
    setState(() => points.add(null));
  }

  void _clear() {
    setState(points.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xfffffdfa),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xffff9b4a), width: 2.4),
            boxShadow: <BoxShadow>[
              BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 22, offset: const Offset(0, 12)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (PointerDownEvent event) => _add(event.localPosition),
            onPointerMove: (PointerMoveEvent event) => _add(event.localPosition),
            onPointerUp: (_) => _endStroke(),
            onPointerCancel: (_) => _endStroke(),
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: CustomPaint(painter: NotebookLinesPainter())),
                Positioned.fill(child: CustomPaint(painter: DrawingPadPainter(points))),
                if (points.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        widget.hint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xff8b6a55)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Neu zeichnen'),
          ),
        ),
      ],
    );
  }
}

class DrawingPadPainter extends CustomPainter {
  DrawingPadPainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPadPainter oldDelegate) => oldDelegate.points != points;
}

class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xffb8d8ff).withOpacity(.55)
      ..strokeWidth = 1.2;
    final marginPaint = Paint()
      ..color = const Color(0xffffb2a1).withOpacity(.45)
      ..strokeWidth = 1.2;

    for (double y = 42; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    canvas.drawLine(const Offset(44, 0), Offset(44, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant NotebookLinesPainter oldDelegate) => false;
}
