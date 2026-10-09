import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/data/repositories/search_repository.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_select_field.dart';
import '../../../widgets/app_selection_sheet.dart';
import '../../../widgets/design_system.dart';
import '../controllers/search_controller.dart';
import '../../../core/locale/plural.dart';
import '../../auth/widgets/register_form_widgets.dart';

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
                icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.tune_rounded)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IntegratedSearchBox(controller: controller, searching: searching, hasText: query.isNotEmpty),
                    const SizedBox(height: 10),
                    if (hasActiveFilters) ...[
                      const SizedBox(height: 10),
                      _ActiveFilterChipsContent(
                        controller: controller,
                        city: city,
                        category: category,
                        level: level,
                        study: study,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
          Expanded(
            child: Text('search_recent'.tr, style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
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
                  label: Text(q, style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
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
    return [
      const SizedBox(height: 8),
      AppEmptyState(message: 'search_no_results'.tr, subtitle: 'search_try_tags'.tr, icon: Icons.search_off_rounded),
    ];
  }

  void _openFilters(BuildContext context) {
    showAppFloatingSheet(
      context: context,
      builder: (_) => _FilterSheet(controller: controller),
    );
  }
}

class _IntegratedSearchBox extends StatelessWidget {
  const _IntegratedSearchBox({required this.controller, required this.searching, required this.hasText});

  final SearchPageController controller;
  final bool searching;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scope = controller.selectedScope.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchScopeSelector(controller: controller, scope: scope),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSoft),
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 10),
                    child: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.queryController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => controller.submitSearch(),
                      decoration: InputDecoration(
                        hintText: scope.hintKey.tr,
                        hintStyle: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 14, 4, 14),
                      ),
                    ),
                  ),
                  if (searching)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 12),
                      child: Center(child: SizedBox(width: 20, height: 20, child: AppInlineLoader(size: 20))),
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scope.descriptionKey.tr,
            style: AppFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      );
    });
  }
}

class _SearchScopeSelector extends StatelessWidget {
  const _SearchScopeSelector({required this.controller, required this.scope});

  final SearchPageController controller;
  final SearchScope scope;

