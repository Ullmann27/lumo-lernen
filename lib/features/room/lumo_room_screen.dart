import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_room_repository.dart';
import '../../core/lumo_room_session.dart';
import '../../core/lumo_voice.dart';
import '../../domain/room/lumo_room.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

class LumoRoomCard extends StatelessWidget {
  const LumoRoomCard({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) => Card(
        color: LumoVisualTokens.glassRow,
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Lumos Zimmer',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Lumo besuchen und sein Zimmer gestalten.',
                      style: TextStyle(color: LumoVisualTokens.muted)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      key: const ValueKey('lumo-room-open'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                              builder: (_) =>
                                  LumoRoomScreen(appState: appState))),
                      icon: const Icon(Icons.cottage_rounded),
                      label: const Text('Zimmer öffnen')),
                ])),
      );
}

class LumoRoomScreen extends StatefulWidget {
  const LumoRoomScreen({super.key, required this.appState});
  final LumoAppState appState;
  @override
  State<LumoRoomScreen> createState() => _LumoRoomScreenState();
}

class _LumoRoomScreenState extends State<LumoRoomScreen> {
  late final LumoRoomSession _session;
  final _character = LumoCharacterController();
  Timer? _clock;
  bool _promptOpen = false;
  String _line = 'Schön, dass du mich besuchst!';

