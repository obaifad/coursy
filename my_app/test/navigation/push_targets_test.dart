import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/navigation/push_navigation.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// الضغط على إشعار يفتح الصفحة الصحيحة دائماً — حتى لو كانت صفحة من النوع نفسه في الأعلى، وحتى لو
/// لم يصل من الإشعار إلا رقم المعرّف.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  Widget stubApp() => GetMaterialApp(
    initialRoute: '/start',
    getPages: [
      GetPage(name: '/start', page: () => const Text('start')),
      GetPage(name: AppRoutes.instituteDetails, page: () => Text('institute ${Get.arguments}')),
      GetPage(name: AppRoutes.instructorDetails, page: () => Text('instructor ${Get.arguments}')),
    ],
  );

  testWidgets('an institute push opens on top of another institute page', (tester) async {
    await tester.pumpWidget(stubApp());
    Get.toNamed<void>(AppRoutes.instituteDetails, arguments: 1);
    await tester.pumpAndSettle();

    PushNavigation.openFromMessageData({'type': 'institute_update', 'institute_id': '2'});
    await tester.pumpAndSettle();
    expect(find.text('institute 2'), findsOneWidget, reason: 'the push was ignored');

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('institute 1'), findsOneWidget);
  });

  testWidgets('an instructor push opens on top of another instructor page', (tester) async {
    await tester.pumpWidget(stubApp());
    Get.toNamed<void>(AppRoutes.instructorDetails, arguments: 1);
    await tester.pumpAndSettle();

    PushNavigation.openFromMessageData({'instructor_id': 3});
    await tester.pumpAndSettle();
    expect(find.text('instructor 3'), findsOneWidget, reason: 'the push was ignored');
  });

  testWidgets('an instructor page opened by id only (push) loads and shows that instructor', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'en');
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        getPages: AppPages.pages,
        navigatorObservers: [RouteMotionObserver()],
        home: const Scaffold(body: Text('home')),
      ),
    );
    final target = sampleInstructors()[1];

    PushNavigation.openFromMessageData({'instructor_id': '${target.id}'});
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(FakeApi.calls, containsAll(['fetchInstructorById', 'fetchInstructorCoursesPage']));
    expect(find.text(target.name), findsWidgets, reason: 'opened with an empty instructor page');
  });
}
