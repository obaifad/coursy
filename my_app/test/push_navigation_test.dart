import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/navigation/push_navigation.dart';
import 'package:my_app/routes/app_routes.dart';

Widget _app() => GetMaterialApp(
  initialRoute: '/start',
  getPages: [
    GetPage(name: '/start', page: () => const Text('start')),
    GetPage(name: AppRoutes.courseDetails, page: () => const Text('course')),
    GetPage(name: AppRoutes.notifications, page: () => const Text('notifications')),
  ],
);

void main() {
  tearDown(Get.reset);

  testWidgets('a Laravel class-name type with course_id opens the course', (tester) async {
    await tester.pumpWidget(_app());

    PushNavigation.openFromMessageData({'type': r'App\Notifications\EnrollmentApproved', 'course_id': '5'});
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.courseDetails);
    expect(Get.arguments, 5);
  });

  testWidgets('a notification without a target does not reopen the notifications page', (tester) async {
    await tester.pumpWidget(_app());
    Get.toNamed(AppRoutes.notifications);
    await tester.pumpAndSettle();

    PushNavigation.openFromMessageData({'type': 'info'});
    await tester.pumpAndSettle();

    expect(find.text('notifications'), findsOneWidget);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/start');
  });
}
