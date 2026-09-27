part of '../design_system.dart';

/// شبكة دورات موحّدة — مقاسات متجاوبة مع عرض الشاشة.
abstract final class CourseCardMetrics {
  CourseCardMetrics._();

  static const double gridSpacing = 12;
  static const double gridAspectRatio = 0.72;
  static const double gridImageHeight = 108;
  static const double gridBodyPadding = 12;
  static const double cardRadius = 18;

  static double featuredCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final inset = AppLayout.horizontalPage(context);
    final available = w - inset * 2;
    // ~70% من العرض المتاح لإظهار جزء من البطاقة التالية وتقليل الفراغ الأبيض.
    return (available * 0.70).clamp(200.0, 280.0);
  }

  /// ارتفاع القائمة الأفقية — يُقدَّر من محتوى البطاقة المميزة المعاد تصميمها.
  static double featuredCardHeight(BuildContext context) {
    final w = featuredCardWidth(context);
    final imageH = (w / 1.65).clamp(88.0, 112.0);
    const contentH = 8 + 32 + 6 + 16 + 8 + 20 + 8 + 30 + 10 + 32 + 14;
    return imageH + contentH;
  }

  static double featuredListHeight(BuildContext context) => featuredCardHeight(context);

  /// عرض بطاقة الشبكة (عمودين) — أضيق من بطاقات القوائم الأفقية في الهوم.
  static bool isCompactTile(double width) => width < 220;

  static bool isFeaturedTile(double width, {required bool includeButton}) {
    return !includeButton && width >= 220;
  }

  static _CourseCardSizeSpec _specFor(double width, {required bool includeButton}) {
    if (isFeaturedTile(width, includeButton: includeButton)) {
      final imageHeight = (width / 1.65).clamp(88.0, 112.0);
      return _CourseCardSizeSpec(
        imageHeight: imageHeight,
        padding: 12,
        titleHeight: 32,
        summaryHeight: 16,
        titleSize: 13,
        chipsHeight: 20,
        statsHeight: 18,
        priceHeight: 30,
        buttonHeight: 32,
        sectionGap: 6,
        includeButton: false,
        compact: true,
      );
    }
    if (isCompactTile(width)) {
      return _CourseCardSizeSpec(
        imageHeight: 84,
        padding: 10,
        titleHeight: 34,
        summaryHeight: 14,
        titleSize: 12.5,
        chipsHeight: 20,
        statsHeight: 16,
        priceHeight: 30,
        buttonHeight: 30,
        sectionGap: 5,
        includeButton: includeButton,
        compact: true,
      );
    }
    return _CourseCardSizeSpec(
      imageHeight: gridImageHeight,
      padding: gridBodyPadding,
      titleHeight: 38,
      summaryHeight: 16,
      titleSize: 14,
      chipsHeight: 22,
      statsHeight: 18,
      priceHeight: 32,
      buttonHeight: 34,
      sectionGap: 6,
      includeButton: includeButton,
      compact: false,
    );
  }

  static double gridTileWidth(BuildContext context) => courseGridTileWidth(context);

  static int courseGridCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hPad = AppLayout.horizontalPage(context);
    final available = w - hPad * 2;
    // عتبات مرتفعة عمدًا: الهدف إبقاء عرض كل بطاقة ضمن الفئة "العادية" (>=220)
    // بدل الانزلاق لفئة "مضغوطة" الأصغر على الأجهزة اللوحية — عمود إضافي واحد
    // كان يقسّم العرض لدرجة تُنتج بطاقات أصغر مما تسمح به الشاشة الواسعة فعليًا.
    if (available >= 1000) return 4;
    if (available >= 700) return 3;
    return 2;
  }

  static double courseGridTileWidth(BuildContext context) {
    final count = courseGridCrossAxisCount(context);
    final w = MediaQuery.sizeOf(context).width;
    final hPad = AppLayout.horizontalPage(context);
    final available = w - hPad * 2;
    return (available - gridSpacing * (count - 1)) / count;
  }

  static double gridTileHeight(BuildContext context) {
    return gridCardHeightForWidth(courseGridTileWidth(context));
  }

  static double gridCardHeightForWidth(double width, {bool? compact, bool includeButton = true}) {
    return _specFor(width, includeButton: includeButton).totalHeight;
  }

  static CourseCardLayout layoutFor(BoxConstraints constraints, {bool showActionButton = true}) {
    final w = constraints.maxWidth;
    final spec = _specFor(w, includeButton: showActionButton);
    return CourseCardLayout(
      cardHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : spec.totalHeight,
      padding: spec.padding,
      imageHeight: spec.imageHeight,
      compact: spec.compact,
      titleSize: spec.titleSize,
      subtitleSize: spec.compact ? 11 : 12,
      titleHeight: spec.titleHeight,
      subtitleHeight: spec.summaryHeight,
      footerHeight: spec.priceHeight,
      chipsHeight: spec.chipsHeight,
      statsHeight: spec.statsHeight,
      priceHeight: spec.priceHeight,
      buttonHeight: spec.buttonHeight,
      sectionGap: spec.sectionGap,
      gapAfterImage: 0,
      gapAfterTitle: spec.sectionGap,
      gapBeforeFooter: spec.sectionGap,
    );
  }
}

