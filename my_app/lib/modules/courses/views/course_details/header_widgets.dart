part of '../course_details_view.dart';

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: AppTextSize.xs),
          ),
        ],
      ),
    );
  }
}

class _AttributeBadges extends StatelessWidget {
  const _AttributeBadges({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (item.categoryName != null)
        _DetailBadge(
          icon: Icons.category_rounded,
          label: item.categoryName!,
          onTap: item.categoryId != null
              ? () => Get.toNamed(
                  AppRoutes.categoryCourses,
                  arguments: {'id': item.categoryId, 'name': item.categoryName},
                )
              : null,
        ),
      if (item.language != null && item.language!.isNotEmpty)
        _DetailBadge(icon: Icons.language_rounded, label: item.language!),
      if (item.requiresAdvancePayment) _DetailBadge(icon: Icons.payments_outlined, label: 'course_advance_payment'.tr),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 8, runSpacing: 8, children: badges),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.sm), child: child);
  }
}

/// بطاقة «معلومات سريعة»: ثلاثة عناصر فقط — المستوى، النمط (حضوري/عن بُعد/هجين)، الشهادة. عدد الطلاب
/// والمقاعد في بطاقة السعة وحدها، فلا يتكرر في الغلاف ولا هنا.
class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatItem>[
      _StatItem(Icons.bar_chart_rounded, item.level),
      if (item.studyType != null && item.studyType!.isNotEmpty) _StatItem(Icons.laptop_mac_rounded, item.studyType!),
      _StatItem(
        item.certificateAvailable ? Icons.verified_rounded : Icons.cancel_outlined,
        item.certificateAvailable ? 'course_certificate_yes'.tr : 'course_certificate_no'.tr,
        highlighted: item.certificateAvailable,
      ),
    ];

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('course_stats_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero, // الافتراضي يضيف حشوة شريط الحالة العلوية فيظهر فراغ كبير تحت العنوان
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // كل العناصر في صف واحد (٢ أو ٣).
              crossAxisCount: stats.length,
              crossAxisSpacing: 6,
              // أطول عند تكبير الخط: نص طويل يحتاج سطرين.
              mainAxisExtent: 48 * CourseCardMetrics.textScaleOf(context),
            ),
            itemBuilder: (_, i) => _StatTile(stat: stats[i]),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.icon, this.label, {this.highlighted = false});
  final IconData icon;
  final String label;
  final bool highlighted;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: stat.highlighted ? AppColors.primary.withValues(alpha: 0.1) : AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        children: [
          Icon(stat.icon, size: 15, color: stat.highlighted ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.xs, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatsProgressCard extends StatelessWidget {
  const _SeatsProgressCard({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final max = item.maxStudents;
    final current = item.enrolledCountForCapacity;
    if (max == null || max <= 0) return const SizedBox.shrink();

    final progress = (current / max).clamp(0.0, 1.0);
    final remaining = (max - current).clamp(0, max);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('course_capacity'.tr, style: AppTypography.sectionTitle()),
              const Spacer(),
              Text(
                pluralTr('seats_available', remaining),
                style: const TextStyle(
                  color: AppColors.primaryInk,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.xs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'seats_filled'.trParams({'current': '$current', 'max': '$max'}),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.sm),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.indicatorFill,
                color: value > 0.85 ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseDateTimeline extends StatelessWidget {
  const _CourseDateTimeline({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      if (item.registrationDeadline != null)
        _TimelineStep(
          icon: Icons.hourglass_bottom_rounded,
          title: 'course_registration_deadline'.tr,
          date: JsonHelpers.formatDisplayDate(item.registrationDeadline),
        ),
      if (item.startDate != null)
        _TimelineStep(
          icon: Icons.play_circle_outline_rounded,
          title: 'course_start_date'.tr,
          date: JsonHelpers.formatDisplayDate(item.startDate),
        ),
      if (item.endDate != null)
        _TimelineStep(
          icon: Icons.flag_rounded,
          title: 'course_end_date'.tr,
          date: JsonHelpers.formatDisplayDate(item.endDate),
        ),
    ];

    // المدة وعدد الجلسات بجانب التواريخ (كانا في بطاقة المعلومات السريعة).
    final totals = <_StatItem>[
      if (item.durationHours != null && item.durationHours! > 0)
        _StatItem(Icons.schedule_rounded, pluralTr('hours_unit', item.durationHours!)),
      if (item.sessionsCount != null && item.sessionsCount! > 0)
        _StatItem(Icons.event_note_rounded, pluralTr('sessions_unit', item.sessionsCount!)),
    ];

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('course_dates_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return _TimelineRow(step: step, showLine: !isLast);
          }),
          if (totals.isNotEmpty) ...[
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.12)),
              const SizedBox(height: 14),
            ],
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in totals) _DurationChip(stat: t)]),
          ],
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.stat});
  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              stat.label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.sm),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({required this.icon, required this.title, required this.date});
  final IconData icon;
  final String title;
  final String date;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.showLine});
  final _TimelineStep step;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(step.icon, size: 18, color: AppColors.primary),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.date,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSize.lg),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseHeroImage extends StatelessWidget {
  const _CourseHeroImage({required this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.resolveMediaUrl(imagePath);
    if (url == null) return _fallback();
    return LayoutBuilder(
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
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.category),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BrandBannerPattern(),
          // في الثلث العلوي: العنوان واسم المعهد والتقييم تُكتب في النصف السفلي من الغلاف.
          Align(
            alignment: const Alignment(0, -0.45),
            child: Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.35), size: 56),
          ),
        ],
      ),
    );
  }
}

bool _hasTimelineDates(CourseModel item) {
  return item.registrationDeadline != null ||
      item.startDate != null ||
      item.endDate != null ||
      (item.durationHours ?? 0) > 0 ||
      (item.sessionsCount ?? 0) > 0;
}
