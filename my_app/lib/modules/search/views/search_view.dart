import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/data/repositories/search_repository.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
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

/// شاشة البحث (شريط هادئ): حقل البحث، تبويبات النطاق بأعداد حيّة، شريط الفلاتر النشطة، ثم النتائج
/// كبطاقات صفّية. الفلاتر في ورقة واحدة بمجموعات شرائح وزر «عرض X نتائج».
class SearchView extends GetView<SearchPageController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.readableInset(context);
    final bottomPad = AppLayout.scrollBottomInset(context);

    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('search_title'.tr, style: AppTypography.tabScreenTitle()),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            Obx(() {
              final count = controller.activeFiltersCount;
              return IconButton(
                tooltip: 'search_filters'.tr,
                onPressed: () => _openFilters(context),
                icon: Badge(
                  isLabelVisible: count > 0,
                  backgroundColor: AppColors.primaryStrong,
                  label: Text('$count'),
                  child: const Icon(Icons.tune_rounded),
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          final query = controller.queryText.value.trim();
          final city = controller.selectedCityId.value;
          final category = controller.selectedCategoryId.value;
          final level = controller.selectedLevel.value;
          final study = controller.selectedStudyType.value;
          final searching = controller.isSearching.value;
          final scope = controller.selectedScope.value;
          final courses = controller.courses.toList(growable: false);
          final institutes = controller.institutes.toList(growable: false);
          final instructors = controller.instructors.toList(growable: false);
          final totalCourses = controller.totalCourses.value;
          final totalInstitutes = controller.totalInstitutes.value;
          final totalInstructors = controller.totalInstructors.value;
          final hasActiveFilters = city != null || category != null || level.isNotEmpty || study.isNotEmpty;
          final hasQuery = query.isNotEmpty || hasActiveFilters;
          final hasResults = controller.hasAnyResults;
          final error = controller.errorMessage.value;

          final recent = controller.recentQueries.toList(growable: false);

          final resultChildren = <Widget>[];

          if (!hasQuery) {
            resultChildren.addAll(_recentSearchWidgets(controller, recent));
          } else if (searching && !hasResults) {
            resultChildren.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: AppPageLoader()),
              ),
            );
          } else if (!hasResults && error != null) {
            // بلا اتصال: رسالة الخطأ مع «إعادة المحاولة» بدل «لا نتائج».
            resultChildren.addAll([
              const SizedBox(height: 8),
              AppLoadErrorState(message: error, onRetry: () => controller.runSearch(saveRecent: false)),
            ]);
          } else if (!hasResults) {
            resultChildren.addAll(_emptyResultWidgets());
          } else {
            final showCourses = scope == SearchScope.all || scope == SearchScope.courses;
            final showInstitutes = scope == SearchScope.all || scope == SearchScope.institutes;
            final showInstructors = scope == SearchScope.all || scope == SearchScope.instructors;

            if (showCourses && courses.isNotEmpty) {
              resultChildren.add(_SectionHeader(title: 'search_courses_section'.tr, count: totalCourses));
              resultChildren.add(const SizedBox(height: 10));
              resultChildren.addAll(courses.map((course) => _CourseSearchTile(course: course)));
              resultChildren.add(const SizedBox(height: 18));
            }
            if (showInstitutes && institutes.isNotEmpty) {
              resultChildren.add(_SectionHeader(title: 'search_institutes_section'.tr, count: totalInstitutes));
              resultChildren.add(const SizedBox(height: 10));
              resultChildren.addAll(institutes.map((institute) => _InstituteSearchTile(institute: institute)));
              resultChildren.add(const SizedBox(height: 18));
            }
            if (showInstructors && instructors.isNotEmpty) {
              resultChildren.add(_SectionHeader(title: 'search_instructors_section'.tr, count: totalInstructors));
              resultChildren.add(const SizedBox(height: 10));
              resultChildren.addAll(instructors.map((instructor) => _InstructorSearchTile(instructor: instructor)));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                child: _SearchField(controller: controller, searching: searching, hasText: query.isNotEmpty),
              ),
              const SizedBox(height: 12),
              _ScopeTabs(controller: controller, edgeInset: hPad, showCounts: hasQuery),
              if (hasActiveFilters) ...[
                const SizedBox(height: 10),
                _ActiveFilterBar(
                  controller: controller,
                  edgeInset: hPad,
                  city: city,
                  category: category,
                  level: level,
                  study: study,
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: ListView(padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad), children: resultChildren),
              ),
            ],
          );
        }),
      );
    });
  }

  List<Widget> _recentSearchWidgets(SearchPageController controller, List<String> recent) {
    return [
      Row(
        children: [
          Expanded(child: Text('search_recent'.tr, style: AppTypography.sectionTitle())),
          if (recent.isNotEmpty)
            TextButton(onPressed: controller.clearRecentSearches, child: Text('search_clear_recent'.tr)),
        ],
      ),
      const SizedBox(height: 12),
      if (recent.isEmpty)
        Text('search_no_recent'.tr, style: AppFonts.tajawal(color: AppColors.textSecondary))
      else
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: recent
              .map(
                (q) => ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
                  label: Text(q, style: AppFonts.tajawal(fontWeight: FontWeight.w500)),
                  onPressed: () {
                    controller.queryController.text = q;
                    controller.queryText.value = q;
                    controller.submitSearch();
                  },
                ),
              )
              .toList(),
        ),
    ];
  }

  List<Widget> _emptyResultWidgets() {
    final filtered = controller.hasActiveFilters;
    return [
      const SizedBox(height: 8),
      AppEmptyState(
        message: 'search_no_results'.tr,
        subtitle: 'search_try_tags'.tr,
        icon: Icons.search_off_rounded,
        // بفلاتر: مسحها أقرب حل؛ وإلا تصفّح كل الدورات.
        action: SizedBox(
          width: 220,
          child: RegisterGradientButton(
            label: filtered ? 'search_clear_filters'.tr : 'browse_courses'.tr,
            onPressed: filtered ? controller.clearFilters : AppNavigation.openCoursesTab,
          ),
        ),
      ),
    ];
  }

  void _openFilters(BuildContext context) {
    showAppFloatingSheet(
      context: context,
      builder: (_) => _FilterSheet(controller: controller),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.searching, required this.hasText});

  final SearchPageController controller;
  final bool searching;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scope = controller.selectedScope.value;
      return SoftCard(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 14),
              child: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: controller.queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => controller.submitSearch(),
                decoration: InputDecoration(
                  hintText: scope.hintKey.tr,
                  hintStyle: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: AppTextSize.sm),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(10, 14, 4, 14),
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
                  controller.queryController.clear();
                  controller.queryText.value = '';
                  controller.runSearch(resetPage: true, saveRecent: false);
                },
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
          ],
        ),
      );
    });
  }
}

