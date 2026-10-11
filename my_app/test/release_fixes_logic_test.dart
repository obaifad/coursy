import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/notification_repository.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/locale/locale_request_guard.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/navigation/push_navigation.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/network/json_parser.dart';
import 'package:my_app/core/push/enrollment_status_change.dart';
import 'package:my_app/core/push/push_background_handler.dart';
import 'package:my_app/core/push/push_local_notifications.dart';
import 'package:my_app/core/session/remote_notification_sync.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:my_app/modules/notifications/controllers/notifications_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/routes/app_routes.dart';

import 'layout/fakes.dart';

/// يرد على كل طلب بحالة وجسم ثابتين.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// إشعارات في الذاكرة تسجّل طلبات «مقروء».
class _RecordingNotifications extends NotificationRepository {
  _RecordingNotifications() : super(ApiClient(TokenStorage()));

  final read = <int>{};
  final readCalls = <int>[];
  var readAllCalls = 0;

  List<NotificationModel> get _items => [
    NotificationModel.fromJson({
      'id': 1,
      'title': 'تم قبول التسجيل',
      'body': 'تمت الموافقة على تسجيلك',
      'type': 'enrollment_approved',
      'is_read': read.contains(1),
      'data': {'course_id': '41', 'enrollment_id': '7'},
    }),
    NotificationModel.fromJson({
      'id': 2,
      'title': 'مرحباً',
      'body': 'أهلاً بك',
      'type': 'info',
      'is_read': read.contains(2),
      'data': null,
    }),
  ];

  @override
  Future<PaginatedResult<NotificationModel>> fetchNotificationsPage({int page = 1, int perPage = 15}) async =>
      PaginatedResult(items: _items, currentPage: 1, lastPage: 1, total: 2, hasMore: false);

  @override
  Future<void> markRead(int notificationId) async {
    readCalls.add(notificationId);
    read.add(notificationId);
  }

  @override
  Future<void> markAllRead() async {
    readAllCalls++;
    read.addAll([1, 2]);
  }
}

Widget _routesApp() => GetMaterialApp(
  initialRoute: '/start',
  getPages: [
    GetPage(name: '/start', page: () => const Text('start')),
    GetPage(name: AppRoutes.courseDetails, page: () => const Text('course')),
    GetPage(name: AppRoutes.notifications, page: () => const Text('notifications')),
  ],
);

EnrollmentModel _enrollment({String studyType = 'offline', Object? acceptsShamcash = _absent}) {
  return EnrollmentModel.fromJson({
    'id': 9,
    'status': 'pending',
    'payment_status': 'unpaid',
    'course': {
      'id': 5,
      'title': 'Course',
      'study_type': studyType,
      'requires_advance_payment': true,
      'institute': {'id': 3, 'name': 'Institute', if (acceptsShamcash != _absent) 'accepts_shamcash': acceptsShamcash},
    },
  });
}