  @override
  void initState() {
    super.initState();
    _session = LumoRoomSession(widget.appState)..addListener(_changed);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session.nextPraise != null) setState(() {});
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    _session.removeListener(_changed);
    _session.dispose();
    _character.dispose();
    super.dispose();
  }

  void _react(String text, {bool dance = false}) {
    if (!mounted) return;
    setState(() => _line = text);
    if (dance) {
      _character.cheer();
    } else {
      _character.wiggle();
    }
    if (widget.appState.state.settings.voiceEnabled) {
      unawaited(LumoVoice.instance.speak(text));
    }
  }

  Future<bool> _confirm(
          String title, String explanation, String button) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  scrollable: true,
                  title: Text(title),
                  content: Text(explanation),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Abbrechen')),
                    FilledButton(
                        key: const ValueKey('room-price-confirm'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(button)),
                  ])) ??
      false;

  Future<void> _buy(LumoRoomItem item) async {
    final owner = _session.owner;
    if (_promptOpen || _session.busy || owner == null) return;
    setState(() => _promptOpen = true);
    try {
      final yes = await _confirm(
          '${item.title} kaufen?',
          'Der Gegenstand kostet ${item.cost} Sterne und gehört danach zu deinem Zimmer. '
              'Anschließend kannst du ihn ausrüsten.',
          'Für ${item.cost} Sterne kaufen');
      if (!yes || !mounted) return;
      _session.guard(owner);
      if (await _session.buy(item, owner) &&
          mounted &&
          _session.isCurrent(owner)) {
        _react(
            '${item.title} gekauft! Jetzt kannst du den Gegenstand ausrüsten.');
      }
    } catch (failure) {
      _showFailure(failure);
    } finally {
      if (mounted) setState(() => _promptOpen = false);
    }
  }

  Future<void> _equip(LumoRoomItem item) async {
    final owner = _session.owner;
    if (owner == null || _session.busy || _promptOpen) return;
    try {
      if (await _session.equip(item, owner) &&
          mounted &&
          _session.isCurrent(owner)) {
        _react('${item.title} ist jetzt in deinem Zimmer aktiv.');
      }
    } catch (failure) {
      _showFailure(failure);
    }
  }

  Future<void> _act(LumoRoomActionKind kind,
      {LumoRoomActionRequest? pending}) async {
    final owner = _session.owner;
    if (owner == null || _session.busy || _promptOpen) return;
    if (pending == null &&
        kind == LumoRoomActionKind.pet &&
        (_session.nextPraise?.isAfter(DateTime.now()) ?? false)) {
      _react('Danke. Ich freue mich schon. Üben wir weiter?');
      return;
    }
    setState(() => _promptOpen = true);
    try {
      if (kind == LumoRoomActionKind.feed &&
          !await _confirm(
              'Fuchs-Snack geben?',
              'Der Snack kostet 10 Sterne. Dafür bekommst du 20 XP.',
              'Für 10 Sterne geben')) return;
      if (!mounted) return;
      _session.guard(owner);
      final request =
          pending ?? LumoRoomRepository.newAction(owner.studentId, kind);
      if (await _session.act(request, owner) &&
          mounted &&
          _session.isCurrent(owner)) {
        _react(kind == LumoRoomActionKind.pet
            ? 'Danke. Das motiviert mich. Fünf Sterne dazu.'
            : 'Mmmh, danke für den Fuchs-Snack. Zwanzig XP dazu.');
      }
    } catch (failure) {
      _showFailure(failure);
    } finally {
      if (mounted) setState(() => _promptOpen = false);
    }
  }

  void _showFailure(Object error) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LumoRoomSession.message(error))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF091A35),
        appBar: AppBar(title: const Text('Lumos Zimmer')),
        body: _session.loading
            ? const Center(child: CircularProgressIndicator())
            : !_session.ready
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              _session.error ??
                                  'Dein Zimmer konnte nicht geladen werden.',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _session.load,
                              child: const Text('Erneut laden')),
                        ])))
                : _content(context),
      );

  Widget _content(BuildContext context) {
    final disabled = _session.busy || _promptOpen || widget.appState.backupBusy;
    final next = _session.nextPraise;
    final remaining = next?.difference(DateTime.now()) ?? Duration.zero;
    final waiting = remaining > Duration.zero;
    return Center(
        child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('Für ${_session.ownerName}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(
                  '${_session.wallet!.stars} Sterne · ${_session.wallet!.xp} XP',
                  key: const ValueKey('room-wallet'),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: LumoVisualTokens.gold,
                      fontSize: 18)),
            ]),
        const SizedBox(height: 16),
        RepaintBoundary(
            key: const ValueKey('lumo-room-preview'),
            child: LumoRoomPreview(
                equipped: _session.equipped,
                theme: _session.theme,
                controller: _character,
                reduceMotion: widget.appState.state.settings.reduceAnimations ||
                    widget.appState.state.settings.calmMode ||
                    MediaQuery.disableAnimationsOf(context))),
        const SizedBox(height: 14),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF19355B),
                borderRadius: BorderRadius.circular(16)),
            child: Text(_line,
                key: const ValueKey('room-lumo-line'),
                style: const TextStyle(
                    fontFamily: 'Nunito', color: Colors.white, fontSize: 16))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
              key: const ValueKey('room-praise'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: disabled || _session.hasPending
                  ? null
                  : () => _act(LumoRoomActionKind.pet),
              icon: const Icon(Icons.favorite_rounded),
              label: Text(waiting ? 'Lumo loben' : 'Lumo loben · +5 Sterne')),
          OutlinedButton.icon(
              key: const ValueKey('room-feed'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
              onPressed:
                  disabled || _session.hasPending || _session.wallet!.stars < 10
                      ? null
                      : () => _act(LumoRoomActionKind.feed),
              icon: const Icon(Icons.restaurant_rounded),
              label: const Text('Fuchs-Snack · 10 Sterne')),
          OutlinedButton.icon(
              key: const ValueKey('room-dance'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
              onPressed: disabled
                  ? null
                  : () => _react('Tanzpause. Danach geht es frisch weiter.',
                      dance: true),
              icon: const Icon(Icons.music_note_rounded),
              label: const Text('Tanzpause')),
        ]),
        if (waiting)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                  remaining > const Duration(minutes: 5)
                      ? 'Der Sternbonus ist später wieder bereit.'
                      : 'Sternbonus wieder in ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  key: const ValueKey('room-praise-cooldown'),
                  style: const TextStyle(color: LumoVisualTokens.muted))),
        if (_session.error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_session.error!,
                  key: const ValueKey('room-error'),
                  style: const TextStyle(color: Colors.white))),
        for (final item in _session.pendingPurchases)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${item.title}: Kauf noch nicht abgeschlossen.'),
                        FilledButton(
                            onPressed: disabled ? null : () => _buy(item),
                            child: const Text('Kauf erneut bestätigen')),
                      ]))),
        for (final action in _session.pendingActions)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(action.kind == LumoRoomActionKind.pet
                            ? 'Dein Lob wartet noch aufs Speichern.'
                            : 'Dein Fuchs-Snack wartet noch aufs Speichern.'),
                        FilledButton(
                            onPressed: disabled
                                ? null
                                : () => _act(action.kind, pending: action),
                            child: const Text('Aktion erneut versuchen')),
                      ]))),
        const SizedBox(height: 24),
        const Text('Dein Zimmer gestalten',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (final item in LumoRoomCatalog.items) _itemCard(item, disabled),
      ]),
    ));
  }

  Widget _itemCard(LumoRoomItem item, bool disabled) {
    final owned = _session.owns(item);
    final active = item.kind == LumoRoomItemKind.theme
        ? _session.theme == item.id
        : _session.equipped.contains(item.id);
    return Card(
      key: ValueKey('room-item-${item.id}'),
      color: const Color(0xFF173052),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(item.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(item.title,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)))
            ]),
            const SizedBox(height: 8),
            Text(
                item.cost == 0
                    ? 'Von Anfang an dabei'
                    : owned
                        ? 'Gekauft'
                        : '${item.cost} Sterne',
                style: const TextStyle(color: LumoVisualTokens.muted)),
            const SizedBox(height: 10),
            FilledButton(
                key: ValueKey(
                    owned ? 'room-equip-${item.id}' : 'room-buy-${item.id}'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: disabled ||
                        active ||
                        (!owned &&
                            (_session.hasPending ||
                                _session.wallet!.stars < item.cost))
                    ? null
                    : owned
                        ? () => _equip(item)
                        : () => _buy(item),
                child: Text(active
                    ? 'Aktiv'
                    : owned
                        ? 'Ausrüsten'
                        : 'Für ${item.cost} Sterne kaufen')),
          ])),
    );
  }
}

