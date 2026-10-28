part of '../app_widgets.dart';

/// بطاقة الدورة بتصميم التذكرة: صورة داخلية بشارة، التصنيف والمستوى، العنوان، المعهد والمدينة،
/// التقييم، ثم خط متقطع بقصّتين جانبيتين، وتحته السعر والمدة ونوع الحضور.
/// تُستخدم في كل القوائم (الرئيسية، الشبكات، المفضلة، صفحة المدرّس) والضغط في أي مكان يفتح الدورة.
/// زر المفضلة على زاوية البداية من الصورة، والشارة على زاوية النهاية — لا يغطي أحدهما الآخر.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap, this.showFavorite = true, this.onFavoritePressed});

  final CourseModel course;
  final VoidCallback? onTap;
  final bool showFavorite;

  /// بديل لتبديل المفضلة الافتراضي (شاشة المفضلة: إزالة مع تلاشٍ وتراجع).
  final Future<void> Function()? onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = CourseCardMetrics.ticketSpec(
          constraints.maxWidth,
          textScale: CourseCardMetrics.textScaleOf(context),
        );
        // ارتفاع مفروض (شبكة / قائمة أفقية) يُحترم؛ وإلا ارتفاع المحتوى الطبيعي.
        final height = constraints.hasTightHeight
            ? constraints.maxHeight
            : spec.totalHeight.clamp(0.0, constraints.maxHeight).toDouble();
        final radius = BorderRadius.circular(_kCourseCardRadius);
        // القصّتان فتحتان حقيقيتان: جسم البطاقة الأبيض وظلّه يُرسمان بمسار التذكرة (محيط واحد بنصفي دائرة
        // على الحافتين)، فيظهر ما خلف البطاقة من الفتحتين ويلتفّ الظل حولهما. رسم لا قصّ: ClipPath بمسار
        // مركّب (Path.combine) كان يُرسم خطأً بمحرّك Impeller على Adreno 618 (كبسولة الحسم فارغة والبطاقة
        // رمادية)؛ المحتوى نفسه يبقى في ClipRRect.
        final notchCenterY = height - spec.notchFromBottom;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const ValueKey('ticket-body'),
                  painter: _TicketBodyPainter(notchCenterY: notchCenterY),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: radius,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                      splashColor: AppColors.primary.withValues(alpha: 0.08),
                      highlightColor: AppColors.primary.withValues(alpha: 0.04),
                      child: _TicketContent(
                        course: course,
                        spec: spec,
                        favorite: showFavorite
                            ? CourseFavoriteButton(
                                courseId: course.id,
                                diameter: spec.compact ? 32 : 34,
                                onPressed: onFavoritePressed,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// جسم بطاقة التذكرة: مستطيل مدوّر بفتحتين نصف دائريتين على الحافتين عند الخط المتقطع، مع ظلّ البطاقة
/// بنفس الشكل (كما يرسم BoxDecoration ظلّه: المسار نفسه بتمويه). محيط واحد بـ arcToPoint، بلا
/// Path.combine ولا قصّ.
class _TicketBodyPainter extends CustomPainter {
  const _TicketBodyPainter({required this.notchCenterY});

  final double notchCenterY;

  static const double _r = _kCourseCardRadius;
  static const double _notch = CourseTicketSpec.notchRadius;

  /// الظل يُرسم بفتحتين أوسع: ظلّ البطاقة تحتها كان يظهر من الفتحة هلالاً رمادياً داكناً.
  static const double _shadowNotchExtra = 8;

  @visibleForTesting
  static Path ticketPath(Size size, double notchCenterY, {double notchRadius = _notch}) {
    final w = size.width, h = size.height;
    final n = notchRadius;
    const corner = Radius.circular(_r);
    final notch = Radius.circular(n);
    return Path()
      ..moveTo(_r, 0)
      ..lineTo(w - _r, 0)
      ..arcToPoint(Offset(w, _r), radius: corner)
      ..lineTo(w, notchCenterY - n)
      ..arcToPoint(Offset(w, notchCenterY + n), radius: notch, clockwise: false)
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: corner)
      ..lineTo(_r, h)
      ..arcToPoint(Offset(0, h - _r), radius: corner)
      ..lineTo(0, notchCenterY + n)
      ..arcToPoint(Offset(0, notchCenterY - n), radius: notch, clockwise: false)
      ..lineTo(0, _r)
      ..arcToPoint(const Offset(_r, 0), radius: corner)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPath = ticketPath(size, notchCenterY, notchRadius: _notch + _shadowNotchExtra);
    for (final shadow in _courseCardShadow) {
      canvas.drawPath(shadowPath.shift(shadow.offset), shadow.toPaint());
    }
    canvas.drawPath(ticketPath(size, notchCenterY), Paint()..color = AppColors.card);
  }

  @override
  bool shouldRepaint(_TicketBodyPainter old) => old.notchCenterY != notchCenterY;
}

class _TicketContent extends StatelessWidget {
  const _TicketContent({required this.course, required this.spec, this.favorite});

  final CourseModel course;
  final CourseTicketSpec spec;
  final Widget? favorite;

  @override
  Widget build(BuildContext context) {
    final pad = spec.padding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(CourseTicketSpec.inset, CourseTicketSpec.inset, CourseTicketSpec.inset, 0),
          child: SizedBox(
            height: spec.imageHeight,
            child: _TicketImage(course: course, compact: spec.compact, favorite: favorite),
          ),
        ),
        const SizedBox(height: CourseTicketSpec.gapAfterImage),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: spec.categoryHeight,
                child: _CategoryLevelLine(course: course),
              ),
              const SizedBox(height: CourseTicketSpec.gapAfterCategory),
              SizedBox(
                height: spec.titleHeight,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: BidiText(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      fontSize: spec.titleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CourseTicketSpec.gapAfterTitle),
              SizedBox(
                height: spec.instituteHeight,
                child: _InstituteLine(course: course),
              ),
              const SizedBox(height: CourseTicketSpec.gapAfterInstitute),
              SizedBox(
                height: spec.ratingHeight,
                child: _RatingLine(course: course),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: CourseTicketSpec.dividerHeight,
          child: _DashedDivider(inset: CourseTicketSpec.notchRadius + 6),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: SizedBox(
            height: spec.footerHeight,
            child: spec.compact ? _CompactFooter(course: course) : _WideFooter(course: course),
          ),
        ),
        const SizedBox(height: CourseTicketSpec.bottomPadding),
      ],
    );
  }
}

