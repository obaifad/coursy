import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/assets/app_assets.dart';
import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';

export 'app_loading.dart';

/// تدرجات العلامة البصرية
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [Color(0xFF7C6CF5), AppColors.primary, Color(0xFF5548CC)],
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
    colors: [Color(0xFF9B8FFF), AppColors.primary, Color(0xFF5548CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ظلال الكروت الموحّدة عبر التطبيق — مصدر واحد لكل حاوية "بطاقة".
abstract final class AppShadows {
  AppShadows._();

  /// ظل ناعم قياسي (يُستخدم داخل [SoftCard] وأي كارد عام آخر).
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 8)),
  ];
}

/// خطوط وعناوين موحّدة عبر التطبيق (Tajawal).
abstract final class AppTypography {
  AppTypography._();

  static TextStyle pageTitle() => GoogleFonts.tajawal(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle pageSubtitle() => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle tabScreenTitle() => GoogleFonts.tajawal(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle homeWelcome() => GoogleFonts.tajawal(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle filterSectionLabel() => GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      );

  static TextStyle sectionTitle() => GoogleFonts.tajawal(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle cardTitle({double size = 15}) => GoogleFonts.tajawal(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle cardSubtitle({double size = 13}) => GoogleFonts.tajawal(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  static TextStyle meta({Color? color}) => GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle actionLabel() => GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );
}

/// شعار Coursy — wordmark أفقي بدون خلفية (افتراضي).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.onDark = false,
    this.lightBackdrop = false,
    this.alignment = AlignmentDirectional.centerStart,
  });

  /// ارتفاع الشعار (العرض يُحسب تلقائياً).
  final double height;

  /// خلفية بيضاء داخل حاوية (splash فقط عند الحاجة).
  final bool onDark;

  /// مُهمَل — الشعار يُعرض بدون خلفية.
  final bool lightBackdrop;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.logo,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Text(
        'Coursy',
        style: AppTypography.tabScreenTitle().copyWith(
          color: onDark ? Colors.white : AppColors.primary,
          fontSize: height * 0.55,
        ),
      ),
    );

    if (!onDark) {
      return Align(alignment: alignment, child: logo);
    }

    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: height * 0.28, vertical: height * 0.18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: logo,
      ),
    );
  }
}

/// شعار العلامة في رأس الصفحة الرئيسية.
class AppHomeBrandLogo extends StatelessWidget {
  const AppHomeBrandLogo({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: AppLogo(
        height: height,
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }
}

/// شريط بحث الصفحة الرئيسية (يفتح شاشة البحث).
class AppHomeSearchBar extends StatelessWidget {
  const AppHomeSearchBar({
    super.key,
    required this.onTap,
    required this.hint,
  });

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F6FF),
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 22, color: AppColors.primary.withValues(alpha: 0.75)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنوان صفحة رئيسي + وصف فرعي (دوراتي، المفضلة، إلخ).
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showLogo = false,
    this.logoInline = false,
    this.logoHeight = 40,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showLogo;
  final bool logoInline;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: logoInline ? AppTypography.tabScreenTitle() : AppTypography.pageTitle()),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTypography.pageSubtitle()),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(hPad, 12, hPad, 4),
      child: logoInline
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppLogo(height: logoHeight),
                SizedBox(width: logoHeight * 0.32),
                Expanded(child: titleBlock),
                if (trailing != null) trailing!,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLogo) ...[
                        AppLogo(height: logoHeight),
                        const SizedBox(height: 10),
                      ],
                      titleBlock,
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
    );
  }
}

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

  static _CourseCardSizeSpec _specFor(
    double width, {
    required bool includeButton,
  }) {
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

  static double gridCardHeightForWidth(
    double width, {
    bool? compact,
    bool includeButton = true,
  }) {
    return _specFor(width, includeButton: includeButton).totalHeight;
  }

  static CourseCardLayout layoutFor(
    BoxConstraints constraints, {
    bool showActionButton = true,
  }) {
    final w = constraints.maxWidth;
    final spec = _specFor(w, includeButton: showActionButton);
    return CourseCardLayout(
      cardHeight: constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : spec.totalHeight,
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
    var h = padding * 2 +
        titleHeight +
        summaryHeight +
        chipsHeight +
        statsHeight +
        priceHeight +
        sectionGap * 4;
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

/// نمط هندسي خفيف للبانرات
class BrandBannerPattern extends StatelessWidget {
  const BrandBannerPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BrandBannerPatternPainter());
  }
}

class _BrandBannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    const step = 28.0;
    for (var x = -step; x < size.width + step; x += step) {
      for (var y = -step; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      }
    }
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1.0;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.15 + i * 0.14);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// بطاقة بيضاء ناعمة + ظل (مطابقة لأسلوب الـ UI Kit)
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// زر أيقونة دائري/مربّع ناعم (AppBar / Home)
class AppIconCircleButton extends StatelessWidget {
  const AppIconCircleButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.filled = true,
    this.size = 44,
    this.iconColor,
    this.iconSize,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool filled;
  final double size;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = size >= 40 ? 14.0 : 12.0;
    final resolvedIconColor = iconColor ?? (filled ? AppColors.textPrimary : AppColors.primary.withValues(alpha: 0.82));
    return Material(
      color: filled ? AppColors.card : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      shadowColor: AppColors.shadowPurple,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? AppColors.card : AppColors.indicatorFill.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(radius),
            border: filled ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            boxShadow: filled
                ? const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: Offset(0, 4))]
                : null,
          ),
          child: Icon(icon, color: resolvedIconColor, size: iconSize ?? size * 0.48),
        ),
      ),
    );
  }
}

