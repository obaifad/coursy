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
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/institutes_controller.dart';
import 'institute_reviews_tab.dart';

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
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppBrandSliverAppBar(
              title: 'institutes_title'.tr,
              badge: institutes.isEmpty ? null : pluralTr('city_institutes_count', controller.displayCount),
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
    // لا يقرأ هذا الـ Obx بيانات المعهد نفسها (فقط: هل وصلت؟): كان كل تحديث لها (وصول التفاصيل، عدد
    // الدورات، إرسال تقييم) يعيد بناء الصفحة كلها — الرأس وشريط التبويبات وجسمها — ولو أثناء تبديل التبويب.
    // الرأس والعنوان يتابعانها بـ Obx خاص بهما، وكل تبويب يتابع ما يعرضه.
    return Obx(() {
      final _ = localeRebuildToken;
      final hasItem = controller.hasInstitute.value;
      if (controller.isLoading.value && !hasItem) {
        return const Scaffold(body: AppDetailSkeleton());
      }
      final detailsError = controller.detailsError.value;
      if (!hasItem && detailsError != null) {
        return Scaffold(
          appBar: AppBar(title: Text('institute_details'.tr)),
          body: AppLoadErrorState(message: detailsError, onRetry: controller.loadDetails),
        );
      }
      return DefaultTabController(
        length: 4,
        // الضغط على تبويب ينقل فوراً: انزلاق 300ms كان يُبقي التبويب السابق ظاهراً وهو يخرج. السحب بالإصبع
        // يبقى كما هو.
        animationDuration: Duration.zero,
        child: Scaffold(
          // الشريط أبيض فوق صورة الغلاف وداكن بعد طيّها (كان داكناً فوق الصورة فلا يُقرأ).
          body: AppHeaderSnap(
            child: CollapsingHeroScope(
              collapseOffset: AppDetailHero.collapseOffset(context, avatarSize: InstituteDetailHero.logoSize),
              builder: (context, collapsed) => NestedScrollView(
                headerSliverBuilder: (context, inner) => [
                  // الجزء المثبّت (الشريط والتبويبات) يُحسب في كل تبويب ([AppNestedTabScrollView]).
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: SliverAppBar(
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
                        child: Obx(
                          () => Text(
                            controller.institute.value?.name ?? 'institute_details'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Obx(() {
                          final item = controller.institute.value;
                          return item != null
                              ? InstituteDetailHero(institute: item)
                              : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.category));
                        }),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: ColoredBox(
                          color: AppColors.surface,
                          child: Builder(
                            builder: (context) => Padding(
                              padding: AppTabBarSection.padding,
                              child: AppSegmentedTabBar(
                                controller: DefaultTabController.of(context),
                                tabs: [
                                  Tab(text: 'tab_info'.tr),
                                  Tab(text: 'tab_courses'.tr),
                                  Tab(text: 'tab_instructors'.tr),
                                  Tab(text: 'tab_reviews'.tr),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // لكل تبويب موضع تمريره المحفوظ (يعود إليه حين يُبنى من جديد). لا keep-alive: NestedScrollView
                // يحرّك كل القوائم الموصولة به معاً، فتبويب حيّ مخفي كان يُمرَّر مع الظاهر.
                body: TabBarView(
                  children: [
                    KeyedSubtree(
                      key: const PageStorageKey('institute-info'),
                      child: _InfoTab(controller: controller),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey('institute-courses'),
                      child: _CoursesTab(controller: controller),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey('institute-instructors'),
                      child: _InstructorsTab(controller: controller),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey('institute-reviews'),
                      child: InstituteReviewsTab(controller: controller),
                    ),
                  ],
                ),
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

      return AppNestedTabScrollView(
        slivers: [
          SliverPadding(
            padding: AppLayout.scrollPadding(context, top: 16),
            sliver: SliverList.list(
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
                // الدورات في تبويبها فقط.
                if (institute != null && institute.hasContact) ...[
                  const SizedBox(height: 14),
                  _InstituteContactCard(institute: institute),
                ],
              ],
            ),
          ),
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
        (
          icon: Icons.call_rounded,
          label: 'contact_call'.tr,
          onTap: () => ExternalLauncher.callOrCopy(institute.phone!),
        ),
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
        return AppNestedTabScrollView(
          slivers: [
            AppEmptyState.sliver(
              message: error,
              icon: Icons.cloud_off_outlined,
              action: FilledButton(onPressed: controller.loadDetails, child: Text('retry'.tr)),
            ),
          ],
        );
      }
      final padding = AppLayout.scrollPadding(context, top: 16);
      if (courses.isEmpty && controller.isLoading.value) {
        // هيكل البطاقات الصفّية بحشوة القائمة نفسها: لا قفزة عند وصول الدورات.
        return AppNestedTabScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [AppSliverRowListSkeleton(itemCount: 3, padding: padding)],
        );
      }
      if (courses.isEmpty) {
        return AppNestedTabScrollView(
          slivers: [AppEmptyState.sliver(message: 'no_courses_for_institute'.tr, icon: Icons.menu_book_outlined)],
        );
      }
      return AppNestedTabScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverList.builder(
              itemCount: courses.length,
              itemBuilder: (_, i) {
                final c = courses[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CourseRowCard(
                    course: c,
                    onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: c),
                  ),
                );
              },
            ),
          ),
        ],
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
        return AppNestedTabScrollView(
          slivers: [
            AppEmptyState.sliver(
              message: error,
              icon: Icons.cloud_off_outlined,
              action: FilledButton(onPressed: controller.loadDetails, child: Text('retry'.tr)),
            ),
          ],
        );
      }
      final padding = AppLayout.scrollPadding(context, top: 16);
      if (instructors.isEmpty && controller.isLoading.value) {
        // بطاقة المدرّس الحقيقية ببيانات وهمية وبحشوة القائمة نفسها: لا قفزة عند وصول المدرّسين.
        return AppNestedTabScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [AppSliverInstructorListSkeleton(itemCount: 3, padding: padding)],
        );
      }
      if (instructors.isEmpty) {
        return AppNestedTabScrollView(
          slivers: [
            AppEmptyState.sliver(message: 'no_instructors_for_institute'.tr, icon: Icons.person_outline_rounded),
          ],
        );
      }
      return AppNestedTabScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverList.builder(
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
            ),
          ),
        ],
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
