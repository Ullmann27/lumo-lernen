import 'package:flutter/material.dart';
import '../scenes/place_value/place_value_scene_director.dart';
import '../scenes/place_value/zehner_werkstatt_view.dart';

export '../scenes/place_value/place_value_scene_director.dart'
    show LumoPlaceValueTransfer;

/// Voluntary offline workshop. Exploring the worked example is never a score.
/// A different number must be built AND explained before emitting evidence.
/// The rules live in [PlaceValueSceneDirector]; [ZehnerWerkstattView] only
/// renders its requests and reports the child's actions back as scene events.
class LumoPlaceValueWorkshop extends StatefulWidget {
  const LumoPlaceValueWorkshop(
      {super.key,
      required this.number,
      this.reduceMotion = false,
      this.sounds = false,
      this.onTransferChecked})
      : assert(number >= 10 && number <= 99);
  final int number;
  final bool reduceMotion;

  /// Subtle workshop sounds; the caller passes the app's sound setting.
  final bool sounds;
  final ValueChanged<LumoPlaceValueTransfer>? onTransferChecked;

  static int? numberForPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    if (!normalized.contains('zehner') && !normalized.contains('einer')) {
      return null;
    }
    final matches = RegExp(r'\b\d{2}\b').allMatches(normalized).toList();
    if (matches.length != 1) return null;
    return int.tryParse(matches.single.group(0)!);
  }

  @override
  State<LumoPlaceValueWorkshop> createState() => _LumoPlaceValueWorkshopState();
}

class _LumoPlaceValueWorkshopState extends State<LumoPlaceValueWorkshop> {
  late PlaceValueSceneDirector _director = _newDirector();

  PlaceValueSceneDirector _newDirector() => PlaceValueSceneDirector(
      number: widget.number,
      onTransferChecked: (result) => widget.onTransferChecked?.call(result));

  @override
  void didUpdateWidget(covariant LumoPlaceValueWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _director.dispose();
      _director = _newDirector();
    }
  }

  @override
  void dispose() {
    _director.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ZehnerWerkstattView(
      director: _director,
      reduceMotion: widget.reduceMotion,
      sounds: widget.sounds);
}
