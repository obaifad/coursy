import 'package:get/get.dart';

import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/notifications/controllers/notifications_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/instructors/controllers/private_instructors_controller.dart';
import '../../modules/search/controllers/search_controller.dart';

/// إعادة تحميل بيانات الـ API بعد تغيير اللغة.
abstract final class LocaleRefresh {
  static Future<void> reloadAll() async {
    final tasks = <Future<void>>[];

    if (Get.isRegistered<HomeController>()) {
      tasks.add(Get.find<HomeController>().reloadLocalizedData());
    }
    if (Get.isRegistered<CoursesController>()) {
      final c = Get.find<CoursesController>();
      tasks.add(c.reloadLocalizedData());
    }
    if (Get.isRegistered<InstitutesController>()) {
      final i = Get.find<InstitutesController>();
      tasks.add(i.reloadLocalizedData());
    }
    if (Get.isRegistered<MyCoursesController>()) {
      tasks.add(Get.find<MyCoursesController>().load());
    }
    if (Get.isRegistered<NotificationsController>()) {
      tasks.add(Get.find<NotificationsController>().loadNotifications());
    }
    if (Get.isRegistered<PrivateInstructorsController>()) {
      tasks.add(Get.find<PrivateInstructorsController>().reloadLocalizedData());
    }
    if (Get.isRegistered<SearchPageController>()) {
      final s = Get.find<SearchPageController>();
      if (s.queryController.text.trim().isNotEmpty || s.hasActiveFilters) {
        tasks.add(s.runSearch(resetPage: true, saveRecent: false));
      }
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }
}
