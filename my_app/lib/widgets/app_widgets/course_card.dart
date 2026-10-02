part of '../app_widgets.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap, this.compact = false, this.showActionButton = true});

  final CourseModel course;
  final VoidCallback? onTap;
  final bool compact;
  final bool showActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = CourseCardMetrics.layoutFor(
          constraints,
          showActionButton: showActionButton,
          textScale: CourseCardMetrics.textScaleOf(context),
        );
        final isFeaturedRail = !showActionButton && layout.compact;

        if (isFeaturedRail) {
          return _buildFeaturedRailCard(context, constraints, layout);
        }

        final cardHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : layout.cardHeight;
        final imageHeight = layout.imageHeight;
        final titleSize = layout.titleSize;
        final priceSize = layout.compact ? 15.0 : 18.0;
        final summary = _courseSummaryLine(course);

        return Container(
          height: cardHeight,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kCourseCardRadius),
            boxShadow: _courseCardShadow,
          ),
          child: Material(
            color: AppColors.card,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(_kCourseCardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_kCourseCardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: _CourseCardHeroImage(course: course, height: imageHeight, compact: layout.compact),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(layout.padding, layout.padding - 2, layout.padding, layout.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: layout.titleHeight,
                            child: Align(
                              alignment: AlignmentDirectional.topStart,
                              child: BidiText(
                                course.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.tajawal(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          // الصف محجوز دائماً (حتى لو فارغ) كي تتساوى مواضع الشارات والأسعار بين البطاقات.
                          SizedBox(height: layout.sectionGap - 1),
                          SizedBox(
                            height: layout.subtitleHeight,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: BidiText(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.tajawal(
                                  fontSize: layout.compact ? 10.5 : 11.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: layout.sectionGap),
                          SizedBox(
                            height: layout.chipsHeight,
                            child: _CourseLevelBadgeRow(course: course, compact: layout.compact),
                          ),
                          SizedBox(height: layout.sectionGap),
                          SizedBox(
                            height: layout.statsHeight,
                            child: _CourseCardCompactStats(course: course, compact: layout.compact),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: layout.priceHeight,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _CourseCardPriceBlock(
                                course: course,
                                priceSize: priceSize,
                                compact: layout.compact,
                              ),
                            ),
                          ),
                          if (showActionButton) ...[
                            SizedBox(height: layout.sectionGap),
                            SizedBox(
                              width: double.infinity,
                              height: layout.buttonHeight,
                              child: FilledButton(
                                onPressed: onTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(layout.compact ? 10 : 12),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: layout.compact ? 8 : 12),
                                  textStyle: AppFonts.tajawal(
                                    fontWeight: FontWeight.w700,
                                    fontSize: layout.compact ? 11 : 12.5,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(_courseActionLabel(course), maxLines: 1),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// بطاقة «دورات مميزة» — تسلسل بصري Udemy/Coursera مع hover على الويب.
  Widget _buildFeaturedRailCard(BuildContext context, BoxConstraints constraints, CourseCardLayout layout) {
    return _FeaturedCourseCard(
      course: course,
      onTap: onTap,
      width: constraints.maxWidth,
      imageHeight: layout.imageHeight,
    );
  }
}

/// نظام مسافات موحّد لبطاقة الدورة المميزة.
abstract final class _FeaturedCardSpace {
  _FeaturedCardSpace._();

  static const double sm = 8;
  static const double coverGap = 10;
  static const double bodyPad = 14;
  static const double bottomPad = 18;
  static const double radius = 18;
  static const double badgeRadius = 8;
}

/// بطاقة دورة مميزة — StatefulWidget لدعم hover على الويب/سطح المكتب.
class _FeaturedCourseCard extends StatefulWidget {
  const _FeaturedCourseCard({
    required this.course,
    required this.onTap,
    required this.width,
    required this.imageHeight,
  });

  final CourseModel course;
  final VoidCallback? onTap;
  final double width;
  final double imageHeight;

  @override
  State<_FeaturedCourseCard> createState() => _FeaturedCourseCardState();
}

class _FeaturedCourseCardState extends State<_FeaturedCourseCard> {
  bool _hovered = false;

  String get _subtitle => _courseSummaryLine(widget.course);

  @override
  Widget build(BuildContext context) {
    final textScale = CourseCardMetrics.textScaleOf(context);
    final shadows = _hovered
        ? const [
            BoxShadow(color: AppColors.shadowPrimaryStrong, blurRadius: 22, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ]
        : _courseCardShadow;

    final card = AnimatedContainer(
      duration: AppMotion.fast,
      curve: Curves.easeOutCubic,
      width: widget.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(_FeaturedCardSpace.radius), boxShadow: shadows),
      child: Material(
        color: AppColors.card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(_FeaturedCardSpace.radius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_FeaturedCardSpace.radius),
          hoverColor: AppColors.primary.withValues(alpha: 0.04),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: widget.imageHeight,
                child: _FeaturedCourseCover(course: widget.course, imageHeight: widget.imageHeight),
              ),
              const SizedBox(height: _FeaturedCardSpace.coverGap),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  _FeaturedCardSpace.bodyPad,
                  0,
                  _FeaturedCardSpace.bodyPad,
                  _FeaturedCardSpace.bottomPad,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) العنوان — أوضح وأثقل بصرياً
                    SizedBox(
                      height: CourseCardMetrics.featuredTitleHeight * textScale,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: BidiText(
                          widget.course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      BidiText(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: _FeaturedCardSpace.sm),
                    _CourseLevelBadgeRow(course: widget.course, compact: true),
                    const SizedBox(height: _FeaturedCardSpace.sm),
                    SizedBox(
                      height: 18 * textScale,
                      child: _CourseCardCompactStats(course: widget.course, compact: true),
                    ),
                    const SizedBox(height: _FeaturedCardSpace.sm),
                    _FeaturedCoursePriceBlock(course: widget.course),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!kIsWeb) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );
  }
}

/// غلاف الدورة — تدرج، أيقونة، شريط تقني، شارة مدمجة.
class _FeaturedCourseCover extends StatelessWidget {
  const _FeaturedCourseCover({required this.course, required this.imageHeight});

  final CourseModel course;
  final double imageHeight;

  String? get _badgeLabel => _coursePromoBadge(course);

  @override
  Widget build(BuildContext context) {
    final badge = _badgeLabel;
    final category = course.categoryName?.trim();
    // لا نعرض "—" عندما لا يُعرف المستوى.
    final level = (course.levelCode ?? '').trim().isEmpty ? '' : course.level.trim();
    // عربي فقط — بدون UPPERCASE إنجليزي يشتت الانتباه
    final stripParts = <String>[if (category != null && category.isNotEmpty) category, if (level.isNotEmpty) level];
    final stripLabel = stripParts.join(' · ');
    final hasImage = course.resolvedImageUrl != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_FeaturedCardSpace.radius)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CourseCardImage(course: course, borderRadius: BorderRadius.zero, fallbackSize: 52),
          // تدرج أقوى عند وجود صورة لتخفيف النص الإنجليزي الخلفي
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: hasImage ? 0.18 : 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: hasImage ? 0.62 : 0.45),
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
          // أيقونة كبيرة عند غياب الصورة
          if (course.resolvedImageUrl == null)
            Center(
              child: Icon(_categoryIcon(course.categoryName), size: 52, color: Colors.white.withValues(alpha: 0.88)),
            ),
          // شريط تقني سفلي
          if (stripLabel.isNotEmpty)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 12, 8),
                color: Colors.black.withValues(alpha: 0.55),
                child: BidiText(
                  stripLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, height: 1.2, color: Colors.white),
                ),
              ),
            ),
          // شارة مدمجة مع هوية التطبيق
          if (badge != null)
            PositionedDirectional(
              top: 10,
              start: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(_FeaturedCardSpace.badgeRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(7, 3, 8, 3),
                  child: Text(
                    badge,
                    style: AppFonts.tajawal(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String? category) => courseCategoryIcon(category);
}

/// السعر — العنصر الأبرز في أسفل البطاقة (رقم كبير + عملة أصغر).
class _FeaturedCoursePriceBlock extends StatelessWidget {
  const _FeaturedCoursePriceBlock({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final price = CoursePriceText(price: course.price, amountSize: 18, currencySize: 11);
    if (!(course.hasDiscount && course.originalPriceLabel != null)) return price;
    // يُصغَّر قليلاً عند ضيق المساحة بدل قصّ الأرقام بـ "…".
    return _ScaleDownStart(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FeaturedStrikethroughPrice(label: course.originalPriceLabel!),
          const SizedBox(width: 10),
          price,
        ],
      ),
    );
  }
}

/// سعر قديم بخط يتوسطه — Stack يدوي لأن lineThrough لا يظهر دائماً مع Tajawal على الويب.
class _FeaturedStrikethroughPrice extends StatelessWidget {
  const _FeaturedStrikethroughPrice({required this.label, this.fontSize = 12, this.currencySize = 10});

  final String label;
  final double fontSize;
  final double currencySize;

  @override
  Widget build(BuildContext context) {
    final parts = label.trim().split(RegExp(r'\s+'));
    final amount = parts.isNotEmpty ? parts.first : label;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final text = Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: AppFonts.tajawal(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          if (currency.isNotEmpty)
            TextSpan(
              text: ' $currency',
              style: AppFonts.tajawal(
                fontSize: currencySize,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        text,
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(widthFactor: 1, child: Container(height: 1.3, color: AppColors.textHint)),
          ),
        ),
      ],
    );
  }
}

class _CourseLevelBadgeRow extends StatelessWidget {
  const _CourseLevelBadgeRow({required this.course, required this.compact});

  final CourseModel course;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // المستوى غير معروف → لا نعرض شارة "—" فارغة المعنى.
    if ((course.levelCode ?? '').trim().isEmpty) return const SizedBox.shrink();
    final level = course.level.trim();

    final colors = _levelBadgeColors(level);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          level,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.tajawal(
            fontSize: compact ? 10 : 10.5,
            fontWeight: FontWeight.w700,
            color: colors.fg,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _CourseCardCompactStats extends StatelessWidget {
  const _CourseCardCompactStats({required this.course, required this.compact});

  final CourseModel course;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 12.0 : 13.0;
    final fontSize = compact ? 10.0 : 10.5;
    final items = <Widget>[];

    // كل عنصر مع فاصله وحدة واحدة — ما لا يتّسع في السطر ينتقل لسطر مخفي بالكامل (لا يُقصّ نصفه).
    void addItem(Widget child) {
      if (items.isEmpty) {
        items.add(child);
        return;
      }
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                '·',
                style: TextStyle(color: AppColors.borderStrong, fontSize: fontSize + 1),
              ),
            ),
            child,
          ],
        ),
      );
    }

    if (course.rating > 0) {
      addItem(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: iconSize, color: AppColors.ratingStar),
            const SizedBox(width: 2),
            Text(
              course.rating.toStringAsFixed(1),
              style: AppFonts.tajawal(fontSize: fontSize, fontWeight: FontWeight.w700, color: AppColors.textBody),
            ),
          ],
        ),
      );
    }

    if (course.durationHours != null && course.durationHours! > 0) {
      addItem(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: iconSize, color: AppColors.primary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                pluralTr('hours_unit', course.durationHours!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (course.duration.isNotEmpty && course.duration != '—') {
      addItem(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: iconSize, color: AppColors.primary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                course.duration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (course.studyType != null && course.studyType!.isNotEmpty) {
      addItem(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(courseStudyTypeIcon(course.studyType!), size: iconSize, color: AppColors.primary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                course.studyType!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final students = course.enrolledCountForCapacity;
    if (students > 0) {
      addItem(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: iconSize, color: AppColors.primary),
            const SizedBox(width: 2),
            Text(
              compact ? '$students' : pluralTr('students_count', students),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(fontSize: fontSize, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // سطر واحد: العناصر التي لا تتسع تلتف لسطر ثانٍ يُقصّ بالكامل (بدل تمرير أفقي خفي داخل البطاقة).
    return ClipRect(
      child: OverflowBox(
        alignment: AlignmentDirectional.topStart,
        maxHeight: double.infinity,
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: items),
      ),
    );
  }
}

class _CourseCardPriceBlock extends StatelessWidget {
  const _CourseCardPriceBlock({required this.course, required this.priceSize, required this.compact});

  final CourseModel course;
  final double priceSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final price = CoursePriceText(price: course.price, amountSize: priceSize, currencySize: compact ? 10 : 11);
    if (!(course.hasDiscount && course.originalPriceLabel != null)) return _ScaleDownStart(child: price);
    final original = _CardStrikethroughPrice(label: course.originalPriceLabel!, fontSize: compact ? 10 : 11);
    // البطاقة الضيقة (عمودان على الهاتف): السعر القديم فوق الحالي — كانا يُقصّان معاً بـ "…".
    return _ScaleDownStart(
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [original, price],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [original, const SizedBox(width: 8), price],
            ),
    );
  }
}

class _CardStrikethroughPrice extends StatelessWidget {
  const _CardStrikethroughPrice({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return _FeaturedStrikethroughPrice(label: label, fontSize: fontSize, currencySize: fontSize - 1);
  }
}

class _CourseCardHeroImage extends StatelessWidget {
  const _CourseCardHeroImage({required this.course, required this.height, required this.compact});

  final CourseModel course;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = _badgeLabel(course);
    final edgeInset = compact ? 10.0 : 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBadgeWidth = (constraints.maxWidth - edgeInset * 2).clamp(60.0, double.infinity);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            _CourseCardImage(
              course: course,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_kCourseCardRadius)),
              fallbackSize: compact ? 34 : 40,
            ),
            if (badge != null)
              PositionedDirectional(
                top: edgeInset,
                start: edgeInset,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8, vertical: compact ? 3 : 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        color: Colors.white,
                        fontSize: compact ? 8.5 : 9,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _badgeLabel(CourseModel course) => _coursePromoBadge(course);
}

class _CourseCardImage extends StatelessWidget {
  const _CourseCardImage({required this.course, required this.borderRadius, required this.fallbackSize});

  final CourseModel course;
  final BorderRadius borderRadius;
  final double fallbackSize;

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

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(gradient: _categoryGradient(course.categoryName)),
      child: Center(
        child: Icon(
          _categoryIcon(course.categoryName),
          color: Colors.white.withValues(alpha: 0.92),
          size: fallbackSize,
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) => courseCategoryIcon(category, rounded: true);

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

/// يعرض المحتوى بحجمه الطبيعي، ويصغّره فقط إن لم يتسع (بدل قصّه) — محاذاة لبداية السطر.
class _ScaleDownStart extends StatelessWidget {
  const _ScaleDownStart({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);
  }
}
