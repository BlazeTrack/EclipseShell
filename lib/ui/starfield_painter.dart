import 'dart:math';
import 'package:flutter/material.dart';

class StarfieldPainter extends CustomPainter {
  final Random _rng = Random(12345);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var i = 0; i < 120; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final radius = _rng.nextDouble() * 1.6 + 0.4;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final eclipsePaint = Paint()..shader = RadialGradient(
      colors: [Colors.white24, Colors.transparent],
      stops: [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.2), radius: size.width * 0.18));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), size.width * 0.18, eclipsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
