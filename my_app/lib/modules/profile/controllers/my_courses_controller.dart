import 'package:get/get.dart';

import '../../../core/data/repositories/enrollment_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/storage/token_storage.dart';

class MyCoursesController extends GetxController {
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
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchEnrollmentsPage(perPage: 50);
      enrollments.assignAll(result.items);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
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
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      cancellingIds.remove(enrollment.id);
    }
  }
}