/// تبويبات النطاق (الكل · دورات · معاهد · مدرّبون) ظاهرة دائماً بدل القائمة المنسدلة داخل الحقل،
/// وبجانب كل تبويب عدد نتائجه من آخر بحث.
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.controller, required this.edgeInset, required this.showCounts});

  final SearchPageController controller;
  final double edgeInset;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedScope.value;
      final counts = Map<SearchScope, int>.of(controller.scopeCounts);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: edgeInset),
        child: Row(
          children: [
            for (final scope in SearchScope.values) ...[
              if (scope != SearchScope.values.first) const SizedBox(width: 8),
              _ScopeTab(
                label: scope.labelKey.tr,
                icon: scope.icon,
                count: showCounts ? counts[scope] : null,
                selected: scope == selected,
                onTap: () => controller.setScope(scope),
              ),
            ],
          ],
        ),
      );
    });
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
    final foreground = selected ? Colors.white : AppColors.textBody;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryStrong : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppCorners.full,
          side: BorderSide(color: selected ? AppColors.primaryStrong : AppColors.borderNeutral),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700, color: foreground),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withValues(alpha: 0.22) : AppColors.indicatorFill,
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
                            color: selected ? Colors.white : AppColors.primaryInk,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InstituteListCard(
        institute: institute,
        onTap: () => Get.toNamed(AppRoutes.instituteDetails, arguments: institute),
      ),
    );
  }
}

class _InstructorSearchTile extends StatelessWidget {
  const _InstructorSearchTile({required this.instructor});

  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PrivateInstructorListCard(
        instructor: instructor,
        onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: instructor),
      ),
    );
  }
}

class _CourseSearchTile extends StatelessWidget {
  const _CourseSearchTile({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CourseRowCard(
        course: course,
        onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
      ),
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

class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
