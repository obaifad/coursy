import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';
import 'design_system.dart';

class CourseFiltersPanel extends StatelessWidget {
  const CourseFiltersPanel({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.selectedSort,
    required this.onSortSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final CourseSortOption selectedSort;
  final ValueChanged<CourseSortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final inset = AppLayout.horizontalPage(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (categories.isNotEmpty) ...[
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('filter_categories'.tr, style: AppTypography.filterSectionLabel()),
            ),
          ),
          HorizontalCategoryFilters(
            categories: categories,
            selectedId: selectedCategoryId,
            onSelected: onCategorySelected,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, 0),
            child: Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          const SizedBox(height: 14),
        ],
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CourseSortDropdown(
              selected: selectedSort,
              onSelected: onSortSelected,
            ),
          ),
        ),
      ],
    );
  }
}

class HorizontalCategoryFilters extends StatelessWidget {
  const HorizontalCategoryFilters({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return AppHorizontalScrollRow(
      height: 44,
      separatorWidth: 8,
      children: [
        _FilterChip(
          label: 'filter_all'.tr,
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        for (final cat in categories)
          _FilterChip(
            label: cat.name,
            selected: selectedId == cat.id,
            category: cat,
            onTap: () => onSelected(cat.id),
          ),
      ],
    );
  }
}

class InstructorSpecializationFiltersPanel extends StatelessWidget {
  const InstructorSpecializationFiltersPanel({
    super.key,
    required this.subjects,
    required this.selectedKey,
    required this.onSelected,
    this.isLoading = false,
  });

  final List<InstructorSubjectModel> subjects;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && subjects.isEmpty) return const SizedBox.shrink();

    final inset = AppLayout.horizontalPage(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('filter_specializations'.tr, style: AppTypography.filterSectionLabel()),
          ),
        ),
        if (isLoading)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, 0),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, __) => Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          )
        else
          HorizontalInstructorSubjectFilters(
            subjects: subjects,
            selectedKey: selectedKey,
            onSelected: onSelected,
            allLabel: 'filter_all'.tr,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class HorizontalInstructorSubjectFilters extends StatelessWidget {
  const HorizontalInstructorSubjectFilters({
    super.key,
    required this.subjects,
    required this.selectedKey,
    required this.onSelected,
    this.allLabel,
  });

  final List<InstructorSubjectModel> subjects;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();
    return AppHorizontalScrollRow(
      height: 44,
      separatorWidth: 8,
      children: [
        _FilterChip(
          label: allLabel ?? 'filter_all_subjects'.tr,
          selected: selectedKey == null,
          onTap: () => onSelected(null),
        ),
        for (final subject in subjects)
          _SubjectFilterChip(
            subject: subject,
            selected: selectedKey == subject.key,
            onTap: () => onSelected(subject.key),
          ),
      ],
    );
  }
}

class _SubjectFilterChip extends StatelessWidget {
  const _SubjectFilterChip({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final InstructorSubjectModel subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x336C63FF), blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InstructorSubjectIcon(
              subject: subject,
              size: 16,
              borderRadius: BorderRadius.circular(6),
              iconColor: selected ? Colors.white : AppColors.primary,
              backgroundColor: selected
                  ? Colors.white.withValues(alpha: 0.22)
                  : AppColors.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 6),
            Text(
              subject.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseSortDropdown extends StatelessWidget {
  const CourseSortDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CourseSortOption selected;
  final ValueChanged<CourseSortOption> onSelected;

  static const _options = CourseSortOption.values;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.75)),
        const SizedBox(width: 6),
        Text('sort_by'.tr, style: AppTypography.filterSectionLabel()),
        const SizedBox(width: 10),
        PopupMenuButton<CourseSortOption>(
          initialValue: selected,
          onSelected: onSelected,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (context) => [
            for (final option in _options)
              PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (option == selected)
                      const Icon(Icons.check_rounded, size: 18, color: AppColors.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(
                      option.labelKey.tr,
                      style: TextStyle(
                        fontWeight: option == selected ? FontWeight.w800 : FontWeight.w600,
                        color: option == selected ? AppColors.primary : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.labelKey.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HorizontalCityFilters extends StatelessWidget {
  const HorizontalCityFilters({
    super.key,
    required this.cities,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CityModel> cities;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();
    return AppHorizontalScrollRow(
      height: 44,
      separatorWidth: 8,
      children: [
        _FilterChip(
          label: 'filter_all_cities'.tr,
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        for (final city in cities)
          _FilterChip(
            label: city.name,
            selected: selectedId == city.id,
            onTap: () => onSelected(city.id),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.category,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF7F6FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x336C63FF), blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (category != null) ...[
              _ChipCategoryIcon(category: category!, selected: selected),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipCategoryIcon extends StatelessWidget {
  const _ChipCategoryIcon({required this.category, required this.selected});
  final CategoryModel category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CategoryIcon(
      category: category,
      size: 22,
      borderRadius: BorderRadius.circular(7),
      iconColor: selected ? Colors.white : AppColors.primary,
      backgroundColor: selected
          ? Colors.white.withValues(alpha: 0.22)
          : AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

