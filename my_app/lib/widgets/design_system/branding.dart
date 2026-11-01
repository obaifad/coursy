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
          fontSize: AppTextSize.snap(height * 0.55),
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
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: logo,
      ),
    );
  }
}

/// شعار العلامة في رأس الصفحة الرئيسية.
///
/// [height] ارتفاع الكلمة المرئية نفسها: صورة الشعار فيها هوامش شفافة (الكلمة 39% من ارتفاعها)، فكان
/// ارتفاع 56 يرسم كلمة بارتفاع ~22 فقط بجانب زر إعدادات قطره 46. الهوامش تُقصّ هنا فيأخذ الشعار مساحة
/// كلمته فقط.
class AppHomeBrandLogo extends StatelessWidget {
  const AppHomeBrandLogo({super.key, this.height = 30});

  final double height;

  // حدود الكلمة داخل images/s.png (677×368): الأعمدة 133–569 والصفوف 113–257.
  static const double _inkLeft = 133 / 677;
  static const double _inkWidth = 436 / 677;
  static const double _inkTop = 113 / 368;
  static const double _inkHeight = 144 / 368;
  static const double _imageAspect = 677 / 368;

  @override
  Widget build(BuildContext context) {
    final imageHeight = height / _inkHeight;
    final imageWidth = imageHeight * _imageAspect;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: SizedBox(
        width: imageWidth * _inkWidth,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: imageWidth,
            maxHeight: imageHeight,
            // يضع حافّتي الكلمة على حافّتي الصندوق (الكلمة ليست في منتصف الصورة تماماً).
            alignment: Alignment(2 * _inkLeft / (1 - _inkWidth) - 1, 2 * _inkTop / (1 - _inkHeight) - 1),
            child: AppLogo(height: imageHeight, alignment: Alignment.center),
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                  style: AppFonts.tajawal(
                    fontSize: AppTextSize.md,
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

/// نمط هندسي خفيف للبانرات
class BrandBannerPattern extends StatelessWidget {
  const BrandBannerPattern({super.key});

  @override
  Widget build(BuildContext context) {
    // نحو 100 دائرة و6 خطوط: تُرسم مرة وتُخزَّن، لا مع كل إطار طي/تمرير للرأس.
    return RepaintBoundary(child: CustomPaint(painter: _BrandBannerPatternPainter()));
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 12)],
            ),
            clipBehavior: Clip.antiAlias,
            child: CategoryIcon(category: category, size: 64, borderRadius: BorderRadius.circular(AppRadius.md)),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: AppTextSize.xl),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    pluralTr('category_courses_count', count),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: AppTextSize.sm),
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
