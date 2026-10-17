import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/data/repositories/search_repository.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_selection_sheet.dart';
import '../../../widgets/design_system.dart';
import '../../auth/widgets/register_form_widgets.dart';
import '../controllers/search_controller.dart';
import '../../../core/locale/plural.dart';

/// مستويات الدورة وأنواع الدراسة التي يقبلها البحث — قيمة الخادم ومفتاح الترجمة.
const _levelOptions = [
  ('beginner', 'level_beginner'),
  ('intermediate', 'level_intermediate'),
  ('advanced', 'level_advanced'),
];
const _studyTypeOptions = [('online', 'study_online'), ('offline', 'study_offline'), ('hybrid', 'study_hybrid')];

String _optionLabel(List<(String, String)> options, String value) =>
    options.firstWhereOrNull((o) => o.$1 == value)?.$2.tr ?? value;

/// شاشة البحث بنفس هيكل شاشات القوائم («كل الدورات»، المفضلة): رأس العلامة البنفسجي ينطوي مع التمرير
/// وكبسولته تعرض عدد النتائج، وتحته شريط مثبّت بخلفية الصفحة: حقل البحث (بشكل شريط البحث في الرئيسية)
/// وزر الفلاتر ملتصق به، تبويبات النطاق بأعداد حيّة، والفلاتر النشطة. النتائج بطاقات صفّية كالمفضلة.
class SearchView extends GetView<SearchPageController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) => _SearchScrollView(controller: controller);
}

class _SearchScrollView extends StatefulWidget {
  const _SearchScrollView({required this.controller});

  final SearchPageController controller;

  @override
  State<_SearchScrollView> createState() => _SearchScrollViewState();
}

class _SearchScrollViewState extends State<_SearchScrollView> {
  final _scrollController = ScrollController();