/// شريط تبويبات يبدأ من حافة الشاشة حسب اتجاه اللغة (بدون فراغ زائد).
class AppEdgeTabBar extends StatelessWidget {
  const AppEdgeTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.edgeInset = 16,
    this.fill = false,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final double edgeInset;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: !fill,
      tabAlignment: fill ? TabAlignment.fill : TabAlignment.start,
      padding: EdgeInsets.zero,
      indicatorPadding: EdgeInsets.zero,
      dividerHeight: 0,
      labelPadding: fill ? EdgeInsets.zero : EdgeInsetsDirectional.only(start: edgeInset, end: 12),
      tabs: tabs,
    );
  }
}

/// تبويبات pill موحّدة عبر التطبيق (دوراتي، تفاصيل الدورة، المعاهد...).
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.height = 48,
    this.padding = const EdgeInsets.all(4),
    this.margin = EdgeInsets.zero,
  });

  final TabController controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// أقل عرض مقبول لكل تبويب في وضع التوزيع المتساوي (fill) قبل التحوّل للتمرير.
  static const double _minTabExtent = 84;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.indicatorFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // يتحوّل للتمرير تلقائياً عندما تضيق الخلايا (هواتف صغيرة + 4 تبويبات)
            // لمنع تجاوز RenderFlex، مع الإبقاء على التوزيع المتساوي على الشاشات الأوسع.
            final available = constraints.maxWidth - padding.horizontal;
            final perTab = tabs.isEmpty ? available : available / tabs.length;
            final scrollable = isScrollable || perTab < _minTabExtent;
            return TabBar(
              controller: controller,
              isScrollable: scrollable,
              tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: padding,
              labelPadding: scrollable ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashBorderRadius: BorderRadius.circular(12),
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x226C63FF), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: tabs,
            );
          },
        ),
      ),
    );
  }
}

/// غلاف تبويبات pill بنفس مقاسات [CourseDetailsView].
class AppTabBarSection extends StatelessWidget {
  const AppTabBarSection({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
  });

  final TabController controller;
  final List<Widget> tabs;
  final bool isScrollable;

  static const double sectionHeight = 60;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sectionHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: AppSegmentedTabBar(
          controller: controller,
          isScrollable: isScrollable,
          tabs: tabs,
        ),
      ),
    );
  }
}

/// مقاسات وتباعدات مشتركة — شريط التنقل العائم، هوامش الصفحة، ومساحة التمرير.
abstract final class AppLayout {
  AppLayout._();

  /// ارتفاع شريط التنقل السفلي العائم في [RootView] (extendBody: true).
  static const double rootNavBarHeight = 92;

