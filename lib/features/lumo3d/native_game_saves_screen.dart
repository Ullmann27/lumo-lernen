import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/native_profile_key_repository.dart';
import '../../widgets/design/lumo_night_scope.dart';
import 'lumo3d_launcher.dart';

/// Uses the existing explicit adult-choice pattern. This is not a PIN or
/// identity-verification flow and does not inspect or migrate native files.
class NativeGameSavesScreen extends StatefulWidget {
  const NativeGameSavesScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<NativeGameSavesScreen> createState() => _NativeGameSavesScreenState();
}

class _NativeGameSavesScreenState extends State<NativeGameSavesScreen> {
  static const _repository = NativeProfileKeyRepository();
  static const _games = {
    'puzzle': 'Puzzle',
    'build': 'Bauwelt',
    'treasure': 'Schatzsuche',
    'jump': 'Jump & Run',
    'kart': 'Lumo Kart',
    'rhythm': 'Rhythm Party',
  };
  late final int _generation;
  late final TextEditingController _previousName;
  late int _previousGrade;
  LearningProfileLease? _owner;
  NativeProfileKeys? _keys;
  String _ownerName = '';
  String _game = 'puzzle';
  String _subject = 'Mathematik';
  String? _error;
  bool _busy = true;
  bool _stale = false;

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _previousName =
        TextEditingController(text: widget.appState.state.childName);
    _previousGrade = widget.appState.state.grade.clamp(1, 4);
    widget.appState.addListener(_profileChanged);
    // Capture before the first asynchronous operation, including profile names.
    unawaited(_load(widget.appState.captureLearningProfile()));
  }

  bool _current() {
    final owner = _owner;
    return mounted &&
        !_stale &&
        owner != null &&
        !widget.appState.resetting &&
        widget.appState.profileGeneration == _generation &&
        widget.appState.canUseLearningLease(owner) &&
        widget.appState.school.cachedActiveStudentId ==
            (owner.logStudentId == 'self' ? null : owner.studentId);
  }

  void _profileChanged() {
    if (_stale || widget.appState.profileGeneration == _generation) return;
    _stale = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load(Future<LearningProfileLease> captured) async {
    try {
      _owner = await captured;
      if (!_current()) return;
      await _repository.resolve(
        ownerId: _owner!.studentId,
        isLocalProfile: _owner!.logStudentId == 'self',
        legacyName: _previousName.text,
        legacyGrade: _previousGrade,
        isCurrent: _current,
      );
      final storedName = _owner!.logStudentId == 'self'
          ? widget.appState.state.childName
          : await widget.appState.school.studentName(_owner!.studentId);
      final keys = await _repository.inspect(_owner!.studentId);
      if (!_current()) return;
      setState(() {
        _keys = keys;
        _ownerName = (storedName == null || storedName.isEmpty)
            ? 'dieses Kinderprofil'
            : storedName;
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _assign(BuildContext dialogContext) async {
    if (_busy || !_current()) return;
    final name = _previousName.text;
    final grade = _previousGrade;
    final ownerId = _owner!.studentId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Same adult confirmation convention as LegacyLearningDataCard; merely
      // opening this screen or choosing a name/year never claims an old key.
      final accepted = await showDialog<bool>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text('Älteren Stand für $_ownerName zuordnen?'),
          content: Text(
            'Bitte gib das Gerät einer erwachsenen Person.\n\n'
            'Damals verwendeter Name: „$name“\nDamals verwendete Klasse: $grade\n\n'
            'Als erwachsene Person bestätige ich, dass dieser ältere Spielstand '
            'zu $_ownerName gehört. Er bleibt getrennt vom aktuellen Stand. '
            'Er wird keinem weiteren Kind zugeordnet.\n\n'
            'Lumo kann hier nicht prüfen, ob unter diesen früheren Angaben '
            'bereits ein Spielstand gespeichert wurde.',
          ),
          actions: [
            TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen')),
            FilledButton(
              key: const ValueKey('native-game-legacy-confirm'),
              style: FilledButton.styleFrom(minimumSize: const Size(100, 48)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Als Erwachsene:r zuordnen'),
            ),
          ],
        ),
      );
      if (accepted != true || !_current()) return;
      await _repository.assignLegacy(
          ownerId: ownerId,
          previousName: name,
          previousGrade: grade,
          isCurrent: _current);
      final keys = await _repository.inspect(ownerId);
      if (_current()) setState(() => _keys = keys);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(BuildContext context, NativeLegacyGameKey legacy) async {
    if (_busy || !_current()) return;
    setState(() => _busy = true);
    try {
      await launchLumo3D(context,
          scene: _game,
          appState: widget.appState,
          grade: legacy.grade,
          subject: _subject,
          legacyGameKey: legacy.key);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) {
    final code = error is NativeProfileKeyException ? error.code : '';
    return switch (code) {
      'key-already-owned' =>
        'Dieser ältere Stand gehört bereits zu einem anderen Kinderprofil. '
            'Die Zuordnung wurde nicht geändert.',
      'already-primary' =>
        'Dieser Stand ist bereits der normale Spielstand dieses Profils. '
            'Du erreichst ihn direkt über die Spielewelt.',
      'profile-changed' =>
        'Das Kinderprofil wurde gewechselt. Öffne die Verwaltung erneut.',
      'damaged-registry' ||
      'missing-salt' =>
        'Die gespeicherte Zuordnung ist unvollständig. Alle vorhandenen '
            'Spielstände bleiben erhalten; es wurde nichts neu zugeordnet.',
      _ => 'Die Zuordnung konnte nicht gespeichert werden. '
          'Deine bisherigen Spielstände bleiben erhalten. Bitte versuche es erneut.',
    };
  }

  @override
  void dispose() {
    widget.appState.removeListener(_profileChanged);
    _previousName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LumoNightScope(
        child: Builder(
            builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Spielstände verwalten')),
                  body: SafeArea(
                      child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_stale)
                        const Text('Das aktive Kinderprofil wurde gewechselt. '
                            'Bitte gehe zurück und öffne die Spielstände erneut.')
                      else ...[
                        Text('Für $_ownerName',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        const Text(
                            'Der normale Spielstand bleibt bei diesem Kinderprofil, '
                            'auch wenn sich Name oder Klasse ändern. '
                            'Um ein anderes Kind zu wählen, gehe zuerst zur Profilzuordnung im Lehrerbereich.'),
                        if (_busy)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator()),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_error!,
                                  key: const ValueKey(
                                      'native-game-save-error'))),
                        if (_keys?.legacyAvailable == true) ...[
                          const SizedBox(height: 24),
                          Text('Älteren Stand zuordnen',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                              'Gib den Namen und die Klasse ein, mit denen das Spiel '
                              'früher gestartet wurde. Großschreibung und Leerzeichen müssen '
                              'genau stimmen. Es werden keine Dateien kopiert oder gelöscht.'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _previousName,
                            key: const ValueKey('native-game-previous-name'),
                            enabled: !_busy,
                            maxLength: 200,
                            decoration: const InputDecoration(
                                labelText: 'Damals verwendeter Name',
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: const ValueKey('native-game-previous-grade'),
                            initialValue: _previousGrade,
                            decoration: const InputDecoration(
                                labelText: 'Damals verwendete Klasse',
                                border: OutlineInputBorder()),
                            items: [
                              for (var grade = 1; grade <= 4; grade++)
                                DropdownMenuItem(
                                    value: grade, child: Text('$grade. Klasse'))
                            ],
                            onChanged: _busy
                                ? null
                                : (grade) =>
                                    setState(() => _previousGrade = grade!),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const ValueKey('native-game-legacy-assign'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48)),
                            onPressed: _busy ? null : () => _assign(context),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Diesen älteren Stand zuordnen'),
                          ),
                        ] else if (_keys != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                              'Keine frühere Spielstand-Kennung verfügbar. '
                              'Deine neuen Spiele verwenden das eigene Kinderprofil.'),
                        ],
                        if (_keys?.legacy.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          Text('Zugeordnete ältere Stände',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                              'Diese Stände werden nur hier geöffnet. Normale Spielstarts '
                              'verwenden weiterhin den aktuellen Stand. Falls unter den alten Angaben '
                              'keine Datei existiert, startet das gewählte Spiel neu.'),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: const ValueKey('native-game-legacy-scene'),
                            initialValue: _game,
                            decoration: const InputDecoration(
                                labelText: 'Spiel',
                                border: OutlineInputBorder()),
                            items: [
                              for (final game in _games.entries)
                                DropdownMenuItem(
                                    value: game.key, child: Text(game.value))
                            ],
                            onChanged: _busy
                                ? null
                                : (game) => setState(() => _game = game!),
                          ),
                          if (_game == 'jump') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _subject,
                              decoration: const InputDecoration(
                                  labelText: 'Damals gewähltes Fach',
                                  border: OutlineInputBorder()),
                              items: [
                                for (final subject in const [
                                  'Mathematik',
                                  'Deutsch',
                                  'Sachunterricht',
                                  'Logik'
                                ])
                                  DropdownMenuItem(
                                      value: subject, child: Text(subject))
                              ],
                              onChanged: _busy
                                  ? null
                                  : (subject) =>
                                      setState(() => _subject = subject!),
                            ),
                          ],
                          for (final legacy in _keys!.legacy)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton(
                                key: ValueKey(
                                    'native-game-legacy-open-${legacy.key}'),
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56)),
                                onPressed:
                                    _busy ? null : () => _open(context, legacy),
                                child: Text(
                                    '„${legacy.name}“, ${legacy.grade}. Klasse · ${_games[_game]} öffnen'),
                              ),
                            ),
                        ],
                      ],
                    ],
                  )),
                )),
      );
}
