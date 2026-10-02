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

  /// ظل ناعم قياسي (يُستخدم داخل [SoftCard] وأي كارد عام آخر).
  static const List<BoxShadow> card = [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 8))];
}

/// خطوط وعناوين موحّدة عبر التطبيق (Tajawal).
abstract final class AppTypography {
  AppTypography._();

  static TextStyle pageTitle() =>
      AppFonts.tajawal(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.15);

  static TextStyle pageSubtitle() =>
      AppFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);

  static TextStyle tabScreenTitle() =>
      AppFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle homeWelcome() =>
      AppFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.25);

  static TextStyle filterSectionLabel() =>
      AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textBody);

  static TextStyle sectionTitle() =>
      AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle cardTitle({double size = 15}) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.textPrimary);

  static TextStyle cardSubtitle({double size = 13}) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w500, height: 1.35, color: AppColors.textSecondary);

  static TextStyle meta({Color? color}) =>
      AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textSecondary);

  static TextStyle actionLabel() =>
      AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary);
}

/// مقاسات وتباعدات مشتركة — شريط التنقل العائم، هوامش الصفحة، ومساحة التمرير.
abstract final class AppLayout {
  AppLayout._();

  /// ارتفاع شريط التنقل السفلي العائم في [RootView] (extendBody: true).
  /// ارتفاع جسم الشريط نفسه (بدون الحشوة السفلية) — تطابق [_RootBottomNav].
  static const double rootNavBarHeight = 82;

  /// المساحة التي يغطيها الشريط العائم من أسفل الشاشة: جسمه + حشوته السفلية
  /// (الأكبر بين 12 وحافة النظام السفلية) — نفس منطق [_RootBottomNav].
  static double rootNavReserve(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return rootNavBarHeight + (inset > 12 ? inset : 12);
  }

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
    if (rootTab) return rootNavReserve(context) + 12;
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
