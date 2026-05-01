import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/ai_task_cache.dart';
import '../../core/app_settings.dart';
import '../../core/lumo_ai_proxy_client.dart';
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
  bool _checkingHealth = false;
  LumoAiHealthStatus? _lastHealth;
  int _aiStatsRevision = 0;
  static const LumoAiProxyClient _proxyClient = LumoAiProxyClient();
  static const AiTaskCache _aiTaskCache = AiTaskCache();

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

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

  Future<void> _runHealthCheck() async {
    setState(() {
      _checkingHealth = true;
      _lastHealth = null;
    });
    final result = await _proxyClient.checkHealth(_settings.aiProxyUrl);
    if (!mounted) return;
    setState(() {
      _checkingHealth = false;
      _lastHealth = result;
    });
  }

  Future<void> _clearAiTaskCache() async {
    for (final subject in _AiTutorStatsPanel.subjects) {
      await _aiTaskCache.clear(childId: _childId, subject: subject);
    }
    if (!mounted) return;
    setState(() => _aiStatsRevision++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KI-Aufgaben-Vorrat wurde geleert.')),
    );
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
            lines: [
              'Offline-first',
              'Mikrofon nur bei aktiver Nutzung',
              _settings.aiProxyEnabled ? 'Lumo-KI-Server durch Eltern freigegeben' : 'Keine Cloud-KI aktiv',
              'Keine Werbung',
            ],
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
        _SettingsCard(title: 'Lumo-KI Testserver', children: [
          _SwitchRow(
            title: 'Lumo-KI-Server erlauben',
            subtitle: 'Nur aktivieren, wenn ein eigener kindergesicherter Proxy-Server läuft. Kein API-Key wird in der App gespeichert.',
            value: _settings.aiProxyEnabled,
            onChanged: (v) => _save(_settings.copyWith(aiProxyEnabled: v)),
          ),
          const SizedBox(height: 10),
          _ProxyUrlField(
            initialValue: _settings.aiProxyUrl,
            enabled: _settings.aiProxyEnabled,
            onSubmitted: (value) => _save(_settings.copyWith(aiProxyUrl: AppSettings.sanitizeProxyUrl(value))),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _settings.aiProxyUrl == AppSettings.defaultAiProxyUrl
                    ? null
                    : () => _save(_settings.copyWith(aiProxyUrl: AppSettings.defaultAiProxyUrl)),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Standard wiederherstellen'),
              ),
              FilledButton.icon(
                onPressed: _checkingHealth ? null : _runHealthCheck,
                icon: _checkingHealth
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.health_and_safety_rounded, size: 18),
                label: Text(_checkingHealth ? 'Pruefe ...' : 'Server pruefen'),
              ),
            ],
          ),
          if (_lastHealth != null) ...[
            const SizedBox(height: 8),
            _HealthStatusBadge(status: _lastHealth!),
          ],
          const SizedBox(height: 12),
          _AiTutorStatsPanel(
            key: ValueKey(_aiStatsRevision),
            childId: _childId,
            enabled: _settings.aiProxyEnabled,
            onClear: _clearAiTaskCache,
          ),
          const SizedBox(height: 10),
          _AiSafetyNotice(enabled: _settings.aiProxyEnabled, url: _settings.aiProxyUrl),
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

class _ProxyUrlField extends StatefulWidget {
  const _ProxyUrlField({required this.initialValue, required this.enabled, required this.onSubmitted});

  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  State<_ProxyUrlField> createState() => _ProxyUrlFieldState();
}

class _ProxyUrlFieldState extends State<_ProxyUrlField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(covariant _ProxyUrlField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: () => widget.onSubmitted(_controller.text),
      decoration: InputDecoration(
        labelText: 'Proxy-URL',
        hintText: 'https://dein-lumo-server.example.com',
        helperText: widget.enabled ? 'Nur die eigene Proxy-Adresse eintragen, nie einen API-Key.' : 'Erst den KI-Server-Schalter aktivieren.',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.dns_rounded),
      ),
    );
  }
}

class _AiTutorStatsPanel extends StatelessWidget {
  const _AiTutorStatsPanel({
    super.key,
    required this.childId,
    required this.enabled,
    required this.onClear,
  });

  static const subjects = <String>['Mathematik', 'Deutsch', 'Sachunterricht'];
  static const AiTaskCache _cache = AiTaskCache();

  final String childId;
  final bool enabled;
  final Future<void> Function() onClear;

