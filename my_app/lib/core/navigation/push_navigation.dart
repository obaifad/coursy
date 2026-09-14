import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../models/json_helpers.dart';
import '../navigation/app_navigation.dart';

/// توجيه المستخدم عند الضغط على إشعار FCM حسب `data` القادمة من الخادم.
abstract final class PushNavigation {
  static void openFromMessageData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      _openNotifications();
      return;
    }

    final screen = _readString(data, const ['screen', 'route', 'target', 'click_action']);
    final type = _readString(data, const ['type', 'notification_type', 'event']);

    if (_matches(screen, type, const ['notification', 'notifications'])) {
      _openNotifications();
      return;
    }

    final courseId = _readId(data, const ['course_id', 'courseId']);
    if (courseId != null || _matches(screen, type, const ['course', 'course_details', 'course-details'])) {
      if (courseId != null) {
        Get.toNamed(AppRoutes.courseDetails, arguments: courseId);
      } else {
        AppNavigation.goToRoot(tab: 0);
      }
      return;
    }

    final instituteId = _readId(data, const ['institute_id', 'instituteId']);
    if (instituteId != null || _matches(screen, type, const ['institute', 'institute_details', 'institute-details'])) {
      if (instituteId != null) {
        Get.toNamed(AppRoutes.instituteDetails, arguments: instituteId);
      } else {
        AppNavigation.goToRoot(tab: 1);
      }
      return;
    }

    if (_matches(screen, type, const [
      'enrollment',
      'enrollments',
      'enrollment_approved',
      'enrollment_pending',
      'enrollment_rejected',
      'enrollment_cancelled',
      'enrollment_status',
      'approval',
      'approved',
      'pending',
      'rejected',
      'my_courses',
      'my-courses',
      'booking',
    ])) {
      AppNavigation.goToRoot(tab: 3);
      return;
    }

    if (_matches(screen, type, const ['favorite', 'favorites'])) {
      Get.toNamed(AppRoutes.favorites);
      return;
    }

    if (_matches(screen, type, const ['profile', 'edit_profile', 'edit-profile'])) {
      Get.toNamed(AppRoutes.editProfile);
      return;
    }

    final instructorId = _readId(data, const ['instructor_id', 'instructorId']);
    if (instructorId != null || _matches(screen, type, const ['instructor', 'instructor_details'])) {
      if (instructorId != null) {
        Get.toNamed(AppRoutes.instructorDetails, arguments: instructorId);
      }
      return;
    }

    _openNotifications();
  }

  static void _openNotifications() {
    if (Get.currentRoute == AppRoutes.root) {
      Get.toNamed(AppRoutes.notifications);
      return;
    }
    Get.toNamed(AppRoutes.notifications);
  }

  static bool _matches(String? screen, String? type, List<String> keys) {
    final haystack = '${screen ?? ''} ${type ?? ''}'.toLowerCase();
    for (final key in keys) {
      if (haystack.contains(key)) return true;
    }
    return false;
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
