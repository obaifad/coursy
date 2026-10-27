import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/modules/courses/controllers/booking_controller.dart';
import 'package:my_app/modules/courses/views/booking_view.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/profile/views/my_courses_tab_view.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// أُزيل رقم الطلب «#9» من بطاقة الحجز في «دوراتي»، وخانة المدة (الساعة) من صفحة تأكيد الحجز —
/// كانت تظهر «—» حين لا يحدّد المعهد ساعات الدورة.
class _Enrollments extends EnrollmentRepository {
  _Enrollments(super.client, this.items);
  final List<EnrollmentModel> items;

  @override
  Future<PaginatedResult<EnrollmentModel>> fetchEnrollmentsPage({int page = 1, int perPage = 15}) async =>
      PaginatedResult(items: items, currentPage: 1, lastPage: 1, total: items.length, hasMore: false);

  @override
  Future<List<EnrollmentModel>> fetchEnrollments() async => items;
}

Map<String, dynamic> _course({int? hours}) => {
  'id': 1,
  'title': 'تصميم واجهات تطبيقات الموبايل',
  'title_ar': 'تصميم واجهات تطبيقات الموبايل',
  'price': '170000',
  'study_type': 'offline',
  'level': 'beginner',
  'start_date': '2026-12-02',
  if (hours != null) 'duration_hours': hours,
  'institute': {'id': 2, 'name_ar': 'مركز مزة التعليمي', 'name_en': 'Mazzeh Educational Center'},
};

Future<void> _pump(WidgetTester tester, Widget scene) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(auditApp(child: scene, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  testWidgets('my courses: the booking card shows no "#id"', (tester) async {
    Get.locale = const Locale('ar');
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.delete<EnrollmentRepository>(force: true);
    Get.put<EnrollmentRepository>(
      _Enrollments(Get.find(), [
        EnrollmentModel.fromJson({'id': 9, 'status': 'pending', 'payment_status': 'unpaid', 'course': _course()}),
      ]),
    );
    Get.put(MyCoursesController());
    await _pump(tester, const MyCoursesTabView());

    expect(find.text('تصميم واجهات تطبيقات الموبايل'), findsWidgets, reason: 'the card is shown');
    expect(find.text('#9'), findsNothing);
    expect(find.byIcon(Icons.confirmation_number_outlined), findsNothing);
    await _dispose(tester);
  });

  for (final hours in [null, 40]) {
    testWidgets('booking confirmation: no duration chip (duration_hours: $hours)', (tester) async {
      Get.locale = const Locale('ar');
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = CourseModel.fromJson(_course(hours: hours));
      Get.put(BookingController());
      await _pump(tester, const CourseBookingView());

      expect(find.text('confirm_booking'.tr), findsOneWidget, reason: 'the page is shown');
      expect(find.byIcon(Icons.schedule_rounded), findsNothing);
      expect(find.text('—'), findsNothing);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget, reason: 'the level chip stays');
      await _dispose(tester);
    });
  }
}
