import 'package:flutter/material.dart';

/// ألوان التطبيق الموحّدة (نفس لغة تصميم Edtech / LMS).
abstract final class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8E7CFF);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color surface = Color(0xFFF4F5FF);
  static const Color surfaceVariant = Color(0xFFECEBFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  /// عنوان الترحيب البطولي في شاشات الدخول/التسجيل (أغمق وأميل للبنفسجي من [textPrimary] عمدًا).
  static const Color authHeroTitle = Color(0xFF1E1B4B);
  static const Color borderSoft = Color(0x1A6C63FF);
  static const Color shadowPurple = Color(0x226C63FF);
  static const Color shadowSoft = Color(0x106C63FF);
  static const Color indicatorFill = Color(0x1F6C63FF);

  /// بنفسجي أغمق — نهاية تدرّجات الهوية.
  static const Color primaryDark = Color(0xFF5548CC);

  /// خلفية فاتحة للحقول والشرائح غير المحددة.
  static const Color surfaceSoft = Color(0xFFF7F6FF);

  /// نص أساسي داخل الشرائح والبطاقات (أفتح من [textPrimary] وأغمق من [textSecondary]).
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF4B5563);

  /// فواصل وخلفيات رمادية محايدة.
  static const Color neutralFill = Color(0xFFF3F4F6);
  static const Color borderNeutral = Color(0xFFE5E7EB);

  static const Color ratingStar = Color(0xFFF59E0B);

  // ألوان الحالات (شارات حالة التسجيل، التنبيهات).
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color warningBorder = Color(0xFFFFD8A8);
  static const Color warningText = Color(0xFF9C4A00);

  // الظلال.
  static const Color shadowPrimary = Color(0x336C63FF);
  static const Color shadowPrimaryStrong = Color(0x446C63FF);
  static const Color shadowNeutral = Color(0x14000000);
  static const Color shadowNeutralSoft = Color(0x0F000000);
}
