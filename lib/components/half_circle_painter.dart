import 'dart:math';

import 'package:flutter/material.dart';

class HalfCirclePainter extends CustomPainter {
  final Color color; // Tambahkan parameter warna

  HalfCirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    // Paint paint = Paint()..color = Color(0x3396FFC6); // Sesuaikan warna dengan kebutuhan Anda
    canvas.drawArc(
      Rect.fromLTWH(-size.width / 2, -size.height / 2, size.width * 2, size.height * 2),
      0.5 * pi, // Mulai dari setengah lingkaran (90 derajat dalam radian)
      pi, // Gambar setengah lingkaran (180 derajat dalam radian)
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
