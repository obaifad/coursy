import 'package:get/get.dart';

import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/favorites/controllers/favorites_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/notifications/controllers/notifications_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
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
    if (Get.isRegistered<FavoritesController>()) {
      tasks.add(Get.find<FavoritesController>().reloadFromService(forceSync: true));
    }
    if (Get.isRegistered<NotificationsController>()) {
      tasks.add(Get.find<NotificationsController>().loadNotifications());
    }
    if (Get.isRegistered<PrivateInstructorsController>()) {
      tasks.add(Get.find<PrivateInstructorsController>().reloadLocalizedData());
    }
    if (Get.isRegistered<SearchPageController>()) {
      tasks.add(Get.find<SearchPageController>().reloadLocalizedData());
      final s = Get.find<SearchPageController>();
      if (s.queryController.text.trim().isNotEmpty || s.hasActiveFilters) {
        tasks.add(s.runSearch(resetPage: true, saveRecent: false));
      }
    }
    if (Get.isRegistered<ProfileController>()) {
      tasks.add(Get.find<ProfileController>().reloadLocalizedData());
    }
    if (Get.isRegistered<AuthController>()) {
      tasks.add(Get.find<AuthController>().reloadLocalizedData());
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }
}
