import 'package:flutter/material.dart';

/// خط Tajawal مضمّن داخل التطبيق (assets/fonts/tajawal) — بلا اتصال بالإنترنت وقت التشغيل،
/// بديل عن حزمة google_fonts التي كانت تنزّل الخط من الشبكة عند أول استخدام.
///
/// التوقيع مطابق لِـ `GoogleFonts.tajawal(...)` و`GoogleFonts.tajawalTextTheme(...)` اللتين تستبدلهما،
/// مع فرق واحد: توزيع المسافة الإضافية نسبي افتراضياً (انظر `AppTheme._centredOnIcons`) كي يبقى النص على
/// خط منتصف الأيقونة المجاورة حتى في الأنماط التي لا ترث من الثيم (أشرطة، أزرار، حوارات).
abstract final class AppFonts {
  static const String familyName = 'Tajawal';

  static TextStyle tajawal({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextLeadingDistribution leadingDistribution = TextLeadingDistribution.proportional,
  }) {
    return TextStyle(
      fontFamily: familyName,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      leadingDistribution: leadingDistribution,
    );
  }

  static TextTheme tajawalTextTheme(TextTheme base) => base.apply(fontFamily: familyName);
}

/// سلّم أحجام الخط الموحّد — سبعة أحجام صحيحة فقط (بلا كسور بكسل).
/// الوزن 800 للعناوين والأسعار فقط، 700 للتسميات والأزرار، 500 للنص الوصفي.
abstract final class AppTextSize {
  /// الشارات والتسميات الصغيرة.
  static const double xs = 12;

  /// النص الوصفي (المعهد، المدة، التاريخ).
  static const double sm = 13;

  /// نص المحتوى والأزرار الثانوية.
  static const double md = 14;

  /// عناوين البطاقات والأزرار الأساسية.
  static const double lg = 15;

  /// عناوين الأقسام والأشرطة العلوية.
  static const double xl = 17;

  /// عناوين الشاشات.
  static const double xxl = 20;

  /// العنوان الكبير في رأس الشاشة الممتد.
  static const double display = 28;

  static const List<double> ramp = [xs, sm, md, lg, xl, xxl, display];

  /// أقرب درجة في السلّم لحجم محسوب (رؤوس متجاوبة) — التعادل للأصغر.
  static double snap(double size) => ramp.reduce((a, b) => (size - b).abs() < (size - a).abs() ? b : a);
}
