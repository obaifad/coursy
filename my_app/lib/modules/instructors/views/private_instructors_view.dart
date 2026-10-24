import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/private_instructors_controller.dart';

class PrivateInstructorsView extends GetView<PrivateInstructorsController> {
  const PrivateInstructorsView({super.key});

  /// الرأس يختفي عند النزول وتبقى فلاتر التخصص ملتصقة بالأعلى — كتبويب الدورات.
  @override
  Widget build(BuildContext context) {
    // الرأس البنفسجي يمتد تحت شريط الحالة.
    return AppStatusBar(
      lightIcons: true,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Obx(() {
          final _ = localeRebuildToken;
          final count = controller.displayCount;
          final loading = controller.isLoading.value && controller.instructors.isEmpty;
          return AppScrollAwayHeaderView(
            onRefresh: controller.loadInstructors,
            header: AppHeroHeader(
              title: 'private_instructors_title'.tr,
              subtitle: 'private_instructors_subtitle'.tr,
              badge: count > 0 ? pluralTr('instructor_subject_count', count) : null,
              onBack: Get.back,
            ),
            // المرشّحات تبقى ظاهرة أثناء التحميل (بهيكلها) — إخفاؤها كان يُنزل القائمة عند وصول البيانات.
            pinned: InstructorSpecializationFiltersPanel(
              subjects: controller.subjects.toList(growable: false),
              selectedKey: controller.selectedSubjectKey.value,
              onSelected: controller.selectSubject,
              isLoading: controller.isLoadingFilters.value && controller.subjects.isEmpty,
            ),
            slivers: loading
                // بطاقة المدرّس الحقيقية ببيانات وهمية وبحشوة القائمة نفسها: لا قفزة عند وصول البيانات.
                ? [AppSliverInstructorListSkeleton(padding: AppLayout.scrollPadding(context, top: 4))]
                : _content(context),
          );
        }),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final error = controller.errorMessage.value;
    if (error != null && controller.instructors.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadErrorState(message: error, onRetry: controller.loadInstructors),
        ),
      ];
    }

    if (controller.instructors.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            message: controller.selectedSubjectKey.value == null
                ? 'no_private_instructors'.tr
                : 'no_instructors_in_subject'.tr,
            icon: Icons.person_search_outlined,
          ),
        ),
      ];
    }

    // لقطة واحدة للعدد والعناصر وحالة «المزيد» (القائمة تُبنى أثناء التمرير).
    final instructors = controller.instructors.toList();
    final hasMore = controller.hasMore.value;
    final isLoadingMore = controller.isLoadingMore.value;
    return [
      SliverPadding(
        padding: AppLayout.scrollPadding(context, top: 4),
        sliver: SliverList.separated(
          itemCount: instructors.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == instructors.length) {
              return AppLoadMoreFooter(
                hasMore: hasMore,
                isLoading: isLoadingMore,
                failed: controller.loadMoreFailed.value,
                onLoadMore: controller.loadMore,
              );
            }

            final item = instructors[i];
            return PrivateInstructorListCard(
              instructor: item,
              onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: item),
            );
          },
        ),
      ),
    ];
  }
}
