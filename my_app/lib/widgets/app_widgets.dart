import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'design_system.dart' show AppGradients, CourseCardLayout, CourseCardMetrics;

IconData courseStudyTypeIcon(String studyType) {
  final probe = studyType.toLowerCase();
  if (probe.contains('أون') || probe.contains('online') || probe.contains('عن')) {
    return Icons.computer_rounded;
  }
  if (probe.contains('مختلط') || probe.contains('hybrid') || probe.contains('mixed')) {
    return Icons.devices_rounded;
  }
  if (probe.contains('حضور') || probe.contains('offline')) {
    return Icons.location_city_rounded;
  }
  return Icons.cast_for_education_outlined;
}

/// سعر الدورة: مبلغ عريض + عملة أصغر
class CoursePriceText extends StatelessWidget {
  const CoursePriceText({
    super.key,
    required this.price,
    this.amountSize = 13,
    this.currencySize = 10,
  });

  final String price;
  final double amountSize;
  final double currencySize;

  @override
  Widget build(BuildContext context) {
    final parts = price.trim().split(RegExp(r'\s+'));
    final amount = parts.isNotEmpty ? parts.first : price;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: amountSize,
              height: 1.1,
            ),
          ),
          if (currency.isNotEmpty)
            TextSpan(
              text: ' $currency',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: currencySize,
              ),
            ),
        ],
      ),
    );
  }
}

/// صورة شبكة تعمل على الويب بدون مشاكل CORS (تفضّل عنصر HTML img).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.ignorePointer = false,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  /// true داخل كروت قابلة للنقر حتى لا تحجب الصورة ضغطة الـ InkWell.
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) {
    Widget imageForSize(double? w, double? h) {
      final hasExplicitSize =
          w != null && h != null && w.isFinite && h.isFinite && w > 0 && h > 0;
      return Image.network(
        url,
        width: hasExplicitSize ? w : null,
        height: hasExplicitSize ? h : null,
        fit: fit,
        webHtmlElementStrategy: kIsWeb && hasExplicitSize
            ? WebHtmlElementStrategy.prefer
            : WebHtmlElementStrategy.never,
        errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
      );
    }

    Widget content;
    if (width != null && height != null) {
      content = SizedBox(width: width, height: height, child: imageForSize(width, height));
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final w = width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
          final h = height ?? (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
          final hasExplicitSize =
              w != null && h != null && w.isFinite && h.isFinite && w > 0 && h > 0;
          if (hasExplicitSize) {
            return SizedBox(width: w, height: h, child: imageForSize(w, h));
          }
          return imageForSize(null, null);
        },
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }
    if (ignorePointer) {
      content = IgnorePointer(child: content);
    }
    return content;
  }
}

/// أيقونة مادة/تخصص مدرّس.
class InstructorSubjectIcon extends StatelessWidget {
  const InstructorSubjectIcon({
    super.key,
    required this.subject,
    this.size = 24,
    this.borderRadius,
    this.iconColor,
    this.backgroundColor,
  });

  final InstructorSubjectModel subject;
  final double size;
  final BorderRadius? borderRadius;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Icon(
        subject.iconData,
        size: size * 0.52,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

/// أيقونة تصنيف من slug الـ API (code, palette, languages...).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.borderRadius,
    this.iconColor,
    this.backgroundColor,
  });

  final CategoryModel category;
  final double size;
  final BorderRadius? borderRadius;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final imageUrl = category.iconImageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: AppNetworkImage(
                url: imageUrl,
                width: size * 0.72,
                height: size * 0.72,
                fit: BoxFit.contain,
              ),
            )
          : Icon(
              category.iconData,
              size: size * 0.52,
              color: iconColor ?? AppColors.primary,
            ),
    );
  }
}

/// عنوان قسم + محتوى (قديم — ي favor AppSectionHeader للعناوين الجديدة)
class AppSection extends StatelessWidget {
  const AppSection({super.key, required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// شارة معلومات صغيرة (نوع الدراسة، الساعات).
class CourseMetaChip extends StatelessWidget {
  const CourseMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: AppColors.textSecondary),
          SizedBox(width: compact ? 5 : 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.compact = false,
    this.showActionButton = true,
  });

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
        );
        final isFeaturedRail = !showActionButton && layout.compact;

        if (isFeaturedRail) {
          return _buildFeaturedRailCard(context, constraints, layout);
        }

