import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/institutes_controller.dart';

class InstitutesView extends GetView<InstitutesController> {
  const InstitutesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTabSafeArea(
      child: Obx(() {
      final _ = localeRebuildToken;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('institutes_title'.tr, style: AppTypography.tabScreenTitle()),
          ),
          const SizedBox(height: 10),
          Obx(
            () => HorizontalCityFilters(
              cities: controller.cities,
              selectedId: controller.selectedCityId.value,
              onSelected: controller.selectCity,
            ),
          ),
          const SizedBox(height: 8),
          if (controller.selectedCityId.value != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () {
                    final city = controller.cities.firstWhereOrNull((c) => c.id == controller.selectedCityId.value);
                    if (city != null) {
                      Get.toNamed(AppRoutes.cityDetails, arguments: {'id': city.id, 'name': city.name});
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text('city_details_btn'.tr),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadInstitutes,
              child: controller.isLoading.value && controller.institutes.isEmpty
                  ? const AppListSkeleton(padding: EdgeInsets.fromLTRB(16, 0, 16, 24))
                  : controller.institutes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                            Center(child: Text('no_institutes'.tr)),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                        key: const PageStorageKey('institutes_tab'),
                        padding: AppLayout.scrollPadding(context, rootTab: true),
                        itemBuilder: (_, i) {
                          if (i == controller.institutes.length) {
                            if (!controller.hasMore.value) return const SizedBox.shrink();
                            return OutlinedButton.icon(
                              onPressed: controller.isLoadingMore.value ? null : controller.loadMoreInstitutes,
                              icon: controller.isLoadingMore.value
                                  ? const AppInlineLoader()
                                  : const Icon(Icons.expand_more_rounded),
                              label: Text('load_more'.tr),
                            );
                          }
                          final institute = controller.institutes[i];
                          return InstituteListCard(
                            institute: institute,
                            onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: institute),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: controller.institutes.length + 1,
                      ),
            ),
          ),
        ],
      );
    }),
    );
  }
}

class InstituteDetailsView extends GetView<InstituteDetailsController> {
  const InstituteDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.institute.value;
      if (controller.isLoading.value && item == null) {
        return const Scaffold(body: AppDetailSkeleton());
      }
      final name = item?.name ?? 'institute_details'.tr;
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, inner) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.surface,
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: const BoxDecoration(gradient: AppGradients.category)),
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 20)],
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 42),
                        ),
                      ),
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
                            Tab(text: 'tab_instructors'.tr),
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
                _InfoTab(controller: controller),
                _CoursesTab(controller: controller),
                _InstructorsTab(controller: controller),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final institute = controller.institute.value;
      final lat = institute?.latitude;
      final lng = institute?.longitude;
      return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('about_institute'.tr, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                institute?.description ?? 'institute_default_desc'.tr,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 16),
              _StatChip(label: 'stat_courses'.tr, value: '${controller.displayedCoursesCount}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(institute?.city ?? '—', style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              if (institute?.address != null && institute!.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(institute.address!, style: const TextStyle(color: AppColors.textSecondary)),
              ],
              if (lat != null && lng != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
    });
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.courses.isEmpty) {
        return Center(child: Text('no_courses_for_institute'.tr));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.courses.length,
        itemBuilder: (_, i) {
          final c = controller.courses[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: AppGradients.primary),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                ),
                title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${c.rating} ★ · ${c.level}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: c),
              ),
            ),
          );
        },
      );
    });
  }
}

class _InstructorsTab extends StatelessWidget {
  const _InstructorsTab({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.instructors.isEmpty) {
        return Center(child: Text('no_instructors_for_institute'.tr));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.instructors.length,
        itemBuilder: (_, i) {
          final ins = controller.instructors[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrivateInstructorListCard(
              instructor: ins,
              onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: ins),
            ),
          );
        },
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(16)),
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
