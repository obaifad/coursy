import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/private_instructors_controller.dart';

class PrivateInstructorsView extends GetView<PrivateInstructorsController> {
  const PrivateInstructorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('private_instructors_title'.tr),
      ),
      body: Obx(() {
        final _ = localeRebuildToken;
        if (controller.isLoading.value && controller.instructors.isEmpty) {
          return const AppListSkeleton(padding: EdgeInsets.fromLTRB(16, 12, 16, 24));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            InstructorSpecializationFiltersPanel(
              subjects: controller.subjects.toList(growable: false),
              selectedKey: controller.selectedSubjectKey.value,
              onSelected: controller.selectSubject,
              isLoading: controller.isLoadingFilters.value && controller.subjects.isEmpty,
            ),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.errorMessage.value != null && controller.instructors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value!,
                textAlign: TextAlign.center,
                style: AppTypography.pageSubtitle(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: controller.loadInstructors, child: Text('retry'.tr)),
            ],
          ),
        ),
      );
    }

    if (controller.instructors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            controller.selectedSubjectKey.value == null
                ? 'no_private_instructors'.tr
                : 'no_instructors_in_subject'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.pageSubtitle(),
          ),
        ),
      );
    }

    return AppMaxWidth(
      child: RefreshIndicator(
      onRefresh: controller.loadInstructors,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppLayout.scrollPadding(context),
        itemCount: controller.instructors.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == controller.instructors.length) {
            if (!controller.hasMore.value) return const SizedBox(height: 8);
            return OutlinedButton.icon(
              onPressed: controller.isLoadingMore.value ? null : controller.loadMore,
              icon: controller.isLoadingMore.value
                  ? const AppInlineLoader()
                  : const Icon(Icons.expand_more_rounded),
              label: Text('load_more'.tr),
            );
          }

          final item = controller.instructors[i];
          return PrivateInstructorListCard(
            instructor: item,
            onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: item),
          );
        },
      ),
      ),
    );
  }
}
