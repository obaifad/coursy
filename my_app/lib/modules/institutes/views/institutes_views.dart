import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_motion.dart';

import '../../../core/locale/plural.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/institutes_controller.dart';

import '../../../theme/app_fonts.dart';

/// رأس العلامة ينطوي مع التمرير وشريط المحافظات يلتصق تحته؛ المعاهد بطاقات صفّية مضغوطة.
class InstitutesView extends GetView<InstitutesController> {
  const InstitutesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      // لقطة واحدة لكل بناء يُحسب منها itemCount وتُقرأ منها العناصر: القائمة تُبنى لاحقاً أثناء التمرير،
      // وقراءة controller.institutes[i] بعد تغيّرها كانت ترمي RangeError (سجلّ نسخة الإصدار).
      final institutes = controller.institutes.toList(growable: false);
      final hasMore = controller.hasMore.value;
      final loadingMore = controller.isLoadingMore.value;
      final error = controller.errorMessage.value;
      final selectedCityId = controller.selectedCityId.value;
      final hPad = AppLayout.readableInset(context);
      return RefreshIndicator(
        onRefresh: controller.loadInstitutes,
        edgeOffset: MediaQuery.paddingOf(context).top + AppBrandSliverAppBar.toolbarHeight,
        child: CustomScrollView(
          key: const PageStorageKey('institutes_tab'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppBrandSliverAppBar(
              title: 'institutes_title'.tr,
              subtitle: 'institutes_subtitle'.tr,
              badge: institutes.isEmpty ? null : pluralTr('city_institutes_count', institutes.length),
            ),
            // أقل من مدينتين: لا فلاتر (HorizontalCityFilters يخفي نفسه) — ولا شريط فارغ ملتصق بحشوته.
            if (controller.cities.length >= 2)
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: HorizontalCityFilters(
                      // نسخة تُقرأ داخل Obx: وصول المدن لاحقاً يعيد البناء.
                      cities: controller.cities.toList(growable: false),
                      selectedId: selectedCityId,
                      onSelected: controller.selectCity,
                    ),
                  ),
                ),
              ),
            if (selectedCityId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () {
                        final city = controller.cities.firstWhereOrNull((c) => c.id == selectedCityId);
                        if (city != null) {
                          Get.toNamed(AppRoutes.cityDetails, arguments: {'id': city.id, 'name': city.name});
                        }
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text('city_details_btn'.tr),
                    ),
                  ),
                ),
              ),
            if (controller.isLoading.value && institutes.isEmpty)
              AppSliverRowListSkeleton(padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 24))
            else if (institutes.isEmpty && error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadErrorState(message: error, onRetry: controller.loadInstitutes),
              )
            else if (institutes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(message: 'no_institutes'.tr, icon: Icons.apartment_outlined),
              )
            else
              SliverPadding(
                padding: AppLayout.scrollPadding(context, rootTab: true, top: 4),
                sliver: SliverList.separated(
                  itemCount: institutes.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i == institutes.length) {
                      return AppLoadMoreFooter(
                        hasMore: hasMore,
                        isLoading: loadingMore,
                        failed: controller.loadMoreFailed.value,
                        onLoadMore: controller.loadMoreInstitutes,
                      );
                    }
                    final institute = institutes[i];
                    return InstituteListCard(
                      institute: institute,
                      onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: institute),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

class InstituteDetailsView extends GetView<InstituteDetailsController> {
  const InstituteDetailsView({super.key, required this.controllerTag});

  /// وسم متحكّم هذه الصفحة (انظر RouteScopedTag).
  final String controllerTag;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final item = controller.institute.value;
      if (controller.isLoading.value && item == null) {
        return const Scaffold(body: AppDetailSkeleton());
      }
      final detailsError = controller.detailsError.value;
      if (item == null && detailsError != null) {
        return Scaffold(
          appBar: AppBar(title: Text('institute_details'.tr)),
          body: AppLoadErrorState(message: detailsError, onRetry: controller.loadDetails),
        );
      }
      final name = item?.name ?? 'institute_details'.tr;
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          // الشريط أبيض فوق صورة الغلاف وداكن بعد طيّها (كان داكناً فوق الصورة فلا يُقرأ).
          body: CollapsingHeroScope(
            collapseOffset: AppDetailHero.collapseOffset(context, avatarSize: InstituteDetailHero.logoSize),
            builder: (context, collapsed) => NestedScrollView(
              headerSliverBuilder: (context, inner) => [
                SliverAppBar(
                  expandedHeight: AppDetailHero.expandedHeight(context, avatarSize: InstituteDetailHero.logoSize),
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  iconTheme: HeroAppBarStyle.icons(collapsed),
                  actionsIconTheme: HeroAppBarStyle.icons(collapsed),
                  titleTextStyle: HeroAppBarStyle.title(collapsed),
                  systemOverlayStyle: HeroAppBarStyle.overlay(collapsed),
                  // العنوان في الشريط يظهر بعد انطواء الرأس فقط: وهو مفتوح يعرض الرأس الاسم تحت الشعار.
                  title: AnimatedOpacity(
                    opacity: collapsed ? 1 : 0,
                    duration: AppMotion.fast,
                    child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: item != null
                        ? InstituteDetailHero(institute: item)
                        : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.category)),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Builder(
                        builder: (context) => Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                          child: AppSegmentedTabBar(
                            controller: DefaultTabController.of(context),
                            tabs: [
                              Tab(text: 'tab_info'.tr),
                              Tab(text: 'tab_courses'.tr),
                              Tab(text: 'tab_instructors'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _InfoTab(controller: controller),
                  _CoursesTab(controller: controller),
                  _InstructorsTab(controller: controller),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.controller});
  final InstituteDetailsController controller;

  Future<void> _openMaps(double lat, double lng) => ExternalLauncher.openMaps(lat: lat, lng: lng);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final institute = controller.institute.value;
      final coords = JsonHelpers.normalizeLatLng(institute?.latitude, institute?.longitude);
      final coursesCount = controller.displayedCoursesCount;
      final address = institute?.address?.trim();
      final showAddress = address != null && address.isNotEmpty && !JsonHelpers.looksLikeCoordinates(address);

      return ListView(
        padding: AppLayout.scrollPadding(context, top: 16),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('about_institute'.tr, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  institute?.description ?? 'institute_default_desc'.tr,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                if (coursesCount > 0) ...[
                  const SizedBox(height: 16),
                  _StatChip(label: 'stat_courses'.tr, value: '$coursesCount'),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(institute?.city ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (showAddress) ...[
                  const SizedBox(height: 8),
                  Text(address, style: const TextStyle(color: AppColors.textSecondary)),
                ],
                if (coords != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => _openMaps(coords.lat, coords.lng),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text('open_in_maps'.tr),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (institute != null && institute.hasContact) ...[
            const SizedBox(height: 14),
            _InstituteContactCard(institute: institute),
          ],
        ],
      );
    });
  }
}

class _InstituteContactCard extends StatelessWidget {
  const _InstituteContactCard({required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      if (institute.phone != null)
        (icon: Icons.call_rounded, label: 'contact_call'.tr, onTap: () => ExternalLauncher.openPhone(institute.phone!)),
      if (institute.whatsapp != null)
        (
          icon: Icons.chat_rounded,
          label: 'contact_whatsapp'.tr,
          onTap: () => ExternalLauncher.openWhatsApp(institute.whatsapp!),
        ),
      if (institute.website != null)
        (
          icon: Icons.language_rounded,
          label: 'contact_website'.tr,
          onTap: () => ExternalLauncher.openWebPage(institute.website!),
        ),
      if (institute.facebook != null)
        (
          icon: Icons.facebook_rounded,
          label: 'contact_facebook'.tr,
          onTap: () => ExternalLauncher.openWebPage(institute.facebook!),
        ),
      if (institute.instagram != null)
        (
          icon: Icons.photo_camera_outlined,
          label: 'contact_instagram'.tr,
          onTap: () => ExternalLauncher.openWebPage(institute.instagram!),
        ),
    ];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('institute_contact_title'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in actions)
                OutlinedButton.icon(
                  onPressed: a.onTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      // لقطة واحدة للعدد والعناصر (القائمة تُبنى أثناء التمرير وقد تتغير القائمة الأصلية بينهما).
      final courses = controller.courses.toList();
      final error = controller.coursesError.value;
      if (courses.isEmpty && error != null) {
        return AppEmptyState.scrollable(
          context: context,
          message: error,
          icon: Icons.cloud_off_outlined,
          action: FilledButton(onPressed: controller.loadDetails, child: Text('retry'.tr)),
        );
      }
      if (courses.isEmpty) {
        return AppEmptyState.scrollable(
          context: context,
          message: 'no_courses_for_institute'.tr,
          icon: Icons.menu_book_outlined,
        );
      }
      return ListView.builder(
        padding: AppLayout.scrollPadding(context, top: 16),
        itemCount: courses.length,
        itemBuilder: (_, i) {
          final c = courses[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              child: ListTile(
                shape: SoftCard.shape,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    gradient: AppGradients.primary,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                ),
                title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  c.hasRating ? '${c.rating.toStringAsFixed(1)} ★ · ${c.level}' : c.level,
                  style: const TextStyle(fontSize: AppTextSize.xs),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: c),
              ),
            ),
          );
        },
      );
    });
  }
}

class _InstructorsTab extends StatelessWidget {
  const _InstructorsTab({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final instructors = controller.instructors.toList();
      final error = controller.instructorsError.value;
      if (instructors.isEmpty && error != null) {
        return AppEmptyState.scrollable(
          context: context,
          message: error,
          icon: Icons.cloud_off_outlined,
          action: FilledButton(onPressed: controller.loadDetails, child: Text('retry'.tr)),
        );
      }
      if (instructors.isEmpty) {
        return AppEmptyState.scrollable(
          context: context,
          message: 'no_instructors_for_institute'.tr,
          icon: Icons.person_outline_rounded,
        );
      }
      return ListView.builder(
        padding: AppLayout.scrollPadding(context, top: 16),
        itemCount: instructors.length,
        itemBuilder: (_, i) {
          final ins = instructors[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrivateInstructorListCard(
              instructor: ins,
              onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: ins),
            ),
          );
        },
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSize.xl, color: AppColors.primaryInk),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: AppTextSize.xs, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
