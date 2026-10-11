import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/city_details_controller.dart';

class CityDetailsView extends GetView<CityDetailsController> {
  const CityDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // الرأس البنفسجي يمتد تحت شريط الحالة.
    return AppStatusBar(
      lightIcons: true,
      child: Obx(() {
        final _ = localeRebuildToken;
        final cityInstitutesCount = controller.city.value?.institutesCount ?? 0;
        final institutesCount = cityInstitutesCount > 0 ? cityInstitutesCount : controller.institutes.length;
        final cityCoursesCount = controller.city.value?.coursesCount ?? 0;
        final coursesCount = cityCoursesCount > 0
            ? cityCoursesCount
            : controller.institutes.fold<int>(0, (sum, item) => sum + item.coursesCount);

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeroHeader(
                title: controller.title.value,
                subtitle: 'city_page_subtitle'.tr,
                badge: institutesCount > 0 ? pluralTr('city_institutes_count', institutesCount) : null,
                onBack: Get.back,
              ),
              Expanded(
                child: AppTabSafeArea(
                  top: false,
                  child: controller.isLoading.value
                      ? const AppListSkeleton()
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
                            children: [
                              SoftCard(
                                child: Row(
                                  children: [
                                    _StatBox(label: 'nav_institutes'.tr, value: '$institutesCount'),
                                    const SizedBox(width: 12),
                                    _StatBox(label: 'stat_courses'.tr, value: '$coursesCount'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('city_institutes_section'.tr, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              if (controller.institutes.isEmpty && controller.errorMessage.value != null)
                                SoftCard(
                                  child: AppLoadErrorState(
                                    message: controller.errorMessage.value!,
                                    onRetry: controller.load,
                                    compact: true,
                                  ),
                                )
                              else if (controller.institutes.isEmpty)
                                SoftCard(
                                  child: AppEmptyState.inline(
                                    message: 'no_institutes_in_city'.tr,
                                    icon: Icons.apartment_outlined,
                                  ),
                                )
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
                                  label: Text('load_more'.tr),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
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
        decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
