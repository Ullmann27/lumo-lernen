import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/legacy_learning_data.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';

/// The parent area is the single visible entry to resolve unowned learning data.
/// Merely opening it, choosing a child or dismissing the dialog never assigns it.
class LegacyLearningDataCard extends StatefulWidget {
  const LegacyLearningDataCard({
    super.key,
    required this.appState,
    this.refreshRevision = 0,
  });

  final LumoAppState appState;
  final int refreshRevision;

  @override
  State<LegacyLearningDataCard> createState() => _LegacyLearningDataCardState();
}

class _LegacyLearningDataCardState extends State<LegacyLearningDataCard> {
  final _repository = LegacyLearningDataRepository();
  LegacyLearningDataStatus? _status;
  List<_LearningOwnerChoice> _choices = const [];
  String? _selectedId;
  String? _error;
  bool _busy = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LegacyLearningDataCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRevision != widget.refreshRevision ||
        oldWidget.appState != widget.appState) {
      _load();
    }
  }

  Future<void> _load({bool clearError = true}) async {
    final generation = ++_loadGeneration;
    try {
      final status = await _repository.inspect();
      if (!status.hasData && status.problem == null) {
        if (mounted && generation == _loadGeneration) {
          setState(() {
            _status = status;
            _choices = const [];
            _selectedId = null;
            if (clearError) _error = null;
          });
        }
        return;
      }
      final directory = await widget.appState.school.load();
      final localId = await _repository.localStudentId();
      final localName = widget.appState.state.childName.trim();
      final choices = [
        _LearningOwnerChoice(
          localId,
          localName.isEmpty ? 'Geräteprofil' : localName,
          localName.isEmpty ? 'Geräteprofil' : '$localName (Geräteprofil)',
        ),
        for (final student in directory.students)
          _LearningOwnerChoice(
            student.id,
            student.name,
            '${student.name} · ${directory.classById(student.classId)?.name ?? 'Schulprofil'}',
          ),
      ];
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _status = status;
        _choices = choices;
        if (clearError) _error = null;
        if (status.pendingAssignment) {
          _selectedId = status.reservedStudentId;
        } else if (!choices.any((choice) => choice.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _error =
            'Der vorhandene Lernstand konnte gerade nicht gelesen werden. '
                'Bitte versuche es erneut.');
      }
    }
  }

  _LearningOwnerChoice? _choice(String? id) {
    for (final choice in _choices) {
      if (choice.id == id) return choice;
    }
    return null;
  }

  Future<void> _assign() async {
    final status = _status;
    final ownerId = _selectedId;
    final owner = _choice(ownerId);
    if (_busy ||
        ownerId == null ||
        owner == null ||
        status == null ||
        status.problem != null ||
        status.assignedStudentId != null) {
      return;
    }
    if (!status.canAssign &&
        !(status.pendingAssignment && status.reservedStudentId == ownerId)) {
      return;
    }
    final ownerName = owner.name;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text('Lernstand für $ownerName übernehmen?'),
          content: Text(
            'Bestätige als erwachsene Person, dass dieser bisherige Lernstand '
            'zu $ownerName gehört. Der vorhandene Lernkosmos wird ebenfalls '
            'diesem Kind zugeordnet.\n\n'
            'Die Zuordnung wechselt nicht das aktuell aktive Kind.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Als Erwachsene:r zuordnen'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.appState.resolveLegacyLearningData(ownerId);
      await _load();
      // The completed card is shorter than the form. Keep its confirmation in
      // view even when the parent scrolled down to the assignment button.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context);
      });
    } on LegacyLearningDataException catch (error) {
      if (mounted) setState(() => _error = _errorText(error.code));
      await _load(clearError: false);
    } catch (_) {
      if (mounted) setState(() => _error = _errorText('write-failed'));
      await _load(clearError: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(String code) => switch (code) {
        'assignment-busy' =>
          'Für dieses Kind wird gerade noch eine Antwort gespeichert. '
              'Bitte warte kurz und versuche die Zuordnung danach erneut.',
        'destination-not-empty' =>
          'Für dieses Kind gibt es bereits einen eigenen Lernstand. '
              'Es wird nichts überschrieben.',
        'reserved-for-another-student' =>
          'Die Zuordnung wurde bereits für ein anderes Kind begonnen. '
              'Bitte schließe diese Zuordnung zuerst ab.',
        'damaged-legacy' ||
        'damaged-claim' =>
          'Die älteren Lerndaten sind unvollständig. Sie bleiben erhalten, '
              'können aber noch nicht sicher zugeordnet werden.',
        'missing-legacy' => 'Es gibt keinen älteren Lernstand mehr zuzuordnen.',
        _ => 'Die Zuordnung konnte nicht gespeichert werden. '
            'Dein bisheriger Lernstand bleibt erhalten. Bitte versuche es erneut.',
      };

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if ((status == null || !status.hasData) &&
        _error == null &&
        status?.problem == null) {
      return const SizedBox.shrink();
    }
    final assigned = status?.assignedStudentId;
    final pending = status?.pendingAssignment ?? false;
    final selected = _choice(_selectedId);
    final problem = _error ??
        (pending && selected == null
            ? 'Das zuvor gewählte Kinderprofil ist nicht mehr verfügbar. '
                'Die bisherigen Daten bleiben erhalten. Bitte prüfe die Kinder '
                'im Lehrerbereich, bevor du die Zuordnung fortsetzt.'
            : null) ??
        (status?.problem == null ? null : _errorText(status!.problem!));
    final canAssign = !_busy &&
        problem == null &&
        selected != null &&
        ((status?.canAssign ?? false) ||
            (pending && _selectedId == status?.reservedStudentId));
    final ownerName = _choice(assigned)?.name ?? 'das gewählte Kind';

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: LumoGlassCard(
        key: const ValueKey('legacy-learning-assignment'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  assigned != null
                      ? Icons.check_circle_outline
                      : Icons.history_edu,
                  color: LumoVisualTokens.cyanBright,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assigned != null
                        ? 'Lernstand zugeordnet'
                        : 'Vorhandenen Lernstand zuordnen',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              assigned != null
                  ? 'Die bisherigen Lerndaten gehören jetzt zu $ownerName. '
                      'Jedes Kind führt seinen Lernfortschritt und Lernkosmos '
                      'im eigenen Profil weiter.'
                  : pending
                      ? 'Die Zuordnung zu ${selected?.name ?? 'dem zuvor gewählten Kind'} '
                          'wurde begonnen. Schließe sie ab, damit der Lernstand '
                          'für dieses Kind bereitsteht.'
                      : 'Auf diesem Gerät gibt es Lernfortschritt aus einer '
                          'älteren Version. Wähle das Kind, dem er gehört. '
                          'Sein vorhandener Lernkosmos wird mit übernommen.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                height: 1.45,
                color: Color(0xFFE2EFFA),
              ),
            ),
            if (assigned == null && status?.problem == null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('legacy-learning-child'),
                initialValue: selected?.id,
                isExpanded: true,
                isDense: false,
                menuMaxHeight: 360,
                itemHeight: null,
                decoration: const InputDecoration(
                  labelText: 'Kind auswählen',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Kind auswählen'),
                items: [
                  for (final choice in _choices)
                    DropdownMenuItem(
                      value: choice.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(choice.label, softWrap: true),
                      ),
                    ),
                ],
                onChanged: _busy || pending
                    ? null
                    : (value) => setState(() {
                          _selectedId = value;
                          _error = null;
                        }),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('legacy-learning-assign'),
                onPressed: canAssign ? _assign : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(
                  _busy
                      ? 'Wird geprüft …'
                      : pending
                          ? 'Zuordnung abschließen'
                          : 'Lernstand zuordnen',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (problem != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(problem,
                    style: const TextStyle(
                      color: Color(0xFFFFD6B1),
                      height: 1.4,
                    )),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Erneut prüfen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LearningOwnerChoice {
  const _LearningOwnerChoice(this.id, this.name, this.label);
  final String id;
  final String name;
  final String label;
}