/// مستطيل بزوايا مدوّرة تُقصّ منه دائرتان على الحافتين عند الخط المتقطع (شكل التذكرة).
/// الظل في [ShapeDecoration] يتبع هذا المسار فتظهر القصّتان فعلاً لا كدوائر ملوّنة فوق البطاقة.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.inset});

  /// المسافة من حافتي البطاقة (بعد القصّتين).
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: const CustomPaint(
        painter: _DashPainter(color: AppColors.borderStrong),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => oldDelegate.color != color;
}

/// الصورة داخل البطاقة بزوايا مدوّرة، مع شارة داكنة (الأكثر طلباً / مقاعد محدودة / جديدة…) في زاوية
/// النهاية وزر المفضلة في زاوية البداية.
class _TicketImage extends StatelessWidget {
  const _TicketImage({required this.course, required this.compact, this.favorite});

  final CourseModel course;
  final bool compact;
  final Widget? favorite;

  /// مساحة اللمس (48) تبدأ من زاوية الصورة والدائرة في وسطها: تبعد عن الحافة كما تبعد الشارة.
  static const _favoriteInset = 0.0;

  @override
  Widget build(BuildContext context) {
    final badge = _coursePromoBadge(course);
    return Stack(
      fit: StackFit.expand,
      children: [
        _CourseCardImage(
          course: course,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          fallbackSize: compact ? 26 : 30,
        ),
        if (badge != null)
          PositionedDirectional(
            top: 8,
            end: 8,
            // لا تمتد الشارة الطويلة تحت زر المفضلة.
            start: favorite != null ? _favoriteInset + CourseFavoriteButton.tapTarget : 40,
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      color: Colors.white,
                      fontSize: compact ? AppTextSize.xs : AppTextSize.xs,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (favorite != null) PositionedDirectional(top: _favoriteInset, start: _favoriteInset, child: favorite!),
      ],
    );
  }
}

/// «البرمجة • مبتدئ»: التصنيف بلون الهوية والمستوى بالأخضر. لا نعرض مستوى غير معروف.
class _CategoryLevelLine extends StatelessWidget {
  const _CategoryLevelLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final category = course.categoryName?.trim() ?? '';
    final level = (course.levelCode ?? '').trim().isEmpty ? '' : course.level.trim();
    if (category.isEmpty && level.isEmpty) return const SizedBox.shrink();
    final style = AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, height: 1.3);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        TextSpan(
          style: style,
          children: [
            if (category.isNotEmpty)
              TextSpan(
                text: category,
                style: const TextStyle(color: AppColors.primaryInk),
              ),
            if (category.isNotEmpty && level.isNotEmpty)
              const TextSpan(
                text: ' • ',
                style: TextStyle(color: AppColors.textHint),
              ),
            if (level.isNotEmpty)
              TextSpan(
                text: level,
                style: const TextStyle(color: AppColors.successText),
              ),
          ],
        ),
      ),
    );
  }
}

