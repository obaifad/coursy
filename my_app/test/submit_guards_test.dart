import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/modules/courses/controllers/booking_controller.dart';
import 'package:my_app/modules/profile/controllers/delete_account_controller.dart';

import 'layout/fakes.dart';
import 'layout/sample_data.dart';

class _CountingEnrollments extends EnrollmentRepository {
  _CountingEnrollments(super.client);

  int calls = 0;
  final gate = Completer<void>();

  @override
  Future<EnrollmentModel> enrollInCourse(int courseId) async {
    calls++;
    await gate.future;
    throw ApiException('full', statusCode: 422);
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('booking: a double tap sends one enrollment request', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _CountingEnrollments(Get.find<ApiClient>());
    Get.delete<EnrollmentRepository>(force: true);
    Get.put<EnrollmentRepository>(repo);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));

    Get.routing.args = sampleCourses()[1];
    final c = Get.put(BookingController());

    unawaited(c.confirmBooking());
    unawaited(c.confirmBooking());
    await tester.pump();
    expect(repo.calls, 1);
    expect(c.isSubmitting.value, isTrue);

    repo.gate.complete();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(c.isSubmitting.value, isFalse);
  });

  testWidgets('delete account: a double tap opens one confirmation, cancel unlocks it', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    final c = Get.put(DeleteAccountController());
    c.passwordController.text = 'secret';

    unawaited(c.deleteAccount());
    unawaited(c.deleteAccount());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(c.isDeleting.value, isTrue);

    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(c.isDeleting.value, isFalse);
  });
}
