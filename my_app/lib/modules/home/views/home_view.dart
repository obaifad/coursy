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
import '../../../theme/app_fonts.dart';
import '../../../core/locale/plural.dart';
import '../controllers/home_controller.dart';
import '../widgets/featured_course_carousel.dart';
import '../widgets/home_categories_grid.dart';
import '../widgets/home_status_banner.dart';

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
        final bannerCourses = controller.bannerCourses;
        final isGuest = !controller.isLoggedIn;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.loadHome(forceRefresh: true, refreshStatic: true),
          child: ListView(
            controller: controller.scrollController,
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.only(top: 4, bottom: AppLayout.scrollBottomInset(context, rootTab: true)),
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
                          const AppHomeBrandLogo(height: 56),
                          _HomeSettingsButton(onTap: () => Get.toNamed(AppRoutes.settings)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppHomeSearchBar(onTap: () => Get.toNamed(AppRoutes.search), hint: 'home_search_hint'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (controller.errorMessage.value != null) ...[
                Padding(
                  padding: _sectionPad(context),
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => controller.loadHome(forceRefresh: true, refreshStatic: true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'retry_action'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // ضيف → دعوة للتسجيل؛ وإلا → عروض الدورات.
              if (isGuest)
                Padding(padding: _sectionPad(context), child: const GuestSignUpBanner())
              else if (bannerCourses.isEmpty)
                Padding(padding: _sectionPad(context), child: const _HomeHeroBanner())
              else
                FeaturedCourseCarousel(courses: bannerCourses),
              const SizedBox(height: 22),
              Padding(
                padding: _sectionPad(context),
                child: AppSectionHeader(
                  title: 'section_categories'.tr,
                  actionLabel: 'show_all'.tr,
                  onAction: () => AppNavigation.switchToTab(0),
                ),
              ),
              const SizedBox(height: 10),
              _CategoriesSection(categories: categories),
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
                    child: AppEmptyState.inline(message: 'no_courses_now'.tr, icon: Icons.menu_book_outlined),
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
                  // ارتفاع ثابت للبطاقة × تكبير الخط — وإلا يفيض اسم المدرّب عند تكبير الخط.
                  height: 120 * CourseCardMetrics.textScaleOf(context),
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
                    child: AppEmptyState.inline(message: 'no_institutes_now'.tr, icon: Icons.apartment_outlined),
                  ),
                )
              else
                AppHorizontalListView(
                  resetToken: scrollReset,
                  height: InstituteMiniCard.railHeight(context),
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
              // محافظة واحدة فقط: القسم بلا فائدة تصفّحية فنخفيه.
              if (cities.length >= 2) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: _sectionPad(context),
                  child: AppSectionHeader(title: 'section_cities'.tr, subtitle: 'section_cities_subtitle'.tr),
                ),
                const SizedBox(height: 12),
                _CitiesRow(cities: cities, scrollReset: scrollReset),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.categories});
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: AppLayout.sectionHorizontal(context),
        child: SoftCard(
          child: AppEmptyState.inline(message: 'no_categories'.tr, icon: Icons.category_outlined),
        ),
      );
    }
    return Padding(
      padding: AppLayout.sectionHorizontal(context),
      child: HomeCategoriesGrid(
        categories: categories,
        onShowAll: () => AppNavigation.switchToTab(0),
        onOpenCategory: (cat) => Get.toNamed(
          AppRoutes.categoryCourses,
          arguments: {'id': cat.id, 'name': cat.name, 'icon': cat.icon, 'coursesCount': cat.coursesCount},
        ),
      ),
    );
  }
}

/// لوحة ألوان هادئة متناسقة مع الهوية — يُسند لون ثابت لكل تصنيف/محافظة حسب المعرّف.
const _kAccentPalette = <Color>[
  Color(0xFF6C63FF),
  Color(0xFF2F80ED),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFEF6C57),
];

Color _accentFor(int id) => _kAccentPalette[id.abs() % _kAccentPalette.length];

/// ظهور تدريجي (تلاشٍ + انزلاق صغير) — مدة أطول لكل عنصر لاحق فيتتابعون بصرياً.
class _EntranceFade extends StatelessWidget {
  const _EntranceFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 8)) * 45),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
      child: child,
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
      height: _CityCard.heightFor(context),
      bottomInset: 4,
      separatorWidth: 12,
      itemCount: cities.length,
      itemBuilder: (_, i) {
        final city = cities[i];
        return _EntranceFade(
          index: i,
          child: _CityCard(
            city: city,
            onTap: () => Get.toNamed(AppRoutes.cityDetails, arguments: {'id': city.id, 'name': city.name}),
          ),
        );
      },
    );
  }
}

/// محافظة كبطاقة متدرّجة: اسم عريض + إحصاءات (معاهد · دورات) + علامة موقع كبيرة شبه شفافة.
class _CityCard extends StatefulWidget {
  const _CityCard({required this.city, this.onTap});

  static const double width = 158;

  static double heightFor(BuildContext context) => 70 + 28 * CourseCardMetrics.textScaleOf(context);

  final CityModel city;
  final VoidCallback? onTap;

  @override
  State<_CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<_CityCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    final accent = _accentFor(city.id);
    final stats = <String>[
      if (city.institutesCount > 0) pluralTr('city_institutes_count', city.institutesCount),
      if (city.coursesCount > 0) pluralTr('category_courses_count', city.coursesCount),
    ].join(' · ');

    return Semantics(
      button: true,
      label: stats.isEmpty ? city.name : '${city.name}، $stats',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: _CityCard.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent, Color.lerp(accent, Colors.black, 0.28)!],
              ),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -10,
                  bottom: -14,
                  child: Icon(Icons.location_on_rounded, size: 84, color: Colors.white.withValues(alpha: 0.16)),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stats,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const double _kSubjectChipHeight = 44;

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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1),
      ),
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
      height: _kSubjectChipHeight,
      separatorWidth: 10,
      itemCount: subjects.length,
      itemBuilder: (_, i) {
        final subject = subjects[i];
        return _InstructorSubjectChip(
          subject: subject,
          onTap: () => Get.toNamed(
            AppRoutes.instructorSubjectInstructors,
            arguments: {'key': subject.key, 'name': subject.name, 'instructorsCount': subject.instructorsCount},
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
        height: _kSubjectChipHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
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

/// زر إعدادات دائري متدرّج — أكثر حضورًا من الأيقونة الرمادية المسطّحة السابقة.
class _HomeSettingsButton extends StatelessWidget {
  const _HomeSettingsButton({required this.onTap});

  final VoidCallback onTap;
  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    // الظل على Container خارجي (دائري) والتأثير على Material مقصوص بدائرة — بلا خلفية مربعة حول الزر.
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.shadowPrimaryStrong, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Center(child: Icon(Icons.settings_rounded, color: Colors.white, size: 22)),
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
        boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 20, offset: Offset(0, 12))],
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
                                      fontSize: 12,
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
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          // textStyle يستبدل نمط الزر بالكامل — لذا الخط صريح وإلا يظهر بخط النظام.
                          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13),
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
