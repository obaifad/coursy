import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/core/navigation/app_navigation.dart';
import 'package:my_app/main.dart' as app;
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/routes/app_routes.dart';

/// زر الرجوع الحقيقي للنظام (KEYCODE_BACK من adb)، لا Navigator.pop من داخل الاختبار: على Android 16
/// مع targetSdk 36 يمرّ الرجوع عبر OnBackInvokedCallback (الرجوع التنبّئي) لا onBackPressed.
///
/// يطبع التطبيق `SYSBACK_READY <n>` في logcat؛ سكربت المضيف (scripts/drive_system_back.ps1) يرسل
/// `adb shell input keyevent 4` عند كل سطر، والاختبار يتحقق من المكان الذي وصل إليه.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<bool> waitFor(WidgetTester tester, bool Function() done, {int timeoutMs = 45000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < timeoutMs) {
      if (done()) return true;
      await tester.pump(const Duration(milliseconds: 50));
    }
    return done();
  }

  testWidgets('system back pops pages and returns to the Home tab', (tester) async {
    final results = <String, Object?>{};
    unawaited(app.main());
    await waitFor(
      tester,
      () => const [AppRoutes.login, AppRoutes.onboarding, AppRoutes.root].contains(Get.currentRoute),
    );
    if (Get.currentRoute != AppRoutes.root) AppNavigation.enterAsGuest();
    // أول عنصر بيانات ظاهر على الرئيسية (على الشاشات الصغيرة بطاقات الدورات أسفل الجزء المبني من القائمة).
    final firstContent = find.byWidgetPredicate(
      (w) => const {'_CategoryGridTile', 'CourseCard', 'InstituteMiniCard'}.contains(w.runtimeType.toString()),
    );
    expect(await waitFor(tester, () => firstContent.evaluate().isNotEmpty), isTrue);
    await tester.pump(const Duration(seconds: 2));

    // 1) صفحة فوق الرئيسية ← رجوع النظام ← الرئيسية
    await tester.tap(firstContent.first, warnIfMissed: false);
    await waitFor(tester, () => Get.currentRoute != AppRoutes.root, timeoutMs: 10000);
    results['opened'] = Get.currentRoute;
    await tester.pump(const Duration(seconds: 2));
    debugPrint('SYSBACK_READY 1');
    results['details_back_to_root'] = await waitFor(tester, () => Get.currentRoute == AppRoutes.root, timeoutMs: 20000);

    // 2) تبويب الدورات ← رجوع النظام ← تبويب الرئيسية (لا خروج من التطبيق)
    await tester.pump(const Duration(seconds: 1));
    AppNavigation.switchToTab(0);
    await tester.pump(const Duration(seconds: 2));
    debugPrint('SYSBACK_READY 2');
    final root = Get.find<RootController>();
    results['tab_back_to_home'] = await waitFor(tester, () => root.currentIndex.value == 2, timeoutMs: 20000);
    results['still_on_root'] = Get.currentRoute == AppRoutes.root;

    debugPrint('SYSBACK_RESULTS $results');
    binding.reportData = {'system_back': results};
    expect(results['details_back_to_root'], isTrue, reason: 'system back did not close the course page');
    expect(results['tab_back_to_home'], isTrue, reason: 'system back on a tab did not return to Home');
    expect(results['still_on_root'], isTrue);
  });
}
