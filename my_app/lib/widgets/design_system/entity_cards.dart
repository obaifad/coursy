part of '../design_system.dart';

/// بطاقة معهد في القائمة الأفقية للرئيسية: غلاف بنفسجي (أو صورة الغلاف) وشريط أبيض، بعرض ثابت.
class InstituteMiniCard extends StatelessWidget {
  const InstituteMiniCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  static const double width = 264;

  /// ارتفاع القائمة الأفقية (يتبع تكبير الخط).
  static double railHeight(BuildContext context) => _InstituteHeroCard.heightFor(width, context);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _InstituteHeroCard(institute: institute, onTap: onTap),
    );
  }
}

/// بطاقة معهد في القوائم (تبويب المعاهد، المحافظة، البحث) — بطاقة صفّية مضغوطة ([AppRowCard]):
/// الشعار في جهة البداية، الاسم وشارة «الأعلى تقييماً»، المدينة وعلامة الاعتماد، ثم التقييم وعدد الدورات.
class InstituteListCard extends StatelessWidget {
  const InstituteListCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final city = institute.city.trim();
    final count = institute.reviewsCount;
    final rating = institute.rating > 0
        ? AppRowMeta(
            icon: Icons.star_rounded,
            iconColor: AppColors.ratingStar,
            emphasized: true,
            text: count != null && count > 0
                ? '${institute.rating.toStringAsFixed(1)} ($count)'
                : institute.rating.toStringAsFixed(1),
          )
        : AppRowMeta(icon: Icons.star_outline_rounded, text: 'rating_none_short'.tr);

