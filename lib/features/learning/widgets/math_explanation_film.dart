import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../widgets/design/lumo_task_object_art.dart';

String _placeName(int exponent) => switch (exponent) {
      -3 => 'Tausendstel',
      -2 => 'Hundertstel',
      -1 => 'Zehntel',
      0 => 'Einer',
      1 => 'Zehner',
      2 => 'Hunderter',
      3 => 'Tausender',
      4 => 'Zehntausender',
      5 => 'Hunderttausender',
      _ => 'Millionen'
    };

typedef MathFilmEquation = ({int a, String sign, int b});
typedef MathFilmShot = ({
  MathFilmEquation equation,
  double from,
  double to,
  String caption
});

class MathFilmPlan {
  const MathFilmPlan(this.title, this.shots, this.question, this.object,
      {this.decimals = 0,
      this.denominator = 0,
      this.expression,
      this.comparisonNames});

  final String title;
  final String? question, object, expression;
  final int decimals, denominator;
  final List<MathFilmShot> shots;
  final List<String>? comparisonNames;

  static MathFilmPlan? forTask(TaskInstance task) {
    if (task.subject != LearningSubject.mathematik) return null;
    final data = task.visualPayload.data;
    if (data['operation'] == 'story_comparison') {
      final a = data['left'], b = data['right'], names = data['names'];
      if (a is! int ||
          b is! int ||
          a < b ||
          b < 0 ||
          a > 30 ||
          names is! List ||
          names.length != 2 ||
          names.any((n) => n is! String)) {
        return null;
      }
      final e = (a: a, sign: '−', b: b);
      return MathFilmPlan(
          'Zwei Mengen vergleichen',
          [
            (
              equation: e,
              from: 0,
              to: 0,
              caption:
                  '${names[0]} hat $a, ${names[1]} hat $b. Lege beide Reihen untereinander.'
            ),
            (
              equation: e,
              from: 0,
              to: .72,
              caption:
                  'Verbinde immer zwei Plättchen. Wie viele Paare kannst du bilden?'
            ),
            (
              equation: e,
              from: .72,
              to: 1,
              caption:
                  'Welche Plättchen haben keinen Partner? Sie zeigen, wie viel mehr ${names[0]} hat.'
            )
          ],
          RegExp(r'[^.!?]+\?$')
              .firstMatch(task.prompt.trim())
              ?.group(0)
              ?.trim(),
          null,
          comparisonNames: names.cast<String>());
    }
    if (data['operation'] == 'fraction_addition') {
      final a = data['numerator'], b = data['extra'], d = data['denominator'];
      if (a is! int ||
          b is! int ||
          d is! int ||
          d < 1 ||
          d > 32 ||
          a < 0 ||
          b < 0 ||
          a + b > d) {
        return null;
      }
      final e = (a: a, sign: '+', b: b);
      return MathFilmPlan(
          'Gleich große Bruchteile',
          [
            (
              equation: e,
              from: 0,
              to: 0,
              caption:
                  'Das Ganze ist in $d gleich große Teile geteilt. Davon sind $a markiert.'
            ),
            (
              equation: e,
              from: 0,
              to: 1,
              caption:
                  'Schiebe $b weitere Teile dazu. Jeder Teil bleibt gleich groß.'
            ),
            (
              equation: e,
              from: 1,
              to: 1,
              caption:
                  'Zähle alle markierten Teile. Welcher Zähler gehört über den Nenner $d?'
            )
          ],
          null,
          null,
          denominator: d,
          expression: '$a/$d + $b/$d = ?');
    }
    if (const {'decimal_addition', 'decimal_subtraction'}
        .contains(data['operation'])) {
      final a = data['leftMinorUnits'],
          b = data['rightMinorUnits'],
          places = data['decimalPlaces'];
      if (a is! int ||
          b is! int ||
          places is! int ||
          a < 0 ||
          b < 0 ||
          places < 1 ||
          places > 3) {
        return null;
      }
      final sign = data['operation'] == 'decimal_addition' ? '+' : '−';
      final e = (a: a, sign: sign, b: b);
      final columns = math.max(places + 1, math.max('$a'.length, '$b'.length));
      final shots = <MathFilmShot>[
        (
          equation: e,
          from: 0,
          to: 0,
          caption:
              'Schreibe Komma unter Komma. Gleichwertige Stellen stehen jetzt untereinander.'
        )
      ];
      for (var pos = 0; pos < columns; pos++) {
        final name = _placeName(pos - places);
        final phase = (pos + .20) / columns;
        shots.add((
          equation: e,
          from: pos / columns,
          to: phase,
          caption:
              'Rechne die $name. ${pos == 0 ? "Beginne ganz rechts." : "Prüfe, ob du einen Übertrag aus der vorherigen Stelle brauchst."}'
        ));
      }
      return MathFilmPlan('Rechnen mit Kommazahlen', shots, null, null,
          decimals: places,
          expression: "${data['leftText']} $sign ${data['rightText']} = ?");
    }
    final equations = <MathFilmEquation>[];
    final steps = data['storyEquations'];
    if (steps is List) {
      for (final s in steps) {
        if (s is! List ||
            s.length != 4 ||
            s[0] is! int ||
            s[1] is! String ||
            s[2] is! int) {
          return null;
        }
        equations.add((a: s[0] as int, sign: s[1] as String, b: s[2] as int));
      }
    } else {
      final a = data['storyStart'] ?? data['left'];
      final b = data['storyChange'] ?? data['right'];
      final sign = data['storyStart'] != null
          ? (data['storySubtract'] == true ? '−' : '+')
          : switch (data['operation']) {
              'addition' => '+',
              'subtraction' => '−',
              'multiplication' => '·',
              'division' => ':',
              _ => null
            };
      if (a is! int ||
          b is! int ||
          a < 0 ||
          b < 0 ||
          sign == null ||
          (sign == '−' && b > a) ||
          (sign == ':' && b == 0)) {
        return null;
      }
      equations.add((a: a, sign: sign, b: b));
    }
    if (equations.isEmpty) return null;
    final shots = <MathFilmShot>[];
    for (final e in equations) {
      final a = e.a, b = e.b;
      final action = switch (e.sign) {
        '+' => 'Zu $a kommen $b dazu.',
        '−' => 'Von $a gehen $b weg.',
        '·' => 'Lege $a gleich große Gruppen mit je $b.',
        _ => 'Verteile $a gerecht auf $b Gruppen.',
      };
      if (equations.length > 1) {
        shots.add((
          equation: e,
          from: 0,
          to: 1,
          caption:
              '$action ${e == equations.last ? "Welche Zahl beantwortet die Frage der Geschichte?" : "Notiere dieses Zwischenergebnis."}'
        ));
      } else if (e.sign == '+' || e.sign == '−') {
        final nextTen = e.sign == '+' ? 10 - a % 10 : a % 10;
        final small = (e.sign == '+' ? a + b : a) <= 30;
        if (small && a <= 20 && nextTen > 0 && nextTen < b) {
          final anchor = e.sign == '+' ? a + nextTen : a - nextTen;
          final f = nextTen / b;
          shots.add((
            equation: e,
            from: 0,
            to: 0,
            caption: 'Beginne bei $a. Suche den nächsten vollen Zehner.'
          ));
          shots.add((
            equation: e,
            from: 0,
            to: f,
            caption: 'Mit $nextTen Plättchen erreichst du $anchor.'
          ));
          shots.add((
            equation: e,
            from: f,
            to: 1,
            caption:
                'Jetzt fehlen noch ${b - nextTen} Schritte. Wo kommst du an?'
          ));
        } else if (small) {
          shots.add((
            equation: e,
            from: 0,
            to: 0,
            caption: 'Lege zuerst $a Plättchen in die Felder.'
          ));
          shots.add((equation: e, from: 0, to: 1, caption: action));
          shots.add((
            equation: e,
            from: 1,
            to: 1,
            caption:
                'Zähle die besetzten Felder. Ein voller Rahmen enthält zehn.'
          ));
        } else {
          final columns = math.max('$a'.length, '$b'.length);
          const names = [
            'Einer',
            'Zehner',
            'Hunderter',
            'Tausender',
            'Zehntausender',
            'Hunderttausender',
            'Millionen'
          ];
          var carry = 0;
          for (var pos = 0; pos < columns; pos++) {
            final place = math.pow(10, pos).toInt();
            final top = a ~/ place % 10, bottom = b ~/ place % 10;
            final plus = e.sign == '+';
            final carried = carry != 0 ? (plus ? ' + 1' : ' − 1') : '';
            final next =
                plus ? top + bottom + carry >= 10 : top - bottom - carry < 0;
            final note = next
                ? (plus
                    ? 'Bündele zehn zu einer Einheit für die nächste Stelle.'
                    : 'Tausche eine Einheit der nächsten Stelle in zehn kleinere.')
                : 'Welche Ziffer gehört hierhin?';
            final phase = (pos + .2) / columns;
            shots.add((
              equation: e,
              from: pos / columns,
              to: phase,
              caption:
                  '${names[math.min(pos, names.length - 1)]}: $top ${e.sign} $bottom$carried. $note'
            ));
            carry = next ? 1 : 0;
          }
        }
      } else if ((e.sign == '·' && a > 12) ||
          (e.sign == ':' && b > 0 && a ~/ b > 12)) {
        final value = e.sign == '·' ? a : a ~/ b;
        var place = 1;
        final portions = <int>[];
        for (var digits = value; digits > 0; digits ~/= 10) {
          if (digits % 10 != 0) portions.insert(0, (digits % 10) * place);
          place *= 10;
        }
        final parts = [for (final q in portions) e.sign == '·' ? q : q * b];
        final rest = e.sign == ':' ? a % b : 0;
        final split = [...parts, if (rest != 0) rest].join(' + ');
        for (var i = 0; i < parts.length; i++) {
          shots.add((
            equation: (a: parts[i], sign: e.sign, b: b),
            from: 0,
            to: 1,
            caption:
                '${i == 0 ? "Zerlege $a in $split. " : ""}Rechne ${parts[i]} ${e.sign} $b. ${i == parts.length - 1 && rest == 0 ? "Setze deine Teilergebnisse zusammen." : "Notiere das Teilergebnis."}'
          ));
        }
      } else {
        shots.add((
          equation: e,
          from: 0,
          to: 0,
          caption: e.sign == '·'
              ? 'Eine Gruppe enthält $b.'
              : 'Teile den Vorrat von $a in gleiche Gruppen.'
        ));
        shots.add((equation: e, from: 0, to: 1, caption: action));
        shots.add((
          equation: e,
          from: 1,
          to: 1,
          caption: e.sign == '·'
              ? 'Wie viele Stück liegen in allen Gruppen zusammen?'
              : 'Wie viele Stück liegen in einer Gruppe?'
        ));
      }
      if (e.sign == ':' && a % b > 0) {
        final rest = a % b;
        shots.add((
          equation: (a: rest, sign: ':', b: b),
          from: 0,
          to: 1,
          caption:
              'Bleiben $rest übrig, reicht das für eine weitere Runde auf $b Gruppen? Notiere den Rest hinter dem Ergebnis.'
        ));
      }
    }
    final isStory = steps is List || data['storyStart'] != null;
    final question = isStory
        ? RegExp(r'[^.!?]+\?$').firstMatch(task.prompt.trim())?.group(0)?.trim()
        : null;
    final context = task.prompt.toLowerCase();
    String? object;
    if (isStory) {
      for (final entry in const {
        'apfel': 'apfel',
        'äpfel': 'apfel',
        'bücher': 'buch',
        'buch ': 'buch',
        'stern': 'stern',
        'bus ': 'bus',
        'baum': 'baum',
        'bälle': 'ball'
      }.entries) {
        if (context.contains(entry.key)) {
          object = entry.value;
          break;
        }
      }
    }
    return MathFilmPlan(
        steps is List
            ? 'Die Geschichte in Rechenschritten'
            : 'So kannst du rechnen',
        shots,
        question,
        object);
  }
}

