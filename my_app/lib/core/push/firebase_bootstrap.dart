import 'package:firebase_core/firebase_core.dart';
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

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushLocalNotifications.ensureInitialized();
  } catch (e) {
    AppDebugLog.fcm('initialize failed: $e');
  }
}