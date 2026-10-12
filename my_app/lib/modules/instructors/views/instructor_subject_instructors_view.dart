import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
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
      // لقطة واحدة للعدد والعناصر (القائمة تُبنى أثناء التمرير).
      final instructors = controller.instructors.toList();
      final title = controller.title.value;
      final count = controller.instructorsCount.value;
      final error = controller.errorMessage.value;

      final Widget content;
      if (isLoading) {
        content = const AppSliverListSkeleton(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 16, 16, 24));
      } else if (error != null && instructors.isEmpty) {
        // كان نصاً فقط بلا «إعادة المحاولة».
        content = SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadErrorState(message: error, onRetry: controller.loadInstructors),
        );
      } else if (instructors.isEmpty) {
        content = SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(message: 'no_instructors_in_subject'.tr, icon: Icons.person_search_outlined),
        );
      } else {
        content = SliverPadding(
          padding: AppLayout.scrollPadding(context, top: 16),
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
        );
      }

      // الرأس البنفسجي يمتد تحت شريط الحالة (ظاهر أثناء التحميل أيضاً) ويختفي عند النزول.
      return AppStatusBar(
        lightIcons: true,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: AppScrollAwayHeaderView(
            onRefresh: controller.loadInstructors,
            header: AppHeroHeader(
              title: title,
              subtitle: 'instructor_subject_subtitle'.tr,
              badge: count > 0 ? pluralTr('instructor_subject_count', count) : null,
              onBack: Get.back,
            ),
            slivers: [
              content,
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
                ),
            ],
          ),
        ),
      );
    });
  }
}
