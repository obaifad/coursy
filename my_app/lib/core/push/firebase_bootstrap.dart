import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_debug_log.dart';
import '../../firebase_options.dart';
import 'push_background_handler.dart';
import 'push_local_notifications.dart';

/// مشروع Firebase على السيرفر — يجب أن يطابق ملفات google-services.json.
const expectedFirebaseProjectId = 'coursy-ec580';

/// تهيئة Firebase ومسجّل الخلفية — يُستدعى من `main` قبل `runApp`.
Future<void> bootstrapFirebase() async {
  if (kIsWeb) return;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final projectId = Firebase.app().options.projectId;
    AppDebugLog.fcm('Firebase project: $projectId');
    if (projectId != expectedFirebaseProjectId) {
      AppDebugLog.fcm(
        'WARNING: Firebase project mismatch — app=$projectId backend=$expectedFirebaseProjectId. '
        'Download google-services.json from the production Firebase project and rebuild.',
      );
    }

    await _setUpCrashReporting();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushLocalNotifications.ensureInitialized();
  } catch (e) {
    AppDebugLog.fcm('initialize failed: $e');
  }
}

/// تقارير الأعطال: أخطاء Flutter وأخطاء Dart غير الملتقطة تُرسل إلى Crashlytics في نسخ الإصدار فقط.
Future<void> _setUpCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  if (kDebugMode) return;

  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
