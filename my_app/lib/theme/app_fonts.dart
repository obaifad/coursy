import 'package:flutter/material.dart';

/// خط Tajawal مضمّن داخل التطبيق (assets/fonts/tajawal) — بلا اتصال بالإنترنت وقت التشغيل،
/// بديل عن حزمة google_fonts التي كانت تنزّل الخط من الشبكة عند أول استخدام.
///
/// التوقيع مطابق تماماً لِـ `GoogleFonts.tajawal(...)` و`GoogleFonts.tajawalTextTheme(...)`
/// اللتين تستبدلهما — استبدال حرفي بلا تغيير في السلوك.
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
    );
  }

  static TextTheme tajawalTextTheme(TextTheme base) => base.apply(fontFamily: familyName);
}
