import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/widgets/course_image_hero.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// دفعة التحسينات: Hero صورة الدورة، أسماء الأزرار الأيقونية، شريط حالة البطاقة الصفّية، وجمع «يبدأ بعد».
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Widget host(Widget child) => GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('ar'),
    home: Scaffold(body: Center(child: child)),
  );

  group('course image hero', () {
    testWidgets('a real course id gets a Hero with the shared tag', (tester) async {
      await tester.pumpWidget(host(const CourseImageHero(courseId: 7, child: SizedBox(width: 10, height: 10))));
      expect(tester.widget<Hero>(find.byType(Hero)).tag, courseImageHeroTag(7));
    });

    testWidgets('skeleton cards (id 0) get no Hero, so identical tags never collide', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              CourseImageHero(courseId: 0, child: SizedBox(width: 10, height: 10)),
              CourseImageHero(courseId: 0, child: SizedBox(width: 10, height: 10)),
            ],
          ),
        ),
      );
      expect(find.byType(Hero), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('an icon-only circle button exposes its name as tooltip and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(AppIconCircleButton(onTap: () {}, icon: Icons.settings_outlined, semanticLabel: 'الإعدادات')),
    );
    expect(find.byTooltip('الإعدادات'), findsOneWidget);
    expect(find.bySemanticsLabel('الإعدادات'), findsWidgets);
    handle.dispose();
  });

  group('row card status bar', () {
    Widget card({Color? accent}) => host(
      SizedBox(
        width: 360,
        child: AppRowCard(
          accentColor: accent,
          leading: const ColoredBox(color: Colors.grey),
          title: const AppRowTitle('دورة'),
        ),
      ),
    );

    testWidgets('draws a thin bar in the given colour on the start edge', (tester) async {
      await tester.pumpWidget(card(accent: Colors.green));
      final bar = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == Colors.green,
      );
      expect(bar, findsOneWidget);
      expect(tester.getSize(bar).width, 4);
      // حافة البداية في العربية = اليمين.
      expect(tester.getRect(bar).right, closeTo(tester.getRect(find.byType(AppRowCard)).right, 1));
    });

    testWidgets('no accent colour, no bar (favorites and search rows are unchanged)', (tester) async {
      await tester.pumpWidget(card());
      expect(tester.getSize(find.byType(AppRowCard)).width, 360);
      final bars = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == Colors.green,
      );
      expect(bars, findsNothing);
    });
  });

  testWidgets('"starts in N days" uses the right Arabic plural forms', (tester) async {
    await tester.pumpWidget(host(const SizedBox()));
    expect(pluralTr('card_starts_in', 1), 'يبدأ بعد يوم واحد');
    expect(pluralTr('card_starts_in', 2), 'يبدأ بعد يومين');
    expect(pluralTr('card_starts_in', 5), 'يبدأ بعد 5 أيام');
    expect(pluralTr('card_starts_in', 15), 'يبدأ بعد 15 يوماً');
  });
}
