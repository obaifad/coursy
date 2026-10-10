import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../config/app_debug_log.dart';
import '../navigation/app_navigation.dart';
import '../storage/token_storage.dart';
import 'session_refresh.dart';

/// عند انتهاء الجلسة من جهة الخادم (401: تغيير كلمة المرور، تسجيل خروج من لوحة التحكم، حذف الحساب من الموقع)
/// ننظّف الجلسة محلياً ونعيد المستخدم لشاشة الدخول بدل أن يبقى «نصف مسجّل» وكل طلب يفشل.
abstract final class SessionExpiry {
  static bool _handling = false;

  static Future<void> handle() async {
    if (_handling) return;
    final storage = Get.isRegistered<TokenStorage>() ? Get.find<TokenStorage>() : null;
    if (storage == null || !storage.isLoggedIn) return;
    _handling = true;
    try {
      AppDebugLog.api('401', 'session expired — clearing local session');
      // التوكن أولاً: الطلبات اللاحقة تُرسل بلا توكن فلا تتكرر 401.
      await storage.clearSession();
      await SessionRefresh.onLogout();
      AppNavigation.goToRoot(tab: 2);
      Get.toNamed(AppRoutes.login);
      Get.snackbar('session_expired_title'.tr, 'session_expired_msg'.tr, duration: const Duration(seconds: 4));
    } catch (e) {
      AppDebugLog.api('401', 'session cleanup failed: $e');
    } finally {
      _handling = false;
    }
  }
}
