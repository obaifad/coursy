import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/repositories/enrollment_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/enrollment_status_coordinator.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/storage/token_storage.dart';

class MyCoursesController extends GetxController with LatestLoadGuard {
  final EnrollmentRepository _repository = Get.find();

  final isLoading = true.obs;
  final cancellingIds = <int>{}.obs;
  final errorMessage = RxnString();
  final enrollments = <EnrollmentModel>[].obs;

  bool get isLoggedIn => Get.find<TokenStorage>().isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!isLoggedIn) {
      clearForLogout();
      return;
    }
    final session = beginLoad();
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchEnrollmentsPage(perPage: 50);
      applyIfCurrent(session, () => enrollments.assignAll(result.items));
      if (Get.isRegistered<EnrollmentStatusCoordinator>()) {
        unawaited(Get.find<EnrollmentStatusCoordinator>().trackFromEnrollments(result.items));
      }
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = userErrorMessage(e);
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  /// يدمج نتيجة الفحص الدوري مع القائمة الحالية بدون حذف عناصر غير موجودة في الصفحة المُرجعة
  /// (الفحص الدوري قد يُرجع الصفحة الأولى فقط من الخادم).
  void mergeEnrollments(List<EnrollmentModel> fresh) {
    if (fresh.isEmpty) return;
    final merged = List<EnrollmentModel>.from(enrollments);
    for (final item in fresh) {
      final index = merged.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        merged[index] = item;
      } else {
        merged.insert(0, item);
      }
    }
    enrollments.assignAll(merged);
  }

  List<EnrollmentModel> byStatus(Set<String> statuses) {
    return enrollments.where((e) => statuses.contains(e.status)).toList();
  }

  List<EnrollmentModel> get pending => byStatus({'pending'});
  List<EnrollmentModel> get confirmed => byStatus({'approved', 'confirmed'});
  List<EnrollmentModel> get cancelled => byStatus({'cancelled', 'rejected'});
  List<EnrollmentModel> get completed => byStatus({'completed'});

  int get totalCount => enrollments.length;
  int get pendingCount => pending.length;
  int get confirmedCount => confirmed.length;
  int get completedCount => completed.length;
  int get cancelledCount => cancelled.length;

  Future<void> cancelEnrollment(EnrollmentModel enrollment) async {
    if (!enrollment.canCancel || cancellingIds.contains(enrollment.id)) return;
    cancellingIds.add(enrollment.id);
    try {
      final updated = await _repository.cancelEnrollment(enrollment.id);
      final index = enrollments.indexWhere((item) => item.id == enrollment.id);
      if (index >= 0) {
        enrollments[index] = updated;
      } else {
        await load();
      }
      Get.snackbar('booking_cancelled_title'.tr, 'booking_cancelled_msg'.tr);
      await SessionRefresh.afterEnrollment(courseId: enrollment.courseId, enrollmentId: enrollment.id);
    } catch (e) {
      Get.snackbar('error'.tr, userErrorMessage(e));
    } finally {
      cancellingIds.remove(enrollment.id);
    }
  }

  void clearForLogout() {
    enrollments.clear();
    cancellingIds.clear();
    errorMessage.value = null;
    isLoading.value = false;
  }
}
