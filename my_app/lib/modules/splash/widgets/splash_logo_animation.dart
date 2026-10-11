import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';

/// أنيميشن شعار Coursy: حلقة تُرسم بخط مضيء، أيقونات تعلّم تدور وتنجذب للمركز،
/// موجة ضوء ثم يظهر الشعار ويمرّ عليه لمعان واحد.
///
/// الأداء: `AnimationController` واحد يقود كل شيء، الرسم في `CustomPainter` معزول بـ
/// `RepaintBoundary`، الشعار يُبنى مرة واحدة (child) ولا يُعاد بناؤه كل إطار، والـ
/// `ShaderMask` لا يعمل إلا في المرحلة الأخيرة فقط.
class SplashLogoAnimation extends StatefulWidget {
  const SplashLogoAnimation({super.key, required this.progress});

  /// تقدّم الأنيميشن 0 → 1.
  final Animation<double> progress;

  static const double stageWidth = 280;
  static const double stageHeight = 200;
  static const double logoHeight = 88;

  @override
  State<SplashLogoAnimation> createState() => _SplashLogoAnimationState();
}

class _SplashLogoAnimationState extends State<SplashLogoAnimation> {
  /// لون اللمعان فوق الشعار الأبيض (بنفسجي فاتح يظهر على الأبيض).
  static const Color _shimmerTint = Color(0xFFA79DFF);

  static const _icons = [Icons.school_rounded, Icons.menu_book_rounded, Icons.star_rounded];

  late final List<TextPainter> _glyphs;
  late final Widget _logo;

  @override
  void initState() {
    super.initState();
    // تُجهَّز الأيقونات مرة واحدة (تخطيط النص مكلف لو تكرّر كل إطار).
    _glyphs = [
      for (final icon in _icons)
        TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(fontSize: 22, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    // الشعار أبيض (silhouette) على الخلفية البنفسجية: واضح بدون أي خلفية بيضاء خلفه.
    _logo = ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset(
        AppAssets.logo,
        height: SplashLogoAnimation.logoHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(AppAssets.logo), context);
  }

  @override
  void dispose() {
    for (final g in _glyphs) {
      g.dispose();
    }
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return curve.transform((t - a) / (b - a));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: SplashLogoAnimation.stageWidth,
        height: SplashLogoAnimation.stageHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(SplashLogoAnimation.stageWidth, SplashLogoAnimation.stageHeight),
              painter: _SplashRingPainter(progress: widget.progress, glyphs: _glyphs),
            ),
            AnimatedBuilder(
              animation: widget.progress,
              child: _logo,
              builder: (context, logo) {
                final t = widget.progress.value;
                final appear = _seg(t, 0.42, 0.72, Curves.easeOut);
                final scale = 0.82 + 0.18 * _seg(t, 0.42, 0.78, Curves.easeOutBack);
                final shimmer = _seg(t, 0.72, 1.0, Curves.easeInOut);

                Widget child = logo!;
                // اللمعان: طبقة shader واحدة وفي آخر مرحلة فقط.
                if (shimmer > 0 && shimmer < 1) {
                  child = ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _shimmerTint.withValues(alpha: 0),
                        _shimmerTint.withValues(alpha: 0.85),
                        _shimmerTint.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlideGradient(shimmer * 2 - 1),
                    ).createShader(rect),
                    child: child,
                  );
                }
                return Opacity(
                  opacity: appear,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// يزيح التدرّج أفقياً بنسبة من عرض المستطيل (−1 … 1).
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

class _SplashRingPainter extends CustomPainter {
  _SplashRingPainter({required this.progress, required this.glyphs}) : super(repaint: progress);

  final Animation<double> progress;
  final List<TextPainter> glyphs;

  static const double _ringRadius = 66;

  static double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return curve.transform((t - a) / (b - a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final c = size.center(Offset.zero);

    // 1) الحلقة تُرسم من الأعلى باتجاه عقارب الساعة ثم تتلاشى عند ظهور الشعار.
    final draw = _seg(t, 0.0, 0.40, Curves.easeInOutCubic);
    final ringFade = 1 - _seg(t, 0.42, 0.60);
    if (draw > 0 && ringFade > 0) {
      final rect = Rect.fromCircle(center: c, radius: _ringRadius);
      final sweep = 2 * math.pi * draw;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5
        ..color = Colors.white.withValues(alpha: 0.92 * ringFade);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, stroke);

      // شرارة عند رأس الخط.
      final a = -math.pi / 2 + sweep;
      final head = c + Offset(math.cos(a), math.sin(a)) * _ringRadius;
      canvas.drawCircle(
        head,
        7,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55 * ringFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(head, 3.2, Paint()..color = Colors.white.withValues(alpha: ringFade));
    }

    // 2) أيقونات التعلّم: تدور حول الحلقة ثم تنجذب إلى المركز وتختفي.
    final orbit = _seg(t, 0.10, 0.52);
    if (orbit > 0 && orbit < 1) {
      final pull = Curves.easeInCubic.transform(_seg(t, 0.30, 0.52));
      final radius = (_ringRadius + 10) * (1 - pull);
      final fadeIn = _seg(t, 0.10, 0.22);
      final fadeOut = 1 - _seg(t, 0.44, 0.52);
      final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
      final spin = orbit * math.pi * 1.4;
      for (var i = 0; i < glyphs.length; i++) {
        final ang = -math.pi / 2 + spin + i * 2 * math.pi / glyphs.length;
        final pos = c + Offset(math.cos(ang), math.sin(ang)) * radius;
        final g = glyphs[i];
        final scale = 0.7 + 0.3 * (1 - pull);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.scale(scale);
        canvas.saveLayer(
          Rect.fromCenter(center: Offset.zero, width: g.width + 8, height: g.height + 8),
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
        g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
        canvas.restore();
        canvas.restore();
      }
    }

    // 3) موجة ضوء تنتشر من المركز لحظة ظهور الشعار.
    final ripple = _seg(t, 0.46, 0.80, Curves.easeOutCubic);
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        c,
        _ringRadius + 120 * ripple,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - ripple) + 0.4
          ..color = Colors.white.withValues(alpha: 0.4 * (1 - ripple)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRingPainter old) => old.progress != progress || old.glyphs != glyphs;
}
