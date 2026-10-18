part of '../app_widgets.dart';

/// بطاقة الدورة «الملصق»: الغلاف يملأ البطاقة وعليه تعتيم داكن متدرّج يحمل العنوان واسم المعهد،
/// وتحته شريط أبيض صلب للسعر والتقييم. لشبكة كل الدورات وصفحات التصنيف؛ الضغط في أي مكان يفتح الدورة.
class CoursePosterCard extends StatelessWidget {
  const CoursePosterCard({super.key, required this.course, this.onTap});

  final CourseModel course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = CourseCardMetrics.posterSpec(
          constraints.maxWidth,
          textScale: CourseCardMetrics.textScaleOf(context),
        );
        // ارتفاع مفروض (خلية شبكة) يُحترم والفرق يذهب للغلاف؛ وإلا الارتفاع الطبيعي.
        final height = constraints.hasTightHeight
            ? constraints.maxHeight
            : spec.totalHeight.clamp(0.0, constraints.maxHeight).toDouble();
        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: AppCorners.md,
              boxShadow: _courseCardShadow,
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: AppCorners.md,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _PosterCover(course: course, spec: spec),
                    ),
                    SizedBox(
                      height: spec.stripHeight,
                      child: _PosterStrip(course: course, spec: spec),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PosterCover extends StatelessWidget {
  const _PosterCover({required this.course, required this.spec});

  final CourseModel course;
  final CoursePosterSpec spec;

  @override
  Widget build(BuildContext context) {
    final badge = _coursePromoBadge(course);
    final percent = course.originalPriceLabel == null ? null : course.discountPercent;
    final institute = [
      course.institute.trim(),
      course.instituteCity?.trim() ?? '',
    ].where((p) => p.isNotEmpty).join(' • ');
    const pad = CoursePosterSpec.padding;

    return Stack(
      fit: StackFit.expand,
      children: [
        CourseImageHero(
          courseId: course.id,
          child: _CourseCardImage(
            course: course,
            borderRadius: BorderRadius.zero,
            fallbackSize: spec.compact ? 26 : 30,
            // العنوان يغطي النصف السفلي — أيقونة البديل في الأعلى.
            fallbackIconAlignment: const Alignment(0, -0.4),
          ),
        ),
        // تعتيم سفلي يُبقي العنوان الأبيض مقروءاً فوق أي صورة.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.35, 0.68, 1],
              colors: [Color(0x00000000), Color(0x00000000), Color(0x80000000), Color(0xD9000000)],
            ),
          ),
        ),
        if (badge != null || percent != null)
          PositionedDirectional(
            top: pad,
            start: pad,
            end: pad,
            child: Row(
              children: [
                if (percent != null) _DiscountPill(percent: percent),
                const Spacer(),
                if (badge != null) Flexible(flex: 8, child: _PosterBadge(label: badge)),
              ],
            ),
          ),
        PositionedDirectional(
          start: pad,
          end: pad,
          bottom: pad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BidiText(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: AppTextSize.lg,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
              if (institute.isNotEmpty) ...[
                const SizedBox(height: 4),
                BidiText(
                  institute,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.tajawal(
                    fontSize: AppTextSize.xs,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// شارة داكنة على الغلاف («الأكثر طلباً»، «مقاعد محدودة»، «جديدة»…).
class _PosterBadge extends StatelessWidget {
  const _PosterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.82), borderRadius: AppCorners.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              color: Colors.white,
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// الشريط الأبيض: السعر في جهة البداية والتقييم في جهة النهاية.
class _PosterStrip extends StatelessWidget {
  const _PosterStrip({required this.course, required this.spec});

  final CourseModel course;
  final CoursePosterSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CoursePosterSpec.padding),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: CoursePriceText(price: course.price, amountSize: AppTextSize.lg, currencySize: AppTextSize.xs),
            ),
          ),
          const SizedBox(width: 8),
          CourseRatingBadge(course: course, showCount: !spec.compact),
        ],
      ),
    );
  }
}

/// تقييم مختصر: نجمة + القيمة (+ العدد)، أو «بلا تقييم» بلون خافت بدل نجوم رمادية أو شرطة.
class CourseRatingBadge extends StatelessWidget {
  const CourseRatingBadge({super.key, required this.course, this.showCount = true});

  final CourseModel course;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    if (!course.hasRating) {
      return Text(
        'rating_none_short'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w500, color: AppColors.textHint),
      );
    }
    final count = course.reviewsCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.ratingStar),
        const SizedBox(width: 2),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: course.rating.toStringAsFixed(1),
              style: AppFonts.tajawal(
                fontSize: AppTextSize.sm,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
                height: 1.2,
              ),
              children: [
                if (showCount && count != null && count > 0)
                  TextSpan(
                    text: ' ($count)',
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
