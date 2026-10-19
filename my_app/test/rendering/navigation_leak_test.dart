import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/navigation/app_page_transition.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';
import 'package:my_app/theme/app_motion.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// 20 دورة فتح/إغلاق لصفحات التفاصيل: لا يبقى متحكّم مسجّلاً ولا صفحة في سجلّ الصفحات المفتوحة ولا مؤقّت
/// حركة — الذاكرة لا تتراكم مع التصفح الطويل.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  testWidgets('20 open/close cycles leave no page controller behind', (tester) async {
    tester.view.physicalSize = const Size(411 * 3, 820 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        getPages: AppPages.pages,
        navigatorObservers: [RouteMotionObserver()],
        customTransition: AppPageTransition(),
        transitionDuration: AppMotion.fast,
        home: const Scaffold(body: Text('home')),
      ),
    );

    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    final pages = [
      (AppRoutes.courseDetails, sampleCourses().first),
      (AppRoutes.instituteDetails, sampleInstitutes().first),
      (AppRoutes.instructorDetails, sampleInstructors().first),
    ];
    for (var cycle = 0; cycle < 20; cycle++) {
      final (route, args) = pages[cycle % pages.length];
      Get.toNamed<void>(route, arguments: args, preventDuplicates: false);
      await settle();
      Get.back<void>();
      await settle();
    }

    expect(find.text('home'), findsOneWidget);
    expect(CourseDetailsController.open, isEmpty, reason: 'course pages still registered as open');
    expect(InstituteDetailsController.open, isEmpty, reason: 'institute pages still registered as open');
    for (var i = 1; i <= 40; i++) {
      expect(Get.isRegistered<CourseDetailsController>(tag: 'course#$i'), isFalse);
      expect(Get.isRegistered<InstituteDetailsController>(tag: 'institute#$i'), isFalse);
      expect(Get.isRegistered<InstructorDetailsController>(tag: 'instructor#$i'), isFalse);
    }
    expect(RouteMotion.isMoving, isFalse, reason: 'transition timers left running');
  });
}
