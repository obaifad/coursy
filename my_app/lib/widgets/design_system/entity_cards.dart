part of '../design_system.dart';

/// بطاقة معهد مضغوطة للعرض الأفقي (الرئيسية)
class InstituteMiniCard extends StatelessWidget {
  const InstituteMiniCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SoftCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: AppGradients.category,
                ),
                clipBehavior: Clip.antiAlias,
                child: _InstituteCoverHeader(
                  coverUrl: institute.resolvedCoverImageUrl,
                  logoUrl: institute.resolvedLogoUrl,
                  height: 88,
                  iconSize: 40,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(
                      institute.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 16),
                        const SizedBox(width: 4),
                        Text('${institute.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivateInstructorListCard extends StatelessWidget {
  const PrivateInstructorListCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _InstructorAvatarBox(imageUrl: instructor.resolvedImageUrl, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BidiText(
                          instructor.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (instructor.isPrivate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'private_instructor_badge'.tr,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  BidiText(
                    instructor.specialization ?? 'instructor_default'.tr,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // التخصص معروض في السطر السابق — هنا الخبرة فقط، وتُخفى إن لم تُعرف.
                  if (instructor.experienceYears > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      pluralTr('instructor_experience', instructor.experienceYears),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (instructor.hourlyPrice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'hourly_price_value'.trParams({'price': instructor.hourlyPrice!}),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                    ),
                  ],
                  if (instructor.address != null && instructor.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: BidiText(
                            instructor.address!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class PrivateInstructorMiniCard extends StatelessWidget {
  const PrivateInstructorMiniCard({super.key, required this.instructor, this.onTap});

  final InstructorModel instructor;
  final VoidCallback? onTap;

  static const double _cardWidth = 288;
  static const double _avatarSize = 54;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: SoftCard(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 2),
                child: _InstructorAvatarBox(imageUrl: instructor.resolvedImageUrl, size: _avatarSize),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(
                      instructor.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 4),
                    BidiText(
                      instructor.specialization ?? 'instructor_default'.tr,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    if (instructor.experienceYears > 0) const SizedBox(height: 4),
                    if (instructor.experienceYears > 0)
                      Text(
                        pluralTr('instructor_experience', instructor.experienceYears),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    if (instructor.hourlyPrice != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: CoursePriceText(price: instructor.hourlyPrice!, amountSize: 14, currencySize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

class _InstituteCoverHeader extends StatelessWidget {
  const _InstituteCoverHeader({required this.coverUrl, this.logoUrl, required this.height, this.iconSize = 40});

  final String? coverUrl;
  final String? logoUrl;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null) {
      return AppNetworkImage(url: coverUrl!, fit: BoxFit.cover);
    }

    if (logoUrl != null) {
      return Center(
        child: _InstituteLogoBox(
          imageUrl: logoUrl,
          size: iconSize * 1.6,
          borderRadius: 16,
          fallbackIcon: Icons.domain_rounded,
          fallbackIconSize: iconSize,
        ),
      );
    }

    return Center(
      child: Icon(Icons.domain_rounded, color: Colors.white, size: iconSize),
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

class InstituteListCard extends StatelessWidget {
  const InstituteListCard({super.key, required this.institute, this.onTap});

  final InstituteModel institute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _InstituteLogoBox(imageUrl: institute.resolvedListImageUrl, size: 72, borderRadius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BidiText(
                          institute.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (institute.isVerified) const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: BidiText(
                          institute.city,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 18),
                      const SizedBox(width: 4),
                      Text('${institute.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          pluralTr('category_courses_count', institute.coursesCount),
                          style: TextStyle(
                            color: institute.coursesCount > 0 ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              appIsRtl(context) ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// صف قائمة للملف الشخصي
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({super.key, required this.title, required this.icon, this.onTap, this.trailing});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

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
            decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
