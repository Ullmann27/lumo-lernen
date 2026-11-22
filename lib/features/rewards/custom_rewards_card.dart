import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/reward_shop_repository.dart';
import '../../core/reward_shop_session.dart';
import '../../domain/rewards/custom_reward_templates.dart';
import '../../domain/rewards/reward_shop.dart';
import '../../theme/lumo_visual_tokens.dart';

/// Parent-area entry. It does not load, create or redeem a voucher by opening
/// Settings, and it never changes microphone/camera/online permissions.
class CustomRewardsCard extends StatelessWidget {
  const CustomRewardsCard({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) => Card(
    color: LumoVisualTokens.glassRow,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Eigene Gutscheine', style: TextStyle(
            color: LumoVisualTokens.white, fontWeight: FontWeight.w900, fontSize: 19)),
        const SizedBox(height: 8),
        const Text('Gemeinsame Belohnungen selbst festlegen: Titel, Kategorie, '
            'Sterne und Mindestlevel.', style: TextStyle(color: LumoVisualTokens.muted)),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey('custom-rewards-open'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.card_giftcard_rounded),
          label: const Text('Eigene Gutscheine verwalten'),
          onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(
              builder: (_) => CustomRewardsScreen(appState: appState))),
        ),
      ]),
    ),
  );
}

class CustomRewardsScreen extends StatefulWidget {
  const CustomRewardsScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<CustomRewardsScreen> createState() => _CustomRewardsScreenState();
}

class _CustomRewardsScreenState extends State<CustomRewardsScreen> {
  late final RewardShopSession _session;

  @override
  void initState() {
    super.initState();
    _session = RewardShopSession(widget.appState);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _edit([CustomRewardDefinition? definition]) async {
    final owner = _session.owner;
    if (!_session.ready || _session.busy || owner == null) return;
    await showDialog<void>(context: context, barrierDismissible: false,
        builder: (_) => _CustomRewardEditor(session: _session,
            owner: owner, initial: definition));
  }

  Future<void> _toggle(CustomRewardDefinition definition) async {
    final owner = _session.owner;
    if (owner == null || _session.busy) return;
    final active = !definition.active;
    final confirmed = await showDialog<bool>(context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Gutschein wieder anbieten?' : 'Gutschein deaktivieren?'),
        content: Text('„${definition.title}“ ${active ? 'erscheint wieder' : 'erscheint nicht mehr'} '
            'im Belohnungs-Laden. Bereits bestätigte Einlösungen behalten ihren Titel und Preis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              child: Text(active ? 'Aktivieren' : 'Deaktivieren')),
        ],
      ));
    if (!mounted || confirmed != true) return;
    try {
      await _session.saveDefinition(definition.nextRevision(active: active), lease: owner);
    } catch (_) {
      // The session displays the actual write/identity error without claiming
      // that a failed platform reply confirmed durable storage.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Eigene Gutscheine')),
    body: AnimatedBuilder(animation: _session, builder: (context, _) {
      if (_session.loading) return const Center(child: CircularProgressIndicator());
      if (!_session.ready) {
        return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_session.error ?? 'Gutscheine konnten nicht geladen werden.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _session.load, child: const Text('Erneut laden')),
          ])));
      }
      final definitions = _session.profile!.currentDefinitions;
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Für ${_session.ownerName}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Diese Gutscheine gehören zu diesem Kinderprofil. Beim Einlösen '
              'bestätigt eine erwachsene Person die gemeinsame Belohnung.'),
          const SizedBox(height: 16),
          FilledButton.icon(key: const ValueKey('custom-reward-add'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _session.busy || widget.appState.backupBusy ? null : () => _edit(),
            icon: const Icon(Icons.add_rounded), label: const Text('Gutschein hinzufügen')),
          if (_session.error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_session.error!, key: const ValueKey('custom-rewards-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (definitions.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Noch keine eigenen Gutscheine. Du kannst auch eine Familienidee als Vorlage wählen.')),
          for (final definition in definitions) Card(
            key: ValueKey('custom-reward-${definition.id}'),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${definition.emoji} ${definition.title}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('${definition.category.label} · ${definition.cost} Sterne · '
                    'ab Level ${definition.minLevel}'),
                if (definition.description.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 6), child: Text(definition.description)),
                if (!definition.active) const Padding(padding: EdgeInsets.only(top: 6),
                    child: Text('Deaktiviert – bisherige Belege bleiben erhalten')),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    key: ValueKey('custom-reward-edit-${definition.id}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _session.busy ? null : () => _edit(definition),
                    icon: const Icon(Icons.edit_outlined), label: const Text('Bearbeiten')),
                  OutlinedButton.icon(
                    key: ValueKey('custom-reward-toggle-${definition.id}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _session.busy ? null : () => _toggle(definition),
                    icon: Icon(definition.active ? Icons.pause_circle_outline : Icons.play_circle_outline),
                    label: Text(definition.active ? 'Deaktivieren' : 'Aktivieren')),
                ]),
              ])),
          ),
        ]),
      ));
    }),
  );
}

