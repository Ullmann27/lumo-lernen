import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/discovery_progress.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../learning_modules/learning_module_progress.dart';

/// Local explicit adult choice, not verified adult identity or online consent.
/// The existing captured-owner writer prevents A's choice being saved for B.
class DiscoverySettingsCard extends StatefulWidget {
  const DiscoverySettingsCard({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<DiscoverySettingsCard> createState() => _DiscoverySettingsCardState();
}

class _DiscoverySettingsCardState extends State<DiscoverySettingsCard> {
  late final int _generation;
  late final _writer = LearningModuleProgress(
      appState: widget.appState, subject: 'Eltern', unit: 'Entdeckungen');
  bool _loading = true;
  bool _confirming = false;
  bool _stale = false;
  String? _error;
  DiscoveryProgress _display = DiscoveryProgress();
  LearningProfileLease? _owner;

  static const _text = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w700);

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _writer.addListener(_writerChanged);
    widget.appState.addListener(_profileChanged);
    unawaited(_load());
  }

  void _writerChanged() {
    if (!mounted) return;
    setState(() {
      // A retry acknowledges the same pending policy. Display it only after
      // native storage succeeds, not from an unacknowledged optimistic grant.
      if (!_writer.hasPending &&
          !_stale &&
          _owner != null &&
          widget.appState.isCurrentLearningLease(_owner!)) {
        _display = _owner!.profile.discovery;
      }
    });
  }

  void _profileChanged() {
    if (_stale || widget.appState.profileGeneration == _generation) return;
    _stale = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      await owner.profile.loadDiscovery();
      if (!mounted ||
          _stale ||
          !widget.appState.isCurrentLearningLease(owner)) {
        return;
      }
      setState(() {
        _owner = owner;
        _display = owner.profile.discovery;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || _stale) return;
      setState(() {
        _loading = false;
        _error = 'Entdeckungsdaten konnten nicht sicher geladen werden. '
            'Gespeicherte Daten bleiben unverändert.';
      });
    }
  }

  Future<void> _change({required bool enabled, required int maxGrade}) async {
    if (_loading ||
        _stale ||
        _confirming ||
        _writer.hasPending ||
        _owner == null ||
        !widget.appState.isCurrentLearningLease(_owner!)) {
      return;
    }
    if (enabled) {
      setState(() => _confirming = true);
      final allowed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              scrollable: true,
              title: const Text('Neues entdecken freigeben'),
              content: Text('Bitte gib das Gerät einer erwachsenen Person.\n\n'
                  'Ich erlaube diesem Kinderprofil freiwillige Entdeckungen bis '
                  'zur $maxGrade. Schulstufe. Die eingestellte Klasse und der '
                  'Schulfortschritt bleiben unverändert.\n\n'
                  'Das ist keine Freigabe für Online-KI, Sprachserver, Mikrofon, '
                  'Kamera, Käufe oder ein Premium-Abo.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Nicht jetzt')),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Als Erwachsene:r freigeben')),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      setState(() => _confirming = false);
      if (!allowed ||
          _stale ||
          !widget.appState.isCurrentLearningLease(_owner!)) {
        return;
      }
    }
    final saved = await _writer.saveDiscoveryPermission(
        enabled: enabled, maxGrade: maxGrade);
    if (!mounted || _stale) return;
    if (saved) {
      setState(() => _display = _owner!.profile.discovery);
    } else {
      setState(() => _error = 'Das Kinderprofil wurde geändert. '
          'Für ein anderes Profil wurde keine Freigabe übernommen.');
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_profileChanged);
    _writer.removeListener(_writerChanged);
    _writer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _loading ||
        _stale ||
        _confirming ||
        _writer.hasPending ||
        _error != null;
    return LumoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Freiwillig Neues entdecken',
              style: TextStyle(
                  color: LumoVisualTokens.white,
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text(
              'Nur für das ausgewählte Kinderprofil. Neue Themen '
              'werden eingeführt, nicht als schwerere Schulaufgaben '
              'aufgedrängt. Die Schulklasse bleibt gleich.',
              style: _text),
          if (_stale)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                    'Das Kinderprofil wurde gewechselt. '
                    'Bitte öffne den Elternbereich erneut.',
                    style: _text)),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Freigabe wird geladen…', style: _text)),
          Material(
            // ListTile ink must be above the glass DecoratedBox, otherwise
            // Flutter reports hidden feedback and the toggle looks unresponsive.
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: const ValueKey('discovery-parent-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Vorlernen erlauben', style: _text),
              subtitle:
                  const Text('Standardmäßig ausgeschaltet.', style: _text),
              value: _display.enabled,
              onChanged: locked
                  ? null
                  : (enabled) => unawaited(
                      _change(enabled: enabled, maxGrade: _display.maxGrade)),
            ),
          ),
          const Text('Höchste erlaubte Schulstufe', style: _text),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey(
                'discovery-parent-limit-$_generation-${_display.maxGrade}'),
            initialValue: _display.maxGrade,
            isExpanded: true,
            dropdownColor: LumoVisualTokens.night,
            style: _text,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16)),
            items: [
              for (var grade = 1; grade <= 4; grade++)
                DropdownMenuItem(
                    value: grade, child: Text('Bis zur $grade. Schulstufe')),
            ],
            onChanged: locked
                ? null
                : (grade) {
                    if (grade != null) {
                      unawaited(
                          _change(enabled: _display.enabled, maxGrade: grade));
                    }
                  },
          ),
          const SizedBox(height: 12),
          Text(
              '${_display.topics.length} Themen bisher ausprobiert. '
              'Eine ausgeschaltete Freigabe löscht diese Daten nicht.',
              style: _text),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: _text),
            OutlinedButton(
                onPressed: _stale
                    ? null
                    : () {
                        setState(() => _loading = true);
                        unawaited(_load());
                      },
                child: const Text('Erneut laden')),
          ],
          if (_writer.hasPending) ...[
            const SizedBox(height: 12),
            Text(_writer.error ?? _writer.savingText, style: _text),
            if (_writer.error != null)
              FilledButton(
                onPressed: _writer.saving || _stale ? null : _writer.retry,
                child: const Text('Freigabe erneut speichern'),
              ),
          ],
        ],
      ),
    );
  }
}