const _absent = Object();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('background push', () {
    test('a server push with a notification block is left to the system (no second local notification)', () {
      const message = RemoteMessage(
        notification: RemoteNotification(title: 'تم قبول التسجيل', body: 'body'),
        data: {'type': 'enrollment_approved', 'enrollment_id': '7'},
      );
      expect(backgroundMessageNeedsLocalNotification(message), isFalse);
    });

    test('a data-only push is still shown locally', () {
      const message = RemoteMessage(data: {'title': 'Hi', 'body': 'There'});
      expect(backgroundMessageNeedsLocalNotification(message), isTrue);
    });

    test('a local notification payload decodes to push data', () {
      expect(PushLocalNotifications.decodePayload('type=enrollment_cancelled&course_id=5&enrollment_id=7'), {
        'type': 'enrollment_cancelled',
        'course_id': '5',
        'enrollment_id': '7',
      });
    });
  });

  group('enrollment status change', () {
    test('cancelled is its own change, not a rejection', () {
      expect(EnrollmentStatusChange.detect('pending', 'cancelled'), EnrollmentStatusChange.cancelled);
      expect(EnrollmentStatusChange.detect('pending', 'rejected'), EnrollmentStatusChange.rejected);
      expect(EnrollmentStatusChange.detect('pending', 'approved'), EnrollmentStatusChange.approved);
      expect(EnrollmentStatusChange.detect('pending', 'confirmed'), EnrollmentStatusChange.approved);
    });

    test('only a change from pending is notified', () {
      expect(EnrollmentStatusChange.detect(null, 'cancelled'), isNull);
      expect(EnrollmentStatusChange.detect('approved', 'cancelled'), isNull);
      expect(EnrollmentStatusChange.detect('cancelled', 'cancelled'), isNull);
      expect(EnrollmentStatusChange.detect('pending', 'pending'), isNull);
    });

    test('each change has its own delivered key and notification id', () {
      expect(EnrollmentStatusChange.cancelled.deliveredKey(7), 'cancelled:7');
      final ids = EnrollmentStatusChange.values.map((c) => c.notificationId(7)).toSet();
      expect(ids, hasLength(EnrollmentStatusChange.values.length));
    });

    test('server push types map back to the change', () {
      expect(EnrollmentStatusChange.fromNotificationType('enrollment_cancelled'), EnrollmentStatusChange.cancelled);
      expect(EnrollmentStatusChange.fromNotificationType('enrollment_rejected'), EnrollmentStatusChange.rejected);
      expect(EnrollmentStatusChange.fromNotificationType('payment_confirmed'), isNull);
    });

    test('cancelled wording exists in both languages and differs from rejected', () {
      final keys = AppTranslations().keys;
      for (final locale in ['ar', 'en']) {
        for (final change in EnrollmentStatusChange.values) {
          for (final key in [change.titleKey, change.bodyKey, change.genericBodyKey]) {
            expect(keys[locale]![key], isNotEmpty, reason: '$locale $key');
          }
          expect(keys[locale]![change.bodyKey], contains('@course'));
        }
        expect(
          keys[locale]![EnrollmentStatusChange.cancelled.titleKey],
          isNot(keys[locale]![EnrollmentStatusChange.rejected.titleKey]),
        );
      }
      expect(keys['ar']!['enrollment_cancelled_title'], 'تم إلغاء التسجيل');
      expect(keys['en']!['enrollment_cancelled_title'], 'Enrollment cancelled');
    });
  });

  group('server error messages', () {
    test('an empty or blank message falls back', () {
      expect(messageFromErrorBody({'message': ''}, fallback: 'fallback'), 'fallback');
      expect(messageFromErrorBody({'message': '   '}, fallback: 'fallback'), 'fallback');
      expect(messageFromErrorBody({'errors': <String, dynamic>{}, 'message': ''}, fallback: 'fallback'), 'fallback');
    });

    test("Laravel's model-not-found text is not shown", () {
      expect(
        messageFromErrorBody({'message': r'No query results for model [App\Models\Course] 99'}, fallback: 'fallback'),
        'fallback',
      );
    });

    test('a real message and field errors are kept', () {
      expect(messageFromErrorBody({'message': 'Course is full.'}, fallback: 'fallback'), 'Course is full.');
      expect(
        messageFromErrorBody({
          'message': 'The given data was invalid.',
          'errors': {
            'email': [''],
            'password': ['Too short.'],
          },
        }),
        'Too short.',
      );
    });
  });

  group('deactivated account (403 account_inactive)', () {
    String? inactiveMessage;
    late int unauthorizedCalls;

    setUp(() {
      inactiveMessage = null;
      unauthorizedCalls = 0;
      ApiClient.onAccountInactive = (message) => inactiveMessage = message;
      ApiClient.onUnauthorized = () => unauthorizedCalls++;
    });

    tearDown(() {
      ApiClient.onAccountInactive = null;
      ApiClient.onUnauthorized = null;
    });

    Future<ApiClient> client({required bool loggedIn, required Map<String, dynamic> body}) async {
      await registerFakes(loggedIn: loggedIn, locale: 'ar');
      final c = Get.find<ApiClient>();
      c.dio.httpClientAdapter = _JsonAdapter(403, body);
      return c;
    }

    test('ends the session with the server message', () async {
      final c = await client(
        loggedIn: true,
        body: {'message': 'Your account is inactive.', 'code': 'account_inactive'},
      );
      await expectLater(
        c.handle(() => c.get('/student/enrollments'), (body) => body),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Your account is inactive.')),
      );
      expect(inactiveMessage, 'Your account is inactive.');
      expect(unauthorizedCalls, 0);
    });

    test('falls back to the 401 path when no handler is set', () async {
      ApiClient.onAccountInactive = null;
      final c = await client(loggedIn: true, body: {'message': 'Inactive', 'code': 'account_inactive'});
      await c.get('/student/me');
      expect(unauthorizedCalls, 1);
    });

    test('a plain 403, a guest request or the login endpoint does not end the session', () async {
      var c = await client(loggedIn: true, body: {'message': 'Forbidden.'});
      await c.get('/student/enrollments');
      c = await client(loggedIn: false, body: {'message': 'Inactive', 'code': 'account_inactive'});
      await c.get('/student/enrollments');
      c = await client(loggedIn: true, body: {'message': 'Inactive', 'code': 'account_inactive'});
      await c.post('/student/login', data: {});
      expect(inactiveMessage, isNull);
      expect(unauthorizedCalls, 0);
    });
  });

  group('password reset', () {
    test('requires the same 6 characters as registration', () {
      expect(ForgotPasswordController.passwordRuleError(''), 'reset_password_required'.tr);
      expect(ForgotPasswordController.passwordRuleError('12345'), 'password_min_6'.tr);
      expect(ForgotPasswordController.passwordRuleError('123456'), isNull);
    });
  });

  group('in-app payment', () {
    test('accepts_shamcash is parsed as an optional flag', () {
      expect(InstituteModel.fromJson({'id': 1, 'name': 'A'}).acceptsShamcash, isNull);
      expect(InstituteModel.fromJson({'id': 1, 'name': 'A', 'accepts_shamcash': false}).acceptsShamcash, isFalse);
      expect(InstituteModel.fromJson({'id': 1, 'name': 'A', 'accepts_shamcash': 1}).acceptsShamcash, isTrue);
    });

    test('online courses and institutes without ShamCash cannot be paid in the app', () {
      expect(MyCoursesController.inAppPaymentBlocked(_enrollment(studyType: 'online')), isTrue);
      expect(MyCoursesController.inAppPaymentBlocked(_enrollment(acceptsShamcash: false)), isTrue);
      expect(MyCoursesController.inAppPaymentBlocked(_enrollment(acceptsShamcash: true)), isFalse);
      // خادم قديم بلا الحقل: السلوك السابق.
      final legacy = _enrollment();
      expect(legacy.institute?.acceptsShamcash, isNull);
      expect(MyCoursesController.inAppPaymentBlocked(legacy), isFalse);
      expect(legacy.canPay, isTrue);
    });
  });

  group('notification data', () {
    test('the data object carries the course and enrollment to open', () {
      final n = NotificationModel.fromJson({
        'id': 3,
        'title': 't',
        'body': 'b',
        'type': 'enrollment_approved',
        'is_read': false,
        'data': {'course_id': '41', 'enrollment_id': '7'},
      });
      expect(n.courseId, 41);
      expect(n.enrollmentId, 7);
      expect(RemoteNotificationSync.notificationToPushData(n)['course_id'], 41);
    });

    test('old notifications without data keep the type only', () {
      final n = NotificationModel.fromJson({'id': 4, 'title': 't', 'type': 'new_course', 'data': null});
      expect(n.courseId, isNull);
      expect(RemoteNotificationSync.notificationToPushData(n), {'type': 'new_course'});
    });
  });

  group('opening a push from a closed app', () {
    tearDown(() {
      PushNavigation.resetLaunchState();
      Get.reset();
    });

    testWidgets('waits for the splash, then opens the course', (tester) async {
      await tester.pumpWidget(_routesApp());
      PushNavigation.open({'type': 'enrollment_approved', 'course_id': '5'});
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/start');

      PushNavigation.completeLaunch(loggedIn: true);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.courseDetails);
      expect(Get.arguments, 5);
    });

    testWidgets('without a session only public targets open', (tester) async {
      await tester.pumpWidget(_routesApp());
      PushNavigation.open({'type': 'enrollment_approved'});
      PushNavigation.completeLaunch(loggedIn: false);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/start');

      expect(PushNavigation.isPublicTarget({'course_id': '5'}), isTrue);
      expect(PushNavigation.isPublicTarget({'type': 'enrollment_approved', 'enrollment_id': '7'}), isFalse);
    });

    testWidgets('after launch a tap opens right away, even over another course page', (tester) async {
      await tester.pumpWidget(_routesApp());
      PushNavigation.completeLaunch(loggedIn: true);
      Get.toNamed(AppRoutes.courseDetails, arguments: 4);
      await tester.pumpAndSettle();

      PushNavigation.open({'course_id': '5'});
      await tester.pumpAndSettle();
      expect(Get.arguments, 5);
      expect(find.text('course', skipOffstage: false), findsNWidgets(2));
    });
  });

  group('in-app notifications', () {
    late _RecordingNotifications repository;

    setUp(() {
      Get.reset();
      Get.put(LocaleRequestGuard());
      repository = _RecordingNotifications();
      Get.put<NotificationRepository>(repository);
    });

    tearDown(Get.reset);

    testWidgets('a tap marks it read and opens its course', (tester) async {
      await tester.pumpWidget(_routesApp());
      final controller = Get.put(NotificationsController());
      await tester.pumpAndSettle();
      expect(controller.items.where((n) => !n.isRead), hasLength(2));

      controller.openNotification(controller.items.first);
      expect(controller.items.first.isRead, isTrue);
      await tester.pumpAndSettle();

      expect(repository.readCalls, [1]);
      expect(Get.currentRoute, AppRoutes.courseDetails);
      expect(Get.arguments, 41);
      // إعادة التحميل بعد الطلب لا تعيد النقطة غير المقروءة.
      expect(controller.items.firstWhere((n) => n.id == 1).isRead, isTrue);
      expect(controller.hasUnread, isTrue);
    });

    testWidgets('mark all read clears every dot with one request', (tester) async {
      await tester.pumpWidget(_routesApp());
      final controller = Get.put(NotificationsController());
      await tester.pumpAndSettle();

      await controller.markAllRead();
      expect(repository.readAllCalls, 1);
      expect(controller.hasUnread, isFalse);

      await controller.markAllRead();
      expect(repository.readAllCalls, 1);
    });

    testWidgets('swiping hides the notification and marks it read', (tester) async {
      await tester.pumpWidget(_routesApp());
      final controller = Get.put(NotificationsController());
      await tester.pumpAndSettle();

      controller.dismiss(controller.items.last);
      await tester.pump();
      expect(controller.items.map((n) => n.id), [1]);
      expect(repository.readCalls, [2]);
    });
  });
}
