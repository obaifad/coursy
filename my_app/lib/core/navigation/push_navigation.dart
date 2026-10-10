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

    // المعرّفات أولاً: نوع إشعار Laravel قد يكون اسم الصنف (`App\Notifications\…`)، فمطابقة كلمة
    // «notification» قبلها كانت تفتح قائمة الإشعارات بدل الدورة.
    final courseId = _readId(data, const ['course_id', 'courseId']);
    if (courseId != null) {
      Get.toNamed(AppRoutes.courseDetails, arguments: courseId);
      return;
    }

    final instituteId = _readId(data, const ['institute_id', 'instituteId']);
    if (instituteId != null) {
      Get.toNamed(AppRoutes.instituteDetails, arguments: instituteId);
      return;
    }

    final instructorId = _readId(data, const ['instructor_id', 'instructorId']);
    if (instructorId != null) {
      Get.toNamed(AppRoutes.instructorDetails, arguments: instructorId);
      return;
    }

    if (_matches(screen, type, const [
      'enrollment',
      'approval',
      'approved',
      'pending',
      'rejected',
      'cancelled',
      'my_courses',
      'my-courses',
      'booking',
      'payment',
    ])) {
      AppNavigation.goToRoot(tab: 3);
      return;
    }

    if (_matches(screen, type, const ['new_course', 'newcourse', 'course'])) {
      AppNavigation.goToRoot(tab: 0);
      return;
    }

    if (_matches(screen, type, const ['institute'])) {
      AppNavigation.goToRoot(tab: 1);
      return;
    }

    if (_matches(screen, type, const ['favorite'])) {
      Get.toNamed(AppRoutes.favorites);
      return;
    }

    if (_matches(screen, type, const ['profile'])) {
      Get.toNamed(AppRoutes.editProfile);
      return;
    }

    _openNotifications();
  }

  /// لا نفتح صفحة إشعارات فوق نفسها (الضغط على إشعار بلا وجهة من داخل القائمة).
  static void _openNotifications() {
    if (Get.currentRoute == AppRoutes.notifications) return;
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
