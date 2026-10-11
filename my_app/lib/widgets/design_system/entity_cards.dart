part of '../design_system.dart';

/// بطاقة معهد في القائمة الأفقية للرئيسية — نفس تصميم [InstituteListCard] بعرض ثابت.
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

/// بطاقة معهد في القوائم (تبويب المعاهد، المحافظة، البحث) — بعرض الشاشة.
class InstituteListCard extends StatelessWidget {
  const InstituteListCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _InstituteHeroCard(institute: institute, onTap: onTap);
}

/// غلاف بنفسجي (أو صورة غلاف المعهد) عليه الشارات والشعار والاسم والمدينة،
/// وتحته شريط أبيض: التقييم وعدد الدورات وزر «عرض الملف». الضغط في أي مكان يفتح المعهد.
class _InstituteHeroCard extends StatelessWidget {
  const _InstituteHeroCard({required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  static const double _radius = 18;

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
                      icon: Icons.emoji_events_rounded,
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
                      borderRadius: 12,
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
                            fontSize: 16,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
    final meta = AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textBody);
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
                  const Icon(Icons.star_rounded, size: 17, color: AppColors.ratingStar),
                  const SizedBox(width: 3),
                  Text(
                    institute.rating > 0 ? institute.rating.toStringAsFixed(1) : '—',
                    textDirection: TextDirection.ltr,
                    style: meta.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (count != null && count > 0) ...[
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                // الثيم يعطي الأزرار عرضاً أدنى لا نهائياً — داخل صف يجب تحديده.
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
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
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
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
              style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: foreground),
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

/// بطاقة مدرّس أفقية: الصورة في جهة البداية، ثم الاسم وشارة «خصوصي»، التخصص، الخبرة، سعر الساعة، العنوان.
class PrivateInstructorListCard extends StatelessWidget {
  const PrivateInstructorListCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final address = instructor.address?.trim() ?? '';
    return _TutorCardShell(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
      child: Row(
        children: [
          _InstructorAvatarBox(imageUrl: instructor.resolvedImageUrl, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BidiText(
                        instructor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _TutorText.name(15),
                      ),
                    ),
                    if (instructor.isPrivate) ...[const SizedBox(width: 6), const _PrivateBadge()],
                  ],
                ),
                const SizedBox(height: 3),
                BidiText(
                  instructor.specialization ?? 'instructor_default'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _TutorText.specialization(12.5),
                ),
                if (instructor.experienceYears > 0) ...[
                  const SizedBox(height: 5),
                  _TutorMeta(
                    icon: Icons.workspace_premium_rounded,
                    text: pluralTr('instructor_experience', instructor.experienceYears),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _TutorMeta(icon: Icons.location_on_outlined, text: address),
                ],
                if (instructor.hourlyPrice != null) ...[
                  const SizedBox(height: 7),
                  _HourlyPrice(price: instructor.hourlyPrice!, size: 13),
                ],
              ],
            ),
          ),
          Icon(appIsRtl(context) ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// بطاقة مدرّس مضغوطة للقائمة الأفقية في الرئيسية.
class PrivateInstructorMiniCard extends StatelessWidget {
  const PrivateInstructorMiniCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  static const double _cardWidth = 288;
  static const double _avatarSize = 58;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: _TutorCardShell(
        onTap: onTap,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        child: Row(
          children: [
            _InstructorAvatarBox(imageUrl: instructor.resolvedImageUrl, size: _avatarSize),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BidiText(
                          instructor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _TutorText.name(13.5),
                        ),
                      ),
                      if (instructor.isPrivate) ...[const SizedBox(width: 6), const _PrivateBadge()],
                    ],
                  ),
                  const SizedBox(height: 2),
                  BidiText(
                    instructor.specialization ?? 'instructor_default'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TutorText.specialization(11.5),
                  ),
                  if (instructor.experienceYears > 0) ...[
                    const SizedBox(height: 4),
                    _TutorMeta(
                      icon: Icons.workspace_premium_rounded,
                      text: pluralTr('instructor_experience', instructor.experienceYears),
                    ),
                  ],
                  if (instructor.hourlyPrice != null) ...[
                    const SizedBox(height: 5),
                    _HourlyPrice(price: instructor.hourlyPrice!, size: 12),
                  ],
                ],
              ),
            ),
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
    final radius = BorderRadius.circular(16);
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
  static TextStyle name(double size) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.textPrimary);

  static TextStyle specialization(double size) =>
      AppFonts.tajawal(fontSize: size, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.primary);
}

class _TutorMeta extends StatelessWidget {
  const _TutorMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: BidiText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// «سعر الساعة» صغير رمادي ثم المبلغ بالبنفسجي العريض.
class _HourlyPrice extends StatelessWidget {
  const _HourlyPrice({required this.price, required this.size});

  final String price;
  final double size;

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
            style: AppFonts.tajawal(fontSize: size - 1.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          CoursePriceText(price: price, amountSize: size + 2, currencySize: size - 2),
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
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          'private_instructor_badge'.tr,
          style: AppFonts.tajawal(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary),
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
                colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.35)],
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: AppGradients.primary),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl != null
            ? AppNetworkImage(url: imageUrl!, width: size, height: size, fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: Colors.white, size: 34),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: destructive ? AppColors.dangerSoft : AppColors.indicatorFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: destructive ? AppColors.danger : AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: destructive ? AppColors.danger : null),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
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
            decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(14)),
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
