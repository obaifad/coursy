import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// علم الجمهورية العربية السورية الجديد: أخضر / أبيض / أسود وثلاث نجوم حمراء على الشريط الأبيض.
/// يُرسم برمجياً لأن إيموجي 🇸🇾 يظهر بالعلم القديم على كثير من الأجهزة (يتبع خط النظام).
class SyrianFlag extends StatelessWidget {
  const SyrianFlag({super.key, this.width = 36, this.borderRadius = AppRadius.xs});

  final double width;
  final double borderRadius;

  static const green = Color(0xFF007A3D);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const red = Color(0xFFCE1126);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Syria',
      child: Container(
        width: width,
        height: width * 2 / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: _SyrianFlagPainter()),
      ),
    );
  }
}

class _SyrianFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final band = size.height / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, band), Paint()..color = SyrianFlag.green);
    canvas.drawRect(Rect.fromLTWH(0, band, size.width, band), Paint()..color = SyrianFlag.white);
    canvas.drawRect(Rect.fromLTWH(0, band * 2, size.width, band), Paint()..color = SyrianFlag.black);

    final starPaint = Paint()..color = SyrianFlag.red;
    final outer = band * 0.36;
    final cy = size.height / 2;
    for (final dx in const [-0.22, 0.0, 0.22]) {
      canvas.drawPath(_star(Offset(size.width / 2 + size.width * dx, cy), outer), starPaint);
    }
  }

  Path _star(Offset center, double outer) {
    final inner = outer * 0.382;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