  void _showScopeSheet(BuildContext context) {
    showAppSelectionSheet<SearchScope>(
      context: context,
      title: 'search_scope_label'.tr,
      titleIcon: Icons.tune_rounded,
      selected: scope,
      onSelected: controller.setScope,
      options: [
        for (final item in SearchScope.values)
          AppSheetOption<SearchScope>(
            value: item,
            label: item.labelKey.tr,
            icon: item.icon,
            subtitle: item.descriptionKey.tr,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'search_scope_label'.tr,
      child: InkWell(
        onTap: () => _showScopeSheet(context),
        borderRadius: const BorderRadiusDirectional.horizontal(
          start: Radius.circular(20),
        ).resolve(Directionality.of(context)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'search_scope_label'.tr,
                style: AppFonts.tajawal(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(scope.icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    scope.labelKey.tr,
                    style: AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ],
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
          decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(20)),
          child: Text(
            pluralTr('search_results_count', count),
            style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
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
      child: SoftCard(
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: course.resolvedImageUrl != null
                        ? AppNetworkImage(url: course.resolvedImageUrl!, fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(gradient: AppGradients.cardPlaceholder),
                            child: const Icon(Icons.school_rounded, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(size: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.institute.isNotEmpty ? course.institute : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardSubtitle(size: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: AppFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: CoursePriceText(price: course.price, amountSize: 12, currencySize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChipsContent extends StatelessWidget {
  const _ActiveFilterChipsContent({
    required this.controller,
    required this.city,
    required this.category,
    required this.level,
    required this.study,
  });

  final SearchPageController controller;
  final int? city;
  final int? category;
  final String level;
  final String study;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (category != null)
          InputChip(
            label: Text(
              controller.categories.firstWhereOrNull((c) => c.id == category)?.name ?? 'search_category_filter'.tr,
            ),
            onDeleted: () {
              controller.selectedCategoryId.value = null;
              controller.runSearch(resetPage: true, saveRecent: false);
            },
          ),
        if (city != null)
          InputChip(
            label: Text(controller.cities.firstWhereOrNull((c) => c.id == city)?.name ?? 'search_city_filter'.tr),
            onDeleted: () {
              controller.selectedCityId.value = null;
              controller.runSearch(resetPage: true, saveRecent: false);
            },
          ),
        if (level.isNotEmpty)
          InputChip(
            label: Text(level),
            onDeleted: () {
              controller.selectedLevel.value = '';
              controller.runSearch(resetPage: true, saveRecent: false);
            },
          ),
        if (study.isNotEmpty)
          InputChip(
            label: Text(study),
            onDeleted: () {
              controller.selectedStudyType.value = '';
              controller.runSearch(resetPage: true, saveRecent: false);
            },
          ),
        ActionChip(
          label: Text('search_clear'.tr, style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
          onPressed: controller.clearFilters,
        ),
      ],
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    cityId = widget.controller.selectedCityId.value;
    categoryId = widget.controller.selectedCategoryId.value;
    level = widget.controller.selectedLevel.value.isEmpty ? null : widget.controller.selectedLevel.value;
    studyType = widget.controller.selectedStudyType.value.isEmpty ? null : widget.controller.selectedStudyType.value;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return AppFloatingSheetFrame(
      title: 'search_filter_title'.tr,
      titleIcon: Icons.tune_rounded,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.categories.isNotEmpty) ...[
              AppSelectField<int?>(
                value: categoryId,
                label: 'search_category_filter'.tr,
                hint: 'filter_all'.tr,
                icon: Icons.category_outlined,
                options: [
                  AppSheetOption<int?>(value: null, label: 'filter_all'.tr, icon: Icons.apps_rounded),
                  ...c.categories.map(
                    (cat) => AppSheetOption<int?>(value: cat.id, label: cat.name, icon: Icons.category_outlined),
                  ),
                ],
                onChanged: (v) => setState(() => categoryId = v),
              ),
              const SizedBox(height: 12),
            ],
            if (c.cities.isNotEmpty) ...[
              AppSelectField<int?>(
                value: cityId,
                label: 'search_city_filter'.tr,
                hint: 'filter_all_cities'.tr,
                icon: Icons.location_city_outlined,
                options: [
                  AppSheetOption<int?>(value: null, label: 'filter_all_cities'.tr, icon: Icons.public_rounded),
                  ...c.cities.map(
                    (city) => AppSheetOption<int?>(value: city.id, label: city.name, icon: Icons.location_city_rounded),
                  ),
                ],
                onChanged: (v) => setState(() => cityId = v),
              ),
              const SizedBox(height: 12),
            ],
            AppSelectField<String?>(
              value: level,
              label: 'search_level_filter'.tr,
              hint: 'filter_all'.tr,
              icon: Icons.bar_chart_rounded,
              options: [
                AppSheetOption<String?>(value: null, label: 'filter_all'.tr, icon: Icons.apps_rounded),
                AppSheetOption<String?>(
                  value: 'beginner',
                  label: 'level_beginner'.tr,
                  icon: Icons.signal_cellular_alt_1_bar_rounded,
                ),
                AppSheetOption<String?>(
                  value: 'intermediate',
                  label: 'level_intermediate'.tr,
                  icon: Icons.signal_cellular_alt_2_bar_rounded,
                ),
                AppSheetOption<String?>(
                  value: 'advanced',
                  label: 'level_advanced'.tr,
                  icon: Icons.signal_cellular_alt_rounded,
                ),
              ],
              onChanged: (v) => setState(() => level = v),
            ),
            const SizedBox(height: 12),
            AppSelectField<String?>(
              value: studyType,
              label: 'search_study_type_filter'.tr,
              hint: 'filter_all'.tr,
              icon: Icons.laptop_mac_rounded,
              options: [
                AppSheetOption<String?>(value: null, label: 'filter_all'.tr, icon: Icons.apps_rounded),
                AppSheetOption<String?>(value: 'online', label: 'study_online'.tr, icon: Icons.language_rounded),
                AppSheetOption<String?>(value: 'offline', label: 'study_offline'.tr, icon: Icons.apartment_rounded),
                AppSheetOption<String?>(value: 'hybrid', label: 'study_hybrid'.tr, icon: Icons.swap_horiz_rounded),
              ],
              onChanged: (v) => setState(() => studyType = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        cityId = null;
                        categoryId = null;
                        level = null;
                        studyType = null;
                      });
                    },
                    child: Text('search_reset_filters'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RegisterGradientButton(
                    label: 'search_apply_filters'.tr,
                    onPressed: () {
                      c.applyFilters(cityId: cityId, categoryId: categoryId, level: level, studyType: studyType);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
