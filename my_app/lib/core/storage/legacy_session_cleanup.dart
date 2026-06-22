import 'package:get_storage/get_storage.dart';

import 'session_keys.dart';

/// إزالة بيانات الجلسة القديمة من GetStorage (كانت تُستعاد بعد إعادة التثبيت).
abstract final class LegacySessionCleanup {
  static Future<void> purge(GetStorage box) async {
    for (final key in const [
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
    ]) {
      await box.remove(key);
    }
  }
}
