part of '../app_widgets.dart';

/// بطاقة الدورة بتصميم التذكرة: صورة داخلية بشارة، التصنيف والمستوى، العنوان، المعهد والمدينة،
/// التقييم، ثم خط متقطع بقصّتين جانبيتين، وتحته السعر والمدة ونوع الحضور.
/// تُستخدم في كل القوائم (الرئيسية، الشبكات، المفضلة، صفحة المدرّس) والضغط في أي مكان يفتح الدورة.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final CourseModel course;
  final VoidCallback? onTap;

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
        final shape = _TicketShape(
          radius: _kCourseCardRadius,
          notchFromBottom: spec.notchFromBottom,
          notchRadius: CourseTicketSpec.notchRadius,
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: AppColors.card, shape: shape, shadows: _courseCardShadow),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.of(context)),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  splashColor: AppColors.primary.withValues(alpha: 0.08),
                  highlightColor: AppColors.primary.withValues(alpha: 0.04),
                  child: _TicketContent(course: course, spec: spec),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TicketContent extends StatelessWidget {
  const _TicketContent({required this.course, required this.spec});

  final CourseModel course;
  final CourseTicketSpec spec;

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
            child: _TicketImage(course: course, compact: spec.compact),
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
class _TicketShape extends ShapeBorder {
  const _TicketShape({required this.radius, required this.notchFromBottom, required this.notchRadius});

  final double radius;
  final double notchFromBottom;
  final double notchRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final card = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final y = rect.bottom - notchFromBottom;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius));
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) =>
      _TicketShape(radius: radius * t, notchFromBottom: notchFromBottom * t, notchRadius: notchRadius * t);

  @override
  bool operator ==(Object other) =>
      other is _TicketShape &&
      other.radius == radius &&
      other.notchFromBottom == notchFromBottom &&
      other.notchRadius == notchRadius;

  @override
  int get hashCode => Object.hash(radius, notchFromBottom, notchRadius);
}

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

/// الصورة داخل البطاقة بزوايا مدوّرة، مع شارة داكنة (الأكثر طلباً / مقاعد محدودة / جديدة…) في الزاوية.
class _TicketImage extends StatelessWidget {
  const _TicketImage({required this.course, required this.compact});

  final CourseModel course;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = _coursePromoBadge(course);
    return Stack(
      fit: StackFit.expand,
      children: [
        _CourseCardImage(
          course: course,
          borderRadius: BorderRadius.circular(_kCourseCardRadius - 4),
          fallbackSize: compact ? 26 : 30,
        ),
        if (badge != null)
          PositionedDirectional(
            top: 8,
            end: 8,
            start: 40,
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      color: Colors.white,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    final style = AppFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3);
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
                style: const TextStyle(color: AppColors.primary),
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
              fontSize: 10.5,
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

/// نجوم صفراء + القيمة + عدد التقييمات بين قوسين (إن أرسله الخادم).
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
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
            style: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textBody, height: 1.2),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '($count)',
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(fontSize: 11, color: AppColors.textHint, height: 1.2),
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
            child: _PriceBlock(course: course, alignEnd: true, amountSize: 18),
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
        _ScaleDownStart(child: _PriceBlock(course: course, alignEnd: false, amountSize: 16)),
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
            style: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textBody, height: 1.2),
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
    final price = CoursePriceText(price: course.price, amountSize: amountSize, currencySize: 11);
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
      decoration: BoxDecoration(color: AppColors.accentPink, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        // «-8%» يبقى بهذا الترتيب في العربية أيضاً.
        child: Text(
          '-$percent%',
          textDirection: TextDirection.ltr,
          style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
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
          style: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHint, height: 1.3),
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
              errorWidget: _fallback(),
            );
          },
        ),
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: _fallback());
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
                borderRadius: BorderRadius.circular(fallbackSize * 0.45),
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
