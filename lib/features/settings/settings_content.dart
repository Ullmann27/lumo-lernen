import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/app_settings.dart';
import '../../core/lumo_voice.dart';
import '../../core/settings_repository.dart';
import 'parent_report_card.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  late AppSettings _settings = widget.appState.state.settings;
  bool _saving = false;

  Future<void> _save(AppSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    widget.appState.updateSettings(next);
    LumoVoice.instance.configure(
      enabled: next.voiceEnabled,
      rate: next.voiceRate,
      pitch: next.voicePitch,
    );
    await SettingsRepository.save(next);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _resetSettings() async {
    const defaults = AppSettings();
    await SettingsRepository.save(defaults);
    await _save(defaults);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(
          title: 'Elternbereich',
          subtitle: 'Sichere Einstellungen für ${state.childName}, Klasse ${state.grade}.',
          emoji: '⚙️',
          accent: LumoColors.ink700,
        ),
        const SizedBox(height: 18),
        ParentReportCard(appState: widget.appState),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _InfoCard(
            title: 'Profil',
            emoji: '👤',
            lines: ['Name: ${state.childName}', 'Klasse: ${state.grade}', 'Fach: ${state.subject}', 'Thema: ${state.unit}'],
          ),
          _InfoCard(
            title: 'Datenschutz',
            emoji: '🛡️',
            lines: const ['Offline-first', 'Mikrofon lokal am Gerät', 'Keine Cloud-KI aktiv', 'Keine Werbung'],
          ),
        ]),
        const SizedBox(height: 18),
        _SettingsCard(title: 'Lernen', children: [
          _DailyGoalSelector(value: _settings.dailyGoal, onChanged: (v) => _save(_settings.copyWith(dailyGoal: v))),
          const SizedBox(height: 12),
          _ModeSelector(value: _settings.learningMode, onChanged: (v) => _save(_settings.copyWith(learningMode: v))),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Ton und Stimme', children: [
          _SwitchRow(title: 'Lumo-Stimme', subtitle: 'Lumo darf Antworten laut sprechen.', value: _settings.voiceEnabled, onChanged: (v) => _save(_settings.copyWith(voiceEnabled: v))),
          _SwitchRow(title: 'Automatisch vorlesen', subtitle: 'Lumo spricht beim Wechseln von Bereichen.', value: _settings.autoReadEnabled, onChanged: (v) => _save(_settings.copyWith(autoReadEnabled: v))),
          const SizedBox(height: 10),
          _SliderRow(title: 'Sprechtempo', value: _settings.voiceRate, min: 0.25, max: 0.55, onChanged: (v) => _save(_settings.copyWith(voiceRate: v))),
          _SliderRow(title: 'Stimmhöhe', value: _settings.voicePitch, min: 0.85, max: 1.18, onChanged: (v) => _save(_settings.copyWith(voicePitch: v))),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(onPressed: _settings.voiceEnabled ? () => LumoVoice.instance.test() : null, icon: const Icon(Icons.volume_up_rounded), label: const Text('Stimme testen')),
            OutlinedButton.icon(onPressed: () => LumoVoice.instance.stop(), icon: const Icon(Icons.stop_rounded), label: const Text('Stopp')),
          ]),
          const SizedBox(height: 8),
          Text('Aktuelle Stimme: ${LumoVoice.instance.selectedVoiceName ?? 'Systemstandard'} (${LumoVoice.instance.selectedLocale ?? 'de'})', style: LumoTextStyles.caption),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Sicherheit und Funktionen', children: [
          _SwitchRow(title: 'Mikrofon erlauben', subtitle: 'Kind darf mit Lumo sprechen.', value: _settings.microphoneEnabled, onChanged: (v) => _save(_settings.copyWith(microphoneEnabled: v))),
          _SwitchRow(title: 'Scanner erlauben', subtitle: 'Foto- und Aufgabenhilfe aktivieren.', value: _settings.scannerEnabled, onChanged: (v) => _save(_settings.copyWith(scannerEnabled: v))),
          _SwitchRow(title: 'Ton-Effekte', subtitle: 'Vorbereitung für spätere Klick- und Belohnungstöne.', value: _settings.soundEnabled, onChanged: (v) => _save(_settings.copyWith(soundEnabled: v))),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Barrierefreiheit', children: [
          _SwitchRow(title: 'Ruhiger Modus', subtitle: 'Weniger Reize und sanftere Ansprache.', value: _settings.calmMode, onChanged: (v) => _save(_settings.copyWith(calmMode: v))),
          _SwitchRow(title: 'Große Schrift', subtitle: 'Texte werden Schritt für Schritt größer nutzbar gemacht.', value: _settings.largeText, onChanged: (v) => _save(_settings.copyWith(largeText: v))),
          _SwitchRow(title: 'Animationen reduzieren', subtitle: 'Bewegung und Effekte reduzieren.', value: _settings.reduceAnimations, onChanged: (v) => _save(_settings.copyWith(reduceAnimations: v))),
        ]),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Verwaltung', children: [
          Text('Speicherstatus: ${_saving ? 'speichert ...' : 'gespeichert'}', style: LumoTextStyles.caption),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _resetSettings, icon: const Icon(Icons.restore_rounded), label: const Text('Einstellungen zurücksetzen')),
        ]),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.emoji, required this.accent});
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: lumoCard(gradient: LinearGradient(colors: [Colors.white, accent.withOpacity(.10)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: accent.withOpacity(.14), borderRadius: BorderRadius.circular(LumoRadius.lg)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: LumoTextStyles.heading1),
          const SizedBox(height: 6),
          Text(subtitle, style: LumoTextStyles.body),
        ])),
      ]),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: LumoTextStyles.heading3),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.emoji, required this.lines});
  final String title;
  final String emoji;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 8), Expanded(child: Text(title, style: LumoTextStyles.heading3))]),
        const SizedBox(height: 10),
        ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $line', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700)))),
      ]),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoColors.ink900)),
      subtitle: Text(subtitle, style: LumoTextStyles.caption),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.title, required this.value, required this.min, required this.max, required this.onChanged});
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$title: ${value.toStringAsFixed(2)}', style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700)),
      Slider(value: value, min: min, max: max, divisions: 12, onChanged: onChanged),
    ]);
  }
}

class _DailyGoalSelector extends StatelessWidget {
  const _DailyGoalSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tagesziel', style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoColors.ink900)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [3, 5, 10, 15].map((goal) => ChoiceChip(label: Text('$goal Aufgaben'), selected: value == goal, onSelected: (_) => onChanged(goal))).toList()),
    ]);
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});
  final LearningMode value;
  final ValueChanged<LearningMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lernmodus', style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoColors.ink900)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: LearningMode.values.map((mode) => ChoiceChip(
        label: Text('${mode.label} – ${mode.description}'),
        selected: value == mode,
        onSelected: (_) => onChanged(mode),
      )).toList()),
    ]);
  }
}
