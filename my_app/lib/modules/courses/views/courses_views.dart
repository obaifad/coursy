import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/courses_controller.dart';

class CoursesView extends GetView<CoursesController> {
  const CoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTabSafeArea(
      child: Obx(() {
      final _ = localeRebuildToken;
      return Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppLayout.horizontalPage(context),
              14,
              AppLayout.horizontalPage(context),
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'all_courses'.tr,
                    style: AppTypography.tabScreenTitle(),
                    textAlign: TextAlign.start,
                  ),
                ),
          
              ],
            ),
          ),
          const SizedBox(height: 10),
          CourseFiltersPanel(
            categories: controller.categories,
            selectedCategoryId: controller.selectedCategoryId.value,
            onCategorySelected: controller.selectCategory,
            selectedSort: controller.selectedSort.value,
            onSortSelected: controller.selectSort,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadCourses,
              child: controller.isLoading.value && controller.courses.isEmpty
                  ? const AppGridSkeleton(padding: EdgeInsets.fromLTRB(16, 16, 16, 8))
                  : controller.courses.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                            Center(child: Text('no_courses'.tr)),
                          ],
                        )
                      : GridView.builder(
                              controller: controller.scrollController,
                              key: const PageStorageKey('courses_tab'),
                              padding: EdgeInsets.fromLTRB(
                                AppLayout.horizontalPage(context),
                                16,
                                AppLayout.horizontalPage(context),
                                AppLayout.scrollBottomInset(context, rootTab: true),
                              ),
                              itemCount: controller.sortedCourses.length +
                                  (controller.isLoadingMore.value ? 1 : 0),
                              gridDelegate: AppGridLayouts.courseGridFor(context),
                              itemBuilder: (_, i) {
                                if (i >= controller.sortedCourses.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: AppInlineLoader(),
                                    ),
                                  );
                                }
                                final course = controller.sortedCourses[i];
                                return CourseCard(
                                  course: course,
                                  onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
                                );
                              },
                            ),
            ),
          ),
        ],
      );
      }),
    );
  }
}