  SearchPageController get controller => widget.controller;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showAppFloatingSheet(
      context: context,
      builder: (_) => _FilterSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.readableInset(context);
    return Obx(() {
      final _ = localeRebuildToken;
      return AppStatusBar(
        lightIcons: true,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              Obx(() {
                final total = controller.countFor(SearchScope.all);
                return AppBrandSliverAppBar(
                  title: 'search_title'.tr,
                  subtitle: 'search_subtitle'.tr,
                  badge: controller.hasQuery && total != null ? pluralTr('search_results_count', total) : null,
                  onBack: Navigator.canPop(context) ? Get.back : null,
                );
              }),
              PinnedHeaderSliver(
                child: AppPinnedBar(
                  scrollController: _scrollController,
                  // لا شيء يختفي بين الرأس والشريط: يلتصق حين ينطوي الرأس تماماً.
                  pinOffset: () => AppBrandSliverAppBar.collapseDistance(context),
                  child: _SearchControls(controller: controller, edgeInset: hPad, onOpenFilters: _openFilters),
                ),
              ),
              Obx(() => _results(context, hPad)),
              SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context))),
            ],
          ),
        ),
      );
    });
  }

  Widget _results(BuildContext context, double hPad) {
    final searching = controller.isSearching.value;
    final scope = controller.selectedScope.value;
    // لقطة واحدة لكل بناء — القائمة تبني عناصرها لاحقاً.
    final courses = controller.courses.toList(growable: false);
    final institutes = controller.institutes.toList(growable: false);
    final instructors = controller.instructors.toList(growable: false);
    final recent = controller.recentQueries.toList(growable: false);
    final error = controller.errorMessage.value;
    final hasResults = courses.isNotEmpty || institutes.isNotEmpty || instructors.isNotEmpty;
    final padding = EdgeInsets.fromLTRB(hPad, 16, hPad, 0);

    if (!controller.hasQuery) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: _RecentSearches(controller: controller, recent: recent),
        ),
      );
    }
    if (searching && !hasResults) {
      return AppSliverRowListSkeleton(padding: padding, itemCount: 4);
    }
    if (!hasResults) {
      // بلا اتصال: رسالة الخطأ مع «إعادة المحاولة» بدل «لا نتائج».
      return SliverFillRemaining(
        hasScrollBody: false,
        child: error != null
            ? AppLoadErrorState(message: error, onRetry: () => controller.runSearch(saveRecent: false))
            : AppEmptyState(
                message: 'search_no_results'.tr,
                subtitle: 'search_try_tags'.tr,
                icon: Icons.search_off_rounded,
                // بفلاتر: مسحها أقرب حل؛ وإلا تصفّح كل الدورات.
                action: SizedBox(
                  width: 220,
                  child: RegisterGradientButton(
                    label: controller.hasActiveFilters ? 'search_clear_filters'.tr : 'browse_courses'.tr,
                    onPressed: controller.hasActiveFilters ? controller.clearFilters : AppNavigation.openCoursesTab,
                  ),
                ),
              ),
      );
    }

    final showCourses = scope == SearchScope.all || scope == SearchScope.courses;
    final showInstitutes = scope == SearchScope.all || scope == SearchScope.institutes;
    final showInstructors = scope == SearchScope.all || scope == SearchScope.instructors;
    final sections = <List<Widget>>[
      if (showCourses && courses.isNotEmpty)
        [
          _SectionHeader(title: 'search_courses_section'.tr, count: controller.totalCourses.value),
          for (final course in courses) _CourseSearchTile(course: course),
        ],
      if (showInstitutes && institutes.isNotEmpty)
        [
          _SectionHeader(title: 'search_institutes_section'.tr, count: controller.totalInstitutes.value),
          for (final institute in institutes) _InstituteSearchTile(institute: institute),
        ],
      if (showInstructors && instructors.isNotEmpty)
        [
          _SectionHeader(title: 'search_instructors_section'.tr, count: controller.totalInstructors.value),
          for (final instructor in instructors) _InstructorSearchTile(instructor: instructor),
        ],
    ];

    return SliverPadding(
      padding: padding,
      sliver: SliverList.list(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            // نفس إيقاع الرئيسية: 22 بين الأقسام، 10 تحت العنوان، 12 بين البطاقات (كالمفضلة).
            if (i > 0) const SizedBox(height: 22),
            sections[i].first,
            const SizedBox(height: 10),
            for (var j = 1; j < sections[i].length; j++) ...[if (j > 1) const SizedBox(height: 12), sections[i][j]],
          ],
        ],
      ),
    );
  }
}

/// محتوى الشريط المثبّت: الحقل وزر الفلاتر، تبويبات النطاق، ثم الفلاتر النشطة إن وُجدت.
class _SearchControls extends StatelessWidget {
  const _SearchControls({required this.controller, required this.edgeInset, required this.onOpenFilters});

  final SearchPageController controller;
  final double edgeInset;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final city = controller.selectedCityId.value;
      final category = controller.selectedCategoryId.value;
      final level = controller.selectedLevel.value;
      final study = controller.selectedStudyType.value;
      final hasActiveFilters = city != null || category != null || level.isNotEmpty || study.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgeInset),
            child: _SearchField(controller: controller, onOpenFilters: onOpenFilters),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgeInset),
            child: _ScopeTabs(controller: controller, showCounts: controller.hasQuery),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 10),
            _ActiveFilterBar(
              controller: controller,
              edgeInset: edgeInset,
              city: city,
              category: category,
              level: level,
              study: study,
            ),
          ],
        ],
      );
    });
  }
}

