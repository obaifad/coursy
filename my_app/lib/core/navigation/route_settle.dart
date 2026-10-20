import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'route_motion_builder.dart';

/// يؤجّل عملاً (عادةً جلب بيانات يبدّل الواجهة) إلى ما بعد انتهاء حركة الانتقال الجارية، كي لا يتغيّر
/// المحتوى والصفحة تتحرك (ولا تُعاد بناء الصفحة أثناء الحركة). بلا انتقال جارٍ: فوراً.
///
/// يعتمد على [RouteMotion] (مراقب المسارات) لا على حالة أنيميشن المسار: مسارات GetX تُبنى أول مرة وحالتها
/// «مكتملة» قبل أن تبدأ حركتها، فكان العمل يجري فوراً.
abstract final class RouteSettle {
  /// حدّ أقصى للانتظار كي لا يتعطّل العمل أبداً.
  static const Duration maxWait = Duration(milliseconds: 900);

  static void run(VoidCallback action) {
    if (!RouteMotion.isMoving) {
      action();
      return;
    }
    var done = false;
    Timer? timer;
    late VoidCallback listener;
    void finish() {
      if (done) return;
      done = true;
      timer?.cancel();
      RouteMotion.inMotion.removeListener(listener);
      action();
    }

    listener = () {
      if (!RouteMotion.isMoving) finish();
    };
    RouteMotion.inMotion.addListener(listener);
    timer = Timer(maxWait, finish);
  }
}

/// لمتحكّمات الصفحات: الجلب الأول بعد انتهاء حركة الفتح ([RouteSettle.run])، ولا يبدأ أبداً إن أُغلقت
/// الصفحة قبل ذلك (رجوع سريع) — طلب لصفحة لم تعد موجودة يهدر الشبكة ويكتب في متحكّم مغلق.
mixin SettledLoad on GetxController {
  void afterRouteSettles(VoidCallback work) => RouteSettle.run(() {
    if (!isClosed) work();
  });
}
