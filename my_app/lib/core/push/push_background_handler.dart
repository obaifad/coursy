import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_debug_log.dart';
import '../../firebase_options.dart';
import 'background_enrollment_checker.dart';
import 'push_local_notifications.dart';

/// معالج الإشعارات عندما يكون التطبيق في الخلفية أو مُغلقاً (isolate منفصل).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppDebugLog.fcm(
    'background: id=${message.messageId} '
    'hasNotification=${message.notification != null} data=${message.data}',
  );

  // الخادم أوصل تغيّر الحالة بنفسه — لا يكرره الفحص الخلفي أو التطبيق بإشعار محلي ثانٍ.
  try {
    await BackgroundEnrollmentChecker.recordDeliveredPush(Map<String, dynamic>.from(message.data));
  } catch (e) {
    AppDebugLog.fcm('background: record delivered failed: $e');
  }

  if (!backgroundMessageNeedsLocalNotification(message)) return;

  await PushLocalNotifications.loadUserEnabled();
  await PushLocalNotifications.ensureInitialized();
  await PushLocalNotifications.showRemoteMessageBackground(message);
}

/// رسائل الخادم فيها كتلة `notification` (FcmClient.php)، والنظام يعرضها بنفسه والتطبيق في الخلفية —
/// عرضها محلياً أيضاً كان يُظهر الإشعار مرتين. نعرض محلياً رسائل البيانات فقط (data-only).
bool backgroundMessageNeedsLocalNotification(RemoteMessage message) => message.notification == null;
