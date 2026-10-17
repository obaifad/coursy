import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/json_helpers.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// البطاقة الأفقية لصفحة كل الدورات: تتّسع بأي عرض هاتف وحجم خط، وتعرض أجزاءها — بلا باركود.
void main() {
  setUpAll(loadAuditFonts);
  setUp(() => Get.locale = const Locale('ar'));
  tearDown(Get.reset);

  Future<void> pumpCard(
    WidgetTester tester,
    CourseModel course, {
    required double screenWidth,
    double textScale = 1,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenWidth, 800), textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.topCenter,
                child: CourseBoardingCard(course: course, onTap: onTap),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final width in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('sample courses fit a ${width.toInt()}dp phone at text scale $scale', (tester) async {
        tester.view.physicalSize = Size(width * 3, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final withImages = sampleCourses().map((c) => c.copyWith(imageUrl: 'https://coursy.sy/storage/c${c.id}.jpg'));
        for (final course in [...sampleCourses(), ...withImages]) {
          await pumpCard(tester, course, screenWidth: width, textScale: scale);
          expect(tester.takeException(), isNull, reason: course.title);
          expect(
            tester.getSize(find.byType(CourseBoardingCard)).height,
            greaterThanOrEqualTo(CourseBoardingCard.minHeight),
          );
        }
      });
    }
  }

  testWidgets('shows category, certificate, title, place, start, duration, price and seats', (tester) async {
    var taps = 0;
    final course = CourseModel.fromJson({
      'id': 5,
      'title_ar': 'أساسيات البرمجة بلغة بايثون',
      'title_en': 'Python basics',
      'price': '350000',
      'category': {'id': 1, 'name_ar': 'البرمجة', 'name_en': 'Programming'},
      'level': 'beginner',
      'certificate_available': 1,
      'institute_name': 'معهد الرواد',
      'start_date': '2026-10-22',
      'end_date': '2026-12-17',
      'duration_hours': 8,
      'max_students': 20,
      'current_students': 15,
      // صورة حقيقية: مسار الصورة فيه LayoutBuilder — كان يرمي داخل IntrinsicHeight على الهاتف فقط.
      'image': 'https://coursy.sy/storage/courses/sample.jpg',
    });
    await pumpCard(tester, course, screenWidth: 360, onTap: () => taps++);

    expect(find.text(course.title), findsOneWidget);
    expect(find.text('card_certificate'.tr), findsOneWidget);
    expect(find.text('card_starts'.tr), findsOneWidget);
    expect(find.text('22 تشرين الأول'), findsOneWidget);
    expect(find.text('card_duration'.tr), findsOneWidget);
    expect(find.text(pluralTr('card_seats', 5)), findsOneWidget);
    // المدة بالأسابيع من تاريخَي البدء والانتهاء (22 تشرين الأول ← 17 كانون الأول = 8 أسابيع).
    expect(find.text(pluralTr('card_weeks', 8)), findsOneWidget);
    // لا باركود في البطاقة.
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.size == const Size(66, 20)), findsNothing);

    await tester.tap(find.text(course.title));
    expect(taps, 1);
  });

  test('day and month in Arabic (Levantine months) and English', () {
    Get.locale = const Locale('ar');
    expect(JsonHelpers.formatDayMonth('2026-11-05'), '5 تشرين الثاني');
    Get.locale = const Locale('en');
    expect(JsonHelpers.formatDayMonth('2026-11-05T10:00:00Z'), '5 Nov');
    expect(JsonHelpers.formatDayMonth(null), isNull);
    expect(JsonHelpers.formatDayMonth('soon'), isNull);
  });
}