  static double rootNavReserve(BuildContext context) {
    return rootNavBarHeight + MediaQuery.viewPaddingOf(context).bottom;
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
    final h = horizontalPage(context);
    return EdgeInsetsDirectional.fromSTEB(
      h,
      top,
      h,
      scrollBottomInset(context, rootTab: rootTab) + extraBottom,
    );
  }

  /// حشوة أفقية موحّدة لعناوين الأقسام والمحتوى العمودي.
  static EdgeInsetsDirectional sectionHorizontal(BuildContext context) {
    final h = horizontalPage(context);
    return EdgeInsetsDirectional.fromSTEB(h, 0, h, 0);
  }
}

/// يمنع تداخل المحتوى مع شريط الحالة في التبويبات والشاشات.
class AppTabSafeArea extends StatelessWidget {
  const AppTabSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = false,
  });

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: child,
    );
  }
}

/// عنوان شاشة داخل التبويب مع احترام المنطقة الآمنة.
class AppTabScreenHeader extends StatelessWidget {
  const AppTabScreenHeader({super.key, required this.title, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
      child: Text(title, style: AppTypography.tabScreenTitle()),
    );
  }
}

/// بانر تصنيف: صورة + اسم + عدد الدورات.
class CategoryHeaderBanner extends StatelessWidget {
  const CategoryHeaderBanner({super.key, required this.category, this.coursesCount});

  final CategoryModel category;
  final int? coursesCount;

  @override
  Widget build(BuildContext context) {
    final count = coursesCount ?? category.coursesCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 12)],
            ),
            clipBehavior: Clip.antiAlias,
            child: CategoryIcon(
              category: category,
              size: 64,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'category_courses_count'.trParams({'count': '$count'}),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// إحصائيات أفقية (الملف الشخصي وغيره).
class AppStatsRow extends StatelessWidget {
  const AppStatsRow({super.key, required this.items});

  final List<AppStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Container(width: 1, height: 36, color: AppColors.borderSoft),
          Expanded(child: _AppStatCell(item: items[i])),
        ],
      ],
    );
  }
}

class AppStatItem {
  const AppStatItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _AppStatCell extends StatelessWidget {
  const _AppStatCell({required this.item});

  final AppStatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(item.value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(item.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }
}

/// عنوان قسم + اختياري "عرض الكل"
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.sectionTitle(),
                textAlign: TextAlign.start,
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTypography.pageSubtitle(),
                  textAlign: TextAlign.start,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsetsDirectional.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: AppTypography.actionLabel()),
          ),
      ],
    );
  }
}

/// هل الواجهة عربية/RTL؟
bool appIsRtl(BuildContext context) => Directionality.of(context) == TextDirection.rtl;

