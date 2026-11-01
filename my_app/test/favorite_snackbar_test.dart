import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// Ø¥Ø´Ø¹Ø§Ø± Â«ØªÙ…Øª Ø§Ù„Ø¥Ø²Ø§Ù„Ø© Ù…Ù† Ø§Ù„Ù…ÙØ¶Ù„Ø©Â» (ÙÙŠÙ‡ Ø²Ø± Â«ØªØ±Ø§Ø¬Ø¹Â»): Flutter Ù„Ø§ ÙŠØºÙ„Ù‚Ù‡ ÙˆØ­Ø¯Ù‡ Ø­ÙŠÙ† ØªØ¹Ù…Ù„ Ø®Ø¯Ù…Ø© ÙˆØµÙˆÙ„ ØªØªÙ†Ù‚Ù‘Ù„
/// Ø¨ÙŠÙ† Ø§Ù„Ø¹Ù†Ø§ØµØ± (Switch AccessØŒ TalkBack)ØŒ ÙÙƒØ§Ù† ÙŠØ¨Ù‚Ù‰ Ù…Ø¹Ù„Ù‘Ù‚Ø§Ù‹ Ø­ØªÙ‰ ÙŠÙØ³Ø­Ø¨ Ø¨Ø§Ù„ÙŠØ¯. Ø§Ù„Ø¢Ù† ÙŠÙØºÙ„Ù‚ Ø¨Ø¹Ø¯ 10 Ø«ÙˆØ§Ù†Ù ÙÙŠ Ù‡Ø°Ù‡
/// Ø§Ù„Ø­Ø§Ù„Ø©ØŒ ÙˆØ¨Ø¹Ø¯ 4 Ø«ÙˆØ§Ù†Ù ÙƒÙ…Ø§ ÙƒØ§Ù† ÙÙŠ ØºÙŠØ±Ù‡Ø§.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  /// Ø¥Ø·Ø§Ø±Ø§Øª Ù…ØªØªØ§Ù„ÙŠØ© (Ù„Ø§ pump ÙˆØ§Ø­Ø¯ Ø·ÙˆÙŠÙ„): Ø­Ø±ÙƒØªØ§ Ø§Ù„Ø¸Ù‡ÙˆØ± ÙˆØ§Ù„Ø§Ø®ØªÙØ§Ø¡ ØªØ­ØªØ§Ø¬Ø§Ù† Ø¥Ø·Ø§Ø±Ø§Øª Ø¨ÙŠÙ†Ù‡Ù…Ø§.
  Future<void> wait(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 100)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openFavorites(WidgetTester tester, {bool accessible = false}) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (accessible) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        accessibleNavigation: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    await tester.runAsync(() => registerFakes(loggedIn: true, locale: 'ar'));
    FavoritesController.ensureRegistered();
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        home: Scaffold(
          body: Center(
            child: TextButton(onPressed: () => Get.to(() => const FavoritesView()), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CourseAuroraCard), findsWidgets);
  }

  Future<void> removeFirst(WidgetTester tester) async {
    tester.widget<CourseAuroraCard>(find.byType(CourseAuroraCard).first).onFavoritePressed!();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await wait(tester, const Duration(milliseconds: 500));
    expect(find.text('favorite_removed'.tr), findsOneWidget);
  }

  Finder snack() => find.text('favorite_removed'.tr);

  testWidgets('normal phone: closes by itself after about 4 seconds', (tester) async {
    await openFavorites(tester);
    await removeFirst(tester);
    await wait(tester, const Duration(seconds: 3));
    expect(snack(), findsOneWidget, reason: 'still there before its 4 seconds');
    await wait(tester, const Duration(seconds: 2));
    expect(snack(), findsNothing);
    await wait(tester, const Duration(seconds: 2)); // مهلة الاحتياط تنتهي ولا تفعل شيئاً
  });

  testWidgets('accessibility service on (Switch Access): closes after 10 seconds instead of staying', (tester) async {
    await openFavorites(tester, accessible: true);
    await removeFirst(tester);
    await wait(tester, const Duration(seconds: 8));
    expect(snack(), findsOneWidget, reason: 'longer, to reach "undo"');
    await wait(tester, const Duration(seconds: 3));
    expect(snack(), findsNothing, reason: 'it used to stay until swiped away');
  });

  testWidgets('accessibility on, two removals in a row: the second one still closes', (tester) async {
    await openFavorites(tester, accessible: true);
    await removeFirst(tester);
    await wait(tester, const Duration(seconds: 2));
    await removeFirst(tester);
    await wait(tester, const Duration(seconds: 11));
    expect(snack(), findsNothing);
  });

  testWidgets('after going back to the previous screen it still closes', (tester) async {
    await openFavorites(tester, accessible: true);
    await removeFirst(tester);
    Get.back();
    await wait(tester, const Duration(seconds: 11));
    expect(find.text('open'), findsOneWidget);
    expect(snack(), findsNothing);
  });
}
