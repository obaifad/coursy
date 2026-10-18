part of '../course_details_view.dart';

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return _CourseTabScrollBody(
      children: [
        _AttributeBadges(item: item),
        const SizedBox(height: 14),
        _QuickStatsGrid(item: item),
        const SizedBox(height: 14),
        _SeatsProgressCard(item: item),
        if (_hasText(item.description)) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'about_course'.tr,
            child: Text(item.description!.trim(), style: const TextStyle(height: 1.55, fontSize: AppTextSize.lg)),
          ),
        ],
        if (_hasText(item.requirements)) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'course_requirements'.tr,
            child: Text(item.requirements!.trim(), style: const TextStyle(height: 1.55, fontSize: AppTextSize.lg)),
          ),
        ],
        if (item.institute.isNotEmpty) ...[const SizedBox(height: 16), _InstituteCard(item: item)],
      ],
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.item, required this.controller});
  final CourseModel item;
  final CourseDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final schedules = controller.schedules;
      return _CourseTabScrollBody(
        children: [
          if (_hasTimelineDates(item)) ...[_CourseDateTimeline(item: item), const SizedBox(height: 16)],
          if (schedules.isEmpty)
            _SectionCard(
              title: 'schedule_title'.tr,
              child: Text('no_schedule_yet'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            )
          else
            _SectionCard(
              title: 'schedule_title'.tr,
              child: Column(children: schedules.map((s) => _ScheduleTile(schedule: s)).toList()),
            ),
        ],
      );
    });
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule});
  final ScheduleModel schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(JsonHelpers.weekdayLabel(schedule.dayOfWeek), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${schedule.startTime} - ${schedule.endTime}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.sm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorTab extends StatelessWidget {
  const _InstructorTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final instructor = item.instructor;
    if (instructor == null) {
      return _CourseTabScrollBody(
        children: [
          _SectionCard(
            title: 'tab_instructor'.tr,
            child: Text('no_instructor_info'.tr, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      );
    }

    return _CourseTabScrollBody(
      children: [
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _InstructorAvatar(instructor: instructor),
              const SizedBox(height: 16),
              Text(
                instructor.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSize.xxl),
              ),
              const SizedBox(height: 6),
              Text(
                instructor.specializationLabel ?? 'instructor_default'.tr,
                style: const TextStyle(color: AppColors.primaryInk, fontWeight: FontWeight.w700),
              ),
              if (instructor.experienceYears > 0) ...[
                const SizedBox(height: 4),
                Text(
                  pluralTr('instructor_experience', instructor.experienceYears),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (instructor.bio != null && instructor.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(instructor.bio!, textAlign: TextAlign.center, style: const TextStyle(height: 1.55)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.instructorDetails, arguments: instructor),
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: Text('view_instructor_profile'.tr),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.instructorCourses, arguments: instructor),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text('view_instructor_courses'.tr),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructorAvatar extends StatelessWidget {
  const _InstructorAvatar({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    final url = instructor.resolvedImageUrl;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
        boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: ClipOval(
        child: url != null
            ? AppNetworkImage(
                url: url,
                fit: BoxFit.cover,
                ignorePointer: true,
                errorWidget: _InstructorHeadFallback(gender: instructor.gender),
              )
            : _InstructorHeadFallback(gender: instructor.gender),
      ),
    );
  }
}

class _InstituteCard extends StatelessWidget {
  const _InstituteCard({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: item.instituteId != null
            ? () => Get.toNamed(AppRoutes.instituteDetails, arguments: item.instituteId)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('course_institute_section'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.institute, style: AppTypography.cardTitle()),
                      if (item.instituteCity != null) Text(item.instituteCity!, style: AppTypography.cardSubtitle()),
                    ],
                  ),
                ),
                if (item.instituteId != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
            if (item.instituteAddress != null && item.instituteAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InstituteInfoLine(icon: Icons.place_outlined, text: item.instituteAddress!),
            ],
            if (item.institutePhone != null && item.institutePhone!.isNotEmpty)
              _InstituteInfoLine(icon: Icons.phone_outlined, text: item.institutePhone!),
          ],
        ),
      ),
    );
  }
}

class _InstituteInfoLine extends StatelessWidget {
  const _InstituteInfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle()),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InstructorHeadFallback extends StatelessWidget {
  const _InstructorHeadFallback({required this.gender});

  final String? gender;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.indicatorFill,
      child: Center(child: Icon(instructorHeadIcon(gender), color: AppColors.primary, size: 50)),
    );
  }
}
