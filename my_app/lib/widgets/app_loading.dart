import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppLoaderSize { small, medium, large }

/// ثلاث نقاط نابضة — لودر خفيف بألوان العلامة (بدون مكتبات خارجية).
class AppDotsLoader extends StatefulWidget {
  const AppDotsLoader({
    super.key,
    this.color,
    this.size = AppLoaderSize.medium,
  });

  final Color? color;
  final AppLoaderSize size;

  @override
  State<AppDotsLoader> createState() => _AppDotsLoaderState();
}

class _AppDotsLoaderState extends State<AppDotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _dotSize {
    switch (widget.size) {
      case AppLoaderSize.small:
        return 5;
      case AppLoaderSize.medium:
        return 7;
      case AppLoaderSize.large:
        return 9;
    }
  }

  double get _gap {
    switch (widget.size) {
      case AppLoaderSize.small:
        return 4;
      case AppLoaderSize.medium:
        return 6;
      case AppLoaderSize.large:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index * 0.2) % 1.0;
            final wave = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
            final scale = 0.55 + wave * 0.45;
            final opacity = 0.35 + wave * 0.65;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: _gap / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// لودر صغير للأزرار و«تحميل المزيد».
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key, this.color, this.size = 16});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: AppDotsLoader(
          color: color ?? AppColors.primary,
          size: AppLoaderSize.small,
        ),
      ),
    );
  }
}

/// لودر مركزي بين الصفحات — حلقة ناعمة + نقاط العلامة.
class AppPageLoader extends StatefulWidget {
  const AppPageLoader({
    super.key,
    this.message,
    this.light = false,
  });

  final String? message;
  final bool light;

  @override
  State<AppPageLoader> createState() => _AppPageLoaderState();
}

class _AppPageLoaderState extends State<AppPageLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.light ? Colors.white : AppColors.primary;
    final ringColor = widget.light ? Colors.white54 : AppColors.primary.withValues(alpha: 0.22);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: AnimatedBuilder(
            animation: _ringController,
            builder: (_, __) {
              return CustomPaint(
                painter: _ArcRingPainter(
                  progress: _ringController.value,
                  color: accent,
                  trackColor: ringColor,
                ),
                child: Center(
                  child: AppDotsLoader(
                    color: accent,
                    size: AppLoaderSize.small,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.light ? Colors.white70 : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  _ArcRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 0.72,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
