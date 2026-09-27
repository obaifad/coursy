import 'package:get/get.dart';

import '../data/repositories/enrollment_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../models/app_models.dart';
import '../storage/token_storage.dart';
import '../storage/notification_delivery_store.dart';
import '../config/app_debug_log.dart';
import '../push/push_local_notifications.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../session/enrollment_status_coordinator.dart';
import '../session/remote_notification_sync.dart';

/// مزامنة حالة التسجيلات من الـ API أثناء فتح التطبيق.
/// الإشعارات خارج التطبيق تتطلب FCM من الخادم.
class EnrollmentSyncService extends GetxService {
  EnrollmentRepository get _repository => Get.find();
  EnrollmentStatusCoordinator get _coordinator => Get.find();
  NotificationDeliveryStore get _deliveryStore => Get.find();

  /// أقل فاصل بين فحصين (تبديل التبويبات، العودة للتطبيق، المؤقت الدوري).
  static const _minCheckInterval = Duration(seconds: 30);

  /// لا نفحص قبل تحميل الحالات المحفوظة — وإلا تُعاد الإشعارات القديمة وتُستبدل الحالات قبل قراءتها.
  bool _seeded = false;
  Future<void>? _inFlight;
  DateTime? _lastCheckAt;

  Future<void> checkForStatusChanges({bool updateMyCoursesList = true, bool force = false}) {
    if (!Get.find<TokenStorage>().isLoggedIn || !_seeded) return Future<void>.value();
    final running = _inFlight;
    if (running != null) return running;
    final last = _lastCheckAt;
    if (!force && last != null && DateTime.now().difference(last) < _minCheckInterval) {
      return Future<void>.value();
    }
    final future = _check(updateMyCoursesList: updateMyCoursesList);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _check({required bool updateMyCoursesList}) async {
    _lastCheckAt = DateTime.now();
    try {
      final enrollments = await _repository.fetchEnrollments();
      await _coordinator.trackFromEnrollments(enrollments);
      await _checkNewServerNotifications();

      if (updateMyCoursesList && Get.isRegistered<MyCoursesController>()) {
        Get.find<MyCoursesController>().mergeEnrollments(enrollments);
      }
    } catch (e) {
      AppDebugLog.repo('EnrollmentSync', e.toString());
    }
  }

  /// عند فتح التطبيق: سجّل الإشعارات الحالية بدون عرضها (تجنّب تكرار 8+ إشعارات).
  Future<void> seedStatuses() async {
    if (!Get.find<TokenStorage>().isLoggedIn) return;

    try {
      await _deliveryStore.initForCurrentUser();
      await _coordinator.loadFromStore();
      await _baselineExistingNotifications();
      _seeded = true;
      await checkForStatusChanges(updateMyCoursesList: false, force: true);
    } catch (e) {
      AppDebugLog.repo('EnrollmentSync', 'seedStatuses: $e');
    }
  }

  Future<void> clearForLogout() {
    _seeded = false;
    _lastCheckAt = null;
    _deliveryStore.clearForCurrentUser();
    _coordinator.reset();
    return Future<void>.value();
  }

  Future<void> _baselineExistingNotifications() async {
    if (!Get.isRegistered<NotificationRepository>()) return;

    try {
      final notifications = await Get.find<NotificationRepository>().fetchNotifications();
      final ids = notifications.map((n) => n.id).where((id) => id > 0);
      await _deliveryStore.markDelivered(ids);
      AppDebugLog.fcm('baselined ${ids.length} existing notifications');
    } catch (e) {
      AppDebugLog.repo('EnrollmentSync', 'baseline notifications: $e');
    }
  }

  Future<void> _checkNewServerNotifications() async {
    if (!Get.isRegistered<NotificationRepository>()) return;

    final notifications = await Get.find<NotificationRepository>().fetchNotifications();
    for (final notification in notifications) {
      if (!RemoteNotificationSync.isEnrollmentNotificationType(notification.type)) continue;
      if (_deliveryStore.wasDelivered(notification.id)) continue;

      await _deliveryStore.markDelivered([notification.id]);

      if (notification.isRead) continue;
      if (notification.enrollmentId != null && _coordinator.wasDeliveredForEnrollment(notification.enrollmentId!)) {
        continue;
      }

      final title = notification.title.trim().isEmpty ? 'notification_default_title'.tr : notification.title;
      final body = notification.subtitle.trim();

      AppDebugLog.fcm('new server notification id=${notification.id} type=${notification.type}');
      await PushLocalNotifications.showRaw(
        id: notification.id + 500000,
        title: title,
        body: body.isEmpty ? title : body,
        payload: _encodeNotificationPayload(notification),
      );

      await RemoteNotificationSync.onMessageReceived(RemoteNotificationSync.notificationToPushData(notification));
    }
  }

  String _encodeNotificationPayload(NotificationModel notification) {
    final data = RemoteNotificationSync.notificationToPushData(notification);
    if (data.isEmpty) return '';
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}
