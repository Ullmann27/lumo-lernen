import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_night_scope.dart';
import '../../core/ai_task_cache.dart';
import '../../core/app_settings.dart';
import '../../core/app_update_service.dart';
import '../../core/error_breakdown_repository.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_error_log.dart';
import '../../core/lumo_voice.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/settings_repository.dart';
import '../../domain/learning/learning_dna_engine.dart';
import '../learning/learning_dna_card.dart';
import '../rewards/test_photo_entry_card.dart';
import '../teacher/teacher_dashboard_screen.dart';
import 'legacy_learning_data_card.dart';
import 'parent_report_card.dart';
import 'writing_report_card.dart';

/// All settings, sheets and dialogs share the same night surface.
/// The State must live below the scope so showDialog captures this Theme.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) => LumoNightScope(
        child: _SettingsContentBody(appState: appState),
      );
}

class _SettingsContentBody extends StatefulWidget {
  const _SettingsContentBody({required this.appState});
  final LumoAppState appState;

  @override
  State<_SettingsContentBody> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContentBody> {
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
  int _legacyDataRevision = 0;
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
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_',
          );
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
      cloudVoiceEnabled: next.cloudVoiceEnabled,
      voiceServerUrl: next.aiProxyUrl,
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
  /// Heinz 2026-05-21: 'Mann muss immer die Moeglichkeit haben das
  /// Profil auf neu zurueckzusetzen - extra Option bei den Eltern.'
  /// Confirmation-Dialog mit doppeltem Tap (Sicherheit).
  Future<void> _confirmResetProfile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Profil wirklich zuruecksetzen?',
          style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Damit gehen verloren:\n'
          '• Name und Klasse des Kindes\n'
          '• Alle gesammelten Sterne und XP\n'
          '• Lese-, Schreib- und Lernfortschritt\n'
          '• Spielstaende der Mini-Spiele\n\n'
          'Die App startet danach wie beim ersten Mal mit der Begruessung.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Ja, zuruecksetzen',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await widget.appState.resetAllProfile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil zurueckgesetzt. App startet beim naechsten Oeffnen neu.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Heinz' Wunsch 2026-05-21: 'Einfach auf Aktualisieren druecken,
  /// dann passiert alles automatisch.' Vorher musste man erst auf
  /// 'Pruefen' druecken und dann nochmal auf 'Herunterladen'.
  /// Jetzt EIN-KLICK: pruefen + (falls verfuegbar) sofort Download.
  Future<void> _checkAndUpdate() async {
    if (_checkingUpdate) return;
    if (!mounted) return;
    setState(() {
      _checkingUpdate = true;
      _updateError = null;
    });
    try {
      const service = AppUpdateService();
      final info = await service.checkLatest();
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _updateError = info.error;
      });
      // Direkt weiter zum Auto-Install wenn ein Update verfuegbar ist.
      // 2026-06-06 Heinz: 'einfach Update-Button druecken, alles automatisch'.
      // Statt Browser-Launch jetzt: APK direkt in den App-Cache laden, dann
      // ueber MethodChannel den System-Installer aufrufen. Bei Berechtigungs-
      // fehler oeffnet sich automatisch der Einstellungs-Dialog.
      if (info.available && info.hasUsableDownload) {
        final result = await service.downloadAndInstall(info);
        if (!mounted) return;
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Build ${info.latestBuildNumber} geladen - jetzt '
                  'auf Installieren tippen!',
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        } else if (result.needsPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ??
                  'Bitte in den Einstellungen "Apps installieren" erlauben.',
              ),
              duration: const Duration(seconds: 8),
            ),
          );
        } else {
          // Fallback: Browser-Download wenn Auto-Install nicht ging.
          final ok = await service.openUpdate(info);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok
                  ? 'Auto-Install ging nicht. Browser-Download gestartet - bitte Notification antippen.'
                  : 'Update konnte nicht gestartet werden: ${result.error ?? "unbekannter Fehler"}',
              ),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      } else if (info.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Du hast die neueste Version (Build '
                '${info.currentBuildNumber}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updateError = 'Update-Pruefung fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
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
    // Same approved night scene as the profile; controls retain a quiet glass surface.
    return LumoSceneBackground(
      scene: LumoScene.profile,
      dimmed: true,
      showPlaceholderLabel: false,
      child: SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 14 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(
          title: 'Elternbereich',
          subtitle: 'Sichere Einstellungen für ${state.childName}, Klasse ${state.grade}.',
          emoji: '⚙️',
          accent: LumoVisualTokens.white,
        ),
        const SizedBox(height: 18),
        _AppUpdateCard(
          info: _updateInfo,
          checking: _checkingUpdate,
          error: _updateError,
          onUpdate: _checkAndUpdate,
        ),
        const SizedBox(height: 18),
        _TeacherAreaCard(
          onOpen: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TeacherDashboardScreen(appState: widget.appState),
              ),
            );
            if (mounted) setState(() => _legacyDataRevision++);
          },
        ),
        LegacyLearningDataCard(
          appState: widget.appState,
          refreshRevision: _legacyDataRevision,
        ),
        const SizedBox(height: 18),
        _ProfileResetCard(
          onReset: () => _confirmResetProfile(context)),
        const SizedBox(height: 18),
        ParentReportCard(appState: widget.appState),
        const SizedBox(height: 18),
        // Phase 6b: Schreibcoach-Uebungsstand (geuebte/schwache Buchstaben,
        // Diktatwoerter, kurze Lumo-Empfehlung).
        const WritingReportCard(),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                constraints.maxWidth < 250 ? constraints.maxWidth : 250.0;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _InfoCard(
                  width: cardWidth,
                  title: 'Profil',
                  emoji: '👤',
                  lines: [
                    'Name: ${state.childName}',
                    'Klasse: ${state.grade}',
                    'Fach: ${state.subject}',
                    'Thema: ${Curriculum.prettifyUnit(state.unit)}',
                  ],
                ),
                _InfoCard(
                  width: cardWidth,
                  title: 'Datenschutz',
                  emoji: '🛡️',
                  lines: [
                    'Offline-first',
                    'Mikrofon nur bei aktiver Nutzung',
                    _settings.aiProxyEnabled
                        ? 'Lumo-KI-Server durch Eltern freigegeben'
                        : 'Keine Cloud-KI aktiv',
                    'Keine Werbung',
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _SettingsCard(title: 'Lernen', children: [
          _DailyGoalSelector(value: _settings.dailyGoal, onChanged: (v) => _save(_settings.copyWith(dailyGoal: v)),
                ),
          const SizedBox(height: 12),
          _ModeSelector(value: _settings.learningMode, onChanged: (v) => _save(_settings.copyWith(learningMode: v)),
                ),
        ],
            ),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Ton und Stimme', children: [
          _SwitchRow(title: 'Lumo-Stimme', subtitle: 'Lumo darf Antworten laut sprechen.', value: _settings.voiceEnabled, onChanged: (v) => _save(_settings.copyWith(voiceEnabled: v)),
                ),
          _SwitchRow(title: 'Automatisch vorlesen', subtitle: 'Lumo spricht beim Wechseln von Bereichen.', value: _settings.autoReadEnabled, onChanged: (v) => _save(_settings.copyWith(autoReadEnabled: v)),
                ),
          const SizedBox(height: 10),
          _SliderRow(title: 'Sprechtempo', value: _settings.voiceRate, min: 0.25, max: 0.55, onChanged: (v) => _save(_settings.copyWith(voiceRate: v)),
                ),
          const SizedBox(height: 6),
          const Text('Original-Lumo-Stimme: Sulafat. Die Stimmhöhe bleibt zur Wahrung des Originalklangs fest eingestellt. Das Sprechtempo gilt auch für die Stimmprobe.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          _SwitchRow(
            title: 'Online-Lumo-Stimme (Sulafat)',
            subtitle: 'Für neue, individuelle Sätze wird ausschließlich der vorzulesende Text über deinen Lumo-Server an Google Gemini TTS gesendet. Elternfreigabe erforderlich. Ohne diese Freigabe spricht Lumo nur vorhandene Originalaufnahmen, niemals die alte Android-Stimme.',
            value: _settings.cloudVoiceEnabled,
            onChanged: (v) => _save(_settings.copyWith(cloudVoiceEnabled: v)),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(onPressed: _settings.voiceEnabled ? () => LumoVoice.instance.test() : null, icon: const Icon(Icons.volume_up_rounded), label: const Text('Stimme testen'),
                    ),
            OutlinedButton.icon(onPressed: () => LumoVoice.instance.stop(), icon: const Icon(Icons.stop_rounded), label: const Text('Stopp'),
                    ),
          ],
                ),
          const SizedBox(height: 8),
          Text('Aktuelle Stimme: Sulafat (Originalaufnahme + freigegebene Sulafat-Synthese). Bei Verbindungsfehlern wird keine andere Stimme eingesetzt.',
              style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted)),
                ),
        ],
            ),
        const SizedBox(height: 14),
            _SettingsCard(
              title: 'Sicherheit und Funktionen',
              children: [
                const Text(
                    'Für Erwachsene: Wähle hier bewusst, welche Funktionen dein Kind nutzen darf. Gerätefreigaben werden erst beim Verwenden angefragt.'),
                const SizedBox(height: 12),
                _SwitchRow(
                  title: 'Mikrofon erlauben',
                  subtitle:
                      'Spracheingabe erst nach Antippen. Ohne Freigabe bleiben Text und lokale Lernhilfe nutzbar.',
                  value: _settings.microphoneEnabled,
                  onChanged: (v) =>
                      _save(_settings.copyWith(microphoneEnabled: v)),
                ),
                _SwitchRow(
                  title: 'Kamera und Scanner erlauben',
                  subtitle:
                      'Aufgabenfotos erst nach Antippen aufnehmen oder auswählen.',
                  value: _settings.scannerEnabled,
                  onChanged: (v) =>
                      _save(_settings.copyWith(scannerEnabled: v)),
                ),
                _SwitchRow(
                  title: 'Ton-Effekte',
                  subtitle:
                      'Vorbereitung für spätere Klick- und Belohnungstöne.',
                  value: _settings.soundEnabled,
                  onChanged: (v) => _save(_settings.copyWith(soundEnabled: v)),
                ),
              ],
            ),
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
            onSubmitted: (value) => _save(_settings.copyWith(aiProxyUrl: AppSettings.sanitizeProxyUrl(value),
                    ),
                  ),
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
                    : () => _save(_settings.copyWith(aiProxyUrl: AppSettings.defaultAiProxyUrl,
                              ),
                            ),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Standard wiederherstellen'),
              ),
              FilledButton.icon(
                onPressed: _checkingHealth ? null : _runHealthCheck,
                icon: _checkingHealth
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                            )
                    : const Icon(Icons.health_and_safety_rounded, size: 18,
                            ),
                label: Text(_checkingHealth ? 'Server wacht auf …' : 'Server prüfen',
                      ),
              ),
              OutlinedButton.icon(
                onPressed: (_runningSmokeTest || !_settings.aiProxyEnabled) ? null : _runSmokeTest,
                icon: _runningSmokeTest
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                            )
                    : const Icon(Icons.chat_bubble_outline_rounded, size: 18,
                            ),
                label: Text(_runningSmokeTest ? 'Sende Test …' : 'KI-Testantwort prüfen',
                      ),
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
            grade: state.grade,
            enabled: _settings.aiProxyEnabled,
            onClear: _clearAiTaskCache,
          ),
          const SizedBox(height: 10),
          _AiSafetyNotice(enabled: _settings.aiProxyEnabled, url: _settings.aiProxyUrl,
                ),
        ],
            ),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Barrierefreiheit', children: [
          _SwitchRow(title: 'Ruhiger Modus', subtitle: 'Weniger Reize und sanftere Ansprache.', value: _settings.calmMode, onChanged: (v) => _save(_settings.copyWith(calmMode: v)),
                ),
          _SwitchRow(title: 'Große Schrift', subtitle: 'Texte werden Schritt für Schritt größer nutzbar gemacht.', value: _settings.largeText, onChanged: (v) => _save(_settings.copyWith(largeText: v)),
                ),
          _SwitchRow(title: 'Animationen reduzieren', subtitle: 'Bewegung und Effekte reduzieren.', value: _settings.reduceAnimations, onChanged: (v) => _save(_settings.copyWith(reduceAnimations: v)),
                ),
        ],
            ),
        const SizedBox(height: 14),
        _SettingsCard(title: 'Verwaltung', children: [
          Text('Speicherstatus: ${_saving ? 'speichert ...' : 'gespeichert'}', style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted),
                ),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _resetSettings, icon: const Icon(Icons.restore_rounded), label: const Text('Einstellungen zurücksetzen'),
                ),
        ],
            ),
        const SizedBox(height: 14),
        // Heinz' Diagnose-Karte: zeigt die letzten 20 Abstuerze mit
        // Stacktrace. Damit kann Claude beim naechsten Bug-Report
        // gezielt fixen, statt blind zu raten.
        const _ErrorLogCard(),
      ],
        ),
      ), // close SingleChildScrollView
    ); // close night scene
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.emoji, required this.accent,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final avatarSize = compact ? 52.0 : 72.0;
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 20,
            compact ? 16 : 22,
            compact ? 14 : 20,
            compact ? 16 : 22,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xEE0B315F), Color(0xF0081D43), Color(0xEA0B2A55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            border: Border.all(
              color: LumoVisualTokens.cyan.withOpacity(.52),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: LumoVisualTokens.cyan.withOpacity(.20),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              const BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38DFFF), Color(0xFF246EFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 16 : 20),
                  border: Border.all(color: Colors.white.withOpacity(.28)),
                  boxShadow: [
                    BoxShadow(
                      color: LumoVisualTokens.cyan.withOpacity(.42),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LumoFoxPose(pose: LumoDesignFoxPose.tabletThumb, size: avatarSize),
              ),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD123D72), Color(0xEE0A2852)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.40)),
        boxShadow: [
          BoxShadow(
            color: LumoVisualTokens.cyan.withOpacity(.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.width,
    required this.title,
    required this.emoji,
    required this.lines,
  });
  final double width;
  final String title;
  final String emoji;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD123D72), Color(0xEE0A2852)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: LumoTextStyles.heading3.copyWith(color: LumoVisualTokens.white),
            ),
          ),
            ],
          ),
        const SizedBox(height: 10),
        ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $line', style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted,
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: LumoTextStyles.body.copyWith(
            fontWeight: FontWeight.w900,
            color: LumoVisualTokens.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted),
        ),
        value: value,
        onChanged: onChanged,
      ),
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
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue,
  );

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
    required this.grade,
    required this.enabled,
    required this.onClear,
  });

  static const subjects = <String>['Mathematik', 'Deutsch', 'Sachunterricht', 'Englisch'];
  static const AiTaskCache _cache = AiTaskCache();

  final String childId;
  final int grade;
  final bool enabled;
  final Future<void> Function() onClear;

  Future<_AiTutorStats> _load() async {
    var freshTotal = 0;
    var generatedToday = 0;
    DateTime? newest;
    final freshBySubject = <String, int>{};
    for (final subject in subjects) {
      final fresh = await _cache.freshCount(childId: childId, subject: subject, grade: grade);
      final last = await _cache.lastGeneratedAt(childId: childId, subject: subject, grade: grade,
      );
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
            gradient: const LinearGradient(
              colors: [Color(0xDD123D72), Color(0xEE0A2852)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.md),
            border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.36)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.psychology_alt_rounded, color: LumoVisualTokens.cyanBright, size: 22,
                  ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KI-Aufgaben-Vorrat',
                  style: LumoTextStyles.caption.copyWith(
                    color: LumoVisualTokens.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
              ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting && data == null)
              Text('Lade KI-Status ...', style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted))
            else ...[
              _AiStatLine(label: 'KI-Schalter', value: enabled ? 'aktiv' : 'aus',
                ),
              _AiStatLine(label: 'Aufgaben im Vorrat', value: '${data?.freshTotal ?? 0}',
                ),
              _AiStatLine(label: 'Heute generierte Fächer', value: '${data?.generatedToday ?? 0}',
                ),
              _AiStatLine(label: 'Letzte Generierung', value: data?.newestLabel ?? 'noch keine',
                ),
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
                style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted,
                  ),
              ),
            ],
          ],
          ),
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
        Expanded(child: Text(label, style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted),
            ),
          ),
        const SizedBox(width: 12),
        Text(value, style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.white, fontWeight: FontWeight.w900,
            ),
          ),
      ],
      ),
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
    final iconColor = enabled ? LumoColors.orange : LumoVisualTokens.muted;
    final iconData = enabled ? Icons.shield_rounded : Icons.shield_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xCC403421) : LumoVisualTokens.glassRow.withOpacity(.45),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: enabled ? LumoColors.orange.withOpacity(.22) : LumoVisualTokens.muted.withOpacity(.20),
        ),
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
                    color: LumoVisualTokens.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subline,
                  style: LumoTextStyles.caption.copyWith(
                    color: LumoVisualTokens.muted,
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
  const _SliderRow({required this.title, required this.value, required this.min, required this.max, required this.onChanged,
  });
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$title: ${value.toStringAsFixed(2)}', style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.white),
        ),
      Slider(value: value, min: min, max: max, divisions: 12, onChanged: onChanged,
        ),
    ],
    );
  }
}

