import 'package:flutter/material.dart';

class EmbeddedLumoFox extends StatelessWidget {
  const EmbeddedLumoFox({super.key, required this.size});
  final double size;

  static const String jpgAssetPath = 'assets/images/lumo_fox.jpg';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      jpgAssetPath,
      width: size,
      height: size * 1.42,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _SafeFoxPlaceholder(size: size),
    );
  }
}

class _SafeFoxPlaceholder extends StatelessWidget {
  const _SafeFoxPlaceholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.3,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC80).withOpacity(0.35),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🦊', style: TextStyle(fontSize: 80)),
          SizedBox(height: 12),
          Text(
            'Lumo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}