/// حقل البحث بنفس شكل شريط البحث في الرئيسية (الذي يفتح هذه الشاشة): أيقونة البحث في البداية وزر
/// الفلاتر في نهاية الشريط نفسه (مكان أيقونة الفلاتر هناك) وعليه عدد الفلاتر النشطة، مع حلقة تركيز بنفسجية.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller, required this.onOpenFilters});

  final SearchPageController controller;
  final VoidCallback onOpenFilters;

  static const double height = 50;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focus = FocusNode();

  SearchPageController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      constraints: const BoxConstraints(minHeight: _SearchField.height),
      decoration: BoxDecoration(
        color: focused ? AppColors.card : AppColors.surfaceSoft,
        borderRadius: AppCorners.md,
        border: Border.all(color: focused ? AppColors.primary : AppColors.primary.withValues(alpha: 0.14)),
        boxShadow: [
          if (focused)
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), spreadRadius: 4)
          else
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Obx(() {
        final searching = c.isSearching.value;
        final hasText = c.queryText.value.trim().isNotEmpty;
        return Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Icon(Icons.search_rounded, size: 22, color: AppColors.primary.withValues(alpha: 0.75)),
            ),
            Expanded(
              child: TextField(
                controller: c.queryController,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => c.submitSearch(),
                style: AppFonts.tajawal(
                  fontSize: AppTextSize.md,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: c.selectedScope.value.hintKey.tr,
                  hintStyle: AppFonts.tajawal(
                    fontSize: AppTextSize.sm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 14, 4, 14),
                ),
              ),
            ),
            if (searching)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 14),
                child: SizedBox(width: 20, height: 20, child: AppInlineLoader(size: 20)),
              )
            else if (hasText)
              IconButton(
                tooltip: 'clear_search'.tr,
                onPressed: () {
                  c.queryController.clear();
                  c.queryText.value = '';
                  c.runSearch(resetPage: true, saveRecent: false);
                },
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 5),
              child: _FilterButton(count: c.activeFiltersCount, onTap: widget.onOpenFilters),
            ),
          ],
        );
      }),
    );
  }
}

/// زر الفلاتر في نهاية الحقل: مربع بنفسجي فاتح (ممتلئ حين توجد فلاتر نشطة) وشارة بعددها.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  /// 40 داخل حقل ارتفاعه 50 — حافة 5 حوله؛ منطقة اللمس تبقى ≥ 40.
  static const double size = 40;

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'search_filters'.tr,
      child: Material(
        color: count > 0 ? AppColors.primaryStrong : AppColors.surfaceVariant,
        borderRadius: AppCorners.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: _FilterButton.size,
            child: Center(
              child: Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppColors.card,
                textColor: AppColors.primaryInk,
                label: Text('$count'),
                child: Icon(Icons.tune_rounded, size: 22, color: count > 0 ? Colors.white : AppColors.primaryInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// آخر عمليات البحث كشرائح بنفس شكل شرائح الفلاتر في التطبيق (حدّ رمادي، زاوية كاملة).
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.controller, required this.recent});

  final SearchPageController controller;
  final List<String> recent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'search_recent'.tr,
          actionLabel: recent.isEmpty ? null : 'search_clear_recent'.tr,
          onAction: recent.isEmpty ? null : controller.clearRecentSearches,
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Text('search_no_recent'.tr, style: AppTypography.meta())
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in recent)
                _SheetChip(
                  label: q,
                  icon: Icons.history_rounded,
                  selected: false,
                  onTap: () {
                    controller.queryController.text = q;
                    controller.queryText.value = q;
                    controller.submitSearch();
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// تبويبات النطاق (الكل · دورات · معاهد · مدرّبون) بنفس شكل التبويبات المقسّمة في التطبيق
/// ([AppSegmentedTabBar]: دوراتي، تفاصيل الدورة، المعاهد)، وبجانب كل تبويب عدد نتائجه من آخر بحث.
/// تتوزع بالتساوي حين تتسع، وتتمرر أفقياً حين تطول الأعداد.
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.controller, required this.showCounts});

  final SearchPageController controller;
  final bool showCounts;

  static const double _pad = 4;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.indicatorFill, borderRadius: AppCorners.md),
      child: Padding(
        padding: const EdgeInsets.all(_pad),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabs = SearchScope.values;
            final minTabWidth = constraints.maxWidth / tabs.length;
            return Obx(() {
              final selected = controller.selectedScope.value;
              final counts = Map<SearchScope, int>.of(controller.scopeCounts);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final scope in tabs)
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minTabWidth),
                        child: _ScopeTab(
                          label: scope.labelKey.tr,
                          icon: scope.icon,
                          count: showCounts ? counts[scope] : null,
                          selected: scope == selected,
                          onTap: () => controller.setScope(scope),
                        ),
                      ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primaryInk : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: AppCorners.sm,
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 10, offset: Offset(0, 3))]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppCorners.sm,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700, color: foreground),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected ? AppColors.surfaceVariant : AppColors.card.withValues(alpha: 0.7),
                          borderRadius: AppCorners.full,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          child: Text(
                            '$count',
                            textDirection: TextDirection.ltr,
                            style: AppFonts.tajawal(
                              fontSize: AppTextSize.xs,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTypography.sectionTitle()),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: const BoxDecoration(color: AppColors.indicatorFill, borderRadius: AppCorners.full),
          child: Text(
            pluralTr('search_results_count', count),
            style: AppFonts.tajawal(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700, color: AppColors.primaryInk),
          ),
        ),
      ],
    );
  }
}

