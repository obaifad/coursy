import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// الإشعارات العلوية العابرة بشكل واحد في كل التطبيق (بدل Get.snackbar بنمطه الافتراضي):
/// بطاقة بيضاء بزوايا مدوّرة وشريط جانبي ملوّن بنوعها (نجاح، خطأ، تنبيه، معلومة)، وتحلّ الجديدة مكان
/// القديمة فلا تتراكم رسائل فوق بعضها.
enum ToastKind { info, success, error, warning }

abstract final class AppToast {
  /// للاختبارات: يلتقط التنبيه بدل عرضه (Get.snackbar يحتاج Overlay وإطارات مرسومة).
  @visibleForTesting
  static void Function(String title, String message, ToastKind kind)? onShow;

  static void show(
    String title,
    String message, {
    ToastKind? kind,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
  }) {
    final resolved = kind ?? _guess(title);
    final hook = onShow;
    if (hook != null) {
      hook(title, message, resolved);
      return;
    }
    final (color, icon) = switch (resolved) {
      ToastKind.success => (AppColors.successText, Icons.check_circle_rounded),
      ToastKind.error => (AppColors.danger, Icons.error_rounded),
      ToastKind.warning => (const Color(0xFFD97706), Icons.warning_amber_rounded),
      ToastKind.info => (AppColors.primary, Icons.info_rounded),
    };
    // الجديدة تحلّ مكان القديمة فوراً.
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      duration: duration,
      snackPosition: position,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      borderRadius: AppRadius.md,
      backgroundColor: AppColors.card,
      colorText: AppColors.textPrimary,
      boxShadows: const [BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6))],
      icon: Icon(icon, color: color),
      shouldIconPulse: false,
      leftBarIndicatorColor: color,
      titleText: Text(
        title,
        style: AppFonts.tajawal(fontSize: AppTextSize.md, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      ),
      messageText: Text(
        message,
        style: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w500, color: AppColors.textBody),
      ),
    );
  }

  /// النوع من العنوان حين لا يحدده المستدعي: «خطأ/فشل» أحمر، «تنبيه» برتقالي، غير ذلك معلومة.
  static ToastKind _guess(String title) {
    final t = title.toLowerCase();
    if (t.contains('خطأ') || t.contains('فشل') || t.contains('error') || t.contains('failed')) return ToastKind.error;
    if (t.contains('تنبيه') || t.contains('alert') || t.contains('انتهت') || t.contains('expired')) {
      return ToastKind.warning;
    }
    return ToastKind.info;
  }
}
