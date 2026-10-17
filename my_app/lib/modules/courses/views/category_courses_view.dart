import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../controllers/category_courses_controller.dart';
import '../../../core/locale/plural.dart';

class CategoryCoursesView extends GetView<CategoryCoursesController> {
  const CategoryCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final isLoading = controller.isLoading.value;
      // لقطة ثابتة لهذا البناء: الشبكة تبني عناصرها لاحقاً، وقراءة القائمة الحية بعد تغيّرها ترمي RangeError.
      final courses = controller.sortedCourses.toList(growable: false);
      final title = controller.title.value;
      final hPad = AppLayout.horizontalPage(context);

      // رأس العلامة يمتد تحت شريط الحالة ويبقى مثبّتاً مطوياً — أيقونات بيضاء في كل حالات التمرير.
      return AppStatusBar(
        lightIcons: true,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadCourses,
            edgeOffset: MediaQuery.paddingOf(context).top + AppBrandSliverAppBar.toolbarHeight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppBrandSliverAppBar(
                  title: title,
                  subtitle: 'category_page_subtitle'.tr,
                  badge: controller.courses.isEmpty
                      ? null
                      : pluralTr('category_courses_count', controller.courses.length),
                  onBack: Get.back,
                ),
                if (isLoading)
                  AppSliverGridSkeleton(padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0), itemCount: 4, poster: true)
                else ...[
                  if (controller.courses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        child: CourseSortDropdown(
                          selected: controller.selectedSort.value,
                          onSelected: controller.selectSort,
                        ),
                      ),
                    ),
                  if (courses.isEmpty && controller.errorMessage.value != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoadErrorState(
                        message: controller.errorMessage.value!,
                        onRetry: controller.loadCourses,
                      ),
                    )
                  else if (courses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        message: 'no_courses_in_category'.tr,
                        subtitle: 'browse_courses'.tr,
                        icon: Icons.category_outlined,
                        action: SizedBox(
                          width: 200,
                          child: RegisterGradientButton(label: 'browse_courses'.tr, onPressed: () => Get.back()),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      sliver: SliverGrid(
                        gridDelegate: AppGridLayouts.posterGridFor(context),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => CoursePosterCard(
                            course: courses[i],
                            onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: courses[i]),
                          ),
                          childCount: courses.length,
                        ),
                      ),
                    ),
                  if (courses.isNotEmpty && controller.hasMore.value)
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
                                  ? const SizedBox(width: 18, height: 18, child: AppInlineLoader())
                                  : const Icon(Icons.expand_more_rounded, size: 20),
                              label: Text('load_more'.tr, style: AppTypography.actionLabel()),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
                SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context))),
              ],
            ),
          ),
        ),
      );
    });
  }
}