class MathExplanationFilm extends StatefulWidget {
  const MathExplanationFilm(
      {super.key,
      required this.plan,
      required this.enabled,
      required this.quiet,
      required this.slow,
      this.onExplore});
  final MathFilmPlan plan;
  final VoidCallback? onExplore;
  final bool enabled, quiet, slow;

  @override
  State<MathExplanationFilm> createState() => _MathExplanationFilmState();
}

class _MathExplanationFilmState extends State<MathExplanationFilm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time;
  bool _open = false;
  bool _manualFrame = false;

  bool get _quiet => widget.quiet || MediaQuery.disableAnimationsOf(context);
  int get _count => widget.plan.shots.length;
  int get _index => math.min(_count - 1, (_time.value * _count).floor());

  @override
  void initState() {
    super.initState();
    _time = AnimationController(vsync: this, duration: _duration);
  }

  Duration get _duration =>
      Duration(milliseconds: (widget.slow ? 6100 : 4100) * _count);

  @override
  void didUpdateWidget(covariant MathExplanationFilm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _time.duration = _duration;
    if (!widget.enabled || widget.quiet) _time.stop();
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  void _play() {
    setState(() {
      if (_time.isAnimating) {
        _time.stop();
      } else {
        _manualFrame = false;
        if (_time.isCompleted) _time.value = 0;
        _time.forward();
      }
    });
  }

  void _seek(int index) {
    _time.stop();
    _manualFrame = true;
    _time.value = index.clamp(0, _count - 1) / _count;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xff83e5d5);
    const ink = Color(0xffeff5fa);
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xff162e47),
            border: Border.all(color: const Color(0xff426977)),
            borderRadius: BorderRadius.circular(16)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextButton.icon(
            key: const ValueKey('math-film-open'),
            icon: Icon(_open ? Icons.expand_less : Icons.movie_outlined),
            label: Text(_open ? widget.plan.title : 'Rechenfilm ansehen'),
            style: TextButton.styleFrom(
                foregroundColor: mint,
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            onPressed: widget.enabled
                ? () {
                    _time.stop();
                    setState(() => _open = !_open);
                    if (_open) widget.onExplore?.call();
                  }
                : null,
          ),
          if (_open)
            AnimatedBuilder(
                animation: _time,
                builder: (context, _) {
                  final index = _index, shot = widget.plan.shots[index];
                  final within = (_time.value * _count - index).clamp(0.0, 1.0);
                  final phase = _quiet || _manualFrame
                      ? 1.0
                      : Curves.easeInOut
                          .transform((within * 1.40).clamp(0.0, 1.0));
                  final p = lerpDouble(shot.from, shot.to, phase)!;
                  final equation = shot.equation;
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.plan.question case final question?)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(children: [
                                    if (widget.plan.object case final object?)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: LumoTaskObjectArt(
                                              name: object, size: 38)),
                                    Expanded(
                                        child: Text(question,
                                            style: const TextStyle(
                                                color: ink,
                                                fontWeight: FontWeight.w700))),
                                  ])),
                            DecoratedBox(
                                decoration: BoxDecoration(
                                    color: const Color(0xffedf3ea),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                              widget.plan.expression ??
                                                  '${equation.a} ${equation.sign} ${equation.b} = ?',
                                              style: const TextStyle(
                                                  color: Color(0xff233849),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 21)),
                                          SizedBox(
                                              height: 88,
                                              child: CustomPaint(
                                                  painter: _FilmDiagram(
                                                      equation,
                                                      p,
                                                      widget.plan.decimals,
                                                      widget.plan.denominator,
                                                      widget.plan
                                                          .comparisonNames))),
                                        ]))),
                            const SizedBox(height: 8),
                            Semantics(
                                liveRegion: true,
                                child: Text(
                                    'Schritt ${index + 1} von $_count · ${shot.caption}',
                                    key: const ValueKey('math-film-caption'),
                                    style: const TextStyle(color: ink))),
                            Row(children: [
                              IconButton(
                                  key: const ValueKey('math-film-back'),
                                  tooltip: 'Voriger Schritt',
                                  color: mint,
                                  onPressed: widget.enabled && index > 0
                                      ? () => _seek(index - 1)
                                      : null,
                                  icon:
                                      const Icon(Icons.skip_previous_rounded)),
                              if (!_quiet)
                                Expanded(
                                    child: TextButton.icon(
                                        key: const ValueKey('math-film-play'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: ink),
                                        onPressed:
                                            widget.enabled ? _play : null,
                                        icon: Icon(_time.isAnimating
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded),
                                        label: Text(_time.isAnimating
                                            ? 'Pause'
                                            : _time.isCompleted
                                                ? 'Wiederholen'
                                                : 'Abspielen')))
                              else
                                const Spacer(),
                              IconButton(
                                  key: const ValueKey('math-film-next'),
                                  tooltip: 'Nächster Schritt',
                                  color: mint,
                                  onPressed:
                                      widget.enabled && index < _count - 1
                                          ? () => _seek(index + 1)
                                          : null,
                                  icon: const Icon(Icons.skip_next_rounded)),
                            ]),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                    value: _quiet
                                        ? (index + 1) / _count
                                        : _time.value,
                                    minHeight: 3,
                                    color: mint,
                                    backgroundColor: const Color(0xff385368))),
                          ]));
                }),
        ]),
      ),
    );
  }
}

