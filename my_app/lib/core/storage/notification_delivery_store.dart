import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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
  }

  void clearForCurrentUser() {
    final studentId = Get.find<TokenStorage>().studentId;
    if (studentId != null) clearForStudent(studentId);
    _deliveredIds.clear();
  }

  bool wasDelivered(int notificationId) => _deliveredIds.contains(notificationId);

  Future<void> markDelivered(Iterable<int> notificationIds) async {
    final studentId = Get.find<TokenStorage>().studentId;
    if (studentId == null) return;

    var changed = false;
    for (final id in notificationIds) {
      if (id <= 0) continue;
      if (_deliveredIds.add(id)) changed = true;
    }
    if (!changed) return;
    await _box.write(_storageKey(studentId), _deliveredIds.toList());
  }

  String _storageKey(int studentId) => 'push_delivered_notification_ids_$studentId';
}
