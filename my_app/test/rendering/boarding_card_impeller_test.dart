import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/widgets/app_widgets.dart';

import '../layout/layout_harness.dart';
import '../layout/sample_data.dart';

/// بطاقة «تذكرة الصعود» بلا قصّ بمسار معقّد (Path.combine + ClipPath) — نفس إصلاح بطاقة التذكرة: كان يُرسم
/// خطأً بمحرّك Impeller على بعض معالجات الرسوميات. الآن مستطيل مدوّر + دائرتان بلون الخلفية على خط الفصل.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  for (final (locale, rtl) in [('ar', true), ('en', false)]) {
    testWidgets('no path clip; two notch circles on the divider line ($locale)', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: Locale(locale),
          builder: (context, child) =>
              Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: CourseBoardingCard(course: sampleCourses().first),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Material(transparency) يضيف ClipPath بلا قصّ (Clip.none) — لا يُرسم. المطلوب: لا قصّ فعلي بمسار.
      final realPathClips = find.descendant(
        of: find.byType(CourseBoardingCard),
        matching: find.byWidgetPredicate((w) => w is ClipPath && w.clipBehavior != Clip.none),
      );
      expect(realPathClips, findsNothing);

      final notches = find.byKey(const ValueKey('boarding-notch'));
      expect(notches, findsNWidgets(2));
      final card = tester.getRect(find.byType(CourseBoardingCard));
      final dividerX = rtl ? card.left + CourseBoardingCard.stubWidth : card.right - CourseBoardingCard.stubWidth;
      final a = tester.getRect(notches.at(0));
      final b = tester.getRect(notches.at(1));
      expect(a.center.dx, closeTo(dividerX, 0.5));
      expect(b.center.dx, closeTo(dividerX, 0.5));
      final ys = [a.center.dy, b.center.dy]..sort();
      expect(ys.first, closeTo(card.top, 0.5));
      expect(ys.last, closeTo(card.bottom, 0.5));
      expect(tester.takeException(), isNull);
    });
  }
}
