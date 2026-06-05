import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/dialog_colors.dart';

class GeometricAvatar extends StatelessWidget {
  const GeometricAvatar({
    super.key,
    required this.label,
    this.userId,
    this.preset,
    this.radius = 24,
    this.backgroundColor,
  });

  final String label;
  final int? userId;
  final AvatarPreset? preset;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? _colorFor(userId ?? label.hashCode);
    final p = preset ?? AvatarPreset.letter;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CustomPaint(
        painter: _AvatarPainter(
          preset: p,
          color: color,
          label: label.isNotEmpty ? label[0].toUpperCase() : '?',
        ),
      ),
    );
  }

  static Color _colorFor(int seed) {
    const palette = [
      Color(0xFF9DAA88),
      Color(0xFF8FA4B8),
      Color(0xFFB8958A),
      Color(0xFFB8A888),
      Color(0xFFA898B8),
      Color(0xFFB8B088),
    ];
    return palette[seed.abs() % palette.length];
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.preset,
    required this.color,
    required this.label,
  });

  final AvatarPreset preset;
  final Color color;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    switch (preset) {
      case AvatarPreset.letter:
        canvas.drawCircle(center, r, Paint()..color = color);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.white,
              fontSize: r * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      case AvatarPreset.mountain:
        _shape(canvas, center, r, 3);
      case AvatarPreset.wave:
        _shape(canvas, center, r, 5);
      case AvatarPreset.lavender:
        _shape(canvas, center, r, 6);
      case AvatarPreset.leaf:
        _shape(canvas, center, r, 4);
    }
  }

  void _shape(Canvas canvas, Offset center, double r, int sides) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.preset != preset || oldDelegate.color != color;
}
