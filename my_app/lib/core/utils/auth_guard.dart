import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../storage/token_storage.dart';

/// يتحقق من تسجيل الدخول قبل إجراءات تتطلب حساباً.
class AuthGuard {
  static bool get isLoggedIn => Get.find<TokenStorage>().isLoggedIn;

  static Future<bool> requireLogin({String? message}) async {
    if (isLoggedIn) return true;
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('login_required_title'.tr),
        content: Text(message ?? 'login_required_default'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('login'.tr),
          ),
        ],
      ),
    );
    if (result == true) {
      await Get.toNamed(AppRoutes.login);
    }
    return false;
  }

  /// ينفّذ [action] فقط إذا كان المستخدم مسجّل الدخول.
  static Future<void> runIfLoggedIn(Future<void> Function() action, {String? message}) async {
    if (await requireLogin(message: message)) await action();
  }

  /// ينفّذ [action] فقط إذا كان المستخدم مسجّل الدخول (متزامن).
  static Future<void> runIfLoggedInSync(void Function() action, {String? message}) async {
    if (await requireLogin(message: message)) action();
  }
}
