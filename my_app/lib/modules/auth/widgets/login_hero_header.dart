import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';
import 'login_page_metrics.dart';

/// رأس شاشة الدخول — خلفية متدرجة موحّدة + شعار + ترحيب.
class LoginHeroHeader extends StatelessWidget {
  const LoginHeroHeader({super.key, required this.metrics});

  final LoginPageMetrics metrics;

  static const _headerGradient = LinearGradient(
    colors: [Color(0xFFF8F6FF), Color(0xFFEFEAFF), Color(0xFFE4DCFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    if (metrics.compactHeader) {
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          metrics.horizontalPadding,
          metrics.headerTopPadding,
          metrics.horizontalPadding,
          metrics.headerBottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(height: metrics.logoHeight, alignment: Alignment.center),
                SizedBox(height: metrics.sectionGap * 0.75),
                Text(
                  'login_welcome_back'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: metrics.welcomeTitleSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'app_tagline'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: metrics.welcomeSubtitleSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipPath(
      clipper: const _LoginHeaderCurveClipper(),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _headerGradient),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            metrics.horizontalPadding,
            metrics.headerTopPadding,
            metrics.horizontalPadding,
            metrics.headerBottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: AppLogo(height: metrics.logoHeight, alignment: Alignment.center),
              ),
              SizedBox(height: metrics.sectionGap * 0.9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LoginSecurityIllustration(size: metrics.illustrationSize),
                  SizedBox(width: metrics.sectionGap * 0.75),
                  Expanded(
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: _LoginWelcomeCopy(metrics: metrics),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHeaderCurveClipper extends CustomClipper<Path> {
  const _LoginHeaderCurveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 28);
    path.quadraticBezierTo(size.width * 0.5, size.height + 18, size.width, size.height - 28);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LoginWelcomeCopy extends StatelessWidget {
  const _LoginWelcomeCopy({required this.metrics});

  final LoginPageMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'login_welcome_back'.tr,
          style: GoogleFonts.tajawal(
            fontSize: metrics.welcomeTitleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B4B),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'app_tagline'.tr,
          style: GoogleFonts.tajawal(
            fontSize: metrics.welcomeSubtitleSize,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// رسمة القفل/الدرع لشاشات الدخول والتسجيل.
class AuthSecurityIllustration extends StatelessWidget {
  const AuthSecurityIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SecurityIllustrationPainter(),
      ),
    );
  }
}

class _LoginSecurityIllustration extends StatelessWidget {
  const _LoginSecurityIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AuthSecurityIllustration(size: size);
  }
}

class _SecurityIllustrationPainter extends CustomPainter {
  static ui.Gradient _linear3(Offset start, Offset end, List<Color> colors) {
    return ui.Gradient.linear(start, end, colors, const [0.0, 0.5, 1.0]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.56);
    final scale = size.width / 132;

    _drawOrbitArc(canvas, center, 58 * scale, -2.4, -0.6);
    _drawOrbitArc(canvas, center, 46 * scale, 2.5, 3.2);
    _drawSoftGlow(canvas, center, 50 * scale);

    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 38 * scale), width: 72 * scale, height: 16 * scale),
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(0, 38 * scale),
          36 * scale,
          [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ),
    );

    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, 6 * scale),
        width: 60 * scale,
        height: 68 * scale,
      ),
      Radius.circular(20 * scale),
    );
    _drawLockBody(canvas, lockRect, scale);
    _drawShield(canvas, Offset(lockRect.left + 2 * scale, lockRect.bottom - 30 * scale), scale);
  }

  void _drawOrbitArc(Canvas canvas, Offset center, double radius, double start, double end) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      end - start,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary.withValues(alpha: 0.18),
    );
  }

  void _drawSoftGlow(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            const Color(0xFFB8AEFF).withValues(alpha: 0.45),
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.0),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  void _drawLockBody(Canvas canvas, RRect body, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(body.outerRect.shift(Offset(0, 14 * scale)), body.tlRadius),
      Paint()
        ..color = const Color(0xFF4A3FD9).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..shader = _linear3(
          body.outerRect.topLeft,
          body.outerRect.bottomRight,
          const [Color(0xFFB8AEFF), Color(0xFF7B72FF), Color(0xFF5548CC)],
        ),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + 6 * scale, body.top + 6 * scale, body.width - 12 * scale, body.height * 0.38),
        Radius.circular(14 * scale),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          body.outerRect.topLeft,
          Offset(body.right, body.top + 20 * scale),
          [Colors.white.withValues(alpha: 0.50), Colors.white.withValues(alpha: 0.0)],
        ),
    );

    final shackleCenter = Offset(body.center.dx, body.top - 6 * scale);
    final shackleRect = Rect.fromCenter(center: shackleCenter, width: 36 * scale, height: 36 * scale);
    canvas.drawArc(
      shackleRect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * scale
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          shackleRect.topLeft,
          shackleRect.bottomRight,
          const [Color(0xFFD4CCFF), Color(0xFF7B72FF)],
        ),
    );

    final keyholePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(body.center.translate(0, 2 * scale), 6.5 * scale, keyholePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: body.center.translate(0, 15 * scale), width: 8 * scale, height: 13 * scale),
        Radius.circular(4 * scale),
      ),
      keyholePaint,
    );
  }

  void _drawShield(Canvas canvas, Offset topLeft, double scale) {
    final cx = topLeft.dx + 24 * scale;
    final cy = topLeft.dy + 18 * scale;
    final path = Path()
      ..moveTo(cx, cy - 26 * scale)
      ..quadraticBezierTo(cx + 30 * scale, cy - 22 * scale, cx + 28 * scale, cy + 2 * scale)
      ..quadraticBezierTo(cx + 26 * scale, cy + 30 * scale, cx, cy + 36 * scale)
      ..quadraticBezierTo(cx - 26 * scale, cy + 30 * scale, cx - 28 * scale, cy + 2 * scale)
      ..quadraticBezierTo(cx - 30 * scale, cy - 22 * scale, cx, cy - 26 * scale)
      ..close();

    canvas.save();
    canvas.translate(3 * scale, 6 * scale);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A3FD9).withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * scale),
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy - 26 * scale),
          Offset(cx, cy + 36 * scale),
          [const Color(0xFFFFFFFF), const Color(0xFFE8E2FF)],
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = AppColors.primary.withValues(alpha: 0.25),
    );

    final check = Path()
      ..moveTo(cx - 9 * scale, cy + 2 * scale)
      ..lineTo(cx - 2 * scale, cy + 12 * scale)
      ..lineTo(cx + 12 * scale, cy - 6 * scale);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF16A34A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
