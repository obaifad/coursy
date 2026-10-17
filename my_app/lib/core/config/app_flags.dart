/// إعدادات التطبيق.
abstract final class AppFlags {
  /// true = يجب تسجيل الدخول أو إنشاء حساب قبل الدخول للتطبيق.
  static const bool requireLogin = true;

  /// التحقق من رقم الهاتف موقوف مؤقتاً: لا يوجد مزوّد SMS في الإنتاج فالرمز لا يصل.
  /// أعِده true حين يُربط مزوّد SMS (أو حين يُرسل الخادم حقلاً يفعّله في `/student/me`).
  static const bool phoneVerificationEnabled = false;

  /// تأكيد البريد الإلكتروني (اختياري): بعد إنشاء الحساب، ومن «حسابي» حين يكون البريد غير مؤكد.
  /// الخادم ينشر `/student/email-verification/send` و`/verify` ويرسل `email_verified_at` دائماً في
  /// `/student/me`؛ إن غاب الحقل تبقى الحالة «غير معروفة» فلا يظهر خيار التأكيد.
  static const bool emailVerificationEnabled = true;
}