class _CustomRewardEditor extends StatefulWidget {
  const _CustomRewardEditor({required this.session, required this.owner, this.initial});
  final RewardShopSession session;
  final LearningProfileLease owner;
  final CustomRewardDefinition? initial;

  @override
  State<_CustomRewardEditor> createState() => _CustomRewardEditorState();
}

class _CustomRewardEditorState extends State<_CustomRewardEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _emoji;
  late final TextEditingController _description;
  late final TextEditingController _cost;
  late final TextEditingController _level;
  late CustomRewardCategory _category;
  CustomRewardDefinition? _attempt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _title = TextEditingController(text: value?.title ?? '');
    _emoji = TextEditingController(text: value?.emoji ?? '🎁');
    _description = TextEditingController(text: value?.description ?? '');
    _cost = TextEditingController(text: value?.cost.toString() ?? '');
    _level = TextEditingController(text: value?.minLevel.toString() ?? '1');
    _category = value?.category ?? CustomRewardCategory.family;
  }

  @override
  void dispose() {
    for (final controller in [_title, _emoji, _description, _cost, _level]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() { _saving = true; _error = null; });
    try {
      widget.session.validateOwner(widget.owner);
      _attempt ??= CustomRewardDefinition(
        id: widget.initial?.id ?? RewardShopRepository.newDefinitionId(),
        revision: (widget.initial?.revision ?? 0) + 1,
        title: _title.text.trim(), emoji: _emoji.text.trim(),
        description: _description.text.trim(), cost: int.parse(_cost.text),
        minLevel: int.parse(_level.text), category: _category,
        active: widget.initial?.active ?? true,
      );
      await widget.session.saveDefinition(_attempt!, lease: widget.owner);
      if (mounted) Navigator.pop(context);
    } catch (failure) {
      if (mounted) setState(() => _error = RewardShopSession.messageFor(failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _integer(String? text, int maximum) {
    final number = int.tryParse(text ?? '');
    return number == null || number < 1 || number > maximum
        ? 'Bitte eine ganze Zahl von 1 bis $maximum eingeben.' : null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final current = widget.session.isCurrent(widget.owner);
      final editable = current && !_saving && _attempt == null;
      return PopScope(canPop: !_saving, child: AlertDialog(
        scrollable: true,
        title: Text(widget.initial == null ? 'Eigener Gutschein' : 'Gutschein bearbeiten'),
        content: SizedBox(width: 440, child: Form(key: _form, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min,
          children: [
            if (!current) const Text('Das Kinderprofil hat gewechselt. Bitte schließe diesen Dialog und öffne ihn erneut.'),
            if (widget.initial == null) ...[
              DropdownButtonFormField<int>(
                key: const ValueKey('custom-reward-template'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Familienidee übernehmen (optional)'),
                items: [for (var i = 0; i < customRewardTemplates.length; i++)
                  DropdownMenuItem(value: i, child: Text(customRewardTemplates[i].title))],
                onChanged: !editable ? null : (index) {
                  if (index == null) return;
                  final idea = customRewardTemplates[index];
                  setState(() {
                    _title.text = idea.title; _emoji.text = idea.emoji; _category = idea.category;
                  });
                },
              ),
              const Padding(padding: EdgeInsets.only(top: 6, bottom: 10),
                  child: Text('Den Sternpreis legst du selbst fest.')),
            ],
            TextFormField(key: const ValueKey('custom-reward-title'),
              controller: _title, enabled: editable, maxLength: 100,
              decoration: const InputDecoration(labelText: 'Titel'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Bitte einen Titel eingeben.' : null),
            TextFormField(key: const ValueKey('custom-reward-emoji'),
              controller: _emoji, enabled: editable, maxLength: 8,
              decoration: const InputDecoration(labelText: 'Symbol oder Emoji'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Bitte ein Symbol eingeben.' : null),
            DropdownButtonFormField<CustomRewardCategory>(
              key: ValueKey('custom-reward-category-${_category.name}'),
              initialValue: _category, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: [for (final category in CustomRewardCategory.values)
                DropdownMenuItem(value: category, child: Text(category.label))],
              onChanged: !editable ? null : (value) {
                if (value != null) setState(() => _category = value);
              }),
            const SizedBox(height: 12),
            TextFormField(key: const ValueKey('custom-reward-cost'),
              controller: _cost, enabled: editable, maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Preis in Sternen'),
              validator: (value) => _integer(value, 999999)),
            TextFormField(key: const ValueKey('custom-reward-level'),
              controller: _level, enabled: editable, maxLength: 5,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Mindestlevel'),
              validator: (value) => _integer(value, 25000)),
            TextFormField(key: const ValueKey('custom-reward-description'),
              controller: _description, enabled: editable, maxLength: 500, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Gemeinsame Vereinbarung (optional)')),
            const Text('Beim Einlösen bestätigt eine erwachsene Person den angezeigten Sternpreis.'),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, key: const ValueKey('custom-reward-editor-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ]))),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(key: const ValueKey('custom-reward-save'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _saving || !current ? null : _save,
            child: Text(_saving ? 'Speichert …' : _attempt == null ? 'Gutschein speichern' : 'Speichern erneut versuchen')),
        ],
      ));
    },
  );
}
