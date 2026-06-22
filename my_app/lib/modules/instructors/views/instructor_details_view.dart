import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../controllers/instructor_details_controller.dart';

class InstructorDetailsView extends GetView<InstructorDetailsController> {
  const InstructorDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.instructor.value;
      if (controller.isLoading.value && item == null) {
        return const Scaffold(body: AppDetailSkeleton());
      }

      final name = item?.name ?? 'instructor_details'.tr;

      return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, inner) => [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.surface,
                actions: [
                  Obx(
                    () => IconButton(
                      onPressed: controller.toggleFavorite,
                      icon: Icon(
                        controller.isFavorite.value ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: controller.isFavorite.value ? Colors.redAccent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.primary)),
                      const BrandBannerPattern(),
                      Center(child: _InstructorHeroAvatar(instructor: item)),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: ColoredBox(
                    color: AppColors.surface,
                    child: Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: AppSegmentedTabBar(
                          controller: DefaultTabController.of(context),
                          tabs: [
                            Tab(text: 'tab_info'.tr),
                            Tab(text: 'tab_courses'.tr),
                            Tab(text: 'tab_institutes'.tr),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _InstructorInfoTab(instructor: item, totalCourses: controller.totalCourses.value),
                _InstructorCoursesTab(controller: controller),
                _InstructorInstitutesTab(instructor: item),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _InstructorHeroAvatar extends StatelessWidget {
  const _InstructorHeroAvatar({required this.instructor});

  final InstructorModel? instructor;

  @override
  Widget build(BuildContext context) {
    final url = instructor?.resolvedImageUrl;
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: ClipOval(
        child: url != null
            ? AppNetworkImage(url: url, fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: AppColors.primary, size: 52),
      ),
    );
  }
}

class _InstructorInfoTab extends StatelessWidget {
  const _InstructorInfoTab({required this.instructor, required this.totalCourses});

  final InstructorModel? instructor;
  final int totalCourses;

  @override
  Widget build(BuildContext context) {
    if (instructor == null) {
      return Center(child: Text('no_description'.tr));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      instructor!.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                  if (instructor!.isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'private_instructor_badge'.tr,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                instructor!.specialization ?? 'instructor_default'.tr,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'instructor_years'.trParams({
                  'role': instructor!.specialization ?? 'instructor_default'.tr,
                  'years': '${instructor!.experienceYears}',
                }),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('about_instructor'.tr, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                instructor!.bio?.trim().isNotEmpty == true ? instructor!.bio! : 'no_description'.tr,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatChip(label: 'stat_courses'.tr, value: '$totalCourses')),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'stat_experience'.tr,
                value: 'instructor_years_short'.trParams({'years': '${instructor!.experienceYears}'}),
              ),
            ),
          ],
        ),
        if (instructor!.hourlyPrice != null || instructor!.sessionPrice != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('instructor_pricing'.tr, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (instructor!.hourlyPrice != null)
                  _InfoRow(icon: Icons.schedule_rounded, label: 'hourly_price'.tr, value: instructor!.hourlyPrice!),
                if (instructor!.sessionPrice != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.event_available_rounded, label: 'session_price'.tr, value: instructor!.sessionPrice!),
                ],
              ],
            ),
          ),
        ],
        if (instructor!.mobile != null && instructor!.mobile!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('contact_instructor'.tr, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.phone_rounded, label: 'phone'.tr, value: instructor!.mobile!),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyPhone(instructor!.mobile!),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text('copy_phone'.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (instructor!.address != null && instructor!.address!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('address'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(instructor!.address!, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar('copied'.tr, 'phone_copied'.tr);
  }
}

class _InstructorCoursesTab extends StatelessWidget {
  const _InstructorCoursesTab({required this.controller});

  final InstructorDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingCourses.value && controller.courses.isEmpty) {
        return const AppGridSkeleton();
      }
      if (controller.courses.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'no_courses_for_instructor'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        );
      }

      final crossAxisCount = MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: AppGridLayouts.courseTileHeightFor(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: controller.courses.length,
              itemBuilder: (_, i) {
                final course = controller.courses[i];
                return CourseCard(
                  course: course,
                  onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
                );
              },
            ),
          ),
          if (controller.hasMoreCourses.value)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: controller.isLoadingMoreCourses.value ? null : controller.loadMoreCourses,
                  icon: controller.isLoadingMoreCourses.value
                      ? const AppInlineLoader()
                      : const Icon(Icons.expand_more_rounded),
                  label: Text('load_more'.tr),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _InstructorInstitutesTab extends StatelessWidget {
  const _InstructorInstitutesTab({required this.instructor});

  final InstructorModel? instructor;

  @override
  Widget build(BuildContext context) {
    final institutes = instructor?.institutes ?? const <InstructorInstituteLink>[];
    if (institutes.isEmpty) {
      return Center(child: Text('no_institutes_for_instructor'.tr));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: institutes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final linked = institutes[i];
        return SoftCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.toNamed(
              AppRoutes.instituteDetails,
              arguments: InstituteModel(
                id: linked.id,
                name: linked.name,
                city: linked.address ?? '—',
                rating: linked.rating,
                coursesCount: 0,
                description: linked.description,
                address: linked.address,
                isVerified: linked.isVerified,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppGradients.category,
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                linked.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (linked.isVerified)
                              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                        if (linked.address != null && linked.address!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            linked.address!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${linked.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
