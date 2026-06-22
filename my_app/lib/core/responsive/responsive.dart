import 'package:flutter/material.dart';

/// نوع الشاشة وفق نقاط التوقف المعتمدة في التطبيق.
enum ScreenType { mobile, tablet, desktop }

/// نقاط التوقف الموحّدة — متوافقة مع المقاسات المستخدمة في [AppLayout].
abstract final class AppBreakpoints {
  AppBreakpoints._();

  /// أقل من هذا العرض = هاتف.
  static const double mobile = 600;

  /// من 600 حتى 1024 = جهاز لوحي / Chromebook.
  static const double desktop = 1024;

  static ScreenType typeForWidth(double width) {
    if (width >= desktop) return ScreenType.desktop;
    if (width >= mobile) return ScreenType.tablet;
    return ScreenType.mobile;
  }
}

/// اختصارات متجاوبة على [BuildContext] — تُبسّط منطق المقاسات في الواجهات.
extension ResponsiveContext on BuildContext {
  Size get _screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => _screenSize.width;
  double get screenHeight => _screenSize.height;

  ScreenType get screenType => AppBreakpoints.typeForWidth(screenWidth);

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// جهاز لوحي أو أكبر — مفيد لتفعيل تخطيطات أوسع.
  bool get isTabletOrLarger => screenWidth >= AppBreakpoints.mobile;

  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// ارتفاع لوحة المفاتيح الظاهر حالياً (0 إن كانت مغلقة).
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  /// يختار القيمة المناسبة حسب نوع الشاشة مع تدرّج اختياري.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }
}

/// يحصر عرض المحتوى ويوسّطه على الشاشات الكبيرة (لوحي/سطح مكتب).
///
/// على الهاتف يُعيد العرض الكامل (لا تغيير بصري)، وعلى الشاشات الأوسع
/// يحصر العرض ويوسّط المحتوى — بدون كسر التصميم الحالي.
class AppMaxWidth extends StatelessWidget {
  const AppMaxWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  /// أقصى عرض افتراضي للمحتوى حسب نوع الشاشة.
  static double defaultMaxWidth(BuildContext context) {
    final w = context.screenWidth;
    if (w >= 1024) return 820;
    if (w >= AppBreakpoints.mobile) return 680;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = maxWidth ?? defaultMaxWidth(context);
    if (context.screenWidth <= resolved) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolved),
        child: child,
      ),
    );
  }
}

/// أدوات عرض الحوارات والـ Bottom Sheets بشكل متجاوب.
abstract final class ResponsiveModals {
  ResponsiveModals._();

  /// أقصى عرض لحوار/بطاقة على الشاشات الكبيرة.
  static double dialogMaxWidth(BuildContext context) {
    final w = context.screenWidth;
    if (w >= 1024) return 520;
    if (w >= AppBreakpoints.mobile) return 480;
    return w;
  }

  /// أقصى عرض للـ Bottom Sheet على الشاشات الكبيرة (يبقى متمركزاً).
  static double sheetMaxWidth(BuildContext context) {
    final w = context.screenWidth;
    if (w >= 1024) return 640;
    if (w >= AppBreakpoints.mobile) return 560;
    return w;
  }
}
