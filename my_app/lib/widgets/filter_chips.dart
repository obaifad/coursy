import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_selection_sheet.dart';
import 'app_widgets.dart';
import 'design_system.dart';
import '../theme/app_motion.dart';

import '../theme/app_fonts.dart';

class HorizontalCategoryFilters extends StatelessWidget {
  const HorizontalCategoryFilters({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.startInset,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  /// حشوة بداية الصف (افتراضياً هامش الصفحة) — 0 حين يسبقه زر في الصف نفسه.
  final double? startInset;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return AppHorizontalScrollRow(
      height: 44,
      separatorWidth: 8,
      startInset: startInset,
      children: [
        _FilterChip(label: 'filter_all'.tr, selected: selectedId == null, onTap: () => onSelected(null)),
        for (final cat in categories)
          _FilterChip(label: cat.name, selected: selectedId == cat.id, category: cat, onTap: () => onSelected(cat.id)),
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
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
  const _SubjectFilterChip({required this.subject, required this.selected, required this.onTap});

  final InstructorSubjectModel subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryStrong : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.shadowPrimary, blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InstructorSubjectIcon(
              subject: subject,
              size: 16,
              borderRadius: BorderRadius.circular(AppRadius.xs),
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
                fontSize: AppTextSize.sm,
                color: selected ? Colors.white : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseSortDropdown extends StatelessWidget {
  const CourseSortDropdown({super.key, required this.selected, required this.onSelected});

  final CourseSortOption selected;
  final ValueChanged<CourseSortOption> onSelected;

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
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: () => showCourseSortSheet(context: context, selected: selected, onSelected: onSelected),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected.labelKey.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextSize.sm,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// زر الترتيب المدمج: أيقونة 44px في نهاية صف التصنيفات (بدل صف «الترتيب» مستقل). نقطة صغيرة تدلّ على أن
/// الترتيب ليس الافتراضي (الأحدث). يفتح ورقة الاختيار نفسها.
class CourseSortButton extends StatelessWidget {
  const CourseSortButton({super.key, required this.selected, required this.onSelected});

  final CourseSortOption selected;
  final ValueChanged<CourseSortOption> onSelected;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final label = 'sort_by'.tr;
    final custom = selected != CourseSortOption.newest;
    return Semantics(
      button: true,
      label: '$label: ${selected.labelKey.tr}',
      child: Tooltip(
        message: label,
        child: Material(
          color: custom ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.primary.withValues(alpha: custom ? 0.5 : 0.22)),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            onTap: () => showCourseSortSheet(context: context, selected: selected, onSelected: onSelected),
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 22, color: AppColors.primary.withValues(alpha: 0.9)),
                  if (custom)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const SizedBox.square(dimension: 8),
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

/// ورقة اختيار ترتيب الدورات (عائمة، بأيقونات، بأنيميشن متتابع).
Future<void> showCourseSortSheet({
  required BuildContext context,
  required CourseSortOption selected,
  required ValueChanged<CourseSortOption> onSelected,
}) {
  IconData iconFor(CourseSortOption option) => switch (option) {
    CourseSortOption.newest => Icons.schedule_rounded,
    CourseSortOption.ratingHigh => Icons.star_rounded,
    CourseSortOption.priceLow => Icons.trending_down_rounded,
    CourseSortOption.priceHigh => Icons.trending_up_rounded,
  };
  return showAppSelectionSheet<CourseSortOption>(
    context: context,
    title: 'sort_by_title'.tr,
    titleIcon: Icons.swap_vert_rounded,
    selected: selected,
    onSelected: onSelected,
    options: [
      for (final option in CourseSortOption.values)
        AppSheetOption<CourseSortOption>(value: option, label: option.labelKey.tr, icon: iconFor(option)),
    ],
  );
}

class HorizontalCityFilters extends StatelessWidget {
  const HorizontalCityFilters({super.key, required this.cities, required this.selectedId, required this.onSelected});

  final List<CityModel> cities;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    // مدينة واحدة فقط → الفلتر بلا فائدة.
    if (cities.length < 2) return const SizedBox.shrink();
    return AppHorizontalScrollRow(
      height: 44,
      separatorWidth: 8,
      children: [
        _FilterChip(label: 'filter_all_cities'.tr, selected: selectedId == null, onTap: () => onSelected(null)),
        for (final city in cities)
          _FilterChip(label: city.name, selected: selectedId == city.id, onTap: () => onSelected(city.id)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.category});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryStrong : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.shadowPrimary, blurRadius: 10, offset: Offset(0, 4))]
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
                fontSize: AppTextSize.sm,
                color: selected ? Colors.white : AppColors.textBody,
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
      borderRadius: BorderRadius.circular(AppRadius.xs),
      iconColor: selected ? Colors.white : AppColors.primary,
      backgroundColor: selected ? Colors.white.withValues(alpha: 0.22) : AppColors.primary.withValues(alpha: 0.1),
    );
  }
}
