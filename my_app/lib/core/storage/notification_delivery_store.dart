import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'background_push_store.dart';
import 'token_storage.dart';

/// يتذكّر الإشعارات التي عُرضت مسبقاً حتى لا تُعاد عند كل فتح للتطبيق.
class NotificationDeliveryStore extends GetxService {
  late final GetStorage _box = GetStorage();
  final Set<int> _deliveredIds = {};

  Future<void> initForCurrentUser() async {
    _deliveredIds.clear();
    final studentId = Get.find<TokenStorage>().studentId;
    if (studentId == null) return;

    final raw = _box.read<List>(_storageKey(studentId));
    if (raw == null) return;
    for (final item in raw) {
      final id = item is int ? item : int.tryParse('$item');
      if (id != null && id > 0) _deliveredIds.add(id);
    }
  }

  void clearForStudent(int studentId) {
    _box.remove(_storageKey(studentId));
    _deliveredIds.clear();
    _shownKeys.clear();
  }

  void clearForCurrentUser() {
    final studentId = Get.find<TokenStorage>().studentId;
    if (studentId != null) clearForStudent(studentId);
    _deliveredIds.clear();
    _shownKeys.clear();
  }

  bool wasDelivered(int notificationId) => _deliveredIds.contains(notificationId);

  /// ما عُرض في هذه الجلسة، من فحص قائمة الخادم أو من FCM والتطبيق مفتوح. كلٌّ منهما يطالب بالإشعار
  /// قبل عرضه، فلا يظهر مرتين أيّاً سبق (كان «تم استلام الحجز» يظهر مرتين بعد الحجز).
  /// المطالبة متزامنة: لا سباق بين المسارين.
  final Set<String> _shownKeys = {};

  /// false = عُرض من المسار الآخر. يُطابَق برقم الإشعار، أو بالنوع ورقم التسجيل إن غاب الرقم عن FCM.
  bool claimShown({int? notificationId, String? type, int? enrollmentId}) {
    final keys = shownKeys(notificationId: notificationId, type: type, enrollmentId: enrollmentId);
    if (keys.any(_shownKeys.contains)) return false;
    _shownKeys.addAll(keys);
    return true;
  }

  @visibleForTesting
  static List<String> shownKeys({int? notificationId, String? type, int? enrollmentId}) =>
      BackgroundPushStore.keys(notificationId: notificationId, type: type, enrollmentId: enrollmentId);

  Future<void> markDelivered(Iterable<int> notificationIds) async {
    final studentId = Get.find<TokenStorage>().studentId;
    if (studentId == null) return;

    var changed = false;
    for (final id in notificationIds) {
      if (id <= 0) continue;
      if (_deliveredIds.add(id)) changed = true;
    }
    if (!changed) return;
    // نحتفظ بأحدث [_maxStoredIds] فقط — كانت القائمة تكبر للأبد.
    if (_deliveredIds.length > _maxStoredIds) {
      final newest = (_deliveredIds.toList()..sort()).sublist(_deliveredIds.length - _maxStoredIds);
      _deliveredIds
        ..clear()
        ..addAll(newest);
    }
    await _box.write(_storageKey(studentId), _deliveredIds.toList());
  }

  static const _maxStoredIds = 500;

  String _storageKey(int studentId) => 'push_delivered_notification_ids_$studentId';
}
