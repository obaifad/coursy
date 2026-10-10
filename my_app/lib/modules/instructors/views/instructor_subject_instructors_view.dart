import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/instructor_subject_instructors_controller.dart';
import '../../../core/locale/plural.dart';

class InstructorSubjectInstructorsView extends GetView<InstructorSubjectInstructorsController> {
  const InstructorSubjectInstructorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final instructors = controller.instructors;
      final title = controller.title.value;
      final count = controller.instructorsCount.value;

      return Scaffold(
        backgroundColor: AppColors.surface,
        body: isLoading
            ? const AppListSkeleton(itemCount: 4)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadInstructors,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AppHeroHeader(
                        title: title,
                        subtitle: 'instructor_subject_subtitle'.tr,
                        badge: count > 0 ? pluralTr('instructor_subject_count', count) : null,
                        onBack: Get.back,
                      ),
                    ),
                    if (controller.errorMessage.value != null && instructors.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              controller.errorMessage.value!,
                              textAlign: TextAlign.center,
                              style: AppTypography.pageSubtitle(),
                            ),
                          ),
                        ),
                      )
                    else if (instructors.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'no_instructors_in_subject'.tr,
                              textAlign: TextAlign.center,
                              style: AppTypography.pageSubtitle(),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: AppLayout.scrollPadding(context),
                        sliver: SliverList.separated(
                          itemCount: instructors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = instructors[i];
                            return PrivateInstructorListCard(
                              instructor: item,
                              onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: item),
                            );
                          },
                        ),
                      ),
                    if (!isLoading && instructors.isNotEmpty && controller.hasMore.value)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppLayout.horizontalPage(context),
                            12,
                            AppLayout.horizontalPage(context),
                            AppLayout.scrollBottomInset(context),
                          ),
                          child: Obx(() {
                            final loadingMore = controller.isLoadingMore.value;
                            return OutlinedButton.icon(
                              onPressed: loadingMore ? null : controller.loadMore,
                              icon: loadingMore ? const AppInlineLoader() : const Icon(Icons.expand_more_rounded),
                              label: Text('load_more'.tr),
                            );
                          }),
                        ),
                      )
                    else
                      SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context))),
                  ],
                ),
              ),
      );
    });
  }
}
