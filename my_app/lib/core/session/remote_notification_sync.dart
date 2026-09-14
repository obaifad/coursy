import 'package:get/get.dart';

import '../models/app_models.dart';
import '../models/json_helpers.dart';
import '../../modules/courses/controllers/course_details_controller.dart';
import '../../modules/notifications/controllers/notifications_controller.dart';
import 'session_refresh.dart';

/// مزامنة حالة التطبيق عند وصول إشعار من الخادم (FCM أو قائمة الإشعارات).
abstract final class RemoteNotificationSync {
  static const _enrollmentTypes = [
    'enrollment',
    'enrollment_approved',
    'enrollment_pending',
    'enrollment_rejected',
    'enrollment_cancelled',
    'enrollment_status',
    'enrollment_status_changed',
    'approval',
    'approved',
    'pending',
    'rejected',
    'cancelled',
    'booking',
  ];

  static const _enrollmentScreens = [
    'enrollment',
    'enrollments',
    'my_courses',
    'my-courses',
    'booking',
  ];

  /// يُستدعى عند وصول رسالة FCM (مقدمة/خلفية/بعد الضغط).
  static Future<void> onMessageReceived(Map<String, dynamic> data) async {
    await _refreshNotifications();
    if (!isEnrollmentRelated(data)) return;
    await SessionRefresh.afterEnrollmentStatusChanged(
      courseId: readCourseId(data),
      enrollmentId: readEnrollmentId(data),
    );
  }

  static bool isEnrollmentRelated(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    final type = _readString(data, const ['type', 'notification_type', 'event']);
    if (type != null) {
      for (final key in _enrollmentTypes) {
        if (type.contains(key)) return true;
      }
    }

    final screen = _readString(data, const ['screen', 'route', 'target', 'click_action']);
    if (screen != null) {
      for (final key in _enrollmentScreens) {
        if (screen.contains(key)) return true;
      }
    }

    final status = _readString(data, const ['status', 'enrollment_status']);
    if (status != null) {
      for (final key in _enrollmentTypes) {
        if (status.contains(key)) return true;
      }
    }

    return readEnrollmentId(data) != null;
  }

  static bool isEnrollmentNotificationType(String type) {
    final normalized = type.toLowerCase();
    for (final key in _enrollmentTypes) {
      if (normalized.contains(key)) return true;
    }
    return false;
  }

  static Map<String, dynamic> notificationToPushData(NotificationModel notification) {
    final data = <String, dynamic>{
      'type': notification.type,
      if (notification.courseId != null) 'course_id': notification.courseId,
      if (notification.enrollmentId != null) 'enrollment_id': notification.enrollmentId,
    };
    final extra = notification.data;
    if (extra != null) {
      for (final entry in extra.entries) {
        data.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return data;
  }

  static int? readCourseId(Map<String, dynamic> data) =>
      _readId(data, const ['course_id', 'courseId']);

  static int? readEnrollmentId(Map<String, dynamic> data) =>
      _readId(data, const ['enrollment_id', 'enrollmentId']);

  static Future<void> refreshCourseDetailsIfVisible(int courseId) async {
    if (!Get.isRegistered<CourseDetailsController>()) return;
    final details = Get.find<CourseDetailsController>();
    if (details.course.value?.id != courseId) return;
    await details.refreshEnrollment();
  }

  static Future<void> _refreshNotifications() async {
    if (!Get.isRegistered<NotificationsController>()) return;
    await Get.find<NotificationsController>().loadNotifications();
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value.toLowerCase();
    }
    return null;
  }

  static int? _readId(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final id = JsonHelpers.parseIntOrNull(data[key]);
      if (id != null && id > 0) return id;
    }
    return null;
  }
}
