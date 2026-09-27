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

  /// الطالب الذي حُمّلت حالته من التخزين — قبل التحميل لا نقارن ولا نحفظ
  /// (وإلا تُستبدل الحالات المحفوظة قبل قراءتها ويضيع اكتشاف الموافقة).
  int? _loadedFor;

  void reset() {
    _statuses.clear();
    _delivered.clear();
    _loadedFor = null;
    final sid = Get.find<TokenStorage>().studentId;
    if (sid != null) {
      unawaited(EnrollmentStatusStore.clear(sid));
    }
  }

  Future<void> loadFromStore() async {
    final sid = Get.find<TokenStorage>().studentId;
    if (sid == null) return;
    await EnrollmentStatusStore.migrateFromGetStorage(sid);
    final statuses = await EnrollmentStatusStore.loadStatuses(sid);
    final delivered = await EnrollmentStatusStore.loadDelivered(sid);
    _statuses
      ..clear()
      ..addAll(statuses);
    _delivered
      ..clear()
      ..addAll(delivered);
    _loadedFor = sid;
  }

  Future<void> _ensureLoaded() async {
    final sid = Get.find<TokenStorage>().studentId;
    if (sid == null || _loadedFor == sid) return;
    await loadFromStore();
  }

  bool wasDeliveredForEnrollment(int enrollmentId) =>
      _delivered.contains('approved:$enrollmentId') || _delivered.contains('rejected:$enrollmentId');

  Future<void> trackFromEnrollments(List<EnrollmentModel> enrollments) async {
    if (!Get.find<TokenStorage>().isLoggedIn) {
      reset();
      return;
    }
    await _ensureLoaded();
    final sid = Get.find<TokenStorage>().studentId;
    if (sid != null) {
      // الفحص الخلفي ربما أظهر إشعاراً بالفعل — لا نكرره.
      _delivered.addAll(await EnrollmentStatusStore.loadDelivered(sid));
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
    unawaited(() async {
      await _ensureLoaded();
      _statuses[enrollment.id] = enrollment.status.toLowerCase();
      await _persist();
    }());
  }

  Future<void> _persist() async {
    final sid = Get.find<TokenStorage>().studentId;
    if (sid == null || _loadedFor != sid) return;
    await EnrollmentStatusStore.persistStatuses(_statuses, sid);
    final merged = await EnrollmentStatusStore.persistDelivered(_delivered, sid);
    _delivered
      ..clear()
      ..addAll(merged);
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

    await SessionRefresh.afterEnrollmentStatusChanged(courseId: enrollment.courseId, enrollmentId: enrollment.id);
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

    await SessionRefresh.afterEnrollmentStatusChanged(courseId: enrollment.courseId, enrollmentId: enrollment.id);
    await _persist();
  }

  String _payloadFor(EnrollmentModel enrollment, {required String type}) {
    final parts = <String>['type=$type'];
    if (enrollment.courseId != null) parts.add('course_id=${enrollment.courseId}');
    parts.add('enrollment_id=${enrollment.id}');
    return parts.join('&');
  }

  static bool _isApproved(String status) => status == 'approved' || status == 'confirmed';

  static bool _isRejected(String status) => status == 'rejected' || status == 'cancelled';
}