class _FilmDiagram extends CustomPainter {
  const _FilmDiagram(
      this.e, this.p, this.decimals, this.denominator, this.comparisonNames);
  final int decimals, denominator;
  final MathFilmEquation e;
  final List<String>? comparisonNames;
  final double p;
  static const navy = Color(0xff234354),
      teal = Color(0xff16867b),
      coral = Color(0xffd06a43),
      pale = Color(0xffc7d7d0);
  void _text(Canvas c, String text, Offset center, double size,
      [Color color = navy]) {
    final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: size,
                color: color)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    final paints = Paint()..isAntiAlias = true;
    final a = e.a, b = e.b, plus = e.sign == '+', take = e.sign == '−';
    if (comparisonNames case final names?) {
      final pitch = math.min(24.0, (size.width - 74) / math.max(a, 1));
      final paired = (p / .72).clamp(0.0, 1.0) * b;
      final extras = ((p - .72) / .28).clamp(0.0, 1.0) * (a - b);
      for (var row = 0; row < 2; row++) {
        _text(c, names[row], Offset(30, row == 0 ? 25 : 64), 13);
      }
      for (var i = 0; i < a; i++) {
        final x = 65 + pitch * (i + .5);
        if (i < b) {
          final extent = (paired - i).clamp(0.0, 1.0);
          c.drawLine(
              Offset(x, 25),
              Offset(x, 25 + 39 * extent),
              Paint()
                ..color = teal
                ..strokeWidth = 2);
          c.drawCircle(Offset(x, 64), pitch * .32, paints..color = teal);
        }
        c.drawCircle(Offset(x, 25), pitch * .32,
            paints..color = i < b || i - b >= extras ? teal : coral);
      }
      return;
    }
    if (denominator > 0) {
      final width = (size.width - 16) / denominator;
      final top = Offset(8, 17), bottom = Offset(8, 55);
      for (var i = 0; i < denominator; i++) {
        final x = top.dx + i * width;
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, top.dy, width - 2, 24),
                const Radius.circular(3)),
            paints..color = i < a ? teal : pale);
      }
      for (var i = 0; i < b; i++) {
        final progress = (p * b - i).clamp(0.0, 1.0);
        final dest = top + Offset((a + i) * width, 0);
        final here =
            Offset.lerp(bottom + Offset(i * width, 0), dest, progress)!;
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(here.dx, here.dy, width - 2, 24),
                const Radius.circular(3)),
            paints..color = coral);
      }
    } else if (decimals == 0 && (plus || take) && (plus ? a + b : a) <= 30) {
      final total = plus ? a + b : a;
      final frames = math.max(1, (total / 10).ceil());
      final cell =
          math.min(21.0, (size.width - 12) / (frames * 5 + frames - 1));
      final pitch = 6 * cell;
      final start =
          Offset((size.width - (frames * 5 + frames - 1) * cell) / 2, 8);
      Offset at(int i) =>
          start +
          Offset((i ~/ 10) * pitch + (i % 5 + .5) * cell,
              (i % 10 ~/ 5 + .5) * cell);
      for (var f = 0; f < frames; f++) {
        final rect =
            Rect.fromLTWH(start.dx + f * pitch, start.dy, cell * 5, cell * 2);
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            paints..color = pale);
        for (var k = 0; k < 10; k++) {
          c.drawCircle(at(f * 10 + k), cell * .33,
              paints..color = const Color(0xffecf3ed));
        }
      }
      final anchor = plus ? a : a - b;
      for (var i = 0; i < anchor; i++) {
        c.drawCircle(at(i), cell * .34, paints..color = teal);
      }
      for (var i = 0; i < b; i++) {
        final spread = math.min(15.0, (size.width - 12) / math.max(b, 1));
        final supply = Offset(
            size.width / 2 + (i - (b - 1) / 2) * spread, size.height - 14);
        final f = (p * b - i).clamp(0.0, 1.0);
        final pos = Offset.lerp(
            plus ? supply : at(a - 1 - i), plus ? at(a + i) : supply, f)!;
        c.drawCircle(pos - Offset(0, sinArc(f) * 8),
            math.min(cell * .34, spread * .46), paints..color = coral);
      }
    } else if (plus || take) {
      final left = '$a'.padLeft(decimals + 1, '0'),
          right = '$b'.padLeft(decimals + 1, '0');
      final n = math.max(left.length, right.length);
      final cell = math.min(40.0, (size.width - 30) / n);
      final start = (size.width - n * cell) / 2;
      final focus = math.min(n - 1, (p * n).floor());
      for (var i = 0; i < n; i++) {
        final x = start + (i + .5) * cell, pos = n - i - 1;
        final active = pos == focus;
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(x, 42), width: cell - 3, height: 78),
                const Radius.circular(5)),
            paints..color = active ? const Color(0xffa5dcca) : pale);
        _text(
            c,
            switch (pos - decimals) {
              -3 => 't',
              -2 => 'h',
              -1 => 'z',
              0 => 'E',
              1 => 'Z',
              2 => 'H',
              3 => 'T',
              4 => 'ZT',
              5 => 'HT',
              _ => 'M'
            },
            Offset(x, 14),
            11);
        if (decimals > 0 && pos == decimals) {
          _text(c, ',', Offset(x + cell * .42, 42), 18);
          _text(c, ',', Offset(x + cell * .42, 67), 18, coral);
        }
        _text(c, pos < left.length ? left[left.length - 1 - pos] : '',
            Offset(x, 37), 20);
        _text(c, pos < right.length ? right[right.length - 1 - pos] : '',
            Offset(x, 62), 20, coral);
      }
    } else {
      final groups = e.sign == '·' ? a : b;
      final each = e.sign == '·' ? b : (b == 0 ? 0 : a ~/ b);
      if (e.sign == ':' && a > 0 && a < b) {
        final spacing = math.min(20.0, (size.width - 24) / a);
        for (var i = 0; i < a; i++) {
          final x = size.width / 2 + (i - (a - 1) / 2) * spacing;
          c.drawCircle(Offset(x, 28 + (1 - p) * 18), spacing * .34,
              paints..color = coral);
        }
        _text(c, '$a übrig für $b Gruppen', Offset(size.width / 2, 67), 16);
        return;
      }
      if (groups == 0) {
        _text(c, '0 Gruppen', Offset(size.width / 2, 43), 20);
        return;
      }
      // For large counts show the first groups, an ellipsis and the final group.
      final cards = math.min(groups, 6);
      final width = math.min(50.0, (size.width - 8) / cards);
      final start = (size.width - width * cards) / 2;
      for (var i = 0; i < cards; i++) {
        final x = start + (i + .5) * width;
        if (groups > 6 && i == cards - 2) {
          _text(c, '…', Offset(x, 42), 21);
          continue;
        }
        final active = p * cards >= i + .35;
        final rect = Rect.fromCenter(
            center: Offset(x, 42), width: width - 4, height: 55);
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            paints..color = active ? const Color(0xffa5dcca) : pale);
        if (active) {
          if (each <= 9) {
            for (var k = 0; k < each; k++) {
              c.drawCircle(
                  Offset(x + (k % 3 - 1) * width * .19, 29 + (k ~/ 3) * 11),
                  3.5,
                  paints..color = teal);
            }
          } else if (e.sign == '·') {
            _text(c, '$each', Offset(x, 42), 18);
          } else {
            _text(c, '?', Offset(x, 42), 18);
          }
        }
        _text(c, '${i == cards - 1 ? groups : i + 1}', Offset(x, 80), 10);
      }
    }
  }

  double sinArc(double t) => math.sin(math.pi * t);
  @override
  bool shouldRepaint(_FilmDiagram old) =>
      old.e != e ||
      old.p != p ||
      old.decimals != decimals ||
      old.denominator != denominator ||
      old.comparisonNames != comparisonNames;
}