class _DailyGoalSelector extends StatelessWidget {
  const _DailyGoalSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tagesziel', style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoVisualTokens.white,
          ),
        ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [3, 5, 10, 15].map((goal) => ChoiceChip(label: Text('$goal Aufgaben'), selected: value == goal, onSelected: (_) => onChanged(goal),
                ),
              ).toList(),
        ),
    ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});
  final LearningMode value;
  final ValueChanged<LearningMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lernmodus', style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoVisualTokens.white,
          ),
        ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: LearningMode.values.map((mode) => ChoiceChip(
        label: Text('${mode.label} – ${mode.description}'),
        selected: value == mode,
        onSelected: (_) => onChanged(mode),
      ),
              ).toList(),
        ),
    ],
    );
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
      bg = const Color(0xCC123E38);
      fg = const Color(0xFF7BE08C);
      icon = Icons.check_circle_rounded;
    } else if (status.reachable) {
      bg = const Color(0xCC3A3420);
      fg = const Color(0xFFFFD166);
      icon = Icons.warning_amber_rounded;
    } else {
      bg = const Color(0xCC44242C);
      fg = const Color(0xFFFF9D9D);
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
      _DiagLine('openAiAvailable', status.openAiAvailable.toString()),
      if (status.upstreamStatus != null) _DiagLine('upstreamStatus', status.upstreamStatus!),
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
        color: const Color(0xD90B2A55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.22)),
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
              color: LumoVisualTokens.white,
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
                      color: LumoVisualTokens.white,
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
              ),
          ),
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
    final bg = ok ? const Color(0xCC123E38) : const Color(0xCC44242C);
    final fg = ok ? const Color(0xFF7BE08C) : const Color(0xFFFF9D9D);
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
    required this.onUpdate,
  });

  final AppUpdateInfo? info;
  final bool checking;
  final String? error;

  /// Heinz 2026-05-21: Ein-Klick-Aktualisierung. Vorher musste man
  /// 'Pruefen' und dann 'Herunterladen' druecken - jetzt EIN Button
  /// macht beides. Wenn ein Update verfuegbar ist, startet der
  /// Download direkt; wenn nicht, kommt eine Snackbar 'du hast die
  /// neueste Version'.
  final VoidCallback onUpdate;

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
            const Color(0xE6123760),
            Color.alphaBlend(accent.withOpacity(.12), const Color(0xE609264B))],
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
                    BoxShadow(color: accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4),
                    ),
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
                        color: LumoVisualTokens.white,
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
                        color: LumoVisualTokens.muted,
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
                color: const Color(0xCC44242C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x88FF9D9D)),
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
                        color: Color(0xFFFFB4B4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Ein-Klick: Heinz' Wunsch. Der Button macht alles in einem
          // Rutsch - pruefen + (falls verfuegbar) Download starten.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: checking ? null : onUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white,
                      ),
                    )
                  : Icon(hasUpdate
                      ? Icons.download_rounded
                      : Icons.refresh_rounded,
                    ),
              label: Text(
                checking
                    ? 'Pruefe…'
                    : hasUpdate
                        ? 'Jetzt aktualisieren'
                        : 'Auf Update prüfen',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Android accepts updates only with the same package and signer.
          const SizedBox(height: 10),
          const Text(
            'Nach dem Download öffnest du die APK zur Installation. '
            'Ein direktes Update braucht denselben Paketnamen und Signaturschlüssel.\n'
            'Deinstalliere die alte App nicht: Dabei können Lernstände verloren gehen. '
            'Eine Variante mit anderer Paketkennung lässt sich parallel installieren; '
            'die Lernstände werden dabei nicht automatisch übernommen.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: LumoVisualTokens.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Heinz 2026-05-21: 'Profil auf neu zuruecksetzen - extra Option
/// bei den Eltern.' Danger-Zone Karte mit rotem Akzent, deutlich
/// abgesetzt vom Update-Bereich.
class _TeacherAreaCard extends StatelessWidget {
  const _TeacherAreaCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lehrerbereich öffnen',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('open-teacher-area'),
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xE6123760), Color(0xE609264B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E7FE0).withOpacity(.4), width: 1.4),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF63E4FF), Color(0xFF1E7FE0)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lehrerbereich',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white)),
                  Text('Klassen, Lernstand und Aufgaben zuweisen',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LumoVisualTokens.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: LumoVisualTokens.cyanBright),
          ]),
        ),
      ),
    );
  }
}

