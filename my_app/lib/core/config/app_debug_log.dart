import 'package:flutter/foundation.dart';

/// تحكم في سجلات التطوير — الافتراضي هادئ لقراءة التيرمنال.
abstract final class AppDebugLog {
  /// سطر واحد لكل طلب API.
  static const logApiRequests = true;

  /// طباعة Bearer token — اتركه false لأسباب أمنية.
  static const logAuthSecrets = false;

  /// جسم استجابة API كامل (favorites, enrollments, reviews...).
  static const logApiBodies = false;

  /// رمز OTP في التيرمنال أثناء التطوير.
  static const logOtp = true;

  /// تفاصيل FCM.
  static const logFcm = true;

  static void api(String method, String path) {
    if (!kDebugMode || !logApiRequests) return;
    debugPrint('[API] $method $path');
  }

  static void fcm(String message) {
    if (!kDebugMode || !logFcm) return;
    debugPrint('[FCM] $message');
  }

  static void repo(String tag, String message) {
    if (!kDebugMode || !logApiBodies) return;
    debugPrint('[$tag] $message');
  }

  static void secret(String message) {
    if (!kDebugMode || !logAuthSecrets) return;
    debugPrint(message);
  }

  static void otp(String message) {
    if (!kDebugMode || !logOtp) return;
    debugPrint(message);
  }
}
