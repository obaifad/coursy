import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../widgets/registration_closed_dialog.dart';
import '../models/app_models.dart';
import 'app_toast.dart';
import 'auth_guard.dart';

/// يتحقق من فتح فترة التسجيل ومن وجود مقاعد قبل الانتقال لشاشة الحجز.
abstract final class CourseRegistrationGuard {
  static Future<bool> ensureOpen(CourseModel course) async {
    if (!course.isRegistrationOpen) {
      await RegistrationClosedDialog.show(course);
      return false;
    }
    if (course.isFull) {
      AppToast.show('course_full'.tr, 'course_full_message'.tr, kind: ToastKind.error);
      return false;
    }
    return true;
  }

  static Future<void> openBooking(CourseModel course, {String? loginMessage}) async {
    if (!await ensureOpen(course)) return;
    if (!await AuthGuard.requireLogin(message: loginMessage ?? 'book_login_required'.tr)) return;
    await Get.toNamed(AppRoutes.courseBooking, arguments: course);
  }
}