class _ProfileResetCard extends StatelessWidget {
  const _ProfileResetCard({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xE6123760), Color.alphaBlend(danger.withOpacity(.10), const Color(0xE609264B))],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: danger.withOpacity(0.25), width: 1.4),
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
                    colors: [Color(0xFFFCA5A5), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('⚠️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil zuruecksetzen',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Loescht Name, Klasse, Sterne, XP und allen Fortschritt. '
                      'Danach startet die App wie neu.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: const BorderSide(color: danger, width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                'Profil zuruecksetzen',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
          colors: [Color(0xE60B315F), Color(0xE6082148)],
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
                        color: LumoVisualTokens.white,
                      ),
                    ),
                    Text(
                      'Tipps zur Foerderung deines Kindes',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoVisualTokens.muted,
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
            ),
                ).toList(growable: false),
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
                    fillColor: Color(0xD90B2A55),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12,
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12,
                  ),
                ),
                child: widget.askingLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,
                        ),
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
                color: const Color(0xD90B2A55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC).withOpacity(.48), width: 1),
              ),
              child: Text(
                widget.reply!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: LumoVisualTokens.white,
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
          color: const Color(0xCC123760),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF7DD3FC).withOpacity(.45), width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: LumoVisualTokens.white,
          ),
        ),
      ),
    );
  }
}

