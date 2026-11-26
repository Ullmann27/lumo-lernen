import 'package:flutter/material.dart';

import 'demo_class_data.dart';
import 'demo_homework.dart';
import 'holo_charts.dart';
import 'holo_widgets.dart';
import 'homework_runner_screen.dart';
import '../../widgets/design/lumo_subject_style.dart';

/// Lehrkräfte-Demo: Klassenübersicht mit Demo-Kindern, holografische
/// Auswertung und selbst gestaltete Hausaufgaben mit automatischer Prüfung.
/// Alle Daten sind Demo-Daten und bleiben lokal auf diesem Gerät.
class TeacherDemoScreen extends StatefulWidget {
  const TeacherDemoScreen({super.key, this.now, this.store});

  /// Stichtag der Demo-Daten (für reproduzierbare Tests).
  final DateTime? now;
  final DemoHomeworkStore? store;

  @override
  State<TeacherDemoScreen> createState() => _TeacherDemoScreenState();
}

class _TeacherDemoScreenState extends State<TeacherDemoScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  late final DemoHomeworkStore _store = widget.store ?? DemoHomeworkStore();
  late final List<DemoChildReport> _reports = [
    for (final c in demoChildren) DemoChildReport.build(c, now: _now),
  ];
  List<DemoHomework> _homework = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _store.load();
    if (mounted) setState(() => _homework = list);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: HoloPalette.deep,
        appBar: AppBar(
          backgroundColor: HoloPalette.night,
          foregroundColor: HoloPalette.text,
          title: const Text('Demo-Klasse 2a'),
          actions: const [
            Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: DemoDataBadge())),
          ],
          bottom: const TabBar(
            indicatorColor: HoloPalette.cyan,
            labelColor: HoloPalette.cyan,
            unselectedLabelColor: HoloPalette.muted,
            tabs: [
              Tab(icon: Icon(Icons.groups_rounded), text: 'Klasse'),
              Tab(icon: Icon(Icons.assignment_rounded), text: 'Hausaufgaben'),
            ],
          ),
        ),
        body: HoloBackground(
          child: TabBarView(
            children: [
              _ClassOverview(reports: _reports, onOpen: _openChild),
              _HomeworkTab(
                reports: _reports,
                homework: _homework,
                store: _store,
                now: _now,
                onChanged: _reload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChild(DemoChildReport report) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => DemoChildDetailScreen(report: report),
    ));
  }
}

