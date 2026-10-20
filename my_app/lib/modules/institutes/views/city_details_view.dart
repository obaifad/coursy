import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/city_details_controller.dart';

import '../../../theme/app_fonts.dart';

class CityDetailsView extends GetView<CityDetailsController> {
  const CityDetailsView({super.key});

  /// الإحصاءات وعنوان القسم فوق بطاقات المعاهد — نفسها في الهيكل وبعد وصول البيانات.
  List<Widget> _header(BuildContext context, {required int institutesCount, required int coursesCount}) => [
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
  ];

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
                      // الصفحة نفسها (الإحصاءات والعنوان وبطاقات المعاهد) ببيانات وهمية: قائمة البلاطات العامة
                      // كانت أقصر من بطاقات المعاهد وتبدأ من الأعلى، فتقفز الصفحة عند وصول البيانات.
                      ? Skeletonizer(
                          enabled: true,
                          child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
                            children: [
                              ..._header(context, institutesCount: 12, coursesCount: 48),
                              for (var i = 0; i < 4; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InstituteListCard(institute: AppSkeletonData.institute),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
                            children: [
                              ..._header(context, institutesCount: institutesCount, coursesCount: coursesCount),
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
                              AppLoadMoreFooter(
                                hasMore: controller.hasMore.value,
                                isLoading: controller.isLoadingMore.value,
                                failed: controller.loadMoreFailed.value,
                                onLoadMore: controller.loadMore,
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
        decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppTextSize.xl,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
            ),
          ],
        ),
      ),
    );
  }
}
