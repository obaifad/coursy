import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// يؤجّل عملاً (عادةً جلب بيانات يبدّل الواجهة) إلى ما بعد انتهاء حركة فتح الصفحة الحالية، كي لا يتغيّر
/// المحتوى (هيكل ← بيانات) وهي تتحرك. بلا مسار انتقالي (اختبارات، صفحة أولى) أو بعد اكتمال الحركة: فوراً.
abstract final class RouteSettle {
  /// هامش بعد آخر إطار من الحركة.
  static const Duration _tail = Duration(milliseconds: 60);

  static void run(VoidCallback action) {
    final route = Get.routing.route;
    final animation = route is TransitionRoute ? route.animation : null;
    final waiting =
        animation != null &&
        (animation.status == AnimationStatus.forward || animation.status == AnimationStatus.dismissed);
    if (route is! TransitionRoute || !waiting) {
      action();
      return;
    }
    // المتبقي من الحركة بالزمن (لا بأحداث حالة الأنيميشن: حالة مسارات GetX تتبدّل فور الدفع).
    final remaining = route.transitionDuration * (1 - animation.value);
    Timer(remaining + _tail, action);
  }
}
