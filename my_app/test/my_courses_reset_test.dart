import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// «دوراتي» حيّة طوال الجلسة (IndexedStack): دخولها من تبويب آخر يعيدها إلى التبويب الفرعي الأول.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Future<RootController> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final tokens = await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(HomeController(tokens));
    Get.put(CoursesController());
    Get.put(InstitutesController());
    Get.put(MyCoursesController());
    final root = Get.put(RootController())..currentIndex.value = 3;
    await tester.pumpWidget(auditApp(locale: 'ar', scale: 1, boundaryKey: GlobalKey(), child: const RootView()));
    await tester.pump(const Duration(milliseconds: 600));
    return root;
  }

  int subTab(WidgetTester tester) => tester.widget<TabBar>(find.byType(TabBar)).controller!.index;

  testWidgets('leaving My Courses and coming back opens the first sub-tab', (tester) async {
    final root = await open(tester);
    expect(subTab(tester), 0);

    await tester.tap(find.text('tab_confirmed'.tr));
    await tester.pumpAndSettle();
    expect(subTab(tester), 1);

    root.changeTab(2);
    await tester.pump(const Duration(milliseconds: 300));
    root.changeTab(3);
    await tester.pump(const Duration(milliseconds: 300));
    expect(subTab(tester), 0, reason: 'back on «Pending», not on the last sub-tab');
  });

  testWidgets('tapping My Courses while already there does not reset the sub-tab', (tester) async {
    final root = await open(tester);
    await tester.tap(find.text('tab_done'.tr));
    await tester.pumpAndSettle();
    expect(subTab(tester), 2);

    root.changeTab(3);
    await tester.pump(const Duration(milliseconds: 300));
    expect(subTab(tester), 2);
  });

  testWidgets('coming from Profile (its "My courses" row) also resets', (tester) async {
    final root = await open(tester);
    await tester.tap(find.text('tab_cancelled'.tr));
    await tester.pumpAndSettle();
    expect(subTab(tester), 3);

    root.changeTab(4);
    await tester.pump(const Duration(milliseconds: 300));
    root.changeTab(3); // ما يفعله AppNavigation.switchToTab(3) من الملف الشخصي
    await tester.pump(const Duration(milliseconds: 300));
    expect(subTab(tester), 0);
  });
}
