import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/views/home_view.dart';
import 'package:my_app/modules/notifications/views/notifications_view.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// جرس الإشعارات بجانب زر الإعدادات في رأس الرئيسية: شاشة الإشعارات كانت لا تُفتح إلا بالضغط على إشعار.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> pumpHome(WidgetTester tester, {required bool loggedIn, String locale = 'ar'}) async {
    Get.locale = Locale(locale);
    final tokens = await registerFakes(loggedIn: loggedIn, locale: locale);
    Get.put(HomeController(tokens));
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: Locale(locale),
        getPages: AppPages.pages,
        home: const Scaffold(body: HomeView()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Rect circle(WidgetTester tester, IconData icon) =>
      tester.getRect(find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)).first);

  for (final locale in ['ar', 'en']) {
    testWidgets('student: bell beside settings, same size and line, settings still on the search edge ($locale)', (
      tester,
    ) async {
      await pumpHome(tester, loggedIn: true, locale: locale);
      final bell = circle(tester, Icons.notifications_rounded);
      final gear = circle(tester, Icons.settings_rounded);
      final search = tester.getRect(find.byType(AppHomeSearchBar));

      expect(bell.width, 40);
      expect((bell.center.dy - gear.center.dy).abs(), lessThan(0.5), reason: 'same centreline');
      expect(bell.right, lessThan(gear.left), reason: 'bell before settings, not overlapping');
      expect(gear.left - bell.right, inInclusiveRange(8, 16), reason: 'a clear but tight gap');
      expect(gear.right, moreOrLessEquals(search.right, epsilon: 0.5), reason: 'settings stays on the edge');
      await close(tester);
    });
  }

  testWidgets('tapping the bell opens the notifications screen', (tester) async {
    await pumpHome(tester, loggedIn: true);
    await tester.tap(find.byIcon(Icons.notifications_rounded));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NotificationsView), findsOneWidget);
    await close(tester);
  });

  testWidgets('guest: no bell (notifications belong to a student account)', (tester) async {
    await pumpHome(tester, loggedIn: false);
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    await close(tester);
  });

  testWidgets('screen readers announce the bell as its own button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester, loggedIn: true);
    expect(find.bySemanticsLabel('notifications'.tr), findsWidgets);
    semantics.dispose();
    await close(tester);
  });
}
