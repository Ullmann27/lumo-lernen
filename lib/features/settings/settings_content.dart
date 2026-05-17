import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/ai_task_cache.dart';
import '../../core/app_settings.dart';
import '../../core/app_update_service.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_voice.dart';
import '../../core/settings_repository.dart';
import '../../domain/learning/learning_dna.dart';
import '../../domain/learning/learning_dna_engine.dart';
import '../learning/learning_dna_card.dart';
import '../rewards/test_photo_entry_card.dart';
import 'parent_report_card.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  /// Diagnose-Versionslabel. Heinz sieht sofort, ob er die neue
  /// APK installiert hat. Bei jedem groesseren Health-Fix
  /// hochzaehlen.
  static const String _aiDiagnosticsVersion = 'KI-Health-Client v4 (root-slash + diagnostics + smoketest)';

  late AppSettings _settings = widget.appState.state.settings;
  bool _saving = false;
  bool _checkingHealth = false;
  bool _runningSmokeTest = false;
  LumoAiHealthStatus? _lastHealth;
  // Update-Check-Status (Codex hat AppUpdateService gebaut, jetzt verdrahtet)
  AppUpdateInfo? _updateInfo;
  bool _checkingUpdate = false;
  String? _updateError;

  // KI-Eltern-Berater: spricht mit Eltern, NICHT mit Kind.
  // Mehr fachlich, mit paedagogischen Vorschlaegen.
  final LumoAiProxyClient _aiProxy = const LumoAiProxyClient();
  String? _aiAdvisorReply;
  bool _aiAdvisorLoading = false;
  LumoAiSmokeTestResult? _lastSmokeTest;
  /// Live-URL aus dem Eingabefeld. Wird bei jedem Tastendruck
  /// aktualisiert, damit "Server pruefen" gegen die wirklich
  /// sichtbare URL prueft, auch wenn Heinz noch nicht
  /// gespeichert/Enter gedrueckt hat.
  String _currentUrlInField = '';
  int _aiStatsRevision = 0;
  static const LumoAiProxyClient _proxyClient = LumoAiProxyClient();
  static const AiTaskCache _aiTaskCache = AiTaskCache();

  @override
  void initState() {
    super.initState();
    _currentUrlInField = _settings.aiProxyUrl;
    // Render-Warmup: Beim Oeffnen des Elternbereichs schon den
    // Server anstossen, damit "Server pruefen" gleich gruen wird
    // statt 30s zu warten. Fire-and-forget, kein State-Update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _proxyClient.warmup(_settings);
    });
  }

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
    // Aktuellen Live-Wert aus dem Eingabefeld lesen, NICHT den
    // gespeicherten _settings.aiProxyUrl. Heinz kann die URL
    // geaendert haben ohne Submit/Speichern.
    final candidateUrl = _currentUrlInField.trim().isEmpty
        ? _settings.aiProxyUrl
        : _currentUrlInField.trim();
    final sanitized = AppSettings.sanitizeProxyUrl(candidateUrl);

    // Wenn die geprueften URL anders ist als die gespeicherte,
    // speichern wir sie zuerst, damit der Check auch in spaeteren
    // Sessions die richtige URL nutzt.
    if (sanitized != _settings.aiProxyUrl) {
      await _save(_settings.copyWith(aiProxyUrl: sanitized));
    }

    setState(() {
      _checkingHealth = true;
      _lastHealth = null;
    });
    final result = await _proxyClient.checkHealth(sanitized);
    if (!mounted) return;
    setState(() {
      _checkingHealth = false;
      _lastHealth = result;
    });
  }

  Future<void> _runSmokeTest() async {
    // Eltern-Smoke-Test gegen /chat. Sendet neutrale Test-Nachricht
    // ohne Kinderdaten. Verwendet aktuelle gespeicherte Settings.
    setState(() {
      _runningSmokeTest = true;
      _lastSmokeTest = null;
    });
    final result = await _proxyClient.parentSmokeTest(_settings);
    if (!mounted) return;
    setState(() {
      _runningSmokeTest = false;
      _lastSmokeTest = result;
    });
  }

  Future<void> _clearAiTaskCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vorrat wirklich leeren?'),
        content: const Text(
          'Lumo verliert den vorbereiteten Aufgaben-Vorrat. '
          'Beim nächsten Lernen wird ein neuer Vorrat erstellt. '
          'Das kann eine kurze Wartezeit verursachen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LumoColors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vorrat leeren'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final subject in _AiTutorStatsPanel.subjects) {
      await _aiTaskCache.clear(childId: _childId, subject: subject);
    }
    if (!mounted) return;
    setState(() => _aiStatsRevision++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KI-Aufgaben-Vorrat wurde geleert.')),
    );
  }

  /// Manuelle Pruefung ob ein neueres Lumo-Lernen Release verfuegbar ist.
  /// Greift auf AppUpdateService zu (von Codex gebaut), der nur
  /// vertrauenswuerdige github.com URLs zulaesst.
  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    if (!mounted) return;
    setState(() {
      _checkingUpdate = true;
      _updateError = null;
    });
    try {
      final service = const AppUpdateService();
      final info = await service.checkLatest();
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _updateError = info.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _updateError = 'Update-Pruefung fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _openUpdate() async {
    final info = _updateInfo;
    if (info == null) return;
    final ok = await const AppUpdateService().openUpdate(info);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download konnte nicht geoeffnet werden.')),
      );
    }
  }

  /// Fragt den Eltern-Berater nach paedagogischen Tipps zum Kind.
  /// Nutzt LumoAiContext.parentAdvisor - andere Persona als beim Kind-Chat.
  Future<void> _askParentAdvisor(String question) async {
    if (_aiAdvisorLoading || question.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _aiAdvisorLoading = true;
      _aiAdvisorReply = null;
    });
    try {
      final response = await _aiProxy.ask(
        settings: widget.appState.state.settings,
        state: widget.appState.state,
        message: question,
        context: LumoAiContext.parentAdvisor,
      );
      if (!mounted) return;
      setState(() {
        _aiAdvisorReply = response.reply;
        _aiAdvisorLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiAdvisorReply = 'Der Berater ist gerade nicht erreichbar. Bitte spaeter erneut.';
        _aiAdvisorLoading = false;
      });
    }
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
        _AppUpdateCard(
          info: _updateInfo,
          checking: _checkingUpdate,
          error: _updateError,
          onCheck: _checkForUpdate,
          onDownload: _openUpdate,
        ),
        const SizedBox(height: 18),
        ParentReportCard(appState: widget.appState),
        const SizedBox(height: 18),
        // Phase 1 - sichtbare Lern-DNA fuer Eltern
        _DnaSettingsSlot(appState: widget.appState),
        const SizedBox(height: 18),
        // Heinz' Wunsch: Eltern fotografieren Test, Note rein, Punkte raus.
        TestPhotoEntryCard(appState: widget.appState),
        if (_settings.aiProxyEnabled) ...[
          const SizedBox(height: 18),
          _AiParentAdvisorCard(
            askingLoading: _aiAdvisorLoading,
            reply: _aiAdvisorReply,
            onAsk: _askParentAdvisor,
          ),
        ],
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
            onChanged: (value) => _currentUrlInField = value,
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
                label: Text(_checkingHealth ? 'Server wacht auf …' : 'Server prüfen'),
              ),
              OutlinedButton.icon(
                onPressed: (_runningSmokeTest || !_settings.aiProxyEnabled) ? null : _runSmokeTest,
                icon: _runningSmokeTest
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(_runningSmokeTest ? 'Sende Test …' : 'KI-Testantwort prüfen'),
              ),
            ],
          ),
          if (_lastHealth != null) ...[
            const SizedBox(height: 8),
            _HealthStatusBadge(status: _lastHealth!),
            const SizedBox(height: 8),
            _HealthDiagnosticsCard(status: _lastHealth!),
          ],
          if (_lastSmokeTest != null) ...[
            const SizedBox(height: 8),
            _SmokeTestResultCard(result: _lastSmokeTest!),
          ],
          const SizedBox(height: 8),
          _DiagnosticsVersionLabel(version: _aiDiagnosticsVersion),
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
    // Premium-Header: warmer Gradient, grosser Avatar mit Glow.
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFE4CC), Color(0xFFFFD1A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFFFB96B), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(-2, -2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A2F).withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 38, height: 1.0)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C2D12),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  const _ProxyUrlField({
    required this.initialValue,
    required this.enabled,
    required this.onSubmitted,
    this.onChanged,
  });

  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

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
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: () => widget.onSubmitted(_controller.text),
      decoration: InputDecoration(
        labelText: 'Proxy-URL',
        hintText: 'https://dein-lumo-server.example.com',
        helperText: widget.enabled ? 'Nur die eigene Proxy-Adresse eintragen, nie einen API-Key.' : 'Erst den KI-Server-Schalter aktivieren.',
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.dns_rounded),
      ),
      style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
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
    final headline = enabled
        ? 'KI ist freigegeben'
        : 'KI ist ausgeschaltet';
    final subline = enabled
        ? 'Lumo darf Antworten über den eigenen kindergesicherten Server holen. Es werden keine API-Schlüssel in der App gespeichert.'
        : 'Lumo nutzt nur die lokale Lernhilfe. Es werden keine Anfragen an externe Server gesendet.';
    final iconColor = enabled ? LumoColors.orange : LumoColors.ink500;
    final iconData = enabled ? Icons.shield_rounded : Icons.shield_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? LumoColors.orangeSurface : LumoColors.ink100.withOpacity(.45),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: enabled ? LumoColors.orange.withOpacity(.22) : LumoColors.ink300.withOpacity(.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: LumoTextStyles.caption.copyWith(
                    color: LumoColors.ink900,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subline,
                  style: LumoTextStyles.caption.copyWith(
                    color: LumoColors.ink600,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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

/// Eltern-Diagnose unter dem Health-Badge. Zeigt technische
/// Details zur letzten Gesundheitsprüfung. Niemals API-Key,
/// niemals Kinderdaten.
class _HealthDiagnosticsCard extends StatelessWidget {
  const _HealthDiagnosticsCard({required this.status});

  final LumoAiHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final lines = <_DiagLine>[
      _DiagLine('reachable', status.reachable.toString()),
      _DiagLine('openAiConfigured', status.openAiConfigured.toString()),
      _DiagLine('fullyOk', status.fullyOk.toString()),
      if (status.statusCode != null) _DiagLine('HTTP', status.statusCode.toString()),
      if (status.endpoint != null) _DiagLine('endpoint', status.endpoint!),
      if (status.checkedUrl != null) _DiagLine('URL', status.checkedUrl!),
      if (status.service != null) _DiagLine('service', status.service!),
      if (status.rawBodySnippet != null) _DiagLine('raw', status.rawBodySnippet!),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnose (Eltern)',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Color(0xFF334155),
                    ),
                    children: [
                      TextSpan(
                        text: '${l.label}: ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: l.value),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _DiagLine {
  const _DiagLine(this.label, this.value);
  final String label;
  final String value;
}

class _SmokeTestResultCard extends StatelessWidget {
  const _SmokeTestResultCard({required this.result});

  final LumoAiSmokeTestResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.success;
    final bg = ok ? const Color(0xFFD9F4D9) : const Color(0xFFFFE0E0);
    final fg = ok ? const Color(0xFF1F6F1F) : const Color(0xFF8A1F1F);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                color: fg,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                ok ? 'KI-Test erfolgreich' : 'KI-Test fehlgeschlagen',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: fg,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'HTTP ${result.statusCode} · source: ${result.source}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: fg,
            ),
          ),
          if (result.replySnippet.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Antwort: ${result.replySnippet}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: fg,
                fontStyle: ok ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticsVersionLabel extends StatelessWidget {
  const _DiagnosticsVersionLabel({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        version,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Premium-Update-Karte oben im Elternbereich.
/// Codex hat AppUpdateService gebaut, diese Karte zeigt das Ergebnis an
/// und ermoeglicht manuellen Check + direkten Download.
class _AppUpdateCard extends StatelessWidget {
  const _AppUpdateCard({
    required this.info,
    required this.checking,
    required this.error,
    required this.onCheck,
    required this.onDownload,
  });

  final AppUpdateInfo? info;
  final bool checking;
  final String? error;
  final VoidCallback onCheck;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final hasUpdate = info?.available == true;
    // Wenn Update verfuegbar: gruener Akzent. Sonst: orange wie der Rest.
    final accent = hasUpdate ? const Color(0xFF22C55E) : LumoColors.orange;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            accent.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.22), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasUpdate
                        ? const [Color(0xFF34D399), Color(0xFF10B981)]
                        : const [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  hasUpdate ? '🎁' : '📦',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUpdate ? 'Neue Version verfügbar' : 'App-Version',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info == null
                          ? 'Aktuell: Build ${AppUpdateService.currentBuildNumber} (${AppUpdateService.currentVersionName})'
                          : hasUpdate
                              ? 'Build ${info!.latestBuildNumber} ist neuer als deine Build ${info!.currentBuildNumber}.'
                              : 'Du hast die neueste Version (Build ${info!.currentBuildNumber}).',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasUpdate)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Herunterladen'),
                  ),
                ),
              if (hasUpdate) const SizedBox(width: 10),
              Expanded(
                flex: hasUpdate ? 0 : 1,
                child: OutlinedButton.icon(
                  onPressed: checking ? null : onCheck,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: accent.withOpacity(0.40)),
                  ),
                  icon: checking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(checking ? 'Prüfe…' : 'Auf Update prüfen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// KI-Eltern-Berater Karte.
/// Eltern koennen Lumo nach paedagogischen Tipps fragen.
/// Andere Persona als der Kind-Chat: fachlicher, mit Foerdervorschlaegen.
class _AiParentAdvisorCard extends StatefulWidget {
  const _AiParentAdvisorCard({
    required this.askingLoading,
    required this.reply,
    required this.onAsk,
  });

  final bool askingLoading;
  final String? reply;
  final ValueChanged<String> onAsk;

  @override
  State<_AiParentAdvisorCard> createState() => _AiParentAdvisorCardState();
}

class _AiParentAdvisorCardState extends State<_AiParentAdvisorCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickQuestions = <String>[
      'Wie kann ich mein Kind beim Lesen unterstuetzen?',
      'Was bedeutet die aktuelle Schwaeche in Mathe?',
      'Wie motiviere ich mein Kind ohne Druck?',
      'Welche Uebungen helfen bei Rechtschreibung?',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFF7DD3FC), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('🧑‍🏫', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lumo Eltern-Berater',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0C4A6E),
                      ),
                    ),
                    Text(
                      'Tipps zur Foerderung deines Kindes',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF075985),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickQuestions.map((q) => _QuickQuestionChip(
              text: q,
              onTap: widget.askingLoading ? null : () => widget.onAsk(q),
            )).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.askingLoading,
                  decoration: const InputDecoration(
                    hintText: 'Eigene Frage stellen…',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (txt) {
                    if (txt.trim().isNotEmpty) widget.onAsk(txt);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.askingLoading
                    ? null
                    : () {
                        final txt = _controller.text.trim();
                        if (txt.isNotEmpty) widget.onAsk(txt);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: widget.askingLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
          if (widget.reply != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC), width: 1),
              ),
              child: Text(
                widget.reply!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  const _QuickQuestionChip({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF7DD3FC), width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0C4A6E),
          ),
        ),
      ),
    );
  }
}

/// Phase 1 - Eltern-Slot fuer die Lern-DNA-Karte.
/// Berechnet die DNA bei jedem Aufruf neu aus dem App-State.
class _DnaSettingsSlot extends StatelessWidget {
  const _DnaSettingsSlot({required this.appState});

  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    // DNA aus aktuellem State berechnen.
    // Quellen: weakSkills, stars, xp, level, lastGrade, solved.
    final dna = const LearningDnaEngine().compute(
      state: appState.state,
      // recentCorrect/Incorrect approximieren aus solved/weakSkills-Summe
      recentCorrect: appState.state.solved.values.fold<int>(0, (sum, v) => sum + v),
      recentIncorrect: appState.state.weakSkills.values.fold<int>(0, (sum, v) => sum + v),
    );
    if (dna.strengths.isEmpty && dna.weaknesses.isEmpty && dna.totalCorrect == 0) {
      // Frueh-Phase: zeige Hinweis statt leere Karte.
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5FF),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
        ),
        child: Row(
          children: [
            const Text('🧬', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Lumo Lern-DNA: noch keine Daten. Nach einigen Aufgaben '
                'siehst du hier Staerken, Schwaechen und die naechste Empfehlung.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6D28D9),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return LearningDnaParentCard(dna: dna);
  }
}
