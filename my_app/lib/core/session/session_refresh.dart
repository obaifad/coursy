import 'dart:async';

import 'package:get/get.dart';

import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/favorites/controllers/favorites_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/notifications/controllers/notifications_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../cache/memory_cache.dart';
import '../services/course_rating_service.dart';
import '../services/favorites_service.dart';
import '../services/app_lifecycle_sync.dart';
import '../services/enrollment_sync_service.dart';
import '../services/enrollment_watch_scheduler.dart';
import '../services/push_notification_service.dart';
import '../config/app_debug_log.dart';
import '../navigation/app_navigation.dart';
import '../storage/recent_search_storage.dart';
import '../storage/api_disk_cache.dart';
import '../storage/home_cache.dart';
import '../storage/token_storage.dart';
import '../../routes/app_routes.dart';
import 'enrollment_status_coordinator.dart';
import 'remote_notification_sync.dart';
import '../utils/app_toast.dart';

/// تنسيق إعادة تحميل الحالة بعد تسجيل الدخول/الخروج والعمليات التي تغيّر البيانات.
abstract final class SessionRefresh {
  /// بعد نجاح تسجيل الدخول أو التسجيل.
  static Future<void> onLoginSuccess() async {
    MemoryCache.clear();
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
      // تسجيل التوكن فقط: إذن الإشعارات يُطلب بعد أول حجز أو من الإعدادات — طلبه هنا كان يُظهر نافذة
      // النظام وزر الدخول ما زال يدور.
      await Get.find<PushNotificationService>().ensurePermissionsAndSyncToken(requestPermission: false);
    }
    if (Get.isRegistered<AppLifecycleSync>()) {
      Get.find<AppLifecycleSync>().startWatching();
    }
    await EnrollmentWatchScheduler.startForLoggedInUser();
  }

  /// عند تسجيل الخروج — مسح الذاكرة المؤقتة في كل المتحكمات النشطة وإلغاء تسجيل الجهاز (يحتاج التوكن).
  /// لا يعيد تحميل البيانات العامة: ذلك في [reloadAsGuest] بعد مسح التوكن، حتى لا ينتظره الانتقال.
  static Future<void> onLogout() async {
    MemoryCache.clear();
    if (Get.isRegistered<RecentSearchStorage>()) {
      await Get.find<RecentSearchStorage>().clear();
    }
    if (Get.isRegistered<HomeCache>()) {
      await Get.find<HomeCache>().clearStudentEntries();
    }
    if (Get.isRegistered<ApiDiskCache>()) {
      await Get.find<ApiDiskCache>().clearStudentEntries();
    }
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

  static bool _handlingInactive = false;

  /// 403 `account_inactive` (ApiClient.onAccountInactive): الإدارة أوقفت حساب الطالب. مثل انتهاء الجلسة
  /// (SessionExpiry) — مسح الجلسة وشاشة الدخول — لكن برسالة الخادم بدل «انتهت الجلسة».
  static Future<void> onAccountInactive(String message) async {
    if (_handlingInactive) return;
    final storage = Get.isRegistered<TokenStorage>() ? Get.find<TokenStorage>() : null;
    if (storage == null || !storage.isLoggedIn) return;
    _handlingInactive = true;
    try {
      AppDebugLog.api('403', 'account inactive — clearing local session');
      // التوكن أولاً: الطلبات اللاحقة تُرسل بلا توكن فلا تتكرر 403.
      await storage.clearSession();
      await onLogout();
      reloadAsGuest();
      AppNavigation.goToRoot(tab: 2);
      Get.toNamed(AppRoutes.login);
      AppToast.show('account_inactive_title'.tr, message, duration: const Duration(seconds: 6), kind: ToastKind.error);
    } catch (e) {
      AppDebugLog.api('403', 'account inactive cleanup failed: $e');
    } finally {
      _handlingInactive = false;
    }
  }

  /// بعد مسح التوكن والانتقال: إعادة تحميل الرئيسية والدورات والمعاهد كضيف في الخلفية.
  static void reloadAsGuest() {
    unawaited(
      Future.wait<void>([
        if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadHome(forceRefresh: true),
        if (Get.isRegistered<CoursesController>()) Get.find<CoursesController>().reloadLocalizedData(),
        if (Get.isRegistered<InstitutesController>()) Get.find<InstitutesController>().reloadLocalizedData(),
      ]).catchError((_) => const <void>[]),
    );
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
