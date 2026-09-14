import 'package:get/get.dart';

import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/favorites/controllers/favorites_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/notifications/controllers/notifications_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../services/course_rating_service.dart';
import '../services/favorites_service.dart';
import '../services/app_lifecycle_sync.dart';
import '../services/enrollment_sync_service.dart';
import '../services/enrollment_watch_scheduler.dart';
import '../services/push_notification_service.dart';
import 'enrollment_status_coordinator.dart';
import 'remote_notification_sync.dart';

/// تنسيق إعادة تحميل الحالة بعد تسجيل الدخول/الخروج والعمليات التي تغيّر البيانات.
abstract final class SessionRefresh {
  /// بعد نجاح تسجيل الدخول أو التسجيل.
  static Future<void> onLoginSuccess() async {
    if (Get.isRegistered<CourseRatingService>()) {
      Get.find<CourseRatingService>().invalidateCache();
    }
    if (Get.isRegistered<FavoritesService>()) {
      await Get.find<FavoritesService>().syncFromApi(force: true);
    }
    if (Get.isRegistered<ProfileController>()) {
      try {
        await Get.find<ProfileController>().refreshForEdit();
      } catch (_) {}
    }
    if (Get.isRegistered<EnrollmentSyncService>()) {
      await Get.find<EnrollmentSyncService>().seedStatuses();
    } else if (Get.isRegistered<EnrollmentStatusCoordinator>()) {
      Get.find<EnrollmentStatusCoordinator>().reset();
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHome(forceRefresh: true);
    }
    if (Get.isRegistered<MyCoursesController>()) {
      await Get.find<MyCoursesController>().load();
    }
    if (Get.isRegistered<FavoritesController>()) {
      await Get.find<FavoritesController>().reloadFromService(forceSync: false);
    }
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().loadNotifications();
    }
    if (Get.isRegistered<PushNotificationService>()) {
      await Get.find<PushNotificationService>().ensurePermissionsAndSyncToken();
    }
    if (Get.isRegistered<AppLifecycleSync>()) {
      Get.find<AppLifecycleSync>().startWatching();
    }
    await EnrollmentWatchScheduler.startForLoggedInUser();
  }

  /// بعد تسجيل الخروج — مسح الذاكرة المؤقتة في كل المتحكمات النشطة.
  static Future<void> onLogout() async {
    if (Get.isRegistered<FavoritesService>()) {
      Get.find<FavoritesService>().clearForLogout();
    }
    if (Get.isRegistered<CourseRatingService>()) {
      Get.find<CourseRatingService>().invalidateCache();
    }
    if (Get.isRegistered<MyCoursesController>()) {
      Get.find<MyCoursesController>().clearForLogout();
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearForLogout();
    }
    if (Get.isRegistered<FavoritesController>()) {
      Get.find<FavoritesController>().clearForLogout();
    }
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().clearForLogout();
    }
    if (Get.isRegistered<EnrollmentSyncService>()) {
      Get.find<EnrollmentSyncService>().clearForLogout();
    } else if (Get.isRegistered<EnrollmentStatusCoordinator>()) {
      Get.find<EnrollmentStatusCoordinator>().reset();
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHome(forceRefresh: true);
    }
    if (Get.isRegistered<CoursesController>()) {
      await Get.find<CoursesController>().reloadLocalizedData();
    }
    if (Get.isRegistered<InstitutesController>()) {
      await Get.find<InstitutesController>().reloadLocalizedData();
    }
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().resetAfterLogout();
    }
    if (Get.isRegistered<PushNotificationService>()) {
      await Get.find<PushNotificationService>().onLogout();
    }
    if (Get.isRegistered<AppLifecycleSync>()) {
      Get.find<AppLifecycleSync>().stopWatching();
    }
    await EnrollmentWatchScheduler.stop();
  }

  /// بعد التسجيل في دورة جديدة أو تغيّر حالة التسجيل (موافقة المعهد، رفض، إلخ).
  static Future<void> afterEnrollment({int? courseId, int? enrollmentId}) =>
      afterEnrollmentStatusChanged(courseId: courseId, enrollmentId: enrollmentId);

  static Future<void> afterEnrollmentStatusChanged({int? courseId, int? enrollmentId}) async {
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().loadNotifications();
    }
    if (Get.isRegistered<MyCoursesController>()) {
      await Get.find<MyCoursesController>().load();
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHome(forceRefresh: true);
    }
    if (Get.isRegistered<CoursesController>()) {
      await Get.find<CoursesController>().reloadLocalizedData();
    }
    if (courseId != null && courseId > 0) {
      await RemoteNotificationSync.refreshCourseDetailsIfVisible(courseId);
    }
  }

  /// بعد تعديل الملف الشخصي — تحديث الشاشات التي تعتمد على اهتمامات المستخدم.
  static Future<void> afterProfileSaved() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHome(forceRefresh: true);
    }
  }
}
