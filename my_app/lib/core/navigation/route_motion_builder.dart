import 'dart:async';

import 'package:flutter/widgets.dart';

/// هل يجري الآن انتقال صفحة (فتح أو إغلاق)؟ يغذّيه [RouteMotionObserver]. لا يُعتمد على
/// `secondaryAnimation` للمسار السفلي: لا يتحرك حين يختلف نوعا المسارين (مثل صفحات GetX فوق الرئيسية).
abstract final class RouteMotion {
  static final ValueNotifier<bool> inMotion = ValueNotifier<bool>(false);
  static final Set<Timer> _timers = {};

  /// هامش بعد انتهاء المدة المعلنة للانتقال (آخر إطار + هبوط Hero).
  static const Duration _tail = Duration(milliseconds: 60);

  /// الانتقال يُعدّ جارياً طوال مدة المسار المعلنة. المدة لا حالة الأنيميشن: حالة أنيميشن مسارات GetX
  /// تتبدّل فور الدفع (completed قبل أول إطار) فلا يُعوَّل عليها.
  static void watch(Route<dynamic>? route, {required bool opening}) {
    if (route is! TransitionRoute) return;
    final duration = opening ? route.transitionDuration : route.reverseTransitionDuration;
    if (duration == Duration.zero) return;
    late Timer timer;
    timer = Timer(duration + _tail, () {
      _timers.remove(timer);
      inMotion.value = _timers.isNotEmpty;
    });
    _timers.add(timer);
    // بعد انتهاء الحدث الحالي: الإشعار أثناء البناء يرمي.
    scheduleMicrotask(() => inMotion.value = _timers.isNotEmpty);
  }

  static void resetForTest() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    inMotion.value = false;
  }
}

/// يُضاف إلى `navigatorObservers` ليعرف [RouteMotion] متى تبدأ حركة الانتقال وتنتهي.
class RouteMotionObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => RouteMotion.watch(route, opening: true);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => RouteMotion.watch(route, opening: false);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => RouteMotion.watch(newRoute, opening: true);
}

/// يبني بحسب كون انتقال صفحة جارياً الآن، لتعطيل المؤثرات المكلفة (التمويه الحقيقي) أثناء الحركة فقط
/// وإعادتها حين تستقر الصفحة.
class RouteMotionBuilder extends StatelessWidget {
  const RouteMotionBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool inMotion) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: RouteMotion.inMotion,
    builder: (context, inMotion, _) => builder(context, inMotion),
  );
}
