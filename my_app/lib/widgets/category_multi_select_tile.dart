import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'interest_picker_sheet.dart';

class CategoryMultiSelectTile extends StatelessWidget {
  const CategoryMultiSelectTile({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onApply,
    this.compact = false,
  });

  final List<CategoryModel> categories;
  final RxList<int> selectedIds;
  final ValueChanged<List<int>> onApply;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ids = selectedIds.toList();
      final summary = interestSelectionSummary(categories, ids);

      if (compact) {
        return Material(
          color: AppColors.indicatorFill,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _showPicker(context, ids.toSet()),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ids.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      }

      return Material(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: const Icon(Icons.interests_rounded, color: AppColors.primary),
          title: Text('interests_optional'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.keyboard_arrow_down_rounded),
          onTap: () => _showPicker(context, ids.toSet()),
        ),
      );
    });
  }

  void _showPicker(BuildContext context, Set<int> initialSelected) {
    showInterestPickerSheet(
      context: context,
      categories: categories,
      initialSelected: initialSelected,
      onApply: (selected) => onApply(selected.toList()),
    );
  }
}