class _InstituteSearchTile extends StatelessWidget {
  const _InstituteSearchTile({required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    return InstituteListCard(
      institute: institute,
      onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: institute),
    );
  }
}

class _InstructorSearchTile extends StatelessWidget {
  const _InstructorSearchTile({required this.instructor});

  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    return PrivateInstructorListCard(
      instructor: instructor,
      onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: instructor),
    );
  }
}

class _CourseSearchTile extends StatelessWidget {
  const _CourseSearchTile({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return CourseRowCard(
      course: course,
      onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
    );
  }
}

/// الفلاتر المطبّقة كشرائح ملوّنة خفيفة قابلة للتمرير أفقياً، لكلٍّ زر ✕، وفي آخرها «مسح الكل».
class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.controller,
    required this.edgeInset,
    required this.city,
    required this.category,
    required this.level,
    required this.study,
  });

  final SearchPageController controller;
  final double edgeInset;
  final int? city;
  final int? category;
  final String level;
  final String study;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (category != null)
        _ActiveFilterChip(
          icon: Icons.category_outlined,
          label: controller.categories.firstWhereOrNull((c) => c.id == category)?.name ?? 'search_category_filter'.tr,
          onClear: () => controller.removeFilter(SearchFilterKind.category),
        ),
      if (city != null)
        _ActiveFilterChip(
          icon: Icons.location_city_outlined,
          label: controller.cities.firstWhereOrNull((c) => c.id == city)?.name ?? 'search_city_filter'.tr,
          onClear: () => controller.removeFilter(SearchFilterKind.city),
        ),
      if (level.isNotEmpty)
        _ActiveFilterChip(
          icon: Icons.bar_chart_rounded,
          label: _optionLabel(_levelOptions, level),
          onClear: () => controller.removeFilter(SearchFilterKind.level),
        ),
      if (study.isNotEmpty)
        _ActiveFilterChip(
          icon: Icons.laptop_mac_rounded,
          label: _optionLabel(_studyTypeOptions, study),
          onClear: () => controller.removeFilter(SearchFilterKind.studyType),
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: edgeInset),
      child: Row(
        children: [
          for (final chip in chips) ...[chip, const SizedBox(width: 8)],
          TextButton(
            onPressed: controller.clearFilters,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('search_clear_all'.tr),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.icon, required this.label, required this.onClear});

  final IconData icon;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.indicatorFill, borderRadius: AppCorners.full),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryInk),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: BidiText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: AppTextSize.sm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryInk,
                ),
              ),
            ),
            IconButton(
              tooltip: 'remove_filter'.tr,
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryInk),
            ),
          ],
        ),
      ),
    );
  }
}

