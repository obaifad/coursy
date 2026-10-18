import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// انتقال الصفحات الموحّد: تلاشٍ مع صعود قصير (3%) — كانتقال أندرويد القياسي، بلا Hero ولا تكبير.
/// الصعود تحويل فقط (رخيص على خيط الرسم)، والمدة قصيرة ([AppMotion.fast]) كي يبدو التنقل فورياً.
class AppPageTransition extends CustomTransition {
  static final Animatable<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(position: animation.drive(_rise), child: child),
    );
  }
}
