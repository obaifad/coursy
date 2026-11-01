import 'package:shared_preferences/shared_preferences.dart';

/// إشعارات FCM التي وصلت والتطبيق في الخلفية (النظام عرضها بنفسه). معالج الخلفية يعمل في isolate منفصل
/// لا يكتب في GetStorage، فكان فحص قائمة الخادم عند العودة للتطبيق يجدها «جديدة» ويعرضها مرة ثانية
/// («تم استلام طلب التسجيل» مرتين). تُحفظ هنا في [SharedPreferencesAsync] المشترك بين الـ isolates.
abstract final class BackgroundPushStore {
  static const _key = 'push_background_shown_keys';

  /// أحدث المفاتيح فقط — القائمة لا تكبر للأبد.
  static const maxKeys = 300;

  static SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  /// مفاتيح مطابقة الإشعار: رقمه في الخادم، أو نوعه ورقم التسجيل إن غاب الرقم عن رسالة FCM.
  static List<String> keys({int? notificationId, String? type, int? enrollmentId}) {
    final normalizedType = type?.trim().toLowerCase() ?? '';
    return [
      if (notificationId != null && notificationId > 0) 'n:$notificationId',
      if (enrollmentId != null && enrollmentId > 0 && normalizedType.isNotEmpty) 'e:$normalizedType:$enrollmentId',
    ];
  }

  /// مفاتيح رسالة FCM من بياناتها (`notification_id`، `type`، `enrollment_id`).
  static List<String> keysForPushData(Map<String, dynamic> data) => keys(
    notificationId: _parseInt(data['notification_id']),
    type: data['type']?.toString(),
    enrollmentId: _parseInt(data['enrollment_id']),
  );

  /// من معالج الخلفية: وصلت الرسالة وعرضها النظام (أو المعالج محلياً).
  static Future<void> recordPush(Map<String, dynamic> data) async {
    final added = keysForPushData(data);
    if (added.isEmpty) return;
    final stored = await _prefs.getStringList(_key) ?? const <String>[];
    final next = [...stored.where((k) => !added.contains(k)), ...added];
    await _prefs.setStringList(_key, next.length > maxKeys ? next.sublist(next.length - maxKeys) : next);
  }

  static Future<Set<String>> load() async => (await _prefs.getStringList(_key))?.toSet() ?? <String>{};

  static Future<void> clear() => _prefs.remove(_key);

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
