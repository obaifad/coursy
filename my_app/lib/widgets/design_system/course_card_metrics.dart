part of '../design_system.dart';

/// شبكة دورات موحّدة — مقاسات متجاوبة مع عرض الشاشة.
abstract final class CourseCardMetrics {
  CourseCardMetrics._();

  static const double gridSpacing = 12;
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

  /// ارتفاع القائمة الأفقية = ارتفاع بطاقة الدورة بعرض بطاقة الرئيسية.
  static double featuredCardHeight(BuildContext context) =>
      ticketSpec(featuredCardWidth(context), textScale: textScaleOf(context)).totalHeight;

  static double featuredListHeight(BuildContext context) => featuredCardHeight(context);

  /// بطاقة ضيقة (عمودان على الهاتف): السعر فوق المدة ونوع الحضور بدل أن يتجاورا.
  static bool isCompactTile(double width) => width < 220;

  /// مقاسات بطاقة الدورة (تصميم التذكرة) لعرض [width]. كل سطر بارتفاع ثابت (حتى لو فارغ)
  /// فتتساوى مواضع العناصر والسعر بين بطاقات الشبكة الواحدة.
  static CourseTicketSpec ticketSpec(double width, {double textScale = 1}) {
    final s = textScale;
    final compact = isCompactTile(width);
    return CourseTicketSpec(
      compact: compact,
      imageHeight: ((width - CourseTicketSpec.inset * 2) / 1.7).clamp(80.0, 150.0),
      padding: compact ? 10 : 12,
      categoryHeight: 16 * s,
      titleSize: compact ? 13 : 14.5,
      titleHeight: (compact ? 34 : 38) * s,
      instituteHeight: 16 * s,
      ratingHeight: 16 * s,
      footerHeight: (compact ? 62 : 42) * s,
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

  static double gridCardHeightForWidth(double width, {double textScale = 1}) {
    return ticketSpec(width, textScale: textScale).totalHeight;
  }

  /// مقاسات تقريبية لهيكل التحميل (Skeleton) بنفس ارتفاع البطاقة الحقيقية.
  static CourseCardLayout layoutFor(BoxConstraints constraints, {double textScale = 1}) {
    final spec = ticketSpec(constraints.maxWidth, textScale: textScale);
    return CourseCardLayout(
      cardHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : spec.totalHeight,
      padding: spec.padding,
      imageHeight: spec.imageHeight,
      compact: spec.compact,
      titleSize: spec.titleSize,
      subtitleSize: 11.5,
      titleHeight: spec.titleHeight,
      subtitleHeight: spec.instituteHeight,
      footerHeight: spec.footerHeight,
      chipsHeight: spec.categoryHeight,
      statsHeight: spec.ratingHeight,
      priceHeight: spec.footerHeight,
      buttonHeight: 0,
      sectionGap: 6,
      gapAfterImage: CourseTicketSpec.gapAfterImage,
      gapAfterTitle: 6,
      gapBeforeFooter: 6,
    );
  }
}

/// مقاسات بطاقة الدورة بتصميم التذكرة (صورة داخلية، تفاصيل، خط متقطع بقصّتين، ثم السعر).
class CourseTicketSpec {
  const CourseTicketSpec({
    required this.compact,
    required this.imageHeight,
    required this.padding,
    required this.categoryHeight,
    required this.titleSize,
    required this.titleHeight,
    required this.instituteHeight,
    required this.ratingHeight,
    required this.footerHeight,
  });

  /// هامش الصورة داخل البطاقة.
  static const double inset = 8;
  static const double gapAfterImage = 10;
  static const double gapAfterCategory = 4;
  static const double gapAfterTitle = 6;
  static const double gapAfterInstitute = 5;
  static const double gapAfterRating = 4;

  /// منطقة الخط المتقطع — القصّتان في منتصفها.
  static const double dividerHeight = 18;
  static const double bottomPadding = 12;
  static const double notchRadius = 8;

  final bool compact;
  final double imageHeight;
  final double padding;
  final double categoryHeight;
  final double titleSize;
  final double titleHeight;
  final double instituteHeight;
  final double ratingHeight;
  final double footerHeight;

  double get totalHeight =>
      inset +
      imageHeight +
      gapAfterImage +
      categoryHeight +
      gapAfterCategory +
      titleHeight +
      gapAfterTitle +
      instituteHeight +
      gapAfterInstitute +
      ratingHeight +
      gapAfterRating +
      dividerHeight +
      footerHeight +
      bottomPadding;

  /// بُعد مركز القصّتين عن أسفل البطاقة.
  double get notchFromBottom => bottomPadding + footerHeight + dividerHeight / 2;
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
    final tileWidth = CourseCardMetrics.courseGridTileWidth(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: CourseCardMetrics.courseGridCrossAxisCount(context),
      // هامش 2 لكسور البكسل في مقاييس الخط.
      mainAxisExtent:
          CourseCardMetrics.gridCardHeightForWidth(tileWidth, textScale: CourseCardMetrics.textScaleOf(context)) + 2,
      crossAxisSpacing: CourseCardMetrics.gridSpacing,
      mainAxisSpacing: CourseCardMetrics.gridSpacing,
    );
  }

  static double courseTileHeightFor(BuildContext context) => CourseCardMetrics.gridTileHeight(context);
}
