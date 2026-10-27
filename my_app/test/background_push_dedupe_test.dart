import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:my_app/core/data/repositories/notification_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/push/push_background_handler.dart';
import 'package:my_app/core/push/push_local_notifications.dart';
import 'package:my_app/core/services/enrollment_sync_service.dart';
import 'package:my_app/core/session/enrollment_status_coordinator.dart';
import 'package:my_app/core/storage/background_push_store.dart';
import 'package:my_app/core/storage/notification_delivery_store.dart';

import 'layout/fakes.dart';

/// «تم استلام طلب التسجيل» ظهر مرتين: FCM وصل والتطبيق في الخلفية فعرضه النظام، ثم عند العودة للتطبيق وجده
/// فحص قائمة الخادم «جديداً» فعرضه ثانية (رقم 500027 = إشعار الخادم 27). معالج الخلفية يعمل في isolate منفصل
/// لا يكتب في GetStorage، فصار يسجّل الإشعار في SharedPreferences المشترك، والفحص يتحقّق منه قبل العرض.
class _ServerList extends NotificationRepository {
  _ServerList(super.client);

  final items = <NotificationModel>[];

  @override
  Future<List<NotificationModel>> fetchNotifications() async => List.of(items);
}

NotificationModel _received({int id = 27, int enrollmentId = 7}) => NotificationModel(
  id: id,
  title: 'تم استلام طلب التسجيل',
  subtitle: 'لقد استلمنا طلب تسجيلك في "تصميم واجهات تطبيقات الموبايل". سيتم إعلامك عند مراجعته.',
  type: 'enrollment_pending',
  enrollmentId: enrollmentId,
);

void main() {
  late Directory dir;
  late _ServerList server;
  late EnrollmentSyncService sync;
  late List<int> shown;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('push_dedupe_test');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
  });

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await registerFakes(loggedIn: true, locale: 'ar');
    await GetStorage().erase();
    server = _ServerList(Get.find<ApiClient>());
    replaceFake<NotificationRepository>(server);
    Get.put(NotificationDeliveryStore());
    Get.put(EnrollmentStatusCoordinator());
    sync = Get.put(EnrollmentSyncService());
    shown = [];
    PushLocalNotifications.onShow = (id, _, __) => shown.add(id);

    // فتح التطبيق: لا إشعارات بعد، فالخط الأساسي فارغ.
    await sync.seedStatuses();
    shown.clear();
  });

  tearDown(() {
    PushLocalNotifications.onShow = null;
    Get.reset();
  });

  Future<void> backToApp() => sync.checkForStatusChanges(force: true);

  test('FCM shown in the background, then back to the app: the server list does not show it again', () async {
    await recordBackgroundDelivery({'notification_id': '27', 'type': 'enrollment_pending', 'enrollment_id': '7'});
    server.items.add(_received());

    await backToApp();

    expect(shown, isEmpty, reason: 'it used to appear a second time as 500027');
  });

  test('a push without notification_id still matches by type and enrollment', () async {
    await recordBackgroundDelivery({'type': 'enrollment_pending', 'enrollment_id': '7'});
    server.items.add(_received());

    await backToApp();

    expect(shown, isEmpty);
  });

  test('no push arrived (FCM failed): the server list shows it, once', () async {
    server.items.add(_received());

    await backToApp();
    await backToApp();

    expect(shown, [PushLocalNotifications.serverNotificationId(27)]);
  });

  test('a push for another notification does not hide this one', () async {
    await recordBackgroundDelivery({'notification_id': '26', 'type': 'enrollment_pending', 'enrollment_id': '6'});
    server.items.add(_received());

    await backToApp();

    expect(shown, [PushLocalNotifications.serverNotificationId(27)]);
  });

  test('the next status of the same enrollment still shows', () async {
    await recordBackgroundDelivery({'notification_id': '27', 'type': 'enrollment_pending', 'enrollment_id': '7'});
    server.items
      ..add(_received())
      ..add(
        NotificationModel(
          id: 28,
          title: 'تمت الموافقة على تسجيلك',
          subtitle: 'تم قبول تسجيلك',
          type: 'enrollment_approved',
          enrollmentId: 7,
        ),
      );

    await backToApp();

    expect(shown, [PushLocalNotifications.serverNotificationId(28)]);
  });

  group('store', () {
    test('keys: notification id and type + enrollment, type normalised', () {
      expect(
        BackgroundPushStore.keysForPushData({
          'notification_id': 27,
          'type': ' Enrollment_Pending',
          'enrollment_id': '7',
        }),
        ['n:27', 'e:enrollment_pending:7'],
      );
      expect(BackgroundPushStore.keysForPushData({'type': 'promo'}), isEmpty);
    });

    test('nothing to match on: nothing is stored', () async {
      await BackgroundPushStore.recordPush({'type': 'promo'});
      expect(await BackgroundPushStore.load(), isEmpty);
    });

    test('only the newest keys are kept', () async {
      for (var i = 1; i <= BackgroundPushStore.maxKeys + 5; i++) {
        await BackgroundPushStore.recordPush({'notification_id': i});
      }
      final keys = await BackgroundPushStore.load();
      expect(keys, hasLength(BackgroundPushStore.maxKeys));
      expect(keys.contains('n:1'), isFalse);
      expect(keys.contains('n:${BackgroundPushStore.maxKeys + 5}'), isTrue);
    });
  });
}
