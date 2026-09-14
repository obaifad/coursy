import 'package:get/get.dart';

import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/favorites/controllers/favorites_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/search/controllers/search_controller.dart';
import '../models/app_models.dart';

/// مزامنة بيانات الدورة عبر القوائم المفتوحة في التطبيق.
abstract final class CourseCatalogSync {
  /// يحدّث نسخة الدورة في كل القوائم التي تعرضها (بعد جلب تفاصيل حديثة).
  static void patchCourse(CourseModel updated) {
    if (updated.id <= 0) return;

    void patchList(RxList<CourseModel> list) {
      final index = list.indexWhere((course) => course.id == updated.id);
      if (index >= 0) list[index] = updated;
    }

    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      patchList(home.courses);
      patchList(home.suggestedCourses);
    }
    if (Get.isRegistered<CoursesController>()) {
      patchList(Get.find<CoursesController>().courses);
    }
    if (Get.isRegistered<FavoritesController>()) {
      patchList(Get.find<FavoritesController>().courses);
    }
    if (Get.isRegistered<InstituteDetailsController>()) {
      patchList(Get.find<InstituteDetailsController>().courses);
    }
    if (Get.isRegistered<MyCoursesController>()) {
      final my = Get.find<MyCoursesController>();
      for (var i = 0; i < my.enrollments.length; i++) {
        final enrollment = my.enrollments[i];
        if (enrollment.courseId != updated.id) continue;
        my.enrollments[i] = EnrollmentModel(
          id: enrollment.id,
          status: enrollment.status,
          paymentStatus: enrollment.paymentStatus,
          courseId: enrollment.courseId,
          courseTitle: updated.title,
          course: updated,
        );
      }
    }
    if (Get.isRegistered<SearchPageController>()) {
      patchList(Get.find<SearchPageController>().courses);
    }
  }

  /// إعادة جلب قوائم الدورات الرئيسية من الـ API.
  static Future<void> refreshPrimaryLists() async {
    final tasks = <Future<void>>[];
    if (Get.isRegistered<HomeController>()) {
      tasks.add(Get.find<HomeController>().loadHome(forceRefresh: true));
    }
    if (Get.isRegistered<CoursesController>()) {
      tasks.add(Get.find<CoursesController>().loadCourses());
    }
    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }
}
