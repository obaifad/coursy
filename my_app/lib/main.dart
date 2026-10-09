import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'core/bindings/app_bindings.dart';
import 'core/config/app_debug_log.dart';
import 'core/locale/locale_controller.dart';
import 'core/push/firebase_bootstrap.dart';
import 'core/services/app_lifecycle_sync.dart';
import 'core/services/enrollment_sync_service.dart';
import 'core/services/enrollment_watch_scheduler.dart';
import 'core/services/favorites_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/recent_search_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPhonesToPortrait();
  await bootstrapFirebase();
  await EnrollmentWatchScheduler.init();
  await GetStorage.init();
  AppBindings().dependencies();
  await Get.find<LocaleController>().init();
  await Get.find<TokenStorage>().init();
  await Get.find<RecentSearchStorage>().init();
  if (Get.isRegistered<PushNotificationService>()) {
    await Get.find<PushNotificationService>().init();
  }

  runApp(const SyrianEducationApp());
  unawaited(_postLaunchSync());
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
