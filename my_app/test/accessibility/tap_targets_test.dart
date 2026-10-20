import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// كل ما يُنقر مساحته 48×48dp على الأقل (إرشاد Android وأداة Accessibility Scanner).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  /// استثناء معروف: شارة التصنيف في صفحة الدورة (33dp) — تكبيرها يغيّر تباعد الرأس (قرار للمالك).
  String allowedBadge() => sampleCourses().first.categoryName!;

  Future<void> check(WidgetTester tester, Future<void> Function() setup, Widget Function() scene) async {
    final handle = tester.ensureSemantics();
    for (final locale in ['ar', 'en']) {
      for (final width in [360.0, 411.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        Get.locale = Locale(locale);
        await setup();
        await tester.pumpWidget(auditApp(child: scene(), locale: locale, scale: 1, boundaryKey: GlobalKey()));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        final result = await androidTapTargetGuideline.evaluate(tester);
        final small = (result.reason ?? '')
            .split('\n')
            .where((l) => l.startsWith('SemanticsNode'))
            .where((l) => !l.contains('label: "${allowedBadge()}"'))
            .toList();
        expect(small, isEmpty, reason: '$locale ${width.toInt()}dp: smaller than 48x48:\n${small.join('\n')}');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        Get.reset();
      }
    }
    tester.view.reset();
    handle.dispose();
  }

  for (final tab in [0, 2, 3]) {
    for (final loggedIn in [true, false]) {
      testWidgets('root tab $tab ${loggedIn ? 'user' : 'guest'}', (tester) async {
        await check(
          tester,
          () async {
            final tokens = await registerFakes(loggedIn: loggedIn, locale: Get.locale?.languageCode ?? 'ar');
            Get.put(HomeController(tokens));
            Get.put(CoursesController());
            Get.put(InstitutesController());
            Get.put(MyCoursesController());
            Get.put(RootController()).currentIndex.value = tab;
          },
          () => const RootView(),
        );
      });
    }
  }

  testWidgets('course details', (tester) async {
    await check(
      tester,
      () async {
        await registerFakes(loggedIn: true, locale: Get.locale?.languageCode ?? 'ar');
        Get.put(CourseDetailsController(), tag: 't').course.value = sampleCourses().first;
      },
      () => const CourseDetailsView(controllerTag: 't'),
    );
  });
}
