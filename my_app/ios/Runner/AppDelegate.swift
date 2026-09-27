import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // عرض الإشعارات المحلية والتطبيق مفتوح، والتعامل مع الضغط عليها (flutter_local_notifications + FCM).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // فحص حالة التسجيل الدوري في الخلفية (Workmanager).
    // المعرّف يجب أن يطابق BGTaskSchedulerPermittedIdentifiers في Info.plist و EnrollmentWatchScheduler.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "enrollment-periodic-watch",
      frequency: NSNumber(value: 15 * 60)
    )

    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
