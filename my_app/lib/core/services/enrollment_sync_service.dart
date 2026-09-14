import 'package:get/get.dart';

import '../data/repositories/enrollment_repository.dart';
import '../data/repositories/notification_repository.dart';
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

  Future<void> checkForStatusChanges({bool updateMyCoursesList = true}) async {
    if (!Get.find<TokenStorage>().isLoggedIn) return;

    try {
      final enrollments = await _repository.fetchEnrollments();
      await _coordinator.trackFromEnrollments(enrollments);
      await _checkNewServerNotifications();

      if (updateMyCoursesList && Get.isRegistered<MyCoursesController>()) {
        Get.find<MyCoursesController>().enrollments.assignAll(enrollments);
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
      await checkForStatusChanges(updateMyCoursesList: false);
    } catch (e) {
      AppDebugLog.repo('EnrollmentSync', 'seedStatuses: $e');
    }
  }

  Future<void> clearForLogout() {
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
      if (notification.enrollmentId != null &&
          _coordinator.wasDeliveredForEnrollment(notification.enrollmentId!)) {
        continue;
      }

      final title = notification.title.trim().isEmpty
          ? 'notification_default_title'.tr
          : notification.title;
      final body = notification.subtitle.trim();

      AppDebugLog.fcm('new server notification id=${notification.id} type=${notification.type}');
      await PushLocalNotifications.showRaw(
        id: notification.id + 500000,
        title: title,
        body: body.isEmpty ? title : body,
        payload: _encodeNotificationPayload(notification),
      );

      await RemoteNotificationSync.onMessageReceived(
        RemoteNotificationSync.notificationToPushData(notification),
      );
    }
  }

  String _encodeNotificationPayload(notification) {
    final data = RemoteNotificationSync.notificationToPushData(notification);
    if (data.isEmpty) return '';
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}