/// Phase 1 - Eltern-Slot fuer die Lern-DNA-Karte.
/// Laedt persistierte Fehler-Breakdown (aus Phase 2) und berechnet DNA.
class _DnaSettingsSlot extends StatefulWidget {
  const _DnaSettingsSlot({required this.appState});

  final LumoAppState appState;

  @override
  State<_DnaSettingsSlot> createState() => _DnaSettingsSlotState();
}

class _DnaSettingsSlotState extends State<_DnaSettingsSlot> {
  static const _errorRepo = ErrorBreakdownRepository();
  Map<String, int> _errorBreakdown = const <String, int>{};
  bool _loaded = false;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_',
          );
    return 'local_${safeName}_${st.grade}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final breakdown = await _errorRepo.load(_childId);
    if (!mounted) return;
    setState(() {
      _errorBreakdown = breakdown;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState.state;
    final dna = const LearningDnaEngine().compute(
      state: state,
      errorBreakdown: _errorBreakdown,
      recentCorrect: state.solved.values.fold<int>(0, (sum, v) => sum + v),
      recentIncorrect: state.weakSkills.values.fold<int>(0, (sum, v) => sum + v,
      ),
    );
    if (dna.strengths.isEmpty &&
        dna.weaknesses.isEmpty &&
        dna.totalCorrect == 0 &&
        _errorBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xD914315F),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: const Color(0xFF9C8BFF).withOpacity(.48), width: 1.2),
        ),
        child: Row(
          children: [
            const Text('🧬', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _loaded
                    ? 'Lumo Lern-DNA: noch keine Daten. Nach einigen Aufgaben '
                        'siehst du hier Staerken, Schwaechen und die naechste Empfehlung.'
                    : 'Lumo Lern-DNA wird geladen...',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: LumoVisualTokens.muted,
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

/// Fehlerprotokoll-Karte: zeigt die letzten Crashes inkl. Stacktrace.
/// Heinz tippt auf "In Zwischenablage kopieren" und sendet den Text
/// an Claude. So kann Claude den naechsten Bug gezielt fixen, statt
/// im Code zu raten.
class _ErrorLogCard extends StatefulWidget {
  const _ErrorLogCard();

  @override
  State<_ErrorLogCard> createState() => _ErrorLogCardState();
}

class _ErrorLogCardState extends State<_ErrorLogCard> {
  List<LumoErrorEntry> _entries = const <LumoErrorEntry>[];
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await LumoErrorLog.instance.hydrate();
    if (!mounted) return;
    setState(() => _entries = LumoErrorLog.instance.entries);
  }

  Future<void> _clear() async {
    await LumoErrorLog.instance.clear();
    if (!mounted) return;
    setState(() => _entries = const <LumoErrorEntry>[]);
  }

  void _copyAll() {
    final buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.writeln('=== ${entry.timestamp.toIso8601String()} ===');
      buffer.writeln('Library: ${entry.library}');
      buffer.writeln('Context: ${entry.context}');
      buffer.writeln('Exception:');
      buffer.writeln(entry.exception);
      buffer.writeln('Stack:');
      buffer.writeln(entry.stack);
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context,
    ).showSnackBar(
      const SnackBar(content: Text('Fehlerprotokoll kopiert.')));
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Fehlerprotokoll (Diagnose)',
      children: [
        Text(
          _entries.isEmpty
              ? 'Bisher keine Abstuerze aufgezeichnet. 🦊'
              : '${_entries.length} Eintraege. Tippe "Kopieren" und sende den Text an Claude, damit er den Fehler gezielt fixen kann.',
          style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _entries.isEmpty ? null : _copyAll,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Alle kopieren'),
            ),
            OutlinedButton.icon(
              onPressed: _entries.isEmpty
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(_expanded ? 'Verbergen' : 'Anzeigen'),
            ),
            OutlinedButton.icon(
              onPressed: _entries.isEmpty ? null : _clear,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: const Text('Loeschen'),
            ),
          ],
        ),
        if (_expanded && _entries.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._entries.take(5).map((entry) => _ErrorEntryTile(entry: entry)),
        ],
      ],
    );
  }
}

class _ErrorEntryTile extends StatelessWidget {
  const _ErrorEntryTile({required this.entry});

  final LumoErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xCC44242C),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: const Color(0x88FF9D9D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.timestamp.toIso8601String().replaceFirst('T', ' ').split('.').first,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFC0C0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.exception,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFB4B4),
            ),
          ),
          if (entry.context.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.context,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: Color(0xFFFFC0C0),
              ),
            ),
          ],
          if (entry.stack.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  entry.stack,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFF374151),
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
