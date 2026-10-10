/// إعدادات التطبيق.
abstract final class AppFlags {
  /// true = يجب تسجيل الدخول أو إنشاء حساب قبل الدخول للتطبيق.
  static const bool requireLogin = true;

  /// التحقق من رقم الهاتف موقوف مؤقتاً: لا يوجد مزوّد SMS في الإنتاج فالرمز لا يصل.
  /// أعِده true حين يُربط مزوّد SMS (أو حين يُرسل الخادم حقلاً يفعّله في `/student/me`).
  static const bool phoneVerificationEnabled = false;
}
