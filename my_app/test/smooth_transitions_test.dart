import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/core/navigation/route_settle.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// الانتقالات: تمويه البطاقة يتوقف أثناء الحركة ويعود بعدها، الجلب يتأخر إلى ما بعد الفتح،
/// وHero يطير بلا أخطاء مع كاش صورة واحد للبطاقة والغلاف.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    Get.reset();
    RouteMotion.resetForTest();
  });

  late CourseModel course;

  // الانتقال يُعدّ جارياً لمدته + هامش قصير: نتجاوزه كي يستقر كل شيء.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpHome(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    course = sampleCourses().first;
    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [RouteMotionObserver()],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              height: 240,
              child: CourseAuroraCard(course: course, onTap: () => Get.to<void>(() => page)),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Finder blur() => find.byType(BackdropFilter);

  testWidgets('Aurora panel: real blur when still, flat while a page opens or closes', (tester) async {
    await pumpHome(tester, const Scaffold(body: Text('details')));
    expect(blur(), findsOneWidget, reason: 'settled -> frosted glass');

    await tester.tap(find.byType(CourseAuroraCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(blur(), findsNothing, reason: 'page opening -> no BackdropFilter');

    await settle(tester);
    expect(find.text('details'), findsOneWidget);

    Get.back<void>();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(blur(), findsNothing, reason: 'page closing -> no BackdropFilter');

    await settle(tester);
    expect(blur(), findsOneWidget, reason: 'back and settled -> frosted glass again');
  });

  testWidgets('RouteSettle runs the work only after the opening animation ends', (tester) async {
    var runs = 0;
    await pumpHome(
      tester,
      Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {});
          return const Scaffold(body: Text('page'));
        },
      ),
    );
    // نفتح الصفحة، ونطلب العمل أثناء الحركة.
    await tester.tap(find.byType(CourseAuroraCard));
    await tester.pump();
    RouteSettle.run(() => runs++);
    await tester.pump(const Duration(milliseconds: 100));
    expect(runs, 0, reason: 'still animating');

    await settle(tester);
    expect(runs, 1, reason: 'ran once when the animation completed');
  });

  testWidgets('RouteSettle runs at once when no page animation is in flight', (tester) async {
    var runs = 0;
    await pumpHome(tester, const SizedBox());
    RouteSettle.run(() => runs++);
    expect(runs, 1);
  });
}
