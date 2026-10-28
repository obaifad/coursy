import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/modules/payment/controllers/payment_controller.dart';
import 'package:my_app/modules/payment/views/payment_view.dart';
import 'package:my_app/theme/app_fonts.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// محاذاة النص مع الأيقونات وتخطيط الأسطر الضيقة (تدقيق التخطيط):
/// - توزيع المسافة الإضافية نسبي في كل أنماط الثيم وفي AppFonts.tajawal (حروف Tajawal على خط منتصف الأيقونة).
/// - سطر المعلومات: العنصر القصير يأخذ حاجته فقط ولا يُقصّ الأطول بجانب فراغ.
/// - أيقونة بجانب نص من عدة أسطر تقف على منتصف سطره الأول، ومع تكبير الخط.
/// - كلمة أعرض من خلية الإحصاء لا تُقسم من منتصفها، وعنوان الدفع لا ينكسر بجانب شارة الحالة.
void main() {
  setUpAll(loadAuditFonts);

  /// عدد أسطر نص معروض.
  int linesOf(WidgetTester tester, String text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length));
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  Future<void> pumpIn(WidgetTester tester, Widget child, {String locale = 'en', double scale = 1, double width = 360}) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(auditApp(child: child, locale: locale, scale: scale, boundaryKey: GlobalKey()));
  }

  group('leading distribution', () {
    test('every theme text style and AppFonts.tajawal distribute the extra leading proportionally', () {
      final t = AppTheme.lightTheme.textTheme;
      for (final style in [
        t.displayLarge, t.displayMedium, t.displaySmall, t.headlineLarge, t.headlineMedium, t.headlineSmall, //
        t.titleLarge, t.titleMedium, t.titleSmall, t.bodyLarge, t.bodyMedium, t.bodySmall, //
        t.labelLarge, t.labelMedium, t.labelSmall,
      ]) {
        expect(style!.leadingDistribution, TextLeadingDistribution.proportional);
      }
      expect(AppFonts.tajawal(fontSize: 13, height: 1.3).leadingDistribution, TextLeadingDistribution.proportional);
    });
  });

  group('AppRowMetaLine', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('a short item takes only what it needs; the long one is not cut beside a gap ($locale)', (
        tester,
      ) async {
        await pumpIn(
          tester,
          const Center(
            child: SizedBox(
              width: 150,
              child: AppRowMetaLine(
                items: [
                  AppRowMeta(icon: Icons.schedule_rounded, text: '16 sessions'),
                  AppRowMeta(icon: Icons.star_rounded, text: '4.4', emphasized: true),
                ],
              ),
            ),
          ),
          locale: locale,
        );
        final duration = tester.renderObject<RenderParagraph>(find.text('16 sessions'));
        expect(duration.didExceedMaxLines, isFalse, reason: '"16 sessions" fits in 150 next to "★ 4.4"');
        final line = tester.getRect(find.byType(AppRowMetaLine));
        final star = tester.getRect(find.byIcon(Icons.schedule_rounded));
        expect(locale == 'ar' ? line.right - star.right : star.left - line.left, moreOrLessEquals(0), reason: 'start');
      });
    }

    testWidgets('when nothing fits, only the longest item shrinks', (tester) async {
      await pumpIn(
        tester,
        const Center(
          child: SizedBox(
            width: 110,
            child: AppRowMetaLine(
              items: [
                AppRowMeta(icon: Icons.schedule_rounded, text: '16 sessions of training'),
                AppRowMeta(icon: Icons.star_rounded, text: '4.4', emphasized: true),
              ],
            ),
          ),
        ),
      );
      expect(tester.renderObject<RenderParagraph>(find.text('4.4')).didExceedMaxLines, isFalse);
      expect(tester.renderObject<RenderParagraph>(find.text('16 sessions of training')).didExceedMaxLines, isTrue);
      expect(tester.getRect(find.byType(AppRowMetaLine)).width, 110);
    });
  });

  group('AppFirstLineIcon', () {
    const style = TextStyle(fontSize: 14, height: 1.4);
    const message = 'You can rate this institute once a booking in one of its courses is accepted.';

    for (final (size, scale) in [(24.0, 1.0), (16.0, 1.0), (16.0, 1.3)]) {
      testWidgets('sits on the first line of a wrapped paragraph (icon $size, x$scale)', (tester) async {
        await pumpIn(
          tester,
          Center(
            child: SizedBox(
              width: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFirstLineIcon(Icons.info_outline_rounded, size: size, textStyle: style),
                  const SizedBox(width: 12),
                  const Expanded(child: Text(message, style: style)),
                ],
              ),
            ),
          ),
          scale: scale,
        );
        expect(linesOf(tester, message), greaterThan(1));
        final paragraph = tester.renderObject<RenderParagraph>(find.text(message));
        final firstLine = paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1)).first;
        final textTop = tester.getTopLeft(find.text(message)).dy;
        final lineCentre = textTop + (firstLine.top + firstLine.bottom) / 2;
        final iconCentre = tester.getCenter(find.byIcon(Icons.info_outline_rounded)).dy;
        expect(iconCentre, moreOrLessEquals(lineCentre, epsilon: 0.5));
      });
    }
  });

  group('narrow layouts', () {
    tearDown(() {
      FakeApi.reset();
      Get.reset();
    });

    testWidgets('course stats: "Intermediate" stays one word on a 360 phone', (tester) async {
      Get.locale = const Locale('en');
      await registerFakes(loggedIn: true, locale: 'en');
      final c = Get.put(CourseDetailsController(), tag: 'stats');
      c.course.value = sampleCourses().first;
      await pumpIn(tester, const CourseDetailsView(controllerTag: 'stats'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.scrollUntilVisible(find.text('Intermediate'), 200, scrollable: find.byType(Scrollable).first);
      expect(linesOf(tester, 'Intermediate'), 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    for (final locale in ['ar', 'en']) {
      testWidgets('course row card on a 360 phone: the duration is shown whole, in its short form ($locale)', (
        tester,
      ) async {
        Get.locale = Locale(locale);
        await registerFakes(loggedIn: true, locale: locale);
        final courses = sampleCourses();
        await pumpIn(
          tester,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final i in [0, 1, 3]) CourseRowCard(course: courses[i]),
            ],
          ),
          locale: locale,
        );
        final expected = locale == 'ar' ? ['120 س', '16 ج', '40 س'] : ['120 h', '16 sess', '40 h'];
        for (final text in expected) {
          expect(tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines, isFalse, reason: text);
        }
      });
    }

    testWidgets('payment summary: the title stays on one line (the status moves under it when needed)', (tester) async {
      Get.locale = const Locale('en');
      await registerFakes(loggedIn: true, locale: 'en');
      fakePaymentJson = {
        'enrollment_id': 42,
        'payment_status': 'partial',
        'currency': 'SYP',
        'amount_due': 1250000,
        'advance_amount': 300000,
        'amount_paid': 300000,
        'amount_remaining': 950000,
        'advance_remaining': 0,
        'shamcash': {'available': false},
        'payments': [],
      };
      Get.put(PaymentController(enrollmentId: 42));
      await pumpIn(tester, const PaymentView());
      await tester.pump(const Duration(milliseconds: 600));
      expect(linesOf(tester, 'Payment summary'), 1);
      expect(find.text('Partially paid'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
