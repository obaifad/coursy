part of '../design_system.dart';

/// تدرجات العلامة البصرية
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [Color(0xFF7C6CF5), AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient screenBg = LinearGradient(
    colors: [AppColors.surface, AppColors.surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient category = LinearGradient(
    colors: [Color(0xFFB8A9FF), AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// بانر الصفحة الرئيسية — تدرج بنفسجي ناعم
  static const LinearGradient heroBanner = LinearGradient(
    colors: [Color(0xFF9B8CFF), AppColors.primary, Color(0xFF574FD6)],
    begin: AlignmentDirectional.topEnd,
    end: AlignmentDirectional.bottomStart,
  );

  /// خلفية بطاقات الدورة الافتراضية (بدون صورة)
  static const LinearGradient cardPlaceholder = LinearGradient(
    colors: [Color(0xFF9B8FFF), AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ظلال الكروت الموحّدة عبر التطبيق — مصدر واحد لكل حاوية "بطاقة".
abstract final class AppShadows {
  AppShadows._();

  /// ظل ناعم قياسي (يُستخدم داخل [SoftCard] وأي كارد عام آخر). نصف قطر التمويه 12 لا 16: كلفة الرسم على
  /// خيط الـ Raster تتناسب معه، والفرق بصرياً شبه معدوم على بطاقة بيضاء.
  static const List<BoxShadow> card = [BoxShadow(color: AppColors.shadowSoft, blurRadius: 12, offset: Offset(0, 6))];
}

/// زوايا جاهزة من مقياس [AppRadius] — لا أنصاف أقطار خارج الدرجات الخمس.
abstract final class AppCorners {
  AppCorners._();

  static const BorderRadius xs = BorderRadius.all(Radius.circular(AppRadius.xs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(AppRadius.sm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(AppRadius.md));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(AppRadius.lg));
  static const BorderRadius full = BorderRadius.all(Radius.circular(AppRadius.full));

  /// الأوراق السفلية: الحافة العلوية فقط.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(AppRadius.lg));
}

/// خطوط وعناوين موحّدة عبر التطبيق (Tajawal) — أحجام [AppTextSize] فقط.
/// 800 للعناوين والأسعار، 700 للتسميات والأزرار، 500 للنص الوصفي.
abstract final class AppTypography {
  AppTypography._();

  static TextStyle pageTitle() => AppFonts.tajawal(
    fontSize: AppTextSize.display,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle pageSubtitle() => AppFonts.tajawal(
    fontSize: AppTextSize.md,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle tabScreenTitle() =>
      AppFonts.tajawal(fontSize: AppTextSize.xxl, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle homeWelcome() => AppFonts.tajawal(
    fontSize: AppTextSize.xxl,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle filterSectionLabel() =>
      AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700, color: AppColors.textBody);

  static TextStyle sectionTitle() =>
      AppFonts.tajawal(fontSize: AppTextSize.xl, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle cardTitle({double size = AppTextSize.lg}) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.textPrimary);

  static TextStyle cardSubtitle({double size = AppTextSize.sm}) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w500, height: 1.35, color: AppColors.textSecondary);

  static TextStyle meta({Color? color}) =>
      AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w500, color: color ?? AppColors.textSecondary);

  static TextStyle actionLabel() =>
      AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700, color: AppColors.primaryInk);

  /// تسمية صغيرة (شارة، وسم، عدّاد).
  static TextStyle caption({Color? color, FontWeight weight = FontWeight.w700}) => AppFonts.tajawal(
    fontSize: AppTextSize.xs,
    fontWeight: weight,
    height: 1.25,
    color: color ?? AppColors.textSecondary,
  );

  /// السعر البارز في البطاقات.
  static TextStyle price({double size = AppTextSize.lg, Color color = AppColors.primaryInk}) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w800, height: 1.1, color: color);
}

/// مقاسات وتباعدات مشتركة — شريط التنقل العائم، هوامش الصفحة، ومساحة التمرير.
abstract final class AppLayout {
  AppLayout._();

  /// ارتفاع شريط التنقل السفلي العائم في [RootView] (extendBody: true).
  static double horizontalPage(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 32;
    if (w >= 600) return 24;
    return 16;
  }

  static double contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 720;
    if (w >= 600) return 640;
    return w;
  }

  /// حشوة جانبية تحصر المحتوى بعرض قابل للقراءة ([contentMaxWidth]) على اللوحي، مع إبقاء
  /// منطقة التمرير بكامل العرض. على الهاتف تساوي [horizontalPage] (أو [min]).
  static double readableInset(BuildContext context, {double? min}) {
    final w = MediaQuery.sizeOf(context).width;
    final base = min ?? horizontalPage(context);
    final centered = (w - contentMaxWidth(context)) / 2;
    return centered > base ? centered : base;
  }

  static double scrollBottomInset(BuildContext context, {bool rootTab = false}) {
    // الشريط السفلي صلب وخارج منطقة المحتوى (extendBody: false) — لا حاجة لحجز مساحته.
    if (rootTab) return 16;
    return MediaQuery.viewPaddingOf(context).bottom + 24;
  }

  static EdgeInsetsGeometry scrollPadding(
    BuildContext context, {
    bool rootTab = false,
    double top = 0,
    double extraBottom = 0,
  }) {
    final h = readableInset(context);
    return EdgeInsetsDirectional.fromSTEB(h, top, h, scrollBottomInset(context, rootTab: rootTab) + extraBottom);
  }

  /// حشوة أفقية موحّدة لعناوين الأقسام والمحتوى العمودي.
  static EdgeInsetsDirectional sectionHorizontal(BuildContext context) {
    final h = horizontalPage(context);
    return EdgeInsetsDirectional.fromSTEB(h, 0, h, 0);
  }
}

/// هل الواجهة عربية/RTL؟
bool appIsRtl(BuildContext context) => Directionality.of(context) == TextDirection.rtl;

/// اتجاه النص حسب أول حرف قوي فيه (عربي → RTL، لاتيني → LTR)، أو null إن لم يوجد.
TextDirection? detectTextDirection(String text) {
  for (final rune in text.runes) {
    final isRtl =
        (rune >= 0x0590 && rune <= 0x08FF) || (rune >= 0xFB1D && rune <= 0xFDFF) || (rune >= 0xFE70 && rune <= 0xFEFF);
    if (isRtl) return TextDirection.rtl;
    final isLatin =
        (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0xC0 && rune <= 0x24F) ||
        (rune >= 0x370 && rune <= 0x58F);
    if (isLatin) return TextDirection.ltr;
  }
  return null;
}

/// نص يضبط اتجاهه حسب محتواه: الأسماء اللاتينية داخل واجهة RTL تُقتطع (…) من نهايتها
/// وتبقى محاذاتها على جهة بداية الواجهة.
class BidiText extends StatelessWidget {
  const BidiText(this.data, {super.key, this.style, this.maxLines, this.overflow, this.textAlign});

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ambientRtl = appIsRtl(context);
    final direction = detectTextDirection(data) ?? Directionality.of(context);
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: direction,
      textAlign: textAlign == null || textAlign == TextAlign.start
          ? (ambientRtl ? TextAlign.right : TextAlign.left)
          : textAlign,
    );
  }
}