/// قائمة أفقية موحّدة — تتبع [Directionality] دائماً:
/// في RTL يبدأ أول عنصر من أقصى اليمين ويملأ نحو اليسار، وفي LTR العكس.
///
/// لا تستخدم `reverse` إطلاقاً — اتجاه التمرير يُشتق تلقائياً من اتجاه اللغة،
/// لضمان محاذاة متطابقة عبر كل القوائم (بطاقات وشرائح) حاضراً ومستقبلاً.
class AppHorizontalListView extends StatefulWidget {
  const AppHorizontalListView({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorWidth = 12,
    this.edgeInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final double? edgeInset;

  /// حشو سفلي للحاوية — يمنع قص ظل البطاقات (Box Shadow) عند حافة القائمة.
  final double bottomInset;

  /// false = لا يحفظ موضع التمرير (مُفضّل للقوائم القصيرة في الرئيسية).
  final bool rememberScroll;

  /// عند تغيّره تُعاد القائمة لنقطة البداية (يُستخدم مع العودة للرئيسية).
  final int resetToken;

  /// مساحة كافية لظل البطاقات ذات الـ boxShadow (مثلاً featured course cards).
  static const double cardShadowBottomInset = 28;

  @override
  State<AppHorizontalListView> createState() => _AppHorizontalListViewState();
}

class _AppHorizontalListViewState extends State<AppHorizontalListView> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(keepScrollOffset: widget.rememberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
  }

  @override
  void didUpdateWidget(covariant AppHorizontalListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != oldWidget.resetToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
    }
    if (widget.rememberScroll != oldWidget.rememberScroll) {
      _controller.dispose();
      _controller = ScrollController(keepScrollOffset: widget.rememberScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToStart() {
    if (!_controller.hasClients) return;
    final target = _controller.position.minScrollExtent;
    if ((_controller.offset - target).abs() > 0.5) {
      _controller.jumpTo(target);
    }
  }

  double _edgeInset(BuildContext context) => widget.edgeInset ?? AppLayout.horizontalPage(context);

  Widget _itemWithEdgeInsets(BuildContext context, int index) {
    final child = widget.itemBuilder(context, index);
    final inset = _edgeInset(context);
    if (inset <= 0) return child;

    final isFirst = index == 0;
    final isLast = index == widget.itemCount - 1;
    if (!isFirst && !isLast) return child;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: isFirst ? inset : 0,
        end: isLast ? inset : 0,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    // ملاحظة: لا نمرّر `reverse` — اتجاه التمرير يُشتق من Directionality،
    // فيبدأ أول عنصر من اليمين في RTL ومن اليسار في LTR بشكل موحّد.
    return SizedBox(
      height: widget.height + widget.bottomInset,
      width: double.infinity,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) => SizedBox(width: widget.separatorWidth),
        itemBuilder: (context, index) => _itemWithEdgeInsets(context, index),
      ),
    );
  }
}

/// صف أفقي جاهز من عناصر — ترتيب منطقي RTL (العنصر الأول يميناً).
class AppHorizontalScrollRow extends StatelessWidget {
  const AppHorizontalScrollRow({
    super.key,
    required this.height,
    required this.children,
    this.separatorWidth = 8,
    this.edgeInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final List<Widget> children;
  final double separatorWidth;
  final double? edgeInset;
  final double bottomInset;
  final bool rememberScroll;
  final int resetToken;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalListView(
      height: height,
      separatorWidth: separatorWidth,
      edgeInset: edgeInset,
      bottomInset: bottomInset,
      rememberScroll: rememberScroll,
      resetToken: resetToken,
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// شريط بحث داخل بطاقة
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, this.hint = 'ابحث عن دورة أو معهد', this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: TextField(
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// بطاقة معهد مضغوطة للعرض الأفقي (الرئيسية)
class InstituteMiniCard extends StatelessWidget {
  const InstituteMiniCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SoftCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: AppGradients.category,
                ),
                clipBehavior: Clip.antiAlias,
                child: _InstituteCoverHeader(
                  coverUrl: institute.resolvedCoverImageUrl,
                  logoUrl: institute.resolvedLogoUrl,
                  height: 88,
                  iconSize: 40,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institute.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${institute.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivateInstructorListCard extends StatelessWidget {
  const PrivateInstructorListCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _InstructorAvatarBox(imageUrl: instructor.resolvedImageUrl, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          instructor.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (instructor.isPrivate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'private_instructor_badge'.tr,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor.specialization ?? 'instructor_default'.tr,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'instructor_years'.trParams({
                      'role': instructor.specialization ?? 'instructor_default'.tr,
                      'years': '${instructor.experienceYears}',
                    }),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (instructor.hourlyPrice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'hourly_price_value'.trParams({'price': instructor.hourlyPrice!}),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                    ),
                  ],
                  if (instructor.address != null && instructor.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            instructor.address!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class PrivateInstructorMiniCard extends StatelessWidget {
  const PrivateInstructorMiniCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  static const double _cardWidth = 288;
  static const double _avatarSize = 54;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: SoftCard(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 2),
                child: _InstructorAvatarBox(
                  imageUrl: instructor.resolvedImageUrl,
                  size: _avatarSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructor.specialization ?? 'instructor_default'.tr,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'instructor_years_short'.trParams({'years': '${instructor.experienceYears}'}),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    if (instructor.hourlyPrice != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: CoursePriceText(
                            price: instructor.hourlyPrice!,
                            amountSize: 14,
                            currencySize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstituteLogoBox extends StatelessWidget {
  const _InstituteLogoBox({
    required this.imageUrl,
    required this.size,
    this.borderRadius = 16,
    this.fallbackIcon = Icons.apartment_rounded,
    this.fallbackIconSize,
    this.border,
  });

  final String? imageUrl;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final iconSize = fallbackIconSize ?? size * 0.45;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: imageUrl == null ? AppGradients.category : null,
        color: imageUrl != null ? Colors.white : null,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageUrl != null
            ? AppNetworkImage(url: imageUrl!, width: size, height: size, fit: BoxFit.cover)
            : Icon(fallbackIcon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class _InstituteCoverHeader extends StatelessWidget {
  const _InstituteCoverHeader({
    required this.coverUrl,
    this.logoUrl,
    required this.height,
    this.iconSize = 40,
  });

  final String? coverUrl;
  final String? logoUrl;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null) {
      return AppNetworkImage(url: coverUrl!, fit: BoxFit.cover);
    }

    if (logoUrl != null) {
      return Center(
        child: _InstituteLogoBox(
          imageUrl: logoUrl,
          size: iconSize * 1.6,
          borderRadius: 16,
          fallbackIcon: Icons.domain_rounded,
          fallbackIconSize: iconSize,
        ),
      );
    }

    return Center(child: Icon(Icons.domain_rounded, color: Colors.white, size: iconSize));
  }
}

/// غلاف صفحة تفاصيل المعهد (صورة الغلاف + لوغو دائري).
class InstituteDetailHero extends StatelessWidget {
  const InstituteDetailHero({super.key, required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    final coverUrl = institute.resolvedCoverImageUrl;
    final logoUrl = institute.resolvedLogoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null)
          AppNetworkImage(url: coverUrl, fit: BoxFit.cover)
        else
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.category)),
        if (coverUrl != null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        Center(
          child: _InstituteLogoBox(
            imageUrl: logoUrl,
            size: 88,
            borderRadius: 44,
            fallbackIcon: Icons.apartment_rounded,
            fallbackIconSize: 42,
            border: Border.all(color: Colors.white, width: 4),
          ),
        ),
      ],
    );
  }
}

class _InstructorAvatarBox extends StatelessWidget {
  const _InstructorAvatarBox({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppGradients.primary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl != null
            ? AppNetworkImage(url: imageUrl!, width: size, height: size, fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

class InstituteListCard extends StatelessWidget {
  const InstituteListCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _InstituteLogoBox(
              imageUrl: institute.resolvedListImageUrl,
              size: 72,
              borderRadius: 16,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          institute.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (institute.isVerified)
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          institute.city,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${institute.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'category_courses_count'.trParams({'count': '${institute.coursesCount}'}),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// صف قائمة للملف الشخصي
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({super.key, required this.title, required this.icon, this.onTap, this.trailing});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.indicatorFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: trailing ?? const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// إشعار داخل بطاقة
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.title, required this.subtitle, required this.icon, this.unread = true});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.indicatorFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

/// حالة فارغة موحّدة — نفس المظهر في كل الصفحات.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.compact = false,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize,
    this.circleSize,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  final bool compact;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconSize;
  final double? circleSize;

  /// للقوائم القابلة للسحب (RefreshIndicator / TabBarView).
  static Widget scrollable({
    required BuildContext context,
    required String message,
    String? subtitle,
    IconData icon = Icons.inbox_outlined,
    Widget? action,
    bool compact = false,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: AppEmptyState(
              message: message,
              subtitle: subtitle,
              icon: icon,
              action: action,
              compact: compact,
              iconColor: iconColor,
              iconBackgroundColor: iconBackgroundColor,
            ),
          ),
        );
      },
    );
  }

  /// داخل SoftCard أو قسم أفقي في الصفحة الرئيسية.
  static Widget inline({
    required String message,
    IconData icon = Icons.inbox_outlined,
    String? subtitle,
  }) {
    return AppEmptyState(
      message: message,
      subtitle: subtitle,
      icon: icon,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;
    final circle = circleSize ?? (compact ? 52.0 : 104.0);
    final iconSz = iconSize ?? (compact ? 26.0 : 52.0);
    final verticalPad = compact ? 16.0 : 24.0;
    final horizontalPad = compact ? 16.0 : 32.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? tint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSz, color: tint),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: compact
                  ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary, height: 1.45)
                  : AppTypography.sectionTitle(),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.pageSubtitle(),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? 12 : 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
