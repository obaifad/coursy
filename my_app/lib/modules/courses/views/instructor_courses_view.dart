import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../controllers/instructor_courses_controller.dart';

class InstructorCoursesView extends GetView<InstructorCoursesController> {
  const InstructorCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(
            'instructor_courses_title'.trParams({'name': controller.instructorName.value}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: controller.isLoading.value
            ? const AppGridSkeleton()
            : RefreshIndicator(
                onRefresh: controller.loadCourses,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _InstructorHeader(controller: controller)),
                    if (controller.courses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'no_courses_for_instructor'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          AppLayout.horizontalPage(context),
                          8,
                          AppLayout.horizontalPage(context),
                          8,
                        ),
                        sliver: SliverGrid.builder(
                          gridDelegate: AppGridLayouts.courseGridFor(context),
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
                      if (controller.hasMore.value)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: controller.isLoadingMore.value ? null : controller.loadMore,
                                icon: controller.isLoadingMore.value
                                    ? const AppInlineLoader()
                                    : const Icon(Icons.expand_more_rounded),
                                label: Text('load_more'.tr),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _InstructorHeader extends StatelessWidget {
  const _InstructorHeader({required this.controller});

  final InstructorCoursesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.instructorName.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'instructor_years'.trParams({
                    'role': controller.specialization.value ?? 'instructor_default'.tr,
                    'years': '${controller.experienceYears.value}',
                  }),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.35),
                ),
                if (controller.bio.value != null && controller.bio.value!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.bio.value!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.4, fontSize: 13),
                  ),
                ],
                if (controller.totalCourses.value > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'instructor_courses_count'.trParams({'count': '${controller.totalCourses.value}'}),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