/// ورقة فلاتر بمستوى واحد: كل فلتر مجموعة شرائح ظاهرة (بلا أوراق اختيار متداخلة)، وزر التطبيق يعرض
/// عدد النتائج الحيّ للمسودة قبل تطبيقها.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.controller});
  final SearchPageController controller;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? cityId;
  int? categoryId;
  String? level;
  String? studyType;

  SearchPageController get c => widget.controller;

  SearchFilters get _draft => SearchFilters(cityId: cityId, categoryId: categoryId, level: level, studyType: studyType);

  @override
  void initState() {
    super.initState();
    cityId = c.selectedCityId.value;
    categoryId = c.selectedCategoryId.value;
    level = c.selectedLevel.value.isEmpty ? null : c.selectedLevel.value;
    studyType = c.selectedStudyType.value.isEmpty ? null : c.selectedStudyType.value;
    c.previewFilters(_draft);
  }

  @override
  void dispose() {
    c.cancelPreview();
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(change);
    c.previewFilters(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return AppFloatingSheetFrame(
      title: 'search_filter_title'.tr,
      titleIcon: Icons.tune_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.categories.isNotEmpty)
                    _FilterChipGroup<int>(
                      label: 'search_category_filter'.tr,
                      allLabel: 'filter_all'.tr,
                      value: categoryId,
                      options: [for (final cat in c.categories) (cat.id, cat.name)],
                      onChanged: (v) => _update(() => categoryId = v),
                    ),
                  if (c.cities.isNotEmpty)
                    _FilterChipGroup<int>(
                      label: 'search_city_filter'.tr,
                      allLabel: 'filter_all_cities'.tr,
                      value: cityId,
                      options: [for (final city in c.cities) (city.id, city.name)],
                      onChanged: (v) => _update(() => cityId = v),
                    ),
                  _FilterChipGroup<String>(
                    label: 'search_level_filter'.tr,
                    allLabel: 'filter_all'.tr,
                    value: level,
                    options: [for (final o in _levelOptions) (o.$1, o.$2.tr)],
                    onChanged: (v) => _update(() => level = v),
                  ),
                  _FilterChipGroup<String>(
                    label: 'search_study_type_filter'.tr,
                    allLabel: 'filter_all'.tr,
                    value: studyType,
                    options: [for (final o in _studyTypeOptions) (o.$1, o.$2.tr)],
                    onChanged: (v) => _update(() => studyType = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _draft.isEmpty
                    ? null
                    : () => _update(() {
                        cityId = null;
                        categoryId = null;
                        level = null;
                        studyType = null;
                      }),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text('search_reset_filters'.tr),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final previewing = c.isPreviewing.value;
                  final count = c.previewCount.value;
                  return FilledButton(
                    onPressed: () {
                      c.applyFilters(cityId: cityId, categoryId: categoryId, level: level, studyType: studyType);
                      Navigator.pop(context);
                    },
                    child: previewing
                        ? const SizedBox(width: 22, height: 22, child: AppInlineLoader(size: 22, color: Colors.white))
                        : Text(_submitLabel(count), maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _submitLabel(int? count) {
    if (count == null) return 'search_show_results_unknown'.tr;
    if (count == 0) return 'search_show_results_none'.tr;
    return pluralTr('search_show_results', count);
  }
}

/// مجموعة شرائح لفلتر واحد: «الكل» ثم الخيارات؛ اختيار واحد، والضغط على المحدد يلغيه.
class _FilterChipGroup<T> extends StatelessWidget {
  const _FilterChipGroup({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTypography.filterSectionLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetChip(label: allLabel, selected: value == null, onTap: () => onChanged(null)),
              for (final (optionValue, optionLabel) in options)
                _SheetChip(
                  label: optionLabel,
                  selected: value == optionValue,
                  onTap: () => onChanged(value == optionValue ? null : optionValue),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريحة اختيار بحدّ رمادي وزاوية كاملة — في ورقة الفلاتر وفي آخر عمليات البحث ([icon] اختيارية).
class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.indicatorFill : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppCorners.full,
          side: BorderSide(color: selected ? AppColors.primary : AppColors.borderNeutral),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryInk),
                    const SizedBox(width: 4),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: BidiText(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        fontSize: AppTextSize.sm,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primaryInk : AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
