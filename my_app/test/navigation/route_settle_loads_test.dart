import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/navigation/app_page_transition.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';
import 'package:my_app/theme/app_motion.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// كل صفحة تفاصيل/قائمة تُفتح فوق الرئيسية: ما لديها يظهر فوراً، وطلبات الشبكة تبدأ بعد انتهاء حركة
/// الفتح فقط (RouteSettle) — ولا تبدأ أبداً إن أُغلقت الصفحة قبل ذلك.
class _RouteCase {
  const _RouteCase(this.route, this.arguments, this.requests);

  final String route;
  final Object? Function() arguments;

  /// الطلبات التي تبدأها الصفحة عند فتحها (أسماء طرق المستودعات الوهمية).
  final List<String> requests;
}

final _cases = <_RouteCase>[
  _RouteCase(AppRoutes.courseDetails, () => sampleCourses().first, ['fetchCourseById']),
  _RouteCase(AppRoutes.instituteDetails, () => sampleInstitutes().first, ['fetchInstituteById']),
  _RouteCase(AppRoutes.instructorDetails, () => sampleInstructors().first, ['fetchInstructorById']),
  _RouteCase(AppRoutes.categoryCourses, () => {'id': 3, 'name': 'البرمجة'}, ['fetchCoursesPage']),
  _RouteCase(AppRoutes.instructorCourses, () => sampleInstructors().first, ['fetchInstructorCoursesPage']),
  _RouteCase(AppRoutes.privateInstructors, () => null, ['fetchInstructorsPage', 'fetchInstructorSubjectFilters']),
  _RouteCase(AppRoutes.instructorSubjectInstructors, () => {'key': 'spec:1', 'name': 'رياضيات'}, [
    'fetchInstructorsBySubject',
  ]),
  _RouteCase(AppRoutes.cityDetails, () => {'id': 1, 'name': 'دمشق'}, ['fetchInstitutesByCity']),
  _RouteCase(AppRoutes.notifications, () => null, ['fetchNotificationsPage']),
  _RouteCase(AppRoutes.search, () => null, ['fetchCategories']),
  _RouteCase(AppRoutes.payment, () => 11, ['fetchPaymentDetails']),
  _RouteCase(AppRoutes.favorites, () => null, ['fetchFavorites']),
];

void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    debugOnRebuildDirtyWidget = null;
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  Future<void> pumpApp(WidgetTester tester, {List<NavigatorObserver> observers = const []}) async {
    // 411 dp: هذا الاختبار عن توقيت الطلبات؛ تخطيط 360 dp تغطيه اختبارات التخطيط.
    tester.view.physicalSize = const Size(411 * 3, 820 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    fakePaymentJson = {
      'enrollment_id': 11,
      'payment_status': 'unpaid',
      'currency': 'SYP',
      'amount_due': 1250000,
      'advance_amount': 300000,
      'amount_paid': 0,
      'amount_remaining': 1250000,
      'advance_remaining': 300000,
      'shamcash': {'available': true, 'account_name': 'Skills Academy', 'address': 'SC-1'},
      'payments': [],
    };
    // كما في التطبيق: نفس الصفحات والانتقال ومراقب الحركة.
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        getPages: AppPages.pages,
        navigatorObservers: [RouteMotionObserver(), ...observers],
        customTransition: AppPageTransition(),
        transitionDuration: AppMotion.fast,
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pumpAndSettle();
    FakeApi.calls.clear();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  for (final c in _cases) {
    testWidgets('${c.route}: requests start after the opening transition, no Obx rebuild during it', (tester) async {
      await pumpApp(tester);
      var obxRebuilds = 0;
      Get.toNamed<void>(c.route, arguments: c.arguments());
      await tester.pump(); // أول إطار: الصفحة والمتحكّم موجودان، والحركة بدأت.
      expect(RouteMotion.isMoving, isTrue);
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (builtOnce && element.widget is ObxWidget) obxRebuilds++;
      };
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));
      expect(FakeApi.calls, isEmpty, reason: 'no request while ${c.route} is still animating in');
      expect(obxRebuilds, 0, reason: 'no data-driven rebuild of ${c.route} during its transition');
      debugOnRebuildDirtyWidget = null;

      await settle(tester);
      for (final request in c.requests) {
        expect(FakeApi.calls, contains(request), reason: '${c.route} loads after it settles');
      }
    });

    testWidgets('${c.route}: closed before the transition ends -> no request at all', (tester) async {
      await pumpApp(tester);
      Get.toNamed<void>(c.route, arguments: c.arguments());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      Get.back<void>();
      await settle(tester);
      expect(find.text('home'), findsOneWidget);
      for (final request in c.requests) {
        expect(FakeApi.calls, isNot(contains(request)), reason: '${c.route} was closed before it settled');
      }
    });
  }

  testWidgets('double tap on a card opens the page once', (tester) async {
    final pushed = <String?>[];
    await pumpApp(tester, observers: [_PushLog(pushed)]);
    final course = sampleCourses().first;
    // ضغطتان متتاليتان قبل أن يبدأ الانتقال.
    Get.toNamed<void>(AppRoutes.courseDetails, arguments: course);
    Get.toNamed<void>(AppRoutes.courseDetails, arguments: course);
    await settle(tester);
    expect(pushed.where((name) => name == AppRoutes.courseDetails), hasLength(1));
  });
}

class _PushLog extends NavigatorObserver {
  _PushLog(this.names);

  final List<String?> names;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
}
