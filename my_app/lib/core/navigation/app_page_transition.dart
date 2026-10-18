import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// انتقال ناعم بين الصفحات: تلاشٍ فقط. بلا تكبير: صورة Hero تحسب مكان هبوطها من الصفحة الجديدة عند بدء
/// الطيران، فكانت تهبط على الصفحة وهي مصغّرة (0.97) ثم تقفز إلى حجمها في آخر إطار.
class AppFadeTransition extends CustomTransition {
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
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    );
  }
}
