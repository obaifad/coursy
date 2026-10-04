import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_fonts.dart';
import '../core/locale/locale_rebuild.dart';
import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_selection_sheet.dart';
import 'app_widgets.dart';
import '../core/locale/plural.dart';

/// ورقة عائمة لاختيار الاهتمامات (اختيار متعدد) — تدعم القوائم الطويلة والبحث.
Future<void> showInterestPickerSheet({
  required BuildContext context,
  required List<CategoryModel> categories,
  required Set<int> initialSelected,
  required ValueChanged<Set<int>> onApply,
  String? title,
}) {
  return showAppFloatingSheet(
    context: context,
    builder: (context) {
      return LocaleRebuild(
        builder: (context) => _InterestPickerSheetBody(
          categories: categories,
          initialSelected: initialSelected,
          onApply: onApply,
          title: title ?? 'interests_optional'.tr,
        ),
      );
    },
  );
}

class _InterestPickerSheetBody extends StatefulWidget {
  const _InterestPickerSheetBody({
    required this.categories,
    required this.initialSelected,
    required this.onApply,
    required this.title,
  });

  final List<CategoryModel> categories;
  final Set<int> initialSelected;
  final ValueChanged<Set<int>> onApply;
  final String title;

  @override
  State<_InterestPickerSheetBody> createState() => _InterestPickerSheetBodyState();
}

class _InterestPickerSheetBodyState extends State<_InterestPickerSheetBody> {
  late Set<int> _selected;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filtered {
    if (_query.isEmpty) return widget.categories;
    return widget.categories
        .where(
          (c) =>
              c.name.toLowerCase().contains(_query) ||
              c.nameAr.toLowerCase().contains(_query) ||
              c.nameEn.toLowerCase().contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return AppFloatingSheetFrame(
      title: widget.title,
      titleIcon: Icons.interests_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('pick_interests'.tr, style: AppFonts.tajawal(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'search_interests'.tr,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.indicatorFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                pluralTr('interests_selected_count', _selected.length),
                style: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('no_results'.tr, style: AppFonts.tajawal(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final category = filtered[i];
                      final selected = _selected.contains(category.id);
                      return AppSelectableTile(
                        label: category.name,
                        selected: selected,
                        leading: CategoryIcon(category: category, size: 38, borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) {
                              _selected.remove(category.id);
                            } else {
                              _selected.add(category.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              widget.onApply(_selected);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('done'.tr),
          ),
        ],
      ),
    );
  }
}

String interestSelectionSummary(List<CategoryModel> categories, List<int> selectedIds) {
  if (selectedIds.isEmpty) return 'pick_interests'.tr;
  if (selectedIds.length == 1) {
    final match = categories.where((c) => c.id == selectedIds.first).firstOrNull;
    return match?.name ?? pluralTr('interests_selected_count', 1);
  }
  return pluralTr('interests_selected_count', selectedIds.length);
}