  Future<_AiTutorStats> _load() async {
    var freshTotal = 0;
    var generatedToday = 0;
    DateTime? newest;
    final freshBySubject = <String, int>{};
    for (final subject in subjects) {
      final fresh = await _cache.freshCount(childId: childId, subject: subject);
      final last = await _cache.lastGeneratedAt(childId: childId, subject: subject);
      freshBySubject[subject] = fresh;
      freshTotal += fresh;
      if (last != null) {
        final now = DateTime.now();
        if (last.year == now.year && last.month == now.month && last.day == now.day) {
          generatedToday++;
        }
        if (newest == null || last.isAfter(newest)) newest = last;
      }
    }
    return _AiTutorStats(
      freshTotal: freshTotal,
      generatedToday: generatedToday,
      newestGeneration: newest,
      freshBySubject: freshBySubject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AiTutorStats>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(LumoRadius.md),
            border: Border.all(color: LumoColors.orange.withOpacity(.18)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.psychology_alt_rounded, color: LumoColors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KI-Aufgaben-Vorrat',
                  style: LumoTextStyles.caption.copyWith(
                    color: LumoColors.ink900,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting && data == null)
              Text('Lade KI-Status ...', style: LumoTextStyles.caption)
            else ...[
              _AiStatLine(label: 'KI-Schalter', value: enabled ? 'aktiv' : 'aus'),
              _AiStatLine(label: 'Aufgaben im Vorrat', value: '${data?.freshTotal ?? 0}'),
              _AiStatLine(label: 'Heute generierte Fächer', value: '${data?.generatedToday ?? 0}'),
              _AiStatLine(label: 'Letzte Generierung', value: data?.newestLabel ?? 'noch keine'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subject) {
                  final count = data?.freshBySubject[subject] ?? 0;
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$subject: $count'),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: data == null || data.freshTotal == 0 ? null : onClear,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('KI-Cache leeren'),
              ),
              const SizedBox(height: 4),
              Text(
                'Nur Eltern sehen diesen Bereich. Der API-Key bleibt ausschließlich auf dem Proxy-Server.',
                style: LumoTextStyles.caption.copyWith(color: LumoColors.ink500),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _AiStatLine extends StatelessWidget {
  const _AiStatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700))),
        const SizedBox(width: 12),
        Text(value, style: LumoTextStyles.caption.copyWith(color: LumoColors.ink900, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _AiTutorStats {
  const _AiTutorStats({
    required this.freshTotal,
    required this.generatedToday,
    required this.newestGeneration,
    required this.freshBySubject,
  });

  final int freshTotal;
  final int generatedToday;
  final DateTime? newestGeneration;
  final Map<String, int> freshBySubject;

  String get newestLabel {
    final value = newestGeneration;
    if (value == null) return 'noch keine';
    final now = DateTime.now();
    if (value.year == now.year && value.month == now.month && value.day == now.day) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return 'heute $hh:$mm';
    }
    final dd = value.day.toString().padLeft(2, '0');
    final mo = value.month.toString().padLeft(2, '0');
    return '$dd.$mo.${value.year}';
  }
}

class _AiSafetyNotice extends StatelessWidget {
  const _AiSafetyNotice({required this.enabled, required this.url});

  final bool enabled;
  final String url;

  @override
  Widget build(BuildContext context) {
    final valid = Uri.tryParse(url)?.hasAbsolutePath == true || Uri.tryParse(url)?.host.isNotEmpty == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? LumoColors.orangeSurface : LumoColors.ink100.withOpacity(.45),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: enabled ? LumoColors.orange.withOpacity(.22) : LumoColors.ink300.withOpacity(.20)),
      ),
      child: Text(
        enabled
            ? 'Aktiv: Lumo darf nur über den eigenen kindergesicherten Proxy antworten. Status der URL: ${valid ? 'eingetragen' : 'fehlt oder ungültig'}.'
            : 'Aus: Lumo nutzt nur die lokale Lernhilfe. Es wird keine externe KI kontaktiert.',
        style: LumoTextStyles.caption.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w800),
      ),
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

class _HealthStatusBadge extends StatelessWidget {
  const _HealthStatusBadge({required this.status});

  final LumoAiHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    if (status.fullyOk) {
      bg = const Color(0xFFD9F4D9);
      fg = const Color(0xFF1F6F1F);
      icon = Icons.check_circle_rounded;
    } else if (status.reachable) {
      bg = const Color(0xFFFFF3CC);
      fg = const Color(0xFF8A5A00);
      icon = Icons.warning_amber_rounded;
    } else {
      bg = const Color(0xFFFFE0E0);
      fg = const Color(0xFF8A1F1F);
      icon = Icons.cloud_off_rounded;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: fg,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
