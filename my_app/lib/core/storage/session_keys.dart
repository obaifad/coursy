/// مفاتيح جلسة المستخدم — تُخزَّن في Secure Storage فقط.
abstract final class SessionKeys {
  static const accessToken = 'session.access_token';
  static const userName = 'session.user_name';
  static const userPhone = 'session.user_phone';
  static const studentId = 'session.student_id';
  static const phoneVerified = 'session.phone_verified';
  static const avatarUrl = 'session.avatar_url';
  static const avatarLocalPath = 'session.avatar_local_path';
  static const academicProfileCache = 'session.academic_profile_cache';
  static const storageVersion = 'session.storage_version';

  /// الإصدار الحالي — عند تغيّره تُمسح الجلسة القديمة تلقائياً.
  static const currentStorageVersion = '2';
}

/// مفاتيح قديمة في GetStorage — تُزال بعد الترحيل.
abstract final class LegacySessionKeys {
  static const token = 'auth_token';
  static const name = 'user_name';
  static const phone = 'user_phone';
  static const studentId = 'student_id';
  static const phoneVerified = 'phone_verified';
  static const avatarUrl = 'user_avatar_url';
  static const avatarLocal = 'user_avatar_local';
}
