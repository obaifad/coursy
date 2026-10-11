import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../push/background_enrollment_checker.dart';

/// جدولة فحص التسجيلات في الخلفية (Android Workmanager).
abstract final class EnrollmentWatchScheduler {
  /// يجب أن يطابق BGTaskSchedulerPermittedIdentifiers في ios/Runner/Info.plist و AppDelegate.swift.
  static const _periodicId = 'enrollment-periodic-watch';

  static Future<void> init() async {
    if (kIsWeb) return;
    await Workmanager().initialize(enrollmentBackgroundCallback);
  }

  static Future<void> startForLoggedInUser() async {
    if (kIsWeb) return;

    await Workmanager().registerPeriodicTask(
      _periodicId,
      enrollmentBackgroundTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Android فقط: iOS لا يسمح بمهام خلفية بمواعيد دقيقة (1–15 دقيقة) ولا بمعرّفات ديناميكية
  /// غير مسجّلة في Info.plist — هناك يكفي الفحص الدوري + FCM.
  static Future<void> scheduleAfterEnrollment(int enrollmentId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    const delays = [1, 2, 5, 10, 15];
    for (final minutes in delays) {
      await Workmanager().registerOneOffTask(
        'enrollment-watch-$enrollmentId-$minutes',
        enrollmentBackgroundTask,
        initialDelay: Duration(minutes: minutes),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
  }
}
