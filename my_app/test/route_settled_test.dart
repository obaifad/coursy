import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';

/// نافذة إذن الإشعارات بعد الحجز كانت تُطلب بعد إطار واحد، أثناء انتقال الصفحة، فلا تظهر على Android.
void main() {
  final navKey = GlobalKey<NavigatorState>();

  setUp(RouteMotion.resetForTest);
  tearDown(RouteMotion.resetForTest);

  /// المسار الأول يُعدّ انتقالاً كذلك: يُترك ليستقر قبل كل حالة.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navKey, navigatorObservers: [RouteMotionObserver()], home: const SizedBox()),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(RouteMotion.isMoving, isFalse);
  }

  Route<void> page(int ms) => PageRouteBuilder<void>(
    transitionDuration: Duration(milliseconds: ms),
    pageBuilder: (_, __, ___) => const SizedBox(),
  );

  /// الوقت يتقدّم إطاراً إطاراً كما في التطبيق (إطار واحد طويل لا يمثّل الواقع).
  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// يبدأ الانتظار ويُرجع دالة تقول هل اكتمل.
  bool Function() startWaiting({Duration maxWait = const Duration(seconds: 3)}) {
    var done = false;
    RouteMotion.whenSettled(maxWait: maxWait).then((_) => done = true);
    return () => done;
  }

  testWidgets('waits for the push it was called right after, then a quiet window', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(page(400));
    final done = startWaiting();

    await advance(tester, 350);
    expect(done(), isFalse, reason: 'still moving');
    await advance(tester, 300);
    expect(done(), isFalse, reason: 'transition just ended, quiet window not over');
    await advance(tester, 500);
    expect(done(), isTrue);
  });

  testWidgets('a second transition (payment after My Courses) restarts the quiet window', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(page(300));
    final done = startWaiting();

    await advance(tester, 500); // الأول انتهى، والهدوء لم يكتمل
    navKey.currentState!.push(page(300));
    await advance(tester, 400);
    expect(done(), isFalse);
    await advance(tester, 500);
    expect(done(), isTrue);
  });

  testWidgets('nothing moving: done after the quiet window only', (tester) async {
    await pumpApp(tester);
    final done = startWaiting();
    await advance(tester, 100);
    expect(done(), isFalse);
    await advance(tester, 400);
    expect(done(), isTrue);
  });

  testWidgets('never waits past maxWait', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(page(5000));
    final done = startWaiting(maxWait: const Duration(seconds: 1));
    await advance(tester, 1200);
    expect(done(), isTrue);
    await tester.pumpAndSettle();
  });
}
