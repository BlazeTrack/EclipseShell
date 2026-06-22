import 'package:flutter/material.dart';

class StarfieldPainter extends CustomPainter {
  final List<Offset> stars;
  final Offset eclipseCenter;
  final double eclipseRadius;

  const StarfieldPainter({
    required this.stars,
    required this.eclipseCenter,
    required this.eclipseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (final star in stars) {
      final radius = 0.4 + (star.dx + star.dy) % 1.6;
      canvas.drawCircle(star, radius, paint);
    }

    final eclipsePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white24, Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: eclipseCenter, radius: eclipseRadius));

    canvas.drawCircle(eclipseCenter, eclipseRadius, eclipsePaint);
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.stars != stars ||
        oldDelegate.eclipseCenter != eclipseCenter ||
        oldDelegate.eclipseRadius != eclipseRadius;
  }
}
