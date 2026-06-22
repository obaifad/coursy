import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../controllers/category_courses_controller.dart';

class CategoryCoursesView extends GetView<CategoryCoursesController> {
  const CategoryCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final courses = controller.sortedCourses;
      final title = controller.title.value;
      final hPad = AppLayout.horizontalPage(context);

      return Scaffold(
        backgroundColor: AppColors.surface,
        body: isLoading
            ? const AppListSkeleton(itemCount: 4)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadCourses,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _CategoryHeroHeader(
                      title: title,
                      coursesCount: controller.courses.length,
                    ),
                    if (!isLoading && controller.courses.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                          child: CourseSortDropdown(
                            selected: controller.selectedSort.value,
                            onSelected: controller.selectSort,
                          ),
                        ),
                      ),
                    if (courses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _CategoryEmptyState(onBrowse: () => Get.back()),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          16,
                          hPad,
                          0,
                        ),
                        sliver: SliverGrid(
                          gridDelegate: AppGridLayouts.courseGridFor(context),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => CourseCard(
                              course: courses[i],
                              onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: courses[i]),
                            ),
                            childCount: courses.length,
                          ),
                        ),
                      ),
                    if (!isLoading && courses.isNotEmpty && controller.hasMore.value)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                          child: Center(
                            child: Obx(() {
                              final loadingMore = controller.isLoadingMore.value;
                              return OutlinedButton.icon(
                                onPressed: loadingMore ? null : controller.loadMore,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                ),
                                icon: loadingMore
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: AppInlineLoader(),
                                      )
                                    : const Icon(Icons.expand_more_rounded, size: 20),
                                label: Text('load_more'.tr, style: AppTypography.actionLabel()),
                              );
                            }),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: AppLayout.scrollBottomInset(context)),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}

class _CategoryHeroHeader extends StatelessWidget {
  const _CategoryHeroHeader({required this.title, required this.coursesCount});

  final String title;
  final int coursesCount;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final titleSize = compact ? 22.0 : 24.0;

    return SliverToBoxAdapter(
      child: ClipRRect(
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
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, hPad, compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: titleSize,
                          height: 1.2,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          'category_page_subtitle'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.category_outlined, size: 42, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'no_courses_in_category'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle(),
          ),
          const SizedBox(height: 8),
          Text(
            'browse_courses'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.pageSubtitle(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: RegisterGradientButton(label: 'browse_courses'.tr, onPressed: onBrowse),
          ),
        ],
      ),
    );
  }
}
