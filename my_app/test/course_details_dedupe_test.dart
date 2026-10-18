import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// تفاصيل الدورة: عدد الطلاب في بطاقة السعة وحدها، «هجين» مرة واحدة، وبطاقة المعلومات ثلاثة عناصر
/// (المستوى، النمط، الشهادة).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  CourseModel course({String? studyType = 'hybrid', bool certificate = true}) => CourseModel.fromJson({
    'id': 1,
    'title_ar': 'أساسيات البرمجة بلغة بايثون',
    'title_en': 'Python basics',
    'price': '350000',
    'category': {'id': 1, 'name_ar': 'البرمجة', 'name_en': 'Programming'},
    'level': 'beginner',
    'certificate_available': certificate ? 1 : 0,
    'study_type': ?studyType,
    'institute_name': 'معهد الرواد',
    'start_date': '2026-10-22',
    'end_date': '2026-12-17',
    'duration_hours': 8,
    'max_students': 30,
    'current_students': 28,
  });

  Future<void> open(WidgetTester tester, CourseModel c, {String locale = 'ar', double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: locale);
    final controller = Get.put(CourseDetailsController(), tag: 'dedupe');
    controller.course.value = c;
    await tester.pumpWidget(
      auditApp(
        child: const CourseDetailsView(controllerTag: 'dedupe'),
        locale: locale,
        scale: scale,
        boundaryKey: GlobalKey(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('the student count appears once: the capacity card', (tester) async {
    final c = course();
    await open(tester, c);
    expect(find.text(c.seatsLabel), findsNothing, reason: 'no «28 / 30 طالب» line on the cover or in the info card');
    expect(find.text('seats_filled'.trParams({'current': '28', 'max': '30'})), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.groups_rounded), findsNothing);
  });

  testWidgets('the study mode appears once', (tester) async {
    await open(tester, course());
    expect(find.text('study_hybrid'.tr), findsOneWidget);
  });

  testWidgets('the info card has exactly three tiles: level, mode, certificate', (tester) async {
    final c = course();
    await open(tester, c);
    expect(find.text(c.level), findsOneWidget);
    expect(find.text('study_hybrid'.tr), findsOneWidget);
    expect(find.text('course_certificate_yes'.tr), findsOneWidget, reason: 'only in the card, not also as a badge');
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.laptop_mac_rounded), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets('no certificate: the third tile says so', (tester) async {
    await open(tester, course(certificate: false));
    expect(find.text('course_certificate_no'.tr), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('no study mode: two tiles, no gap or overflow', (tester) async {
    await open(tester, course(studyType: null));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.laptop_mac_rounded), findsNothing);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('three tiles fit at text scale 1.3 ($locale)', (tester) async {
      await open(tester, course(), locale: locale, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }
}
