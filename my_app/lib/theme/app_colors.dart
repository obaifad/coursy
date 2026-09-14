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
}