class _InstituteLine extends StatelessWidget {
  const _InstituteLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final city = course.instituteCity?.trim() ?? '';
    final parts = [course.institute.trim(), city].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.apartment_rounded, size: 13, color: AppColors.textHint),
        const SizedBox(width: 5),
        Expanded(
          child: BidiText(
            parts.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// نجوم صفراء + القيمة + عدد التقييمات بين قوسين (إن أرسله الخادم). دورة بلا تقييمات فعلية:
/// «لا تقييمات بعد» بدل خمس نجوم رمادية توحي بتقييم 0.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    if (!course.hasRating) {
      return Row(
        children: [
          const Icon(Icons.star_outline_rounded, size: 15, color: AppColors.textHint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'no_ratings_yet'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(
                fontSize: AppTextSize.xs,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                height: 1.2,
              ),
            ),
          ),
        ],
      );
    }
    final rating = course.rating;
    final filled = rating.round().clamp(0, 5);
    final count = course.reviewsCount;
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(Icons.star_rounded, size: 15, color: i < filled ? AppColors.ratingStar : AppColors.borderNeutral),
        if (rating > 0) ...[
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            textDirection: TextDirection.ltr,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
              height: 1.2,
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '($count)',
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(fontSize: AppTextSize.xs, color: AppColors.textHint, height: 1.2),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// البطاقة العريضة: المدة ونوع الحضور في جهة البداية، والسعر في جهة النهاية.
class _WideFooter extends StatelessWidget {
  const _WideFooter({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final meta = _metaItems(course);
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < meta.length; i++) ...[if (i > 0) const SizedBox(height: 4), _MetaItem(item: meta[i])],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: _PriceBlock(course: course, alignEnd: true, amountSize: AppTextSize.xl),
          ),
        ),
      ],
    );
  }
}

