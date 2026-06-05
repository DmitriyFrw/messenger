import 'package:flutter/material.dart';

import '../theme/dialog_colors.dart';

class LandscapeIllustration extends StatelessWidget {
  const LandscapeIllustration({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LandscapePainter(),
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()..color = const Color(0xFFF0E6C8);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.22), 18, sunPaint);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    _cloud(canvas, Offset(size.width * 0.62, size.height * 0.18), cloudPaint);
    _cloud(canvas, Offset(size.width * 0.72, size.height * 0.12), cloudPaint);

    _hill(canvas, size, 0.95, DialogColors.illustrationHill3, 0.55);
    _hill(canvas, size, 0.75, DialogColors.illustrationHill2, 0.42);
    _hill(canvas, size, 0.55, DialogColors.illustrationHill1, 0.32);

    final pathPaint = Paint()
      ..color = DialogColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.82,
        size.width * 0.9,
        size.height * 0.58,
      );
    canvas.drawPath(path, pathPaint);
  }

  void _hill(Canvas canvas, Size size, double base, Color color, double peak) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * base)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * (base - peak),
        size.width * 0.5,
        size.height * (base - peak * 0.6),
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * (base - peak * 0.35),
        size.width,
        size.height * (base - peak * 0.15),
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _cloud(Canvas canvas, Offset c, Paint paint) {
    canvas.drawCircle(c, 8, paint);
    canvas.drawCircle(c.translate(10, 2), 7, paint);
    canvas.drawCircle(c.translate(-8, 3), 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
