import 'dart:async';

import 'package:get/get.dart';

import '../config/app_debug_log.dart';
import '../models/app_models.dart';
import '../models/json_helpers.dart';
import '../push/enrollment_status_change.dart';
import '../push/push_local_notifications.dart';
import '../storage/token_storage.dart';
import '../storage/enrollment_status_store.dart';
import 'session_refresh.dart';

/// يراقب تغيّر حالة التسجيل (pending → approved/rejected/cancelled) ويُحدّث الواجهة.
class EnrollmentStatusCoordinator extends GetxService {
  final Map<int, String> _statuses = {};
  final Set<String> _delivered = {};

  /// ما عرضه هذا المراقب بنفسه في الجلسة. منفصل عن [_delivered] الذي يضم أيضاً ما وصل عبر FCM
  /// وما ألغاه الطالب بنفسه (إشعار الخادم بالإلغاء يجب أن يظهر).
  final Set<String> _shownHere = {};

  /// الطالب الذي حُمّلت حالته من التخزين — قبل التحميل لا نقارن ولا نحفظ
  /// (وإلا تُستبدل الحالات المحفوظة قبل قراءتها ويضيع اكتشاف الموافقة).
  int? _loadedFor;

  void reset() {
    _statuses.clear();
    _delivered.clear();
    _shownHere.clear();
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
      EnrollmentStatusChange.values.any((change) => _delivered.contains(change.deliveredKey(enrollmentId)));

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
      final next = enrollment.status.toLowerCase();
      final change = EnrollmentStatusChange.detect(_statuses[enrollment.id], next);
      if (change != null) {
        AppDebugLog.fcm('enrollment ${change.key} detected id=${enrollment.id}');
        await _onChanged(enrollment, change);
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

  /// الطالب ألغى حجزه من التطبيق: نسجّل الحالة الجديدة ونعدّ الإلغاء «مُبلَّغاً عنه»، فلا يظهر له إشعار
  /// محلي عن قرار اتخذه بنفسه (هنا أو في الفحص الخلفي). إشعار الخادم بالإلغاء يصل عبر FCM.
  Future<void> markCancelledByStudent(int enrollmentId) async {
    if (!Get.find<TokenStorage>().isLoggedIn) return;
    await _ensureLoaded();
    _statuses[enrollmentId] = 'cancelled';
    _delivered.add(EnrollmentStatusChange.cancelled.deliveredKey(enrollmentId));
    await _persist();
  }

  /// وصل عبر FCM إشعارُ تغيّرٍ عرضه هذا المراقب قبل لحظات (اكتشفه من قائمة التسجيلات أولاً).
  bool wasShownLocally(Map<String, dynamic> data) {
    final change = EnrollmentStatusChange.fromNotificationType(data['type']?.toString());
    final enrollmentId = JsonHelpers.parseIntOrNull(data['enrollment_id']);
    if (change == null || enrollmentId == null) return false;
    return _shownHere.contains(change.deliveredKey(enrollmentId));
  }

  /// FCM أوصل إشعار تغيّر الحالة (`enrollment_approved`…): لا نعرض إشعاراً محلياً ثانياً حين نكتشفه.
  Future<void> recordServerPush(Map<String, dynamic> data) async {
    final change = EnrollmentStatusChange.fromNotificationType(data['type']?.toString());
    final enrollmentId = JsonHelpers.parseIntOrNull(data['enrollment_id']);
    if (change == null || enrollmentId == null || enrollmentId <= 0) return;
    if (!Get.find<TokenStorage>().isLoggedIn) return;
    await _ensureLoaded();
    _delivered.add(change.deliveredKey(enrollmentId));
    await _persist();
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

  Future<void> _onChanged(EnrollmentModel enrollment, EnrollmentStatusChange change) async {
    final key = change.deliveredKey(enrollment.id);
    if (_delivered.contains(key)) return;
    _delivered.add(key);
    _shownHere.add(key);

    final courseName = enrollment.courseTitle?.trim();
    final title = change.titleKey.tr;
    final body = courseName == null || courseName.isEmpty
        ? change.genericBodyKey.tr
        : change.bodyKey.trParams({'course': courseName});

    await PushLocalNotifications.showRaw(
      id: change.notificationId(enrollment.id),
      title: title,
      body: body,
      payload: _payloadFor(enrollment, type: change.type),
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
}
