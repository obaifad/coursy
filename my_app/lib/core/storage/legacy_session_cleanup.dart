import 'package:get_storage/get_storage.dart';

import 'session_keys.dart';

/// إزالة بيانات قديمة من GetStorage (جلسة كانت تُستعاد بعد إعادة التثبيت، مفضلة محلية...).
abstract final class LegacySessionCleanup {
  static const _keys = [
    LegacySessionKeys.token,
    LegacySessionKeys.name,
    LegacySessionKeys.phone,
    LegacySessionKeys.studentId,
    LegacySessionKeys.phoneVerified,
    LegacySessionKeys.avatarUrl,
    LegacySessionKeys.avatarLocal,
    'auth_migrated_v2',
    'login_remember_me',
    'login_email',
    'login_phone',
    // مفضلة محلية قديمة — المفضلة الآن من الخادم فقط.
    'favorite_course_ids',
  ];

  /// يحذف فقط المفاتيح الموجودة (فحص في الذاكرة) — لا كتابة على القرص إن لم يوجد شيء.
  static Future<void> purge(GetStorage box) async {
    for (final key in _keys) {
      if (box.hasData(key)) await box.remove(key);
    }
  }
}
