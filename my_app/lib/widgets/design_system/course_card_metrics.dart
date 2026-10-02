part of '../design_system.dart';

/// شبكة دورات موحّدة — مقاسات متجاوبة مع عرض الشاشة.
abstract final class CourseCardMetrics {
  CourseCardMetrics._();

  static const double gridSpacing = 12;
  static const double gridAspectRatio = 0.72;
  static const double gridImageHeight = 108;
  static const double gridBodyPadding = 12;
  static const double cardRadius = 18;

  /// معامل تكبير الخط الفعلي (إعداد الجهاز محصور بين 1.0 و1.3 في app.dart).
  /// ارتفاعات أسطر النص في البطاقة تُضرب به — وإلا تتداخل النصوص عند تكبير الخط.
  static double textScaleOf(BuildContext context) => MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

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
    // العنوان سطران بخط 14 يحتاج 36 (كان 32 فيُقصّ السطر الثاني).
    const contentH = 8 + featuredTitleHeight + 6 + 16 + 8 + 20 + 8 + 30 + 10 + 32 + 14;
    return imageH + contentH * textScaleOf(context);
  }

  /// ارتفاع عنوان البطاقة المميزة (سطران) عند حجم الخط الافتراضي.
  static const double featuredTitleHeight = 36;

  static double featuredListHeight(BuildContext context) => featuredCardHeight(context);

  /// عرض بطاقة الشبكة (عمودين) — أضيق من بطاقات القوائم الأفقية في الهوم.
  static bool isCompactTile(double width) => width < 220;

  static bool isFeaturedTile(double width, {required bool includeButton}) {
    return !includeButton && width >= 220;
  }

  static _CourseCardSizeSpec _specFor(double width, {required bool includeButton, double textScale = 1}) {
    final s = textScale;
    if (isFeaturedTile(width, includeButton: includeButton)) {
      final imageHeight = (width / 1.65).clamp(88.0, 112.0);
      return _CourseCardSizeSpec(
        imageHeight: imageHeight,
        padding: 12,
        titleHeight: 36 * s,
        summaryHeight: 16 * s,
        titleSize: 13,
        chipsHeight: 20 * s,
        statsHeight: 18 * s,
        priceHeight: 30 * s,
        buttonHeight: 32 * s + 14 * (s - 1),
        sectionGap: 6,
        includeButton: false,
        compact: true,
      );
    }
    if (isCompactTile(width)) {
      return _CourseCardSizeSpec(
        imageHeight: 84,
        padding: 10,
        titleHeight: 34 * s,
        summaryHeight: 14 * s,
        titleSize: 12.5,
        chipsHeight: 20 * s,
        statsHeight: 16 * s,
        // السعر القديم فوق الحالي في البطاقة الضيقة (بدل قصّهما بـ "…").
        priceHeight: 36 * s,
        buttonHeight: 30 * s + 14 * (s - 1),
        sectionGap: 5,
        includeButton: includeButton,
        compact: true,
      );
    }
    return _CourseCardSizeSpec(
      imageHeight: gridImageHeight,
      padding: gridBodyPadding,
      titleHeight: 38 * s,
      summaryHeight: 16 * s,
      titleSize: 14,
      chipsHeight: 22 * s,
      statsHeight: 18 * s,
      priceHeight: 32 * s,
      buttonHeight: 34 * s + 14 * (s - 1),
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
    return gridCardHeightForWidth(courseGridTileWidth(context), textScale: textScaleOf(context));
  }

  static double gridCardHeightForWidth(double width, {bool? compact, bool includeButton = true, double textScale = 1}) {
    return _specFor(width, includeButton: includeButton, textScale: textScale).totalHeight;
  }

  static CourseCardLayout layoutFor(BoxConstraints constraints, {bool showActionButton = true, double textScale = 1}) {
    final w = constraints.maxWidth;
    final spec = _specFor(w, includeButton: showActionButton, textScale: textScale);
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
      mainAxisExtent: CourseCardMetrics.gridCardHeightForWidth(
        tileWidth,
        textScale: CourseCardMetrics.textScaleOf(context),
      ),
      crossAxisSpacing: CourseCardMetrics.gridSpacing,
      mainAxisSpacing: CourseCardMetrics.gridSpacing,
    );
  }

  static double courseTileHeightFor(BuildContext context) => CourseCardMetrics.gridTileHeight(context);
}