    return AppRowCard(
      onTap: onTap,
      leading: _InstituteRowThumb(institute: institute),
      title: AppRowTitle(institute.name),
      trailing: institute.rating >= 4.5
          ? Tooltip(
              message: 'institute_top_rated_badge'.tr,
              child: Semantics(
                label: 'institute_top_rated_badge'.tr,
                child: const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.ratingStar),
              ),
            )
          : null,
      subtitle: city.isEmpty && !institute.isVerified
          ? null
          : Row(
              children: [
                if (city.isNotEmpty)
                  Flexible(
                    child: AppRowMeta(icon: Icons.location_on_outlined, text: city),
                  ),
                if (institute.isVerified) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'institute_verified_badge'.tr,
                    child: Semantics(
                      label: 'institute_verified_badge'.tr,
                      child: const Icon(Icons.verified_rounded, size: 16, color: AppColors.info),
                    ),
                  ),
                ],
              ],
            ),
      footer: Row(
        children: [
          Expanded(
            child: AppRowMetaLine(
              items: [
                rating,
                AppRowMeta(
                  icon: Icons.menu_book_outlined,
                  iconColor: AppColors.primary,
                  text: pluralTr('category_courses_count', institute.coursesCount),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// الشعار (أو صورة الغلاف) بخلفية بيضاء، أو تدرّج الهوية بأيقونة مبنى.
class _InstituteRowThumb extends StatelessWidget {
  const _InstituteRowThumb({required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    final url = institute.resolvedLogoUrl ?? institute.resolvedCoverImageUrl;
    if (url != null) {
      return ColoredBox(
        color: Colors.white,
        child: AppNetworkImage(url: url, fit: BoxFit.cover, ignorePointer: true),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.category),
      child: Center(child: Icon(Icons.apartment_rounded, color: Colors.white, size: 40)),
    );
  }
}

/// غلاف بنفسجي (أو صورة غلاف المعهد) عليه الشارات والشعار والاسم والمدينة،
/// وتحته شريط أبيض: التقييم وعدد الدورات وزر «عرض الملف». الضغط في أي مكان يفتح المعهد.
class _InstituteHeroCard extends StatelessWidget {
  const _InstituteHeroCard({required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  static const double _radius = AppRadius.md;

  static double coverHeightFor(double width) => (width * 0.5).clamp(124.0, 156.0);

  static double footerHeightFor(BuildContext context) => 24 + 34 * CourseCardMetrics.textScaleOf(context);

  static double heightFor(double width, BuildContext context) => coverHeightFor(width) + footerHeightFor(context);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: heightFor(width, context),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: AppShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: coverHeightFor(width),
                    child: _InstituteHeroCover(institute: institute),
                  ),
                  SizedBox(
                    height: footerHeightFor(context),
                    child: _InstituteHeroFooter(institute: institute, onTap: onTap),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InstituteHeroCover extends StatelessWidget {
  const _InstituteHeroCover({required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    final cover = institute.resolvedCoverImageUrl;
    final logo = institute.resolvedLogoUrl;
    final city = institute.city.trim();
    final topRated = institute.rating >= 4.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cover != null)
          AppNetworkImage(url: cover, fit: BoxFit.cover, ignorePointer: true)
        else ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
          ),
          const BrandBannerPattern(),
          PositionedDirectional(top: -40, end: -30, child: _GlowCircle(size: 130, alpha: 0.12)),
          PositionedDirectional(bottom: -50, start: 40, child: _GlowCircle(size: 110, alpha: 0.08)),
        ],
        // تعتيم سفلي ليبقى النص الأبيض مقروءاً فوق صورة الغلاف.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: cover != null ? 0.15 : 0),
                Colors.black.withValues(alpha: cover != null ? 0.6 : 0.12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (institute.isVerified)
                    _CoverChip(
                      icon: Icons.verified_rounded,
                      label: 'institute_verified_badge'.tr,
                      background: Colors.white.withValues(alpha: 0.2),
                      foreground: Colors.white,
                    ),
                  const Spacer(),
                  if (topRated)
                    _CoverChip(
                      icon: Icons.verified_user_rounded,
                      label: 'institute_top_rated_badge'.tr,
                      background: const Color(0xFFFFC94D),
                      foreground: const Color(0xFF4A2A00),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (logo != null) ...[
                    _InstituteLogoBox(
                      imageUrl: logo,
                      size: 42,
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BidiText(
                          institute.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(
                            fontSize: AppTextSize.lg,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: Colors.white,
                          ),
                        ),
                        if (city.isNotEmpty || institute.isVerified) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 3),
                              Flexible(
                                child: BidiText(
                                  city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.tajawal(
                                    fontSize: AppTextSize.xs,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ),
                              if (institute.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF7CC4FF)),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstituteHeroFooter extends StatelessWidget {
  const _InstituteHeroFooter({required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final count = institute.reviewsCount;
    final meta = AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, color: AppColors.textBody);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  if (institute.rating > 0) ...[
                    const Icon(Icons.star_rounded, size: 17, color: AppColors.ratingStar),
                    const SizedBox(width: 3),
                    Text(
                      institute.rating.toStringAsFixed(1),
                      textDirection: TextDirection.ltr,
                      style: meta.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ] else ...[
                    // بلا تقييمات: نص واضح بدل نجمة صفراء و«—».
                    const Icon(Icons.star_outline_rounded, size: 17, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      'no_ratings_yet'.tr,
                      style: meta.copyWith(fontWeight: FontWeight.w600, color: AppColors.textHint),
                    ),
                  ],
                  if (institute.rating > 0 && count != null && count > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      '($count)',
                      textDirection: TextDirection.ltr,
                      style: meta.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(width: 12),
                  const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(pluralTr('category_courses_count', institute.coursesCount), style: meta),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34 * CourseCardMetrics.textScaleOf(context),
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryStrong,
                foregroundColor: Colors.white,
                elevation: 0,
                // الثيم يعطي الأزرار عرضاً أدنى لا نهائياً — داخل صف يجب تحديده.
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                textStyle: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700),
              ),
              child: Text('institute_view_profile'.tr, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverChip extends StatelessWidget {
  const _CoverChip({required this.icon, required this.label, required this.background, required this.foreground});

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              style: AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.alpha});

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

/// بطاقة مدرّس صفّية ([AppRowCard]): الصورة في جهة البداية، الاسم وشارة «خصوصي»، التخصص،
/// ثم الخبرة والعنوان في جهة البداية وسعر الساعة في جهة النهاية.
class PrivateInstructorListCard extends StatelessWidget {
  const PrivateInstructorListCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final address = instructor.address?.trim() ?? '';
    final price = instructor.hourlyPrice;
    return AppRowCard(
      onTap: onTap,
      leading: _InstructorRowThumb(imageUrl: instructor.resolvedImageUrl, name: instructor.name),
      title: AppRowTitle(instructor.name),
      trailing: instructor.isPrivate ? const _PrivateBadge() : null,
      subtitle: BidiText(
        instructor.specializationLabel ?? 'instructor_default'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _TutorText.specialization(AppTextSize.sm),
      ),
      footer: Row(
        children: [
          Expanded(
            flex: 5,
            child: AppRowMetaLine(
              items: [
                if (instructor.experienceYears > 0)
                  AppRowMeta(
                    icon: Icons.workspace_premium_outlined,
                    text: pluralTr('instructor_experience', instructor.experienceYears),
                  ),
                if (address.isNotEmpty) AppRowMeta(icon: Icons.location_on_outlined, text: address),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (price != null)
            Flexible(
              flex: 4,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _HourlyPrice(price: price),
              ),
            )
          else
            // يتبع اتجاه اللغة تلقائياً (matchTextDirection) — قلبه يدوياً كان يجعله يشير للخلف بالعربية.
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _InstructorRowThumb extends StatelessWidget {
  const _InstructorRowThumb({required this.imageUrl, this.name});

  final String? imageUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final fallback = InstructorPlaceholder(name: name);
    if (imageUrl == null) return fallback;
    return AppNetworkImage(url: imageUrl!, fit: BoxFit.cover, ignorePointer: true, errorWidget: fallback);
  }
}

/// بطاقة مدرّس للقائمة الأفقية في الرئيسية: رأس بتدرّج باستيل (بنفسجي فاتح إلى سماوي) عليه رسوم تعليمية
/// باهتة، والصورة الدائرية تتوسّط حافّته السفلى مع شارة قبعة التخرّج، ثم الاسم والتخصص في المنتصف، شارتا
/// الخبرة والكتاب، وزر السعر.
///
/// خفيفة على التمرير: تدرّجات وأيقونات ثابتة (const) وظلّان فقط (البطاقة والصورة)، بلا تمويه أو أقنعة.
class PrivateInstructorMiniCard extends StatelessWidget {
  const PrivateInstructorMiniCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  static const double _cardWidth = 200;
  static const double _avatarSize = 88;

  /// الصورة تبدأ تحت أعلى البطاقة بـ [_avatarTop]، ومنتصفها على حافّة الرأس السفلى.
  static const double _avatarTop = 18;
  static const double _headerHeight = _avatarTop + _avatarSize / 2;
  static const double _badgeRowHeight = 28;
  static const double _buttonHeight = 44;

  /// ارتفاع شريط الرئيسية: الأجزاء الثابتة (الرأس والصورة، الشارات، الزر، المسافات) + سطرا الاسم والتخصص
  /// مع تكبير الخط.
  static double railHeight(BuildContext context) {
    final s = CourseCardMetrics.textScaleOf(context);
    const fixed = _avatarTop + _avatarSize + 10 + 2 + 10 + _badgeRowHeight + 14 + _buttonHeight + 14.0;
    // 1.45 لا 1.3: الأسطر تُقرَّب لأعلى بكسل، والفرق يكبر مع تكبير الخط.
    final text = (AppTextSize.lg + AppTextSize.sm) * 1.45 * s;
    return (fixed + text + 2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final experience = instructor.experienceYears > 0
        ? pluralTr('instructor_experience', instructor.experienceYears)
        : null;
    final price = instructor.hourlyPrice;
    return SizedBox(
      width: _cardWidth,
      child: _TutorCardShell(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _avatarTop + _avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(top: 0, left: 0, right: 0, height: _headerHeight, child: _TutorHeaderArt()),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _TutorAvatar(
                      imageUrl: instructor.resolvedImageUrl,
                      size: _avatarSize,
                      name: instructor.name,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BidiText(
                    instructor.name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.lg,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  BidiText(
                    instructor.specializationLabel ?? 'instructor_default'.tr,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.sm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: _badgeRowHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // الكبسولة بارتفاع المربّع نفسه.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _TutorBookBadge(size: _badgeRowHeight),
                        if (experience != null) ...[
                          const SizedBox(width: 8),
                          Flexible(child: _TutorExperiencePill(label: experience)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BookInstructorButton(
                    height: _buttonHeight,
                    label: price == null ? 'book_now'.tr : '${'hourly_rate_label'.tr} $price',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رأس البطاقة: تدرّج باستيل ناعم، وفوقه رسوم خطّية تعليمية باهتة (قلمان وكتاب مفتوح) كعلامة مائية.
class _TutorHeaderArt extends StatelessWidget {
  const _TutorHeaderArt();

  static const _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEBD9FB), Color(0xFFD7E3FB), Color(0xFFC9EEF8)],
  );

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      // زاويتاه السفليتان مستديرتان: يبدو طبقة ناعمة فوق البطاقة لا شريطاً مقصوصاً.
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.md)),
      ),
      child: CustomPaint(painter: _TutorArtPainter(), size: Size.infinite),
    );
  }
}

/// الرسوم الخطّية الباهتة في رأس بطاقة المدرّس. رسم واحد بدل ثلاث أيقونات (كلٌّ منها نص يُخطَّط في كل
/// بطاقة تدخل الشريط): الرموز تُخطَّط مرة واحدة للتطبيق كله ثم تُرسم فقط.
class _TutorArtPainter extends CustomPainter {
  const _TutorArtPainter();

  static const _ink = Color(0x2E6C5CE7);

  /// (الأيقونة، الحجم، المسافة من الحافّة اليسرى أو اليمنى (سالبة)، من الأعلى، الدوران بالدورات).
  static const _items = [
    (Icons.edit_outlined, 22.0, 14.0, 22.0, -0.1),
    (Icons.create_outlined, 18.0, 46.0, 8.0, 0.08),
    (Icons.menu_book_outlined, 26.0, -14.0, 12.0, 0.0),
  ];

  static final List<TextPainter> _glyphs = [
    for (final (icon, size, _, _, _) in _items)
      TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: _ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _items.length; i++) {
      final (_, _, x, top, turns) = _items[i];
      final glyph = _glyphs[i];
      final left = x >= 0 ? x : size.width + x - glyph.width;
      canvas
        ..save()
        ..translate(left + glyph.width / 2, top + glyph.height / 2)
        ..rotate(turns * 2 * math.pi);
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TutorArtPainter oldDelegate) => false;
}

/// صورة المدرّس الدائرية: حلقة بلون الهوية حولها إطار أبيض وظل خفيف، وشارة قبعة التخرّج تطفو على حافّتها
/// العليا اليمنى. بلا صورة (أو فشل تحميلها): [InstructorPlaceholder] (الحروف الأولى من الاسم).
class _TutorAvatar extends StatelessWidget {
  const _TutorAvatar({required this.imageUrl, required this.size, this.name});

  final String? imageUrl;
  final double size;
  final String? name;

  static const double _ring = 2.5;
  static const double _white = 3;
  static const double _badgeSize = 28;

  @override
  Widget build(BuildContext context) {
    final fallback = InstructorPlaceholder(name: name);
    final photo = size - (_ring + _white) * 2;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(_white),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: _ring),
              boxShadow: AppShadows.card,
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? AppNetworkImage(
                      url: imageUrl!,
                      width: photo,
                      height: photo,
                      fit: BoxFit.cover,
                      errorWidget: fallback,
                    )
                  : fallback,
            ),
          ),
          const Positioned(top: 0, right: -2, child: _GraduationCapBadge(size: _badgeSize)),
        ],
      ),
    );
  }
}

class _GraduationCapBadge extends StatelessWidget {
  const _GraduationCapBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8EEFF),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.school_rounded, size: 16, color: AppColors.primaryInk),
    );
  }
}

/// مربّع صغير بزوايا ناعمة وخلفية بنفسجية فاتحة، فيه أيقونة كتاب خطّية.
class _TutorBookBadge extends StatelessWidget {
  const _TutorBookBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), borderRadius: AppCorners.xs),
      child: const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.primary),
    );
  }
}

/// شارة الخبرة: كبسولة بخلفية ذهبية فاتحة ونص داكن، والوسام بعد النص.
class _TutorExperiencePill extends StatelessWidget {
  const _TutorExperiencePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFEF0C3), borderRadius: AppCorners.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        // يصغر قليلاً حين لا يتّسع («15 years of experience») بدل أن يُقصّ بـ «…».
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: AppFonts.tajawal(
                  fontSize: AppTextSize.sm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.workspace_premium_rounded, size: 15, color: AppColors.ratingStar),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر عريض كبسولي بتدرّج الهوية: السعر بالأبيض، وساعة رملية بعده.
class _BookInstructorButton extends StatelessWidget {
  const _BookInstructorButton({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(gradient: AppGradients.primary, borderRadius: AppCorners.full),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: AppFonts.tajawal(fontSize: AppTextSize.md, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.hourglass_bottom_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// غلاف بطاقة المدرّس: أبيض، زوايا 16، ظل ناعم، وتموّج الضغط داخل الحواف.
class _TutorCardShell extends StatelessWidget {
  const _TutorCardShell({required this.child, required this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: radius, boxShadow: AppShadows.card),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

abstract final class _TutorText {
  static TextStyle specialization(double size) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.primaryInk);
}

/// «سعر الساعة» صغير رمادي ثم المبلغ بالبنفسجي العريض.
class _HourlyPrice extends StatelessWidget {
  const _HourlyPrice({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'hourly_rate_label'.tr,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          CoursePriceText(price: price, amountSize: AppTextSize.lg, currencySize: AppTextSize.xs),
        ],
      ),
    );
  }
}

class _PrivateBadge extends StatelessWidget {
  const _PrivateBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          'private_instructor_badge'.tr,
          style: AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, color: AppColors.primaryInk),
        ),
      ),
    );
  }
}

class _InstituteLogoBox extends StatelessWidget {
  const _InstituteLogoBox({
    required this.imageUrl,
    required this.size,
    this.borderRadius = AppRadius.md,
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

/// غلاف صفحة تفاصيل المعهد (صورة الغلاف + لوغو دائري).
class InstituteDetailHero extends StatelessWidget {
  const InstituteDetailHero({super.key, required this.institute});

  final InstituteModel institute;

  static const double logoSize = 88;

  @override
  Widget build(BuildContext context) {
    final coverUrl = institute.resolvedCoverImageUrl;
    final logoUrl = institute.resolvedLogoUrl;

    return AppDetailHeroContent(
      name: institute.name,
      background: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            AppNetworkImage(url: coverUrl, fit: BoxFit.cover)
          else
            const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.category)),
          // اسم أبيض فوق الغلاف: تعتيم أقوى نحو الأسفل ليُقرأ فوق أي صورة.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: coverUrl != null ? 0.55 : 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
      avatar: _InstituteLogoBox(
        imageUrl: logoUrl,
        size: logoSize,
        borderRadius: AppRadius.full,
        fallbackIcon: Icons.apartment_rounded,
        fallbackIconSize: 42,
        border: Border.all(color: Colors.white, width: 4),
      ),
    );
  }
}

/// صف قائمة للملف الشخصي
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// إجراء خطِر (تسجيل الخروج): أحمر ليتميّز عن باقي العناصر.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          shape: SoftCard.shape,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: destructive ? AppColors.dangerSoft : AppColors.indicatorFill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: destructive ? AppColors.danger : AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: destructive ? AppColors.danger : null),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// إشعار داخل بطاقة
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.unread = true,
  });

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
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.sm),
                ),
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
