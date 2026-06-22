import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// انتقال ناعم بين الصفحات: fade + scale خفيف.
class AppFadeScaleTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
