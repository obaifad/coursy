import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/core/navigation/app_navigation.dart';
import 'package:my_app/main.dart' as app;
import 'package:my_app/routes/app_routes.dart';

/// الشبكة السيئة على الجهاز نفسه، مع الخادم المحلي (tool/fixture_api_server.dart) الذي يحقن الأعطال:
///
/// flutter drive --profile --no-dds --dart-define=API_BASE_URL=http://10.0.2.2:8787/api \
///   --driver=test_driver/integration_test.dart --target=integration_test/resilience_test.dart -d DEVICE_ID
///
/// لكل عطل: لا شاشة بيضاء، لا تحميل بلا نهاية، حالة خطأ مع «إعادة المحاولة»، والتعافي بعد عودة الخادم.
const _control = 'http://10.0.2.2:8787/__control';

Future<void> _mode(String mode, {int delayMs = 0}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('$_control?mode=$mode&delay_ms=$delayMs'));
    await (await request.close()).drain<void>();
  } finally {
    client.close(force: true);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Finder byTypeName(Set<String> names) => find.byWidgetPredicate((w) => names.contains(w.runtimeType.toString()));
  final homeContent = byTypeName(const {'_CategoryGridTile', 'CourseCard', 'InstituteMiniCard'});
  final retry = find.byWidgetPredicate(
    (w) => w is Text && const {'إعادة', 'إعادة المحاولة', 'Retry', 'Try again'}.contains(w.data),
  );

  Future<bool> waitFor(WidgetTester tester, bool Function() done, {int timeoutMs = 40000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < timeoutMs) {
      if (done()) return true;
      await tester.pump(const Duration(milliseconds: 100));
    }
    return done();
  }

  testWidgets('bad network: error + retry, recovery, cached data kept', (tester) async {
    final results = <String, Object?>{};
    // 1) الإقلاع والخادم يرد 500: الرئيسية تعرض الخطأ مع إعادة المحاولة (لا هيكل بلا نهاية).
    await _mode('fail500');
    unawaited(app.main());
    await waitFor(
      tester,
      () => const [AppRoutes.login, AppRoutes.onboarding, AppRoutes.root].contains(Get.currentRoute),
    );
    if (Get.currentRoute != AppRoutes.root) AppNavigation.enterAsGuest();
    results['launch_500_shows_retry'] = await waitFor(tester, () => retry.evaluate().isNotEmpty);
    results['launch_500_no_content'] = homeContent.evaluate().isEmpty;

    // 2) عاد الخادم: «إعادة المحاولة» تجلب البيانات.
    await _mode('ok');
    if (retry.evaluate().isNotEmpty) await tester.tap(retry.first, warnIfMissed: false);
    results['retry_recovers'] = await waitFor(tester, () => homeContent.evaluate().isNotEmpty);

    // 3) صفحة تصنيف والخادم يفشل (مهلة/ردّ مشوّه/فارغ): خطأ أو حالة فارغة، لا تحميل بلا نهاية.
    for (final mode in const ['drop', 'malformed', 'html403', 'empty']) {
      await _mode(mode);
      final tile = byTypeName(const {'_CategoryGridTile'});
      if (tile.evaluate().isEmpty) break;
      await tester.tap(tile.first, warnIfMissed: false);
      final settled = await waitFor(tester, () {
        final skeleton = find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Skeleton')).evaluate();
        return Get.currentRoute == AppRoutes.categoryCourses && skeleton.isEmpty;
      }, timeoutMs: 20000);
      results['category_$mode'] = settled
          ? (retry.evaluate().isNotEmpty ? 'error+retry' : 'empty/other')
          : 'still loading';
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
    }

    // 4) تحديث فاشل والبيانات ظاهرة: تبقى البيانات.
    await _mode('fail500');
    AppNavigation.switchToTab(1);
    await tester.pump(const Duration(seconds: 2));
    AppNavigation.switchToTab(2);
    await tester.pump(const Duration(seconds: 3));
    results['home_kept_after_failed_refresh'] = homeContent.evaluate().isNotEmpty;

    await _mode('ok');
    debugPrint('RESILIENCE_RESULTS $results');
    binding.reportData = {'resilience': results};
    expect(results['launch_500_shows_retry'], isTrue);
    expect(results['retry_recovers'], isTrue);
    expect(results['home_kept_after_failed_refresh'], isTrue);
    for (final mode in const ['drop', 'malformed', 'html403', 'empty']) {
      expect(results['category_$mode'], isNot('still loading'), reason: 'endless loading on $mode');
    }
  });
}
