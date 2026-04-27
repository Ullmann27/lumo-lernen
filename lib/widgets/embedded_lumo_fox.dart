import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EmbeddedLumoFox extends StatelessWidget {
  const EmbeddedLumoFox({super.key, required this.size});
  final double size;

  static final Uint8List _bytes = base64Decode(_data);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .10),
      child: Image.memory(
        _bytes,
        width: size,
        height: size * 1.45,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

const String _data = '<DATA_PLACEHOLDER>';