import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/core/navigation/app_navigation.dart';
import 'package:my_app/main.dart' as app;
import 'package:my_app/routes/app_routes.dart';

/// قياس الأداء على جهاز حقيقي/محاكي (وضع profile) — ليس اختبار وحدة.
///
/// flutter drive --profile --driver=test_driver/perf_driver.dart \
///   --target=integration_test/perf_flows_test.dart -d DEVICE_ID
///
/// كل مسار يُسجَّل بـ traceAction؛ المشغّل (test_driver/perf_driver.dart) يكتب ملخص الإطارات لكل مسار في
/// build/KEY.timeline_summary.json (متوسط/أسوأ زمن البناء والرسم، وعدد الإطارات فوق 16 ms).
/// يعمل على الخادم الحقيقي كضيف؛ الأرقام نسبية بين القياسات على الجهاز نفسه.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // كل الإطارات حقيقية (لا يُجمّع الاختبار الإطارات): ضروري لقياس الأداء.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Finder byTypeName(String name) => find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

  Future<void> wait(WidgetTester tester, int ms) => tester.pump(Duration(milliseconds: ms));

  Future<bool> waitFor(WidgetTester tester, bool Function() done, {int timeoutMs = 45000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < timeoutMs) {
      if (done()) return true;
      await tester.pump(const Duration(milliseconds: 50));
    }
    return done();
  }

  bool visible(Finder f) => f.evaluate().isNotEmpty;

  /// فتح أول عنصر ثم الرجوع بزر الرجوع (كالنظام)، مع انتظار يكفي للحركة وجلب البيانات.
  Future<void> openAndBack(WidgetTester tester, Finder target) async {
    await tester.tap(target.first, warnIfMissed: false);
    await wait(tester, 2200);
    await tester.binding.handlePopRoute();
    await wait(tester, 1200);
  }

  testWidgets('perf flows a-g', (tester) async {
    final report = <String, dynamic>{};
    final startup = Stopwatch()..start();
    unawaited(app.main());

    final reachedEntry = await waitFor(
      tester,
      () => const [AppRoutes.login, AppRoutes.onboarding, AppRoutes.root].contains(Get.currentRoute),
    );
    report['entry_route_ms'] = startup.elapsedMilliseconds;
    expect(reachedEntry, isTrue, reason: 'splash never left');
    if (Get.currentRoute != AppRoutes.root) AppNavigation.enterAsGuest();

    // a) أول محتوى حقيقي: بطاقة دورة على الرئيسية.
    final homeCards = byTypeName('CourseCard');
    final gotContent = await waitFor(tester, () => visible(homeCards));
    report['first_content_ms'] = startup.elapsedMilliseconds;
    report['first_content_found'] = gotContent;
    debugPrint('PERF_MARK first_content ${DateTime.now().toIso8601String()}');
    await wait(tester, 3000);

    // b) الرئيسية ← تصنيف ← رجوع
    final categoryTile = byTypeName('_CategoryGridTile');
    if (visible(categoryTile)) {
      await binding.traceAction(() => openAndBack(tester, categoryTile), reportKey: 'b_home_category');
    }

    // g1) تمرير الرئيسية
    final homeScroll = find.byType(Scrollable).first;
    await binding.traceAction(() async {
      for (var i = 0; i < 3; i++) {
        await tester.fling(homeScroll, const Offset(0, -500), 1800, warnIfMissed: false);
        await wait(tester, 700);
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(homeScroll, const Offset(0, 500), 1800, warnIfMissed: false);
        await wait(tester, 700);
      }
    }, reportKey: 'g1_home_scroll');

    // e) مدرّس ← تفاصيل ← رجوع (بطاقات المدرّسين الخصوصيين على الرئيسية)
    final instructorCard = byTypeName('PrivateInstructorMiniCard');
    if (!visible(instructorCard)) {
      await tester.scrollUntilVisible(instructorCard.first, 300, scrollable: homeScroll, maxScrolls: 30);
      await wait(tester, 600);
    }
    if (visible(instructorCard)) {
      await binding.traceAction(() => openAndBack(tester, instructorCard), reportKey: 'e_instructor_details');
    }

    // c) الدورات ← تفاصيل دورة ← رجوع
    AppNavigation.switchToTab(0);
    await waitFor(tester, () => visible(byTypeName('CourseAuroraCard')), timeoutMs: 20000);
    await wait(tester, 1500);
    final courseCard = byTypeName('CourseAuroraCard');
    if (visible(courseCard)) {
      await binding.traceAction(() => openAndBack(tester, courseCard), reportKey: 'c_course_details');
    }

    // g2) تمرير شبكة الدورات
    await binding.traceAction(() async {
      final grid = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(grid, const Offset(0, -600), 2000, warnIfMissed: false);
        await wait(tester, 700);
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(grid, const Offset(0, 600), 2000, warnIfMissed: false);
        await wait(tester, 700);
      }
    }, reportKey: 'g2_courses_scroll');

    // d) المعاهد ← تفاصيل معهد ← رجوع
    AppNavigation.switchToTab(1);
    await waitFor(tester, () => visible(byTypeName('InstituteListCard')), timeoutMs: 20000);
    await wait(tester, 1500);
    final instituteCard = byTypeName('InstituteListCard');
    if (visible(instituteCard)) {
      await binding.traceAction(() => openAndBack(tester, instituteCard), reportKey: 'd_institute_details');
    }

    // f) التبديل بين التبويبات الخمسة (الملف الشخصي للضيف يفتح الدخول، ثم رجوع)
    await binding.traceAction(() async {
      for (final tab in const [2, 0, 1, 3, 2, 3, 0, 1, 2]) {
        AppNavigation.switchToTab(tab);
        await wait(tester, 600);
      }
      AppNavigation.switchToTab(4);
      await wait(tester, 900);
      if (Get.currentRoute != AppRoutes.root) await tester.binding.handlePopRoute();
      await wait(tester, 900);
    }, reportKey: 'f_tabs');

    debugPrint('PERF_MARK end ${DateTime.now().toIso8601String()}');
    await wait(tester, 3000);
    binding.reportData = {...?binding.reportData, 'meta': report};
  });
}
