import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/enrollment_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/enrollment_status_coordinator.dart';
import '../../../core/services/enrollment_sync_service.dart';
import '../../../core/services/enrollment_watch_scheduler.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/course_registration_guard.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/registration_closed_dialog.dart';
import '../../../core/utils/app_toast.dart';

class BookingController extends GetxController {
  final EnrollmentRepository _enrollmentRepository = Get.find();

  final isSubmitting = false.obs;
  late final CourseModel course;

  @override
  void onInit() {
    super.onInit();
    course = Get.arguments as CourseModel;
    if (course.isRegistrationClosed || course.isFull) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await RegistrationClosedDialog.show(course);
        if (Get.currentRoute == AppRoutes.courseBooking) Get.back<void>();
      });
    }
  }

  Future<void> confirmBooking() async {
    if (isSubmitting.value) return;
    // القفل قبل التحقق من فتح التسجيل (انتظار): ضغطتان سريعتان كانتا ترسلان حجزين.
    isSubmitting.value = true;
    try {
      if (!await CourseRegistrationGuard.ensureOpen(course)) return;
      final enrollment = await _enrollmentRepository.enrollInCourse(course.id);
      // إعادة الحجز بعد الإلغاء/الرفض: الخادم يُرجع السجل القديم بحالته (200) ولا ينشئ طلباً جديداً.
      final status = enrollment.status.toLowerCase();
      if (status == 'cancelled' || status == 'rejected') {
        AppToast.show(
          'booking_failed_title'.tr,
          status == 'cancelled' ? 'booking_previously_cancelled'.tr : 'booking_previously_rejected'.tr,
          duration: const Duration(seconds: 5),
          kind: ToastKind.error,
        );
        return;
      }
      if (Get.isRegistered<EnrollmentStatusCoordinator>()) {
        Get.find<EnrollmentStatusCoordinator>().markPending(enrollment);
      }
      AppToast.show('booking_success_title'.tr, 'booking_success_msg'.tr, kind: ToastKind.success);
      // التحديث في الخلفية: «دوراتي» تُحدَّث وهي ظاهرة بدل انتظار إعادة تحميل كل الشاشات قبل الانتقال.
      unawaited(SessionRefresh.afterEnrollment(courseId: course.id).catchError((Object _) {}));
      if (Get.isRegistered<EnrollmentSyncService>()) {
        unawaited(Get.find<EnrollmentSyncService>().checkForStatusChanges());
      }
      unawaited(EnrollmentWatchScheduler.scheduleAfterEnrollment(enrollment.id));
      AppNavigation.goToRoot(tab: 3);
      // بعد التسجيل فقط يُعرض عنوان شام كاش (التحويل قبل التسجيل يُرفض من الخادم).
      // الدورات الأونلاين لا تُدفع داخل التطبيق: تُدفع للمعهد مباشرة.
      if (!course.isOnline && (course.requiresAdvancePayment || enrollment.canPay)) {
        unawaited(Get.toNamed(AppRoutes.payment, arguments: enrollment));
      }
      // بعد بدء الانتقالات: الطلب ينتظر انتهاءها كلها قبل نافذة النظام.
      if (Get.isRegistered<PushNotificationService>()) {
        unawaited(Get.find<PushNotificationService>().requestPermissionAfterBooking());
      }
    } on ApiException catch (e) {
      AppToast.show('booking_failed_title'.tr, e.message, kind: ToastKind.error);
    } catch (_) {
      AppToast.show('error'.tr, 'booking_failed_generic'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }
}
