import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/data/repositories/review_repository.dart';
import '../core/models/app_models.dart';
import '../core/network/api_exception.dart';
import '../core/services/student_id_resolver.dart';
import 'app_loading.dart';
import 'app_selection_sheet.dart';

/// الإبلاغ عن تقييم مسيء (سياسة Google Play للمحتوى الذي ينشره المستخدمون): يختار الطالب
/// السبب ثم يُرسل البلاغ إلى الخادم، ويراجعه المشرف من لوحة التحكم.
abstract final class ReviewReportFlow {
  static const _reasons = ['offensive', 'spam', 'misleading', 'other'];

  /// بلاغ جارٍ (من فتح القائمة حتى ردّ الخادم): ضغطات «إبلاغ» أخرى تُتجاهل فلا يُرسل مرتين.
  static bool _busy = false;

  static Future<void> start(BuildContext context, ReviewModel review) async {
    if (review.id <= 0 || _busy) return;
    _busy = true;
    Future<void>? sending;
    try {
      final ownId = await _currentUserId();
      if (ownId != null && review.studentId == ownId) {
        Get.snackbar('review_report_title'.tr, 'review_report_own'.tr);
        return;
      }
      if (!context.mounted) return;
      await showAppSelectionSheet<String>(
        context: context,
        title: 'review_report_title'.tr,
        titleIcon: Icons.flag_outlined,
        selected: null,
        onSelected: (reason) => sending = _send(review.id, reason),
        options: [
          for (final reason in _reasons)
            AppSheetOption<String>(value: reason, label: 'review_report_reason_$reason'.tr, icon: _icon(reason)),
        ],
      );
      await sending;
    } finally {
      _busy = false;
    }
  }

  static Future<int?> _currentUserId() async {
    try {
      return await Get.find<StudentIdResolver>().resolveUserId();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _send(int reviewId, String reason) async {
    try {
      final message = await _withLoading(() => Get.find<ReviewRepository>().reportReview(reviewId, reason: reason));
      Get.snackbar('review_report_sent_title'.tr, message ?? 'review_report_sent_msg'.tr);
    } on ApiException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (_) {
      Get.snackbar('error'.tr, 'review_report_failed'.tr);
    }
  }

  /// مؤشر تحميل فوق الشاشة (يحجب اللمس) حتى ينتهي الطلب — يُزال دائماً، حتى مع خطأ غير متوقع.
  static Future<T> _withLoading<T>(Future<T> Function() task) async {
    final context = Get.overlayContext;
    final overlay = context == null ? null : Overlay.maybeOf(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: Color(0x33000000),
        child: Center(child: AppDotsLoader()),
      ),
    );
    overlay?.insert(entry);
    try {
      return await task();
    } finally {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }
  }

  static IconData _icon(String reason) => switch (reason) {
    'offensive' => Icons.sentiment_very_dissatisfied_outlined,
    'spam' => Icons.report_gmailerrorred_outlined,
    'misleading' => Icons.help_outline_rounded,
    _ => Icons.more_horiz_rounded,
  };
}