class _CourseCardSizeSpec {
  const _CourseCardSizeSpec({
    required this.imageHeight,
    required this.padding,
    required this.titleHeight,
    required this.summaryHeight,
    required this.titleSize,
    required this.chipsHeight,
    required this.statsHeight,
    required this.priceHeight,
    required this.buttonHeight,
    required this.sectionGap,
    required this.includeButton,
    required this.compact,
  });

  final double imageHeight;
  final double padding;
  final double titleHeight;
  final double summaryHeight;
  final double titleSize;
  final double chipsHeight;
  final double statsHeight;
  final double priceHeight;
  final double buttonHeight;
  final double sectionGap;
  final bool includeButton;
  final bool compact;

  double get bodyHeight {
    var h = padding * 2 + titleHeight + summaryHeight + chipsHeight + statsHeight + priceHeight + sectionGap * 4;
    if (includeButton) h += buttonHeight + 6;
    return h;
  }

  double get totalHeight => imageHeight + bodyHeight;
}

class CourseCardLayout {
  const CourseCardLayout({
    required this.cardHeight,
    required this.padding,
    required this.imageHeight,
    required this.compact,
    required this.titleSize,
    required this.subtitleSize,
    required this.titleHeight,
    required this.subtitleHeight,
    required this.footerHeight,
    required this.chipsHeight,
    required this.statsHeight,
    required this.priceHeight,
    required this.buttonHeight,
    required this.sectionGap,
    required this.gapAfterImage,
    required this.gapAfterTitle,
    required this.gapBeforeFooter,
  });

  final double cardHeight;
  final double padding;
  final double imageHeight;
  final bool compact;
  final double titleSize;
  final double subtitleSize;
  final double titleHeight;
  final double subtitleHeight;
  final double footerHeight;
  final double chipsHeight;
  final double statsHeight;
  final double priceHeight;
  final double buttonHeight;
  final double sectionGap;
  final double gapAfterImage;
  final double gapAfterTitle;
  final double gapBeforeFooter;
}

abstract final class AppGridLayouts {
  static SliverGridDelegateWithFixedCrossAxisCount courseGridFor(BuildContext context) {
    final crossAxisCount = CourseCardMetrics.courseGridCrossAxisCount(context);
    final tileWidth = CourseCardMetrics.courseGridTileWidth(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisExtent: CourseCardMetrics.gridCardHeightForWidth(tileWidth),
      crossAxisSpacing: CourseCardMetrics.gridSpacing,
      mainAxisSpacing: CourseCardMetrics.gridSpacing,
    );
  }

  static double courseTileHeightFor(BuildContext context) => CourseCardMetrics.gridTileHeight(context);
}
