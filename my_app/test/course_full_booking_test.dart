import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/utils/course_registration_guard.dart';
import 'package:my_app/modules/auth/widgets/register_form_widgets.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/widgets/registration_closed_dialog.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// دورة اكتملت مقاعدها تتصرّف كدورة انتهى تسجيلها: مكان «احجز الآن» زر «المقاعد مكتملة» يفتح نافذة
/// انتهاء التسجيل نفسها (برقم المعهد) بعنوان ورسالة الامتلاء، وبطاقة السعة تقول ذلك، ولا يصل أحد إلى شاشة
/// الحجز. المسجّل فيها يبقى يرى «تم التسجيل».
CourseModel _course({required int current, int? max = 14, String? phone, String? deadline}) => CourseModel.fromJson({
  'id': 3,
  'title_ar': 'تصميم واجهات الموبايل',
  'title_en': 'Mobile UI Design',
  'price': '100000',
  'max_students': ?max,
  'current_students': current,
  'institute': {'id': 1, 'name_ar': 'معهد الرواد', 'name_en': 'Al Rowad', 'phone': ?phone},
  'registration_deadline': ?deadline,
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
    testWidgets('full course: the button opens the registration-closed dialog, with the full message ($locale)', (
      tester,
    ) async {
      await open(tester, _course(current: 14, phone: '0933000000'), locale: locale);
      expect(find.byType(RegisterGradientButton), findsNothing, reason: 'no «book now» button');
      final full = find.widgetWithText(OutlinedButton, 'course_full'.tr);
      expect(full, findsOneWidget);
      // بطاقة السعة: «المقاعد مكتملة» بدل «0 مقعد متبقٍ».
      expect(find.text('course_full'.tr), findsNWidgets(2));

      await tester.tap(full);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RegistrationClosedDialog), findsOneWidget);
      expect(find.text('course_full_title'.tr), findsOneWidget);
      expect(find.text('course_full_message'.tr), findsOneWidget);
      expect(find.text('registration_closed_title'.tr), findsNothing);
      expect(
        find.descendant(of: find.byType(RegistrationClosedDialog), matching: find.text('0933000000')),
        findsOneWidget,
        reason: 'the institute number, as when registration is closed',
      );
      expect(find.byIcon(Icons.calendar_today_rounded), findsNothing, reason: 'no deadline box');
    });
  }

  testWidgets('registration closed and full: the closed dialog wins', (tester) async {
    await open(tester, _course(current: 14, deadline: '2020-01-01'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'registration_closed_action'.tr));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('registration_closed_title'.tr), findsOneWidget);
    expect(find.text('course_full_title'.tr), findsNothing);
  });

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
    final refused = CourseRegistrationGuard.ensureOpen(_course(current: 14));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('course_full_title'.tr), findsOneWidget);
    Get.back<void>();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await refused, isFalse);
    expect(await CourseRegistrationGuard.ensureOpen(_course(current: 13)), isTrue);
  });
}
