import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_debug_log.dart';
import '../../firebase_options.dart';
import 'push_local_notifications.dart';

/// معالج الإشعارات عندما يكون التطبيق في الخلفية أو مُغلقاً (isolate منفصل).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppDebugLog.fcm(
    'background: id=${message.messageId} '
    'hasNotification=${message.notification != null} data=${message.data}',
  );

  await PushLocalNotifications.ensureInitialized();
  await PushLocalNotifications.showRemoteMessageBackground(message);
}
