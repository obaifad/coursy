import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/home/views/home_view.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// بطاقات الدورات المتجاورة في الرئيسية: القصّتان الجانبيتان كانتا تُرسمان نصفهما خارج البطاقة، في فراغ
/// 12 فقط بين البطاقات، فتلتقي قصّة البطاقة بقصّة جارتها وتمحوان الظل بينهما (دائرة مدموجة)، والبطاقات
/// تبدو ملتصقة. الآن القصّة فتحة داخل جسم البطاقة نفسه، والمسافة 16.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> openHome(WidgetTester tester, String locale) async {
    Get.locale = Locale(locale);
    final tokens = await registerFakes(loggedIn: false, locale: locale);
    Get.put(HomeController(tokens));
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: const HomeView(), locale: locale, scale: 1, boundaryKey: GlobalKey()));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final locale in ['ar', 'en']) {
    testWidgets('neighbouring course cards: 16 apart, notches stay inside each card ($locale)', (tester) async {
      await openHome(tester, locale);
      final cards = find.byType(CourseCard);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(first.top, second.top, reason: 'the first two cards of the same row');
      final gap = locale == 'ar' ? first.left - second.right : second.left - first.right;
      expect(gap, moreOrLessEquals(16, epsilon: 0.01));

      for (final card in [cards.at(0), cards.at(1)]) {
        final body = find.descendant(of: card, matching: find.byKey(const ValueKey('ticket-body')));
        expect(tester.getRect(body), tester.getRect(card), reason: 'the notches are cut at the card edge');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
