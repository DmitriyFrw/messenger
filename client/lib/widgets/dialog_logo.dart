import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dialog_colors.dart';

class DialogLogo extends StatelessWidget {
  const DialogLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DialogLogoPainter(),
    );
  }
}

class _DialogLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();

    canvas.drawPath(
      hex,
      Paint()
        ..color = DialogColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05,
    );

    final barPaint = Paint()..color = DialogColors.textPrimary;
    final heights = [0.35, 0.55, 0.75, 0.5, 0.65];
    final barW = size.width * 0.07;
    final gap = size.width * 0.05;
    final totalW = heights.length * barW + (heights.length - 1) * gap;
    var x = center.dx - totalW / 2;
    for (final h in heights) {
      final barH = size.height * h * 0.55;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + barW / 2, center.dy), width: barW, height: barH),
          Radius.circular(barW / 2),
        ),
        barPaint,
      );
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
