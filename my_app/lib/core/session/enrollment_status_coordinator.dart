import 'dart:async';

import 'package:get/get.dart';

import '../config/app_debug_log.dart';
import '../models/app_models.dart';
import '../push/push_local_notifications.dart';
import '../storage/token_storage.dart';
import '../storage/enrollment_status_store.dart';
import 'session_refresh.dart';

/// يراقب تغيّر حالة التسجيل (pending → approved) ويُحدّث الواجهة.
class EnrollmentStatusCoordinator extends GetxService {
  final Map<int, String> _statuses = {};
  final Set<String> _delivered = {};

  void reset() {
    _statuses.clear();
    _delivered.clear();
    final sid = Get.find<TokenStorage>().studentId;
    if (sid != null) {
      unawaited(EnrollmentStatusStore.clear(sid));
    }
  }

  Future<void> loadFromStore() async {
    final sid = Get.find<TokenStorage>().studentId;
    if (sid == null) return;
    _statuses
      ..clear()
      ..addAll(EnrollmentStatusStore.loadStatuses(sid));
    _delivered
      ..clear()
      ..addAll(EnrollmentStatusStore.loadDelivered(sid));
  }

  bool wasDeliveredForEnrollment(int enrollmentId) =>
      _delivered.contains('approved:$enrollmentId') ||
      _delivered.contains('rejected:$enrollmentId');

  Future<void> trackFromEnrollments(List<EnrollmentModel> enrollments) async {
    if (!Get.find<TokenStorage>().isLoggedIn) {
      reset();
      return;
    }

    for (final enrollment in enrollments) {
      final previous = _statuses[enrollment.id];
      final next = enrollment.status.toLowerCase();

      if (previous != null) {
        if (previous == 'pending' && _isApproved(next)) {
          AppDebugLog.fcm('enrollment approved detected id=${enrollment.id}');
          await _onApproved(enrollment);
        } else if (previous == 'pending' && _isRejected(next)) {
          AppDebugLog.fcm('enrollment rejected detected id=${enrollment.id}');
          await _onRejected(enrollment);
        }
      }

      _statuses[enrollment.id] = next;
    }

    await _persist();
  }

  /// بعد حجز جديد — سجّل الحالة pending لاكتشاف الموافقة لاحقاً.
  void markPending(EnrollmentModel enrollment) {
    _statuses[enrollment.id] = enrollment.status.toLowerCase();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final sid = Get.find<TokenStorage>().studentId;
    if (sid == null) return;
    await EnrollmentStatusStore.persistStatuses(_statuses, sid);
    await EnrollmentStatusStore.persistDelivered(_delivered, sid);
  }

  Future<void> _onApproved(EnrollmentModel enrollment) async {
    final key = 'approved:${enrollment.id}';
    if (_delivered.contains(key)) return;
    _delivered.add(key);

    final courseName = enrollment.courseTitle?.trim();
    final title = 'enrollment_approved_title'.tr;
    final body = courseName == null || courseName.isEmpty
        ? 'enrollment_approved_body_generic'.tr
        : 'enrollment_approved_body'.trParams({'course': courseName});

    await PushLocalNotifications.showRaw(
      id: enrollment.id,
      title: title,
      body: body,
      payload: _payloadFor(enrollment, type: 'enrollment_approved'),
    );

    await SessionRefresh.afterEnrollmentStatusChanged(
      courseId: enrollment.courseId,
      enrollmentId: enrollment.id,
    );
    await _persist();
  }

  Future<void> _onRejected(EnrollmentModel enrollment) async {
    final key = 'rejected:${enrollment.id}';
    if (_delivered.contains(key)) return;
    _delivered.add(key);

    final courseName = enrollment.courseTitle?.trim();
    final title = 'enrollment_rejected_title'.tr;
    final body = courseName == null || courseName.isEmpty
        ? 'enrollment_rejected_body_generic'.tr
        : 'enrollment_rejected_body'.trParams({'course': courseName});

    await PushLocalNotifications.showRaw(
      id: enrollment.id + 100000,
      title: title,
      body: body,
      payload: _payloadFor(enrollment, type: 'enrollment_rejected'),
    );

    await SessionRefresh.afterEnrollmentStatusChanged(
      courseId: enrollment.courseId,
      enrollmentId: enrollment.id,
    );
    await _persist();
  }

  String _payloadFor(EnrollmentModel enrollment, {required String type}) {
    final parts = <String>['type=$type'];
    if (enrollment.courseId != null) parts.add('course_id=${enrollment.courseId}');
    parts.add('enrollment_id=${enrollment.id}');
    return parts.join('&');
  }

  static bool _isApproved(String status) =>
      status == 'approved' || status == 'confirmed';

  static bool _isRejected(String status) =>
      status == 'rejected' || status == 'cancelled';
}
