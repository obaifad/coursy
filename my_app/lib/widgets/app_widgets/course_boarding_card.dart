part of '../app_widgets.dart';

/// بطاقة الدورة الأفقية لصفحة كل الدورات — «تذكرة الصعود»: الجزء الأبيض فيه التصنيف والمستوى وشارة
/// الشهادة، العنوان، المعهد والمدينة، ثم موعد البدء والمدة بالأسابيع. الجزء الملوّن في جهة النهاية: صورة
/// الدورة بلون تصنيفها، السعر، والمقاعد المتبقية — بلا باركود. قصّتان دائريتان على خط الفصل
/// بين الجزأين (أعلى وأسفل)، والظل يتبع شكلهما.
class CourseBoardingCard extends StatelessWidget {
  const CourseBoardingCard({super.key, required this.course, this.onTap});

  final CourseModel course;
  final VoidCallback? onTap;

  static const double minHeight = 150;
  static const double stubWidth = 94;
  static const double notchRadius = 9;

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0F111827), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x246C63FF), blurRadius: 16, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = courseCategoryPalette(course.categoryName);
    const shape = _BoardingShape(radius: AppRadius.md, stubWidth: stubWidth, notchRadius: notchRadius);
    return DecoratedBox(
      decoration: const ShapeDecoration(color: AppColors.card, shape: shape, shadows: shadow),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.of(context)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            // الجزء الأبيض وحده يحدد ارتفاع البطاقة (نصوص فقط، فقياسه المسبق آمن)، والملوّن مثبّت فوق جهة
            // النهاية بطولها كله. لا يدخل الملوّن في IntrinsicHeight: صورته فيها LayoutBuilder، وFlutter يرفض
            // قياسه مسبقاً (كان يرمي خطأ في كل إطار على الهاتف).
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: minHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: stubWidth),
                      child: _BoardingMain(course: course, palette: palette),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: stubWidth,
                  child: _BoardingStub(course: course, palette: palette),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// مستطيل بزوايا مدوّرة تُقصّ منه دائرتان على خط الفصل بين الجزأين: في أعلى البطاقة وأسفلها.
/// خط الفصل على بُعد [stubWidth] من حافة النهاية (يسار بالعربية، يمين بالإنجليزية).
class _BoardingShape extends ShapeBorder {
  const _BoardingShape({required this.radius, required this.stubWidth, required this.notchRadius});

  final double radius;
  final double stubWidth;
  final double notchRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final card = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final x = textDirection == TextDirection.rtl ? rect.left + stubWidth : rect.right - stubWidth;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, rect.top), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(x, rect.bottom), radius: notchRadius));
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) =>
      _BoardingShape(radius: radius * t, stubWidth: stubWidth * t, notchRadius: notchRadius * t);

  @override
  bool operator ==(Object other) =>
      other is _BoardingShape &&
      other.radius == radius &&
      other.stubWidth == stubWidth &&
      other.notchRadius == notchRadius;

  @override
  int get hashCode => Object.hash(radius, stubWidth, notchRadius);
}

class _BoardingMain extends StatelessWidget {
  const _BoardingMain({required this.course, required this.palette});

  final CourseModel course;
  final CourseCategoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final category = course.categoryName?.trim() ?? '';
    final level = (course.levelCode ?? '').trim().isEmpty ? '' : course.level.trim();
    final eyebrow = [category, level].where((p) => p.isNotEmpty).join(' · ');
    final place = [course.institute.trim(), course.instituteCity?.trim() ?? ''].where((p) => p.isNotEmpty).join(' · ');
    final start = course.startDayMonth;
    final weeks = course.durationWeeks;
    final duration = weeks != null ? pluralTr('card_weeks', weeks) : (course.duration == '—' ? null : course.duration);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (eyebrow.isNotEmpty) ...[
                Icon(courseCategoryIcon(course.categoryName, rounded: true), size: 13, color: palette.ink),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: palette.ink,
                    ),
                  ),
                ),
              ],
              if (course.certificateAvailable) ...[const Spacer(), const SizedBox(width: 8), const _CertificateBadge()],
            ],
          ),
          const SizedBox(height: 4),
          BidiText(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.lg,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
          ),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 2),
            BidiText(
              place,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(
                fontSize: AppTextSize.xs,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          if (start != null || duration != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (start != null)
                  Flexible(
                    child: _BoardingPoint(label: 'card_starts'.tr, value: start),
                  ),
                const Spacer(),
                if (duration != null)
                  Flexible(
                    child: _BoardingPoint(label: 'card_duration'.tr, value: duration, alignEnd: true),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BoardingPoint extends StatelessWidget {
  const _BoardingPoint({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          style: AppFonts.tajawal(
            fontSize: AppTextSize.xs,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.tajawal(
            fontSize: AppTextSize.md,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CertificateBadge extends StatelessWidget {
  const _CertificateBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: AppCorners.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, size: 12, color: Color(0xFF166534)),
            const SizedBox(width: 3),
            Text(
              'card_certificate'.tr,
              maxLines: 1,
              style: AppFonts.tajawal(
                fontSize: AppTextSize.xs,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: const Color(0xFF166534),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الجزء الملوّن: صورة الدورة تحت تلوين بلون التصنيف، السعر، والمقاعد المتبقية (بلا باركود).
class _BoardingStub extends StatelessWidget {
  const _BoardingStub({required this.course, required this.palette});

  final CourseModel course;
  final CourseCategoryPalette palette;

  @override
  Widget build(BuildContext context) {
    final parts = course.price.trim().split(RegExp(r'\s+'));
    final amount = parts.first;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final old = course.originalPriceLabel?.trim().split(RegExp(r'\s+')).first;
    final max = course.maxStudents;
    final left = max != null && max > 0 ? max - course.enrolledCountForCapacity : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        _CourseCardImage(course: course, borderRadius: BorderRadius.zero, fallbackSize: 26),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.3, -1),
              end: const Alignment(0.3, 1),
              colors: [palette.c1.withValues(alpha: 0.8), palette.c2.withValues(alpha: 0.8)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      style: AppFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: AppTextSize.xl,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (currency.isNotEmpty)
                    Text(
                      currency,
                      maxLines: 1,
                      style: AppFonts.tajawal(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: AppTextSize.xs,
                        height: 1.4,
                      ),
                    ),
                  if (old != null && old.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        old,
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: AppTextSize.xs,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (left != null && left > 0) _SeatsChip(left: left),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeatsChip extends StatelessWidget {
  const _SeatsChip({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: AppCorners.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                pluralTr('card_seats', left),
                maxLines: 1,
                style: AppFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.xs,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
