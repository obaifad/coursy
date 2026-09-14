import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AllCoursesHeroHeader(coursesCount: controller.courses.length),
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
                      ? AppEmptyState.scrollable(
                          context: context,
                          message: 'no_courses'.tr,
                          icon: Icons.menu_book_outlined,
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

/// بانر متدرّج أعلى تبويب "كل الدورات" — نفس لغة البانر في [CategoryCoursesView]
/// (بدون زر رجوع لأنها شاشة تبويب رئيسي وليست صفحة مدفوعة).
class _AllCoursesHeroHeader extends StatelessWidget {
  const _AllCoursesHeroHeader({required this.coursesCount});

  final int coursesCount;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final compact = MediaQuery.sizeOf(context).height < 700;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.heroBanner),
        child: Stack(
          children: [
            const BrandBannerPattern(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(hPad, 14, hPad, compact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'category_courses_count'.trParams({'count': '$coursesCount'}),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'all_courses'.tr,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 22 : 24,
                      height: 1.2,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      'browse_courses'.tr,
                      style: GoogleFonts.tajawal(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
