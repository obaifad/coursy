import 'package:get_storage/get_storage.dart';

/// حالة التسجيلات محفوظة للمقارنة في الخلفية (Workmanager).
abstract final class EnrollmentStatusStore {
  static String _statusesKey(int studentId) => 'enrollment_statuses_$studentId';
  static String _deliveredKey(int studentId) => 'enrollment_delivered_$studentId';

  static Map<int, String> loadStatuses(int studentId) {
    final raw = GetStorage().read<Map>(_statusesKey(studentId));
    if (raw == null) return {};
    final result = <int, String>{};
    for (final entry in raw.entries) {
      final id = int.tryParse(entry.key.toString());
      if (id != null && id > 0) {
        result[id] = entry.value.toString();
      }
    }
    return result;
  }

  static Set<String> loadDelivered(int studentId) {
    final raw = GetStorage().read<List>(_deliveredKey(studentId));
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  static Future<void> persistStatuses(Map<int, String> statuses, int studentId) async {
    final encoded = statuses.map((k, v) => MapEntry('$k', v));
    await GetStorage().write(_statusesKey(studentId), encoded);
  }

  static Future<void> persistDelivered(Set<String> delivered, int studentId) async {
    await GetStorage().write(_deliveredKey(studentId), delivered.toList());
  }

  static Future<void> clear(int studentId) async {
    final box = GetStorage();
    await box.remove(_statusesKey(studentId));
    await box.remove(_deliveredKey(studentId));
  }
}