        final cardHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : layout.cardHeight;
        final imageHeight = layout.imageHeight;
        final titleSize = layout.titleSize;
        final priceSize = layout.compact ? 13.0 : 15.0;

        return Container(
          height: cardHeight,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.card,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: _CourseCardHeroImage(
                      course: course,
                      height: imageHeight,
                      compact: layout.compact,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.padding,
                        layout.padding,
                        layout.padding,
                        layout.padding + (showActionButton ? 6 : 0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: layout.titleHeight,
                            child: Align(
                              alignment: AlignmentDirectional.topStart,
                              child: Text(
                                course.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.tajawal(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: layout.sectionGap),
                          _CourseCardTags(
                            course: course,
                            compact: layout.compact,
                            height: layout.chipsHeight,
                          ),
                          SizedBox(height: layout.sectionGap),
                          SizedBox(
                            height: layout.statsHeight,
                            child: _CourseCardStatsRow(
                              course: course,
                              compact: layout.compact,
                            ),
                          ),
                          SizedBox(height: layout.sectionGap),
                          SizedBox(
                            height: layout.priceHeight,
                            child: Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: _CourseCardPriceBlock(
                                course: course,
                                priceSize: priceSize,
                                compact: layout.compact,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (showActionButton) ...[
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
                                    borderRadius: BorderRadius.circular(
                                      layout.compact ? 10 : 12,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: layout.compact ? 6 : 12,
                                  ),
                                  textStyle: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.w700,
                                    fontSize: layout.compact ? 11 : 13,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'view_details'.tr,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
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
  Widget _buildFeaturedRailCard(
    BuildContext context,
    BoxConstraints constraints,
    CourseCardLayout layout,
  ) {
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
  static const double md = 12;
  static const double coverGap = 10;
  static const double bodyPad = 14;
  static const double bottomPad = 18;
  static const double radius = 18;
  static const double badgeRadius = 6;
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

  String get _subtitle {
    final desc = widget.course.description?.trim();
    if (desc != null && desc.isNotEmpty) {
      return _FeaturedCourseCardState._compactSubtitle(desc);
    }
    return widget.course.institute;
  }

  /// يختصر الوصف عند حدّ معقول مع قطع عند مسافة/فاصلة لتجنب "...intermediat".
  static String _compactSubtitle(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 58) return normalized;
    final slice = normalized.substring(0, 58);
    final breakAt = slice.lastIndexOf(RegExp(r'[\s،,.;]'));
    final cut = (breakAt > 28 ? slice.substring(0, breakAt) : slice).trim();
    return '$cut…';
  }

  @override
  Widget build(BuildContext context) {
    final shadows = _hovered
        ? const [
            BoxShadow(color: Color(0x446C63FF), blurRadius: 22, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ]
        : const [
            BoxShadow(color: Color(0x266C63FF), blurRadius: 16, offset: Offset(0, 6)),
            BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
          ];

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_FeaturedCardSpace.radius),
        boxShadow: shadows,
      ),
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
                child: _FeaturedCourseCover(
                  course: widget.course,
                  imageHeight: widget.imageHeight,
                ),
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
                      height: 34,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Text(
                          widget.course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _FeaturedCardSpace.sm),
                    // وصف قصير — سطران كحد أقصى مع قطع ذكي
                    Text(
                      _subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: _FeaturedCardSpace.md),
                    // 2) معلومات الدورة — صف واحد بأيقونات
                    _FeaturedCourseMetaRow(course: widget.course),
                    const SizedBox(height: _FeaturedCardSpace.md),
                    // 3) التقييم + الطلاب — قسم مميز
                    _FeaturedCourseStatsBand(course: widget.course),
                    const SizedBox(height: _FeaturedCardSpace.md),
                    // 4) السعر — إبراز أقوى + مسافة سفلية إضافية
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 2),
                      child: _FeaturedCoursePriceBlock(course: widget.course),
                    ),
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
        duration: const Duration(milliseconds: 200),
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

  String? get _badgeLabel {
    if (course.isFeatured) return 'course_badge_bestseller'.tr;
    final raw = course.startDate;
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null && DateTime.now().difference(parsed).inDays.abs() <= 30) {
        return 'course_badge_new'.tr;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeLabel;
    final category = course.categoryName?.trim();
    final level = course.level.trim();
    // عربي فقط — بدون UPPERCASE إنجليزي يشتت الانتباه
    final stripParts = <String>[
      if (category != null && category.isNotEmpty) category,
      if (level.isNotEmpty) level,
    ];
    final stripLabel = stripParts.join(' · ');
    final hasImage = course.resolvedImageUrl != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_FeaturedCardSpace.radius)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CourseCardImage(
            course: course,
            borderRadius: BorderRadius.zero,
            fallbackSize: 52,
          ),
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
              child: Icon(
                _categoryIcon(course.categoryName),
                size: 52,
                color: Colors.white.withValues(alpha: 0.88),
              ),
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
                child: Text(
                  stripLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.white,
                  ),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 9, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (course.isFeatured)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(end: 3),
                          child: Icon(
                            Icons.local_fire_department_outlined,
                            size: 12,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      Text(
                        badge,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String? category) {
    final name = (category ?? '').toLowerCase();
    if (name.contains('لغ') || name.contains('lang')) return Icons.translate_outlined;
    if (name.contains('تصم') || name.contains('design')) return Icons.palette_outlined;
    if (name.contains('أعمال') || name.contains('business')) return Icons.business_center_outlined;
    if (name.contains('برمج') || name.contains('program')) return Icons.code_outlined;
    return Icons.school_outlined;
  }
}

/// صف معلومات الدورة — نوع الدراسة + الساعات.
class _FeaturedCourseMetaRow extends StatelessWidget {
  const _FeaturedCourseMetaRow({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final hasStudy = course.studyType != null && course.studyType!.isNotEmpty;
    final hasHours = course.durationHours != null && course.durationHours! > 0;
    if (!hasStudy && !hasHours) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (hasStudy) ...[
            Icon(_studyTypeIcon(course.studyType!), size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                course.studyType!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ],
          if (hasStudy && hasHours) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: const Color(0xFFD1D5DB)),
            const SizedBox(width: 8),
          ],
          if (hasHours) ...[
            const Icon(Icons.schedule_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
              'hours_unit'.trParams({'n': '${course.durationHours}'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _studyTypeIcon(String studyType) => courseStudyTypeIcon(studyType);
}

/// قسم التقييم وعدد الطلاب — بارز ومنفصل.
class _FeaturedCourseStatsBand extends StatelessWidget {
  const _FeaturedCourseStatsBand({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final students = course.enrolledCountForCapacity;
    final hasRating = course.rating > 0;
    final hasStudents = students > 0;
    if (!hasRating && !hasStudents) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (hasRating)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.star_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 6),
                Text(
                  course.rating.toStringAsFixed(1),
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  ' / 5',
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          if (hasStudents)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'students_count'.trParams({'n': '$students'}),
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// السعر — العنصر الأبرز في أسفل البطاقة (رقم كبير + عملة أصغر).
class _FeaturedCoursePriceBlock extends StatelessWidget {
  const _FeaturedCoursePriceBlock({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    if (course.hasDiscount && course.originalPriceLabel != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: _FeaturedStrikethroughPrice(label: course.originalPriceLabel!),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: CoursePriceText(
              price: course.price,
              amountSize: 17,
              currencySize: 11,
            ),
          ),
        ],
      );
    }

    return CoursePriceText(
      price: course.price,
      amountSize: 17,
      currencySize: 11,
    );
  }
}

/// سعر قديم بخط يتوسطه — Stack يدوي لأن lineThrough لا يظهر دائماً مع Tajawal على الويب.
class _FeaturedStrikethroughPrice extends StatelessWidget {
  const _FeaturedStrikethroughPrice({
    required this.label,
    this.fontSize = 12,
    this.currencySize = 10,
  });

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
            style: GoogleFonts.tajawal(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          if (currency.isNotEmpty)
            TextSpan(
              text: ' $currency',
              style: GoogleFonts.tajawal(
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
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Container(
                height: 1.3,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseCardTags extends StatelessWidget {
  const _CourseCardTags({
    required this.course,
    required this.compact,
    required this.height,
  });

  final CourseModel course;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[];
    if (course.studyType != null && course.studyType!.isNotEmpty) {
      tags.add(CourseMetaChip(
        icon: courseStudyTypeIcon(course.studyType!),
        label: course.studyType!,
        compact: compact,
      ));
    }
    if (course.durationHours != null && course.durationHours! > 0) {
      tags.add(CourseMetaChip(
        icon: Icons.schedule_rounded,
        label: 'hours_unit'.trParams({'n': '${course.durationHours}'}),
        compact: compact,
      ));
    }
    if (tags.isEmpty) {
      return height <= 0 ? const SizedBox.shrink() : SizedBox(height: height);
    }

    if (height <= 0) {
      return tags.length > 1
          ? Row(
              children: [
                for (var i = 0; i < tags.length; i++) ...[
                  if (i > 0) SizedBox(width: compact ? 4 : 6),
                  Expanded(child: tags[i]),
                ],
              ],
            )
          : tags.first;
    }

    return SizedBox(
      height: height,
      child: tags.length > 1
          ? Row(
              children: [
                for (var i = 0; i < tags.length; i++) ...[
                  if (i > 0) SizedBox(width: compact ? 4 : 6),
                  Expanded(child: tags[i]),
                ],
              ],
            )
          : tags.first,
    );
  }
}

class _CourseCardStatsRow extends StatelessWidget {
  const _CourseCardStatsRow({required this.course, required this.compact});

  final CourseModel course;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final students = course.enrolledCountForCapacity;
    final starSize = compact ? 13.0 : 16.0;
    final fontSize = compact ? 10.0 : 12.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (course.rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: starSize, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                course.rating.toStringAsFixed(1),
                style: GoogleFonts.tajawal(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        if (students > 0)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.people_outline_rounded, size: starSize, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    compact
                        ? '$students'
                        : 'students_count'.trParams({'n': '$students'}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.tajawal(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CourseCardPriceBlock extends StatelessWidget {
  const _CourseCardPriceBlock({
    required this.course,
    required this.priceSize,
    required this.compact,
  });

  final CourseModel course;
  final double priceSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (course.hasDiscount && course.originalPriceLabel != null) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardStrikethroughPrice(
              label: course.originalPriceLabel!,
              fontSize: compact ? 10 : 11,
            ),
            SizedBox(height: compact ? 1 : 2),
            CoursePriceText(
              price: course.price,
              amountSize: compact ? 12 : priceSize,
              currencySize: compact ? 9 : 11,
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: CoursePriceText(
        price: course.price,
        amountSize: priceSize,
        currencySize: compact ? 9 : 11,
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
    return _FeaturedStrikethroughPrice(
      label: label,
      fontSize: fontSize,
      currencySize: fontSize - 1,
    );
  }
}

class _CourseCardHeroImage extends StatelessWidget {
  const _CourseCardHeroImage({
    required this.course,
    required this.height,
    required this.compact,
  });

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              fallbackSize: compact ? 36 : 44,
            ),
            if (badge != null)
              PositionedDirectional(
                top: edgeInset,
                start: edgeInset,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: course.isFeatured
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.88)
                          : AppColors.primary.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (course.isFeatured ? const Color(0xFF1E3A8A) : AppColors.primary)
                              .withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (course.isFeatured)
                          Padding(
                            padding: EdgeInsetsDirectional.only(end: compact ? 3 : 4),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              size: compact ? 11 : 13,
                              color: const Color(0xFFFFB347),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _badgeLabel(CourseModel course) {
    if (course.isFeatured) return 'course_badge_bestseller'.tr;
    if (_isNewCourse(course)) return 'course_badge_new'.tr;
    return null;
  }

  bool _isNewCourse(CourseModel course) {
    final raw = course.startDate;
    if (raw == null || raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    return DateTime.now().difference(parsed).inDays.abs() <= 30;
  }
}

class _CourseCardImage extends StatelessWidget {
  const _CourseCardImage({
    required this.course,
    required this.borderRadius,
    required this.fallbackSize,
  });

  final CourseModel course;
  final BorderRadius borderRadius;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    final url = course.resolvedImageUrl;
    if (url != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: AppNetworkImage(
          url: url,
          fit: BoxFit.cover,
          ignorePointer: true,
          errorWidget: _fallback(),
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

  IconData _categoryIcon(String? category) {
    final name = (category ?? '').toLowerCase();
    if (name.contains('لغ') || name.contains('lang')) return Icons.translate_rounded;
    if (name.contains('تصم') || name.contains('design')) return Icons.palette_outlined;
    if (name.contains('أعمال') || name.contains('business')) return Icons.business_center_outlined;
    if (name.contains('برمج') || name.contains('program')) return Icons.code_rounded;
    return Icons.school_rounded;
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

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.message, required this.cta, this.onCta});

  final String message;
  final String cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 24, offset: Offset(0, 12))],
              ),
              child: const Icon(Icons.inbox_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCta ?? () {},
                child: Text(cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
