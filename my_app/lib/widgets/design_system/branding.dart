part of '../design_system.dart';

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
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 10))],
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
      child: AppLogo(height: height, alignment: AlignmentDirectional.centerStart),
    );
  }
}

/// شريط بحث الصفحة الرئيسية (يفتح شاشة البحث).
class AppHomeSearchBar extends StatelessWidget {
  const AppHomeSearchBar({super.key, required this.onTap, required this.hint});

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
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
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                  style: AppFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
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
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: AppTypography.pageSubtitle())],
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
                      if (showLogo) ...[AppLogo(height: logoHeight), const SizedBox(height: 10)],
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
            child: CategoryIcon(category: category, size: 64, borderRadius: BorderRadius.circular(18)),
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

/// شريط بحث داخل بطاقة
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, this.hint, this.onTap});

  /// عند غيابه يُستخدم نص البحث المترجم بلغة الواجهة.
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: TextField(
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint ?? 'home_search_hint'.tr,
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
