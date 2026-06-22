import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/repositories/search_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchPageController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final bottomPad = AppLayout.scrollBottomInset(context);

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
        final hasActiveFilters =
            city != null || category != null || level.isNotEmpty || study.isNotEmpty;
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
                  _IntegratedSearchBox(
                    controller: controller,
                    searching: searching,
                    hasText: query.isNotEmpty,
                  ),
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                children: resultChildren,
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _recentSearchWidgets(SearchPageController controller, List<String> recent) {
    return [
      Text('search_recent'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 12),
      if (recent.isEmpty)
        Text('search_no_recent'.tr, style: GoogleFonts.tajawal(color: AppColors.textSecondary))
      else
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: recent
              .map(
                (q) => ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
                  label: Text(q, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
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
      const SizedBox(height: 24),
      Center(
        child: Icon(Icons.search_off_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      const SizedBox(height: 16),
      Text(
        'search_no_results'.tr,
        textAlign: TextAlign.center,
        style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      const SizedBox(height: 8),
      Text(
        'search_try_tags'.tr,
        textAlign: TextAlign.center,
        style: GoogleFonts.tajawal(color: AppColors.textSecondary, height: 1.45),
      ),
    ];
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _FilterSheet(controller: controller),
    );
  }
}

class _IntegratedSearchBox extends StatelessWidget {
  const _IntegratedSearchBox({
    required this.controller,
    required this.searching,
    required this.hasText,
  });

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
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8E6F8)),
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
                        hintStyle: GoogleFonts.tajawal(color: AppColors.textSecondary, fontSize: 14),
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
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: AppInlineLoader(size: 20),
                        ),
                      ),
                    )
                  else if (hasText)
                    IconButton(
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
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchScope>(
      tooltip: 'search_scope_label'.tr,
      initialValue: scope,
      onSelected: controller.setScope,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => SearchScope.values
          .map(
            (item) => PopupMenuItem<SearchScope>(
              value: item,
              child: _SearchScopeMenuTile(scope: item, selected: item == scope),
            ),
          )
          .toList(),
      child: InkWell(
        borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(20)).resolve(Directionality.of(context)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'search_scope_label'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 10,
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
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
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

class _SearchScopeMenuTile extends StatelessWidget {
  const _SearchScopeMenuTile({required this.scope, required this.selected});

  final SearchScope scope;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF7F6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(scope.icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope.labelKey.tr,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: selected ? AppColors.primary : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scope.descriptionKey.tr,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
            ),
        ],
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
        Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.indicatorFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'search_results_count'.trParams({'n': '$count'}),
            style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.institute.isNotEmpty ? course.institute : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                          const SizedBox(width: 3),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              course.price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
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
              controller.categories.firstWhereOrNull((c) => c.id == category)?.name ??
                  'search_category_filter'.tr,
            ),
            onDeleted: () {
              controller.selectedCategoryId.value = null;
              controller.runSearch(resetPage: true, saveRecent: false);
            },
          ),
        if (city != null)
          InputChip(
            label: Text(
              controller.cities.firstWhereOrNull((c) => c.id == city)?.name ?? 'search_city_filter'.tr,
            ),
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
          label: Text('search_clear'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
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
    final sheetWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          width: sheetWidth - 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'search_filter_title'.tr,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (c.categories.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'search_category_filter'.tr),
                  items: [
                    DropdownMenuItem(value: null, child: Text('filter_all'.tr)),
                    ...c.categories.map(
                      (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => categoryId = v),
                ),
              if (c.categories.isNotEmpty) const SizedBox(height: 12),
              if (c.cities.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: cityId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'search_city_filter'.tr),
                  items: [
                    DropdownMenuItem(value: null, child: Text('filter_all_cities'.tr)),
                    ...c.cities.map(
                      (city) => DropdownMenuItem(value: city.id, child: Text(city.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => cityId = v),
                ),
              if (c.cities.isNotEmpty) const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: level,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'search_level_filter'.tr),
                items: [
                  DropdownMenuItem(value: null, child: Text('filter_all'.tr)),
                  const DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                  const DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                  const DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                ],
                onChanged: (v) => setState(() => level = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: studyType,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'search_study_type_filter'.tr),
                items: [
                  DropdownMenuItem(value: null, child: Text('filter_all'.tr)),
                  const DropdownMenuItem(value: 'online', child: Text('أونلاين')),
                  const DropdownMenuItem(value: 'offline', child: Text('حضوري')),
                  const DropdownMenuItem(value: 'hybrid', child: Text('هجين')),
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
                    child: FilledButton(
                      onPressed: () {
                        c.applyFilters(
                          cityId: cityId,
                          categoryId: categoryId,
                          level: level,
                          studyType: studyType,
                        );
                        Navigator.pop(context);
                      },
                      child: Text('search_apply_filters'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
