import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../widgets/registration_closed_dialog.dart';
import '../models/app_models.dart';
import 'auth_guard.dart';

/// يتحقق من فتح فترة التسجيل قبل الانتقال لشاشة الحجز.
abstract final class CourseRegistrationGuard {
  static Future<bool> ensureOpen(CourseModel course) async {
    if (course.isRegistrationOpen) return true;
    await RegistrationClosedDialog.show(course);
    return false;
  }

  static Future<void> openBooking(CourseModel course, {String? loginMessage}) async {
    if (!await ensureOpen(course)) return;
    if (!await AuthGuard.requireLogin(message: loginMessage ?? 'book_login_required'.tr)) return;
    await Get.toNamed(AppRoutes.courseBooking, arguments: course);
  }
}
