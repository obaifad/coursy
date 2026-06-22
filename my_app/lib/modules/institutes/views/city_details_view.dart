import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/city_details_controller.dart';

class CityDetailsView extends GetView<CityDetailsController> {
  const CityDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final cityInstitutesCount = controller.city.value?.institutesCount ?? 0;
        final institutesCount = cityInstitutesCount > 0 ? cityInstitutesCount : controller.institutes.length;
        final cityCoursesCount = controller.city.value?.coursesCount ?? 0;
        final coursesCount = cityCoursesCount > 0
            ? cityCoursesCount
            : controller.institutes.fold<int>(0, (sum, item) => sum + item.coursesCount);

        return Scaffold(
        appBar: AppBar(
          title: Text(controller.title.value),
          centerTitle: true,
        ),
        body: AppTabSafeArea(
          top: false,
          child: controller.isLoading.value
            ? const AppListSkeleton()
            : RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SoftCard(
                    child: Row(
                      children: [
                        _StatBox(label: 'المعاهد', value: '$institutesCount'),
                        const SizedBox(width: 12),
                        _StatBox(label: 'الدورات', value: '$coursesCount'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('معاهد المدينة', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (controller.institutes.isEmpty)
                    const SoftCard(child: Text('لا توجد معاهد في هذه المدينة'))
                  else
                    ...controller.institutes.map(
                      (inst) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InstituteListCard(
                          institute: inst,
                          onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: inst),
                        ),
                      ),
                    ),
                  if (controller.hasMore.value)
                    OutlinedButton.icon(
                      onPressed: controller.isLoadingMore.value ? null : controller.loadMore,
                      icon: controller.isLoadingMore.value
                          ? const AppInlineLoader()
                          : const Icon(Icons.expand_more_rounded),
                      label: const Text('تحميل المزيد'),
                    ),
                ],
              ),
            ),
        ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.indicatorFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