/// البطاقة الضيقة (عمودان): السعر أولاً ثم المدة ونوع الحضور في سطر واحد.
class _CompactFooter extends StatelessWidget {
  const _CompactFooter({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final meta = _metaItems(course);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScaleDownStart(
          child: _PriceBlock(course: course, alignEnd: false, amountSize: AppTextSize.lg),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ScaleDownStart(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < meta.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _MetaItem(item: meta[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

List<({IconData icon, String text})> _metaItems(CourseModel course) {
  final duration = course.duration;
  final studyType = course.studyType;
  return [
    if (duration.isNotEmpty && duration != '—') (icon: Icons.schedule_rounded, text: duration),
    if (studyType != null && studyType.isNotEmpty) (icon: courseStudyTypeIcon(studyType), text: studyType),
  ];
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.item});

  final ({IconData icon, String text}) item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            item.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// السعر القديم مشطوباً + وسم النسبة الوردي فوق السعر الحالي البارز.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.course, required this.alignEnd, required this.amountSize});

  final CourseModel course;
  final bool alignEnd;
  final double amountSize;

  @override
  Widget build(BuildContext context) {
    final price = CoursePriceText(price: course.price, amountSize: amountSize, currencySize: AppTextSize.xs);
    final original = course.originalPriceLabel;
    final percent = course.discountPercent;
    if (original == null) return price;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StrikethroughPrice(label: original),
            if (percent != null) ...[const SizedBox(width: 6), _DiscountPill(percent: percent)],
          ],
        ),
        const SizedBox(height: 3),
        price,
      ],
    );
  }
}

class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.accentPink, borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        // «-8%» يبقى بهذا الترتيب في العربية أيضاً.
        child: Text(
          '-$percent%',
          textDirection: TextDirection.ltr,
          style: AppFonts.tajawal(
            fontSize: AppTextSize.xs,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// سعر قديم بخط يتوسطه — Stack يدوي لأن lineThrough لا يظهر دائماً مع Tajawal على الويب.
class _StrikethroughPrice extends StatelessWidget {
  const _StrikethroughPrice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final amount = label.trim().split(RegExp(r'\s+')).first;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Text(
          amount,
          maxLines: 1,
          style: AppFonts.tajawal(
            fontSize: AppTextSize.xs,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
            height: 1.3,
          ),
        ),
        Positioned.fill(
          child: Align(child: Container(height: 1.3, color: AppColors.textHint)),
        ),
      ],
    );
  }
}

class _CourseCardImage extends StatelessWidget {
  const _CourseCardImage({
    required this.course,
    required this.borderRadius,
    required this.fallbackSize,
    this.fallbackIconAlignment = const Alignment(0, 0.3),
  });

  final CourseModel course;
  final BorderRadius borderRadius;
  final double fallbackSize;

  /// موضع أيقونة البديل (بلا صورة) — أسفل المركز افتراضياً كي لا تغطيها الشارة.
  final Alignment fallbackIconAlignment;

  @override
  Widget build(BuildContext context) {
    final url = course.resolvedImageUrl;
    if (url != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth.isFinite ? constraints.maxWidth : null;
            final h = constraints.maxHeight.isFinite ? constraints.maxHeight : null;
            return AppNetworkImage(
              url: url,
              width: w,
              height: h,
              fit: BoxFit.cover,
              ignorePointer: true,
              // الصورة تتلاشى فوق تدرّج التصنيف نفسه الذي يُعرض عند غيابها (لا فراغ ولا كتلة رمادية).
              placeholder: _gradientOnly(),
              errorWidget: _fallback(),
            );
          },
        ),
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: _fallback());
  }

  /// تدرّج التصنيف + النقش بلا أيقونة: خلفية الانتظار قبل وصول الصورة.
  Widget _gradientOnly() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _categoryGradient(course.categoryName)),
      child: const BrandBannerPattern(),
    );
  }

  /// بلا صورة: تدرّج التصنيف + نقش خفيف ودائرتان شفافتان، والأيقونة داخل مربع زجاجي.
  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _categoryGradient(course.categoryName)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BrandBannerPattern(),
          PositionedDirectional(
            top: -fallbackSize * 0.9,
            end: -fallbackSize * 0.7,
            child: _SoftCircle(size: fallbackSize * 2.6, alpha: 0.12),
          ),
          PositionedDirectional(
            bottom: -fallbackSize * 0.8,
            start: -fallbackSize * 0.5,
            child: _SoftCircle(size: fallbackSize * 2, alpha: 0.09),
          ),
          Align(
            alignment: fallbackIconAlignment,
            child: Container(
              width: fallbackSize * 1.7,
              height: fallbackSize * 1.7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(
                courseCategoryIcon(course.categoryName, rounded: true),
                color: Colors.white,
                size: fallbackSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _categoryGradient(String? category) {
    final name = (category ?? '').toLowerCase();
    if (name.contains('تصم') || name.contains('design')) {
      return const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]);
    }
    if (name.contains('أعمال') || name.contains('business')) {
      return const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]);
    }
    return AppGradients.cardPlaceholder;
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// يعرض المحتوى بحجمه الطبيعي، ويصغّره فقط إن لم يتسع (بدل قصّه) — محاذاة لبداية السطر.
class _ScaleDownStart extends StatelessWidget {
  const _ScaleDownStart({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);
  }
}
