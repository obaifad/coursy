import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  EdgeInsetsDirectional _sectionPad(BuildContext context) => AppLayout.sectionHorizontal(context);

  @override
  Widget build(BuildContext context) {
    return AppTabSafeArea(
      child: Obx(() {
        final _ = localeRebuildToken;
        if (controller.isLoading.value && controller.categories.isEmpty && controller.courses.isEmpty) {
          return const AppHomeSkeleton();
        }
        final categories = controller.categories.toList(growable: false);
        final courses = controller.courses.toList(growable: false);
        final suggestedCourses = controller.suggestedCourses.toList(growable: false);
        final cities = controller.cities.toList(growable: false);
        final institutes = controller.institutes.toList(growable: false);
        final privateInstructors = controller.privateInstructors.toList(growable: false);
        final instructorSubjects = controller.instructorSubjects.toList(growable: false);
        final scrollReset = controller.horizontalScrollReset.value;
        return RefreshIndicator(
          onRefresh: () => controller.loadHome(forceRefresh: true),
          child: ListView(
            controller: controller.scrollController,
            primary: false,
            padding: EdgeInsetsDirectional.only(
              top: 4,
              bottom: AppLayout.scrollBottomInset(context, rootTab: true),
            ),
            children: [
              Padding(
                padding: _sectionPad(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const AppHomeBrandLogo(height: 80),
                          _HomeSettingsButton(onTap: () => Get.toNamed(AppRoutes.settings)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppHomeSearchBar(
                      onTap: () => Get.toNamed(AppRoutes.search),
                      hint: 'home_search_hint'.tr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (controller.errorMessage.value != null) ...[
                Padding(
                  padding: _sectionPad(context),
                  child: Material(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_outlined, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(child: Text(controller.errorMessage.value!, style: const TextStyle(fontSize: 13))),
                          TextButton(
                            onPressed: () => controller.loadHome(forceRefresh: true),
                            child: Text('retry'.tr),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Padding(
                padding: _sectionPad(context),
                child: const _HomeHeroBanner(),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: _sectionPad(context),
                child: AppSectionHeader(
                  title: 'section_categories'.tr,
                  actionLabel: 'view_all'.tr,
                  onAction: () => AppNavigation.switchToTab(0),
                ),
              ),
              const SizedBox(height: 10),
              _CategoriesRow(categories: categories, scrollReset: scrollReset),
              const SizedBox(height: 22),
              Padding(
                padding: _sectionPad(context),
                child: AppSectionHeader(
                  title: 'section_featured'.tr,
                  actionLabel: 'show_all'.tr,
                  onAction: () => AppNavigation.switchToTab(0),
                ),
              ),
              const SizedBox(height: 10),
              if (courses.isEmpty)
                Padding(
                  padding: _sectionPad(context),
                  child: SoftCard(
                    child: AppEmptyState.inline(
                      message: 'no_courses_now'.tr,
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                )
              else
                AppHorizontalListView(
                  resetToken: scrollReset,
                  height: CourseCardMetrics.featuredCardHeight(context),
                  bottomInset: AppHorizontalListView.cardShadowBottomInset,
                  itemCount: courses.length,
                  itemBuilder: (_, i) {
                    final course = courses[i];
                    final cardWidth = CourseCardMetrics.featuredCardWidth(context);
                    return SizedBox(
                      width: cardWidth,
                      child: CourseCard(
                        course: course,
                        showActionButton: false,
                        onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
                      ),
                    );
                  },
                ),
              if (suggestedCourses.isNotEmpty) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: _sectionPad(context),
                  child: AppSectionHeader(
                    title: 'section_suggested'.tr,
                    subtitle: controller.isLoggedIn ? 'section_suggested_subtitle'.tr : null,
                    actionLabel: 'show_all'.tr,
                    onAction: () => AppNavigation.switchToTab(0),
                  ),
                ),
                const SizedBox(height: 10),
                AppHorizontalListView(
                  resetToken: scrollReset,
                  height: CourseCardMetrics.featuredCardHeight(context),
                  bottomInset: AppHorizontalListView.cardShadowBottomInset,
                  itemCount: suggestedCourses.length,
                  itemBuilder: (_, i) {
                    final course = suggestedCourses[i];
                    final cardWidth = CourseCardMetrics.featuredCardWidth(context);
                    return SizedBox(
                      width: cardWidth,
                      child: CourseCard(
                        course: course,
                        showActionButton: false,
                        onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
                      ),
                    );
                  },
                ),
              ],
              if (privateInstructors.isNotEmpty) ...[
                const SizedBox(height: 36),
                Padding(
                  padding: _sectionPad(context),
                  child: AppSectionHeader(
                    title: 'section_private_instructors'.tr,
                    actionLabel: 'show_all'.tr,
                    onAction: () => Get.toNamed(AppRoutes.privateInstructors),
                  ),
                ),
                if (instructorSubjects.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InstructorSubjectsRow(subjects: instructorSubjects, scrollReset: scrollReset),
                ],
                const SizedBox(height: 10),
                AppHorizontalListView(
                  resetToken: scrollReset,
                  height: 120,
                  bottomInset: AppHorizontalListView.cardShadowBottomInset,
                  itemCount: privateInstructors.length,
                  itemBuilder: (_, i) {
                    final instructor = privateInstructors[i];
                    return PrivateInstructorMiniCard(
                      instructor: instructor,
                      onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: instructor),
                    );
                  },
                ),
              ],
              if (cities.isNotEmpty) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: _sectionPad(context),
                  child: AppSectionHeader(title: 'section_cities'.tr),
                ),
                const SizedBox(height: 10),
                _CitiesRow(cities: cities, scrollReset: scrollReset),
              ],
              const SizedBox(height: 22),
              Padding(
                padding: _sectionPad(context),
                child: AppSectionHeader(
                  title: 'section_institutes'.tr,
                  actionLabel: 'more'.tr,
                  onAction: () => AppNavigation.switchToTab(1),
                ),
              ),
              const SizedBox(height: 10),
              if (institutes.isEmpty)
                Padding(
                  padding: _sectionPad(context),
                  child: SoftCard(
                    child: AppEmptyState.inline(
                      message: 'no_institutes_now'.tr,
                      icon: Icons.apartment_outlined,
                    ),
                  ),
                )
              else
                AppHorizontalListView(
                  resetToken: scrollReset,
                  height: 200,
                  bottomInset: AppHorizontalListView.cardShadowBottomInset,
                  itemCount: institutes.length,
                  itemBuilder: (_, i) {
                    final institute = institutes[i];
                    return InstituteMiniCard(
                      institute: institute,
                      onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: institute),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories, required this.scrollReset});
  final List<CategoryModel> categories;
  final int scrollReset;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: AppLayout.sectionHorizontal(context),
        child: SoftCard(
          child: AppEmptyState.inline(
            message: 'no_categories'.tr,
            icon: Icons.category_outlined,
          ),
        ),
      );
    }
    return AppHorizontalListView(
      resetToken: scrollReset,
      height: _CategoryChip.height,
      bottomInset: 12,
      separatorWidth: 10,
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        return _CategoryChip(
          label: cat.name,
          category: cat,
          count: cat.coursesCount,
          onTap: () => Get.toNamed(
            AppRoutes.categoryCourses,
            arguments: {
              'id': cat.id,
              'name': cat.name,
              'icon': cat.icon,
              'coursesCount': cat.coursesCount,
            },
          ),
        );
      },
    );
  }
}

class _CitiesRow extends StatelessWidget {
  const _CitiesRow({required this.cities, required this.scrollReset});
  final List<CityModel> cities;
  final int scrollReset;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalListView(
      resetToken: scrollReset,
      height: _CityChip.height,
      separatorWidth: 10,
      itemCount: cities.length,
      itemBuilder: (_, i) {
        final city = cities[i];
        return _CityChip(
          label: city.name,
          onTap: () => Get.toNamed(AppRoutes.cityDetails, arguments: {'id': city.id, 'name': city.name}),
        );
      },
    );
  }
}

class _InstructorSubjectsRow extends StatelessWidget {
  const _InstructorSubjectsRow({required this.subjects, required this.scrollReset});
  final List<InstructorSubjectModel> subjects;
  final int scrollReset;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalListView(
      resetToken: scrollReset,
      height: _CategoryChip.height,
      separatorWidth: 10,
      itemCount: subjects.length,
      itemBuilder: (_, i) {
        final subject = subjects[i];
        return _InstructorSubjectChip(
          subject: subject,
          onTap: () => Get.toNamed(
            AppRoutes.instructorSubjectInstructors,
            arguments: {
              'key': subject.key,
              'name': subject.name,
              'instructorsCount': subject.instructorsCount,
            },
          ),
        );
      },
    );
  }
}

class _InstructorSubjectChip extends StatelessWidget {
  const _InstructorSubjectChip({required this.subject, this.onTap});
  final InstructorSubjectModel subject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: _CategoryChip.height,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InstructorSubjectIcon(subject: subject, size: 26),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if (subject.instructorsCount > 0) ...[
              const SizedBox(width: 8),
              _CategoryCountBadge(count: subject.instructorsCount),
            ],
          ],
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.label, this.onTap});

  static const double height = 44;
  static const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0);

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        padding: _padding,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.category, this.count = 0, this.onTap});

  static const double height = 44;
  static const double _iconSize = 26;
  static const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0);

  final String label;
  final CategoryModel category;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        padding: _padding,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CategoryIcon(category: category, size: _iconSize),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              _CategoryCountBadge(count: count),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCountBadge extends StatelessWidget {
  const _CategoryCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          height: 1,
        ),
      ),
    );
  }
}

/// زر إعدادات دائري متدرّج — أكثر حضورًا من الأيقونة الرمادية المسطّحة السابقة.
class _HomeSettingsButton extends StatelessWidget {
  const _HomeSettingsButton({required this.onTap});

  final VoidCallback onTap;
  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x446C63FF), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 380;
    final horizontalPad = compact ? 16.0 : 20.0;
    final titleSize = compact ? 17.0 : 19.0;
    final subtitleSize = compact ? 12.5 : 13.5;
    final contentMaxWidth = screenWidth - (horizontalPad * 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowPurple, blurRadius: 20, offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.heroBanner)),
              ),
              const Positioned.fill(child: BrandBannerPattern()),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(horizontalPad, 18, horizontalPad, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'smart_suggestions'.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'start_journey'.tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: titleSize,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'hero_subtitle'.tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: subtitleSize,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => AppNavigation.switchToTab(0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          minimumSize: const Size(0, 42),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        child: Text('hero_cta'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
    );
  }
}