class _ClassOverview extends StatelessWidget {
  const _ClassOverview({required this.reports, required this.onOpen});
  final List<DemoChildReport> reports;
  final void Function(DemoChildReport) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LocalDemoNotice(),
        const SizedBox(height: 12),
        const Text(
          'So sieht die Auswertung nach etwa einem Monat Üben aus. '
          'Die Kinder sind erfunden, die Auswertung nutzt die echte Lernanalyse der App.',
          style: TextStyle(color: HoloPalette.muted),
        ),
        const SizedBox(height: 14),
        for (final r in reports) ...[
          _ChildTile(report: r, onOpen: () => onOpen(r)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.report, required this.onOpen});
  final DemoChildReport report;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final weak = report.weaknesses;
    return HoloPanel(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('demo-child-${report.child.id}'),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                HoloRing(
                  value: report.overallAccuracy,
                  label: 'richtig',
                  size: 72,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(report.child.name,
                              style: const TextStyle(
                                  color: HoloPalette.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        const DemoDataBadge(),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        '${report.attempts.length} Aufgaben · ${report.analysis.totalMinutes} Min. in 4 Wochen',
                        style: const TextStyle(color: HoloPalette.muted),
                      ),
                      if (weak.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Achtung: ${weak.first}',
                              style: const TextStyle(color: HoloPalette.amber)),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: HoloPalette.cyan, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Auswertung eines Demo-Kindes mit allen Diagrammen.
class DemoChildDetailScreen extends StatefulWidget {
  const DemoChildDetailScreen({super.key, required this.report});
  final DemoChildReport report;

  @override
  State<DemoChildDetailScreen> createState() => _DemoChildDetailScreenState();
}

class _DemoChildDetailScreenState extends State<DemoChildDetailScreen> {
  String? _subject;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final radar =
        _subject == null ? r.subjectAccuracy : r.unitAccuracy(_subject!);
    return Scaffold(
      backgroundColor: HoloPalette.deep,
      appBar: AppBar(
        backgroundColor: HoloPalette.night,
        foregroundColor: HoloPalette.text,
        title: Text(r.child.name),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: DemoDataBadge())),
        ],
      ),
      body: HoloBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LocalDemoNotice(),
            const SizedBox(height: 12),
            HoloPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HoloSectionTitle('Kompetenz-Radar',
                      icon: Icons.radar_rounded),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Alle Fächer', null),
                    for (final s in demoSubjects) _chip(s, s),
                  ]),
                  const SizedBox(height: 8),
                  HoloRadarChart(
                    key: ValueKey('radar-${_subject ?? 'all'}'),
                    values: radar,
                    color: _subject == null
                        ? HoloPalette.cyan
                        : HoloPalette.subject(_subject!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HoloPanel(
              accent: HoloPalette.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HoloSectionTitle('Verlauf über 4 Wochen',
                      icon: Icons.show_chart_rounded),
                  HoloTrendChart(series: r.weeklyAccuracy),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HoloPanel(
              accent: HoloPalette.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HoloSectionTitle('Genauigkeit und Bearbeitungszeit',
                      icon: Icons.timer_rounded),
                  HoloAccuracyBars(
                      accuracy: r.subjectAccuracy, seconds: r.subjectSeconds),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HoloPanel(
              accent: HoloPalette.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HoloSectionTitle('Hilfenutzung (Lumo-Hilfe pro Aufgabe)',
                      icon: Icons.lightbulb_rounded),
                  Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      for (final e in r.subjectHintShare.entries)
                        HoloRing(
                            value: e.value,
                            label: e.key,
                            color: HoloPalette.subject(e.key)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eine Hilfe gibt keine Punkte. Häufige Hilfe zeigt, wo das Kind Unterstützung braucht.',
                    style: TextStyle(color: HoloPalette.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _listPanel('Automatisch erkannte Schwächen', Icons.flag_rounded,
                HoloPalette.amber, r.weaknesses,
                empty: 'Keine auffälligen Schwächen.'),
            const SizedBox(height: 14),
            _listPanel('Stärken', Icons.star_rounded, HoloPalette.mint,
                r.strengths,
                empty: 'Noch keine sicheren Kompetenzen.'),
            const SizedBox(height: 14),
            _listPanel('Empfehlungen', Icons.tips_and_updates_rounded,
                HoloPalette.cyan, r.recommendations,
                empty: 'Weiter so üben wie bisher.'),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? subject) {
    final selected = _subject == subject;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: TextStyle(
          color: selected ? HoloPalette.deep : HoloPalette.text,
          fontWeight: FontWeight.w700),
      selectedColor: subject == null ? HoloPalette.cyan : HoloPalette.subject(subject),
      backgroundColor: Colors.white.withValues(alpha: .08),
      side: BorderSide(color: HoloPalette.cyan.withValues(alpha: .5)),
      onSelected: (_) => setState(() => _subject = subject),
    );
  }

  Widget _listPanel(String title, IconData icon, Color accent,
      List<String> items, {required String empty}) {
    return HoloPanel(
      accent: accent,
      shimmer: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoloSectionTitle(title, icon: icon),
          if (items.isEmpty)
            Text(empty, style: const TextStyle(color: HoloPalette.muted)),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: HoloPalette.text, fontSize: 15)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeworkTab extends StatefulWidget {
  const _HomeworkTab({
    required this.reports,
    required this.homework,
    required this.store,
    required this.now,
    required this.onChanged,
  });

  final List<DemoChildReport> reports;
  final List<DemoHomework> homework;
  final DemoHomeworkStore store;
  final DateTime now;
  final Future<void> Function() onChanged;

  @override
  State<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends State<_HomeworkTab> {
  String _subject = homeworkSubjects.first;
  late int _grade = widget.reports.first.child.grade;
  late String _unit =
      widget.reports.first.suggestedHomeworkUnit ?? homeworkMathUnits.first;

  List<String> get _units => homeworkUnitsFor(_subject, _grade);

  /// Fach oder Stufe gewechselt: bekanntes Thema behalten, sonst das erste.
  void _themaPassend() {
    final units = _units;
    if (!units.contains(_unit) && units.isNotEmpty) _unit = units.first;
  }
  int _count = 6;
  int _dueDays = 2;
  final _note = TextEditingController();
  late final Set<String> _kids = {widget.reports.first.child.id};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final hw = DemoHomework(
      id: 'hw-${widget.homework.length + 1}-${DateTime.now().microsecondsSinceEpoch}',
      subject: _subject,
      grade: _grade,
      unit: _unit,
      count: _count,
      due: DateTime(widget.now.year, widget.now.month, widget.now.day)
          .add(Duration(days: _dueDays)),
      note: _note.text.trim(),
      studentIds: _kids.toList()..sort(),
      createdAt: widget.now,
    );
    await widget.store.add(hw);
    _note.clear();
    await widget.onChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hausaufgabe ${hw.subject} „${hw.unit}“ '
            '(${hw.grade}. Schulstufe) zugewiesen (Demo, lokal).')));
  }

  Future<void> _solve(DemoHomework hw, DemoChild child) async {
    await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) =>
          HomeworkRunnerScreen(homework: hw, child: child, store: widget.store),
    ));
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: HoloPalette.muted, fontSize: 13);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LocalDemoNotice(),
        const SizedBox(height: 12),
        HoloPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HoloSectionTitle('Neue Hausaufgabe gestalten',
                  icon: Icons.edit_calendar_rounded),
              const Text('Fach (automatisch geprüft)', style: label),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final subject in homeworkSubjects)
                  ChoiceChip(
                    key: ValueKey('homework-subject-$subject'),
                    avatar: LumoSubjectBadge(subject: subject, size: 26),
                    label: Text(subject),
                    selected: _subject == subject,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    selectedColor: HoloPalette.cyan.withValues(alpha: .35),
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    labelStyle: const TextStyle(
                        color: HoloPalette.text, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() {
                      _subject = subject;
                      _themaPassend();
                    }),
                  ),
              ]),
              const SizedBox(height: 10),
              const Text('Schulstufe', style: label),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final grade in homeworkGrades)
                  ChoiceChip(
                    key: ValueKey('homework-grade-$grade'),
                    label: Text('$grade. Stufe'),
                    selected: _grade == grade,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    selectedColor: HoloPalette.cyan.withValues(alpha: .35),
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    labelStyle: const TextStyle(
                        color: HoloPalette.text, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() {
                      _grade = grade;
                      _themaPassend();
                    }),
                  ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('homework-unit-$_subject-$_grade'),
                initialValue: _units.contains(_unit) ? _unit : null,
                isExpanded: true,
                dropdownColor: HoloPalette.night,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: HoloPalette.text, fontSize: 16),
                decoration: const InputDecoration(
                    labelText: 'Untergruppe', labelStyle: label),
                items: [
                  for (final u in _units)
                    DropdownMenuItem(
                        value: u,
                        child: Text(u, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              const SizedBox(height: 10),
              Text('Anzahl Aufgaben: $_count', style: label),
              Slider(
                value: _count.toDouble(),
                min: 3,
                max: 12,
                divisions: 9,
                activeColor: HoloPalette.cyan,
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.round()),
              ),
              Text('Fällig in $_dueDays Tagen', style: label),
              Slider(
                value: _dueDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                activeColor: HoloPalette.blue,
                label: '$_dueDays',
                onChanged: (v) => setState(() => _dueDays = v.round()),
              ),
              TextField(
                key: const ValueKey('homework-note'),
                controller: _note,
                style: const TextStyle(color: HoloPalette.text),
                decoration: const InputDecoration(
                  labelText: 'Eigener Hinweis für das Kind',
                  hintText: 'z. B. Denk an den Zehnerübergang!',
                  labelStyle: label,
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Zuweisen an:', style: label),
              Wrap(spacing: 8, children: [
                for (final r in widget.reports)
                  FilterChip(
                    key: ValueKey('assign-${r.child.id}'),
                    label: Text(r.child.name),
                    selected: _kids.contains(r.child.id),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    selectedColor: HoloPalette.cyan.withValues(alpha: .35),
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    labelStyle: const TextStyle(color: HoloPalette.text),
                    onSelected: (on) => setState(() =>
                        on ? _kids.add(r.child.id) : _kids.remove(r.child.id)),
                  ),
              ]),
              const SizedBox(height: 12),
              HoloButton(
                key: const ValueKey('homework-create'),
                label: 'Hausaufgabe zuweisen',
                icon: Icons.send_rounded,
                onPressed: _kids.isEmpty || !_units.contains(_unit)
                    ? null
                    : _create,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final hw in widget.homework.reversed) ...[
          _homeworkCard(hw),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _homeworkCard(DemoHomework hw) {
    final due = '${hw.due.day}.${hw.due.month}.';
    return HoloPanel(
      accent: HoloPalette.violet,
      shimmer: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LumoSubjectBadge(subject: hw.subject, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: HoloSectionTitle(
                  'Hausaufgabe: ${hw.subject} · ${hw.unit}'
                  '${hw.grade == null ? '' : ' · ${hw.grade}. Stufe'}'
                  ' · ${hw.count} Aufgaben · fällig $due'),
            ),
          ]),
          if (hw.note.isNotEmpty)
            Text('Hinweis: ${hw.note}',
                style: const TextStyle(color: HoloPalette.muted)),
          for (final id in hw.studentIds)
            if (demoChildren.where((c) => c.id == id).firstOrNull
                case final child?)
              _resultRow(hw, child),
        ],
      ),
    );
  }

  Widget _resultRow(DemoHomework hw, DemoChild child) {
    final items = hw.results[child.id];
    if (items == null || !hw.isDoneBy(child.id)) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [
          Expanded(
            child: Text('${child.name}: noch offen',
                style: const TextStyle(color: HoloPalette.text)),
          ),
          HoloButton(
            key: ValueKey('solve-${hw.id}-${child.id}'),
            label: 'Als Kind lösen',
            icon: Icons.child_care_rounded,
            accent: HoloPalette.mint,
            onPressed: () => _solve(hw, child),
          ),
        ]),
      );
    }
    final e = HomeworkEvaluation(hw, child.id, items);
    final weak = e.analysis.stats
        .where((s) => s.accuracy < .7)
        .map((s) => s.competency)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        key: ValueKey('evaluation-${hw.id}-${child.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${child.name}: ${e.correct} von ${e.items.length} richtig (${e.percent} %) · '
            'Ø ${e.averageSeconds.toStringAsFixed(1)} s · ${e.hints}× Hilfe',
            style: const TextStyle(
                color: HoloPalette.text, fontWeight: FontWeight.w700),
          ),
          if (weak.isNotEmpty)
            Text('Üben: ${weak.join(', ')}',
                style: const TextStyle(color: HoloPalette.amber)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final item in e.items)
              Tooltip(
                message:
                    '${item.prompt} → ${item.given} (richtig: ${item.expected})',
                child: Icon(
                  item.correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: item.correct ? HoloPalette.mint : HoloPalette.rose,
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
