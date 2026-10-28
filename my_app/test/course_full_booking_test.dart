import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/utils/course_registration_guard.dart';
import 'package:my_app/modules/auth/widgets/register_form_widgets.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// دورة اكتملت مقاعدها: زر الحجز معطّل ومكتوب عليه «الدورة ممتلئة»، وبطاقة السعة تقول ذلك، ولا يصل
/// أحد إلى شاشة الحجز. المسجّل فيها يبقى يرى «تم التسجيل».
CourseModel _course({required int current, int? max = 14}) => CourseModel.fromJson({
  'id': 3,
  'title_ar': 'تصميم واجهات الموبايل',
  'title_en': 'Mobile UI Design',
  'price': '100000',
  'max_students': ?max,
  'current_students': current,
});

void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  group('isFull', () {
    test('full at or above capacity, not below, never without a capacity', () {
      expect(_course(current: 14).isFull, isTrue);
      expect(_course(current: 15).isFull, isTrue);
      expect(_course(current: 13).isFull, isFalse);
      expect(_course(current: 40, max: null).isFull, isFalse);
      expect(_course(current: 0, max: 0).isFull, isFalse);
    });
  });

  Future<void> open(WidgetTester tester, CourseModel c, {bool registered = false, String locale = 'ar'}) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: locale);
    final controller = Get.put(CourseDetailsController(), tag: 'full');
    controller.course.value = c;
    controller.enrollmentResolved.value = true;
    controller.hasCourseEnrollment.value = registered;
    await tester.pumpWidget(
      auditApp(
        child: const CourseDetailsView(controllerTag: 'full'),
        locale: locale,
        scale: 1,
        boundaryKey: GlobalKey(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  RegisterGradientButton button(WidgetTester tester) => tester.widget(find.byType(RegisterGradientButton));

  for (final locale in ['ar', 'en']) {
    testWidgets('full course: the book button is disabled and says so ($locale)', (tester) async {
      await open(tester, _course(current: 14), locale: locale);
      expect(button(tester).label, 'course_full'.tr);
      expect(button(tester).onPressed, isNull);
      expect(find.text('book_now'.tr), findsNothing);
      // بطاقة السعة: «الدورة ممتلئة» بدل «0 مقعد متبقٍ».
      expect(find.text('course_full'.tr), findsNWidgets(2));
    });
  }

  testWidgets('seats left: the book button works', (tester) async {
    await open(tester, _course(current: 13));
    expect(button(tester).label, 'book_now'.tr);
    expect(button(tester).onPressed, isNotNull);
    expect(find.text('course_full'.tr), findsNothing);
  });

  testWidgets('registered in a full course: still shows «registered»', (tester) async {
    await open(tester, _course(current: 14), registered: true);
    expect(button(tester).label, 'enrollment_registered'.tr);
  });

  testWidgets('the booking screen cannot be opened for a full course', (tester) async {
    await open(tester, _course(current: 14));
    final ok = await CourseRegistrationGuard.ensureOpen(_course(current: 14));
    expect(ok, isFalse);
    expect(await CourseRegistrationGuard.ensureOpen(_course(current: 13)), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });
}
