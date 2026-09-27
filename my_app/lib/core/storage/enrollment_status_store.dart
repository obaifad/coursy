import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حالة التسجيلات محفوظة للمقارنة بين التطبيق والفحص الخلفي (Workmanager).
///
/// تُحفظ في [SharedPreferencesAsync] وليس GetStorage: الفحص الخلفي يعمل في isolate منفصل،
/// وGetStorage يحتفظ بنسخة كاملة في الذاكرة ويعيد كتابة الملف كله عند كل حفظ — فكان كل
/// طرف يمسح تعديلات الآخر (ومعها إعدادات المستخدم). هنا كل قراءة تأتي من القرص مباشرة.
abstract final class EnrollmentStatusStore {
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// أقصى عدد مفاتيح "تم الإشعار" المحفوظة — الأقدم يُحذف أولاً.
  static const maxDeliveredKeys = 300;

  static String _statusesKey(int studentId) => 'enrollment_statuses_$studentId';
  static String _deliveredKey(int studentId) => 'enrollment_delivered_$studentId';

  static Future<Map<int, String>> loadStatuses(int studentId) async {
    final raw = await _prefs.getString(_statusesKey(studentId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <int, String>{};
      for (final entry in decoded.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id != null && id > 0) result[id] = entry.value.toString();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> loadDelivered(int studentId) async {
    final raw = await _prefs.getStringList(_deliveredKey(studentId));
    return raw?.toSet() ?? <String>{};
  }

  static Future<void> persistStatuses(Map<int, String> statuses, int studentId) async {
    final encoded = statuses.map((k, v) => MapEntry('$k', v));
    await _prefs.setString(_statusesKey(studentId), jsonEncode(encoded));
  }

  /// يدمج مع المحفوظ على القرص (قد يكون الفحص الخلفي أضاف مفاتيح) ثم يحفظ آخر [maxDeliveredKeys].
  static Future<Set<String>> persistDelivered(Set<String> delivered, int studentId) async {
    final stored = await _prefs.getStringList(_deliveredKey(studentId)) ?? const <String>[];
    final merged = <String>[...stored, ...delivered.where((key) => !stored.contains(key))];
    final trimmed = merged.length > maxDeliveredKeys ? merged.sublist(merged.length - maxDeliveredKeys) : merged;
    await _prefs.setStringList(_deliveredKey(studentId), trimmed);
    return trimmed.toSet();
  }

  static Future<void> clear(int studentId) async {
    await _prefs.remove(_statusesKey(studentId));
    await _prefs.remove(_deliveredKey(studentId));
  }

  /// نقل البيانات القديمة من GetStorage (مرة واحدة) — يُستدعى من الـ isolate الرئيسي فقط.
  static Future<void> migrateFromGetStorage(int studentId) async {
    final box = GetStorage();
    final legacyStatuses = box.read<Map>(_statusesKey(studentId));
    final legacyDelivered = box.read<List>(_deliveredKey(studentId));
    if (legacyStatuses == null && legacyDelivered == null) return;

    if (legacyStatuses != null && await _prefs.getString(_statusesKey(studentId)) == null) {
      final statuses = <int, String>{};
      for (final entry in legacyStatuses.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id != null && id > 0) statuses[id] = entry.value.toString();
      }
      await persistStatuses(statuses, studentId);
    }
    if (legacyDelivered != null) {
      await persistDelivered(legacyDelivered.map((e) => e.toString()).toSet(), studentId);
    }
    await box.remove(_statusesKey(studentId));
    await box.remove(_deliveredKey(studentId));
  }
}
