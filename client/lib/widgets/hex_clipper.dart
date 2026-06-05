import 'package:flutter/material.dart';

/// Обрезка углов под «архитектурные» пузыри из макета.
class HexClipper extends CustomClipper<Path> {
  const HexClipper({this.cut = 10, this.mine = false});

  final double cut;
  final bool mine;

  @override
  Path getClip(Size size) {
    final c = cut.clamp(4.0, size.shortestSide / 4);
    if (mine) {
      return Path()
        ..moveTo(0, 0)
        ..lineTo(size.width - c, 0)
        ..lineTo(size.width, c)
        ..lineTo(size.width, size.height)
        ..lineTo(c, size.height)
        ..lineTo(0, size.height - c)
        ..close();
    }
    return Path()
      ..moveTo(c, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(covariant HexClipper oldClipper) =>
      oldClipper.cut != cut || oldClipper.mine != mine;
}