/// A real local 2D room. Original Lumo artwork and an independently painted
/// scarf move together inside LumoCharacter; no global avatar is replaced.
class LumoRoomPreview extends StatelessWidget {
  const LumoRoomPreview(
      {super.key,
      required this.equipped,
      required this.theme,
      required this.controller,
      required this.reduceMotion});
  final Set<String> equipped;
  final String theme;
  final LumoCharacterController controller;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.2,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.maxHeight * .79;
          final scarf = equipped.contains('scarf_green')
              ? 'scarf_green'
              : equipped.contains('scarf_rose')
                  ? 'scarf_rose'
                  : 'scarf_blue';
          final color = scarf == 'scarf_green'
              ? const Color(0xFF35CE91)
              : scarf == 'scarf_rose'
                  ? const Color(0xFFF59AC6)
                  : const Color(0xFF55B9F0);
          return ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(children: [
                Positioned.fill(
                    child: CustomPaint(
                        key: ValueKey('room-theme-$theme'),
                        painter: _RoomBackdrop(theme == 'room_space'))),
                Positioned(
                    left: 16,
                    top: 14,
                    child: Text(
                        theme == 'room_space' ? 'Sternenraum' : 'Starterzimmer',
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontWeight: FontWeight.w900))),
                if (equipped.contains('rug'))
                  Positioned(
                      left: constraints.maxWidth * .18,
                      right: constraints.maxWidth * .15,
                      bottom: constraints.maxHeight * .035,
                      child: Container(
                          key: const ValueKey('room-equipped-rug'),
                          height: constraints.maxHeight * .16,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: const LinearGradient(colors: [
                                Color(0xFFDF863C),
                                Color(0xFFF2B561)
                              ]),
                              border: Border.all(
                                  color: const Color(0xFFFFD89A), width: 3)),
                          child: const Center(
                              child: Icon(Icons.auto_awesome_rounded,
                                  color: Color(0xFFFFEFCE))))),
                if (equipped.contains('plant'))
                  Positioned(
                      left: 10,
                      bottom: constraints.maxHeight * .12,
                      child: _RoomDecoration(
                          key: const ValueKey('room-equipped-plant'),
                          icon: Icons.local_florist_rounded,
                          color: const Color(0xFF70E6A7),
                          size: size * .30,
                          label: 'Lumo-Pflanze')),
                if (equipped.contains('star'))
                  Positioned(
                      right: 15,
                      top: constraints.maxHeight * .13,
                      child: _RoomDecoration(
                          key: const ValueKey('room-equipped-star'),
                          icon: Icons.star_rounded,
                          color: const Color(0xFFFFD878),
                          size: size * .23,
                          label: 'Sternlampe')),
                Positioned(
                    bottom: constraints.maxHeight * .055,
                    left: (constraints.maxWidth - size) / 2,
                    child: LumoCharacter(
                        key: const ValueKey('room-original-lumo'),
                        pose: LumoDesignFoxPose.armsOpen,
                        controller: controller,
                        size: size,
                        reduceMotion: reduceMotion,
                        intro: false,
                        idleHops: false,
                        child: SizedBox(
                            width: size,
                            height: size,
                            child: Stack(fit: StackFit.expand, children: [
                              Image.asset(LumoDesignFoxPose.armsOpen.assetPath,
                                  fit: BoxFit.contain,
                                  semanticLabel:
                                      'Original-Lumo mit blauer Brille und Jacke'),
                              CustomPaint(
                                  key: ValueKey('room-scarf-$scarf'),
                                  painter: _RoomScarf(color)),
                            ])))),
                if (equipped.contains('pet'))
                  Positioned(
                      right: 13,
                      bottom: constraints.maxHeight * .06,
                      child: _RoomDecoration(
                          key: const ValueKey('room-equipped-pet'),
                          icon: Icons.pets_rounded,
                          color: const Color(0xFFFFC7A0),
                          size: size * .25,
                          label: 'Mini-Haustier')),
              ]));
        }),
      );
}

