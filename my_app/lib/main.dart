import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'core/bindings/app_bindings.dart';
import 'core/config/app_debug_log.dart';
import 'core/locale/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/push/firebase_bootstrap.dart';
import 'core/services/app_config_service.dart';
import 'core/services/app_lifecycle_sync.dart';
import 'core/services/enrollment_sync_service.dart';
import 'core/services/enrollment_watch_scheduler.dart';
import 'core/services/favorites_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/session/session_expiry.dart';
import 'core/session/session_refresh.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/recent_search_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // كل خطوة معزولة: فشل واحدة (Firebase، التخزين، الإشعارات…) لا يمنع التطبيق من الإقلاع،
  // وفي أسوأ حال يبدأ بلا جلسة (ضيف) بدل شاشة بيضاء.
  await _step('orientation', _lockPhonesToPortrait);
  await _step('firebase', bootstrapFirebase);
  await _step('enrollment-watch', EnrollmentWatchScheduler.init);
  await _step('storage', GetStorage.init);
  AppBindings().dependencies();
  ApiClient.onUnauthorized = () => unawaited(SessionExpiry.handle());
  // حساب أوقفه المشرف (403 account_inactive): خروج مع رسالة الخادم بدل «انتهت الجلسة».
  ApiClient.onAccountInactive = (message) => unawaited(SessionRefresh.onAccountInactive(message));
  // اللغة أولاً: تضبط Accept-Language، وإلا طُلبت إعدادات التطبيق (ورسالة الصيانة) بالعربية دائماً.
  await _step('locale', Get.find<LocaleController>().init);
  // يبدأ جلب إعدادات التطبيق مبكراً؛ يُعرض أي تنبيه بعد الانتقال من شاشة البداية.
  unawaited(_step('app-config', Get.find<AppConfigService>().load));
  await _step('session', Get.find<TokenStorage>().init);
  await _step('recent-search', Get.find<RecentSearchStorage>().init);
  if (Get.isRegistered<PushNotificationService>()) {
    await _step('push', Get.find<PushNotificationService>().init);
  }

  runApp(const SyrianEducationApp());
  unawaited(_postLaunchSync());
}

Future<void> _step(String name, Future<void> Function() run) async {
  try {
    await run();
  } catch (e, st) {
    AppDebugLog.repo('Startup', '$name failed: $e $st');
  }
}

/// الهواتف بالوضع العمودي فقط (التخطيط مصمَّم له)؛ التابلت (أقصر ضلع ≥ 600) يدور بحرية.
Future<void> _lockPhonesToPortrait() async {
  final displays = WidgetsBinding.instance.platformDispatcher.displays;
  if (displays.isEmpty) return;
  final display = displays.first;
  if (display.size.shortestSide / display.devicePixelRatio >= 600) return;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

/// مزامنة بعد فتح الواجهة — لا نحجب runApp بانتظار الشبكة.
Future<void> _postLaunchSync() async {
  await Future<void>.delayed(const Duration(milliseconds: 800));
  if (!Get.find<TokenStorage>().isLoggedIn) return;

  try {
    if (Get.isRegistered<PushNotificationService>()) {
      // الإذن يُطلب في PushNotificationService.init — هنا نزامن التوكن فقط.
      await Get.find<PushNotificationService>().ensurePermissionsAndSyncToken(requestPermission: false);
    }
  } catch (e) {
    AppDebugLog.fcm('post-launch token sync failed: $e');
  }

  try {
    if (Get.isRegistered<FavoritesService>()) {
      await Get.find<FavoritesService>().syncFromApi();
    }
  } catch (e) {
    AppDebugLog.repo('Favorites', 'post-launch sync failed: $e');
  }

  try {
    if (Get.isRegistered<EnrollmentSyncService>()) {
      await Get.find<EnrollmentSyncService>().seedStatuses();
    }
  } catch (e) {
    AppDebugLog.repo('EnrollmentSync', 'seed failed: $e');
  }

  if (Get.isRegistered<AppLifecycleSync>()) {
    Get.find<AppLifecycleSync>().startWatching();
  }
  await EnrollmentWatchScheduler.startForLoggedInUser();
}