class _RoomDecoration extends StatelessWidget {
  const _RoomDecoration(
      {super.key,
      required this.icon,
      required this.color,
      required this.size,
      required this.label});
  final IconData icon;
  final Color color;
  final double size;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [color.withValues(alpha: .30), Colors.transparent])),
          child: Icon(icon, size: size * .8, color: color)));
}

class _RoomBackdrop extends CustomPainter {
  const _RoomBackdrop(this.space);
  final bool space;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: space
                ? const [Color(0xFF351E65), Color(0xFF071C3C)]
                : const [Color(0xFF256C91), Color(0xFF102C53)],
          ).createShader(bounds));
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height * .78)
          ..lineTo(size.width * .5, size.height * .69)
          ..lineTo(size.width, size.height * .78)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
        Paint()..color = const Color(0xFF193753));
    if (space) {
      final paint = Paint()..color = const Color(0xFFFFE7B0);
      for (var i = 0; i < 32; i++) {
        final x = ((i * 37 + 11) % 97) / 97 * size.width;
        final y = ((i * 23 + 7) % 83) / 100 * size.height;
        canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 2.0 : 1.1, paint);
      }
      canvas.drawCircle(Offset(size.width * .82, size.height * .22),
          size.width * .07, Paint()..color = const Color(0xFFB4CAFF));
    } else {
      final window = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .67, size.height * .15, size.width * .20,
              size.height * .29),
          const Radius.circular(16));
      canvas.drawRRect(window, Paint()..color = const Color(0xFF67AEC7));
      canvas.drawRRect(
          window,
          Paint()
            ..color = const Color(0xFFB3E2F2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomBackdrop oldDelegate) =>
      space != oldDelegate.space;
}

class _RoomScarf extends CustomPainter {
  const _RoomScarf(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final tail = Path()
      ..moveTo(.60, .505)
      ..quadraticBezierTo(.67, .53, .67, .64)
      ..lineTo(.61, .66)
      ..quadraticBezierTo(.615, .56, .565, .54)
      ..close();
    canvas.drawShadow(tail, Colors.black, .01, false);
    canvas.drawPath(
        tail, Paint()..color = Color.lerp(color, Colors.black, .18)!);
    final wrap = Path()
      ..moveTo(.455, .49)
      ..quadraticBezierTo(.535, .525, .622, .475)
      ..lineTo(.647, .515)
      ..quadraticBezierTo(.55, .565, .456, .531)
      ..close();
    canvas.drawPath(wrap, Paint()..color = color);
    canvas.drawPath(
        Path()
          ..moveTo(.47, .514)
          ..quadraticBezierTo(.55, .542, .627, .504),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .008
          ..color = Colors.white.withValues(alpha: .35));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoomScarf oldDelegate) =>
      color != oldDelegate.color;
}
