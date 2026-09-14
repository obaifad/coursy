import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/locale/locale_rebuild.dart';
import '../core/models/app_models.dart';
import '../core/responsive/responsive.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';

/// Bottom sheet لاختيار الاهتمامات — يدعم القوائم الطويلة والبحث.
Future<void> showInterestPickerSheet({
  required BuildContext context,
  required List<CategoryModel> categories,
  required Set<int> initialSelected,
  required ValueChanged<Set<int>> onApply,
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return AppMaxWidth(
          maxWidth: ResponsiveModals.sheetMaxWidth(context),
          child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + context.keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                'pick_interests'.tr,
                style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_interests'.tr,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.indicatorFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'interests_selected_count'.trParams({'count': '${_selected.length}'}),
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'no_results'.tr,
                          style: GoogleFonts.tajawal(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        itemBuilder: (_, i) {
                          final category = filtered[i];
                          final selected = _selected.contains(category.id);
                          return CheckboxListTile(
                            value: selected,
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            secondary: CategoryIcon(
                              category: category,
                              size: 36,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(
                              category.name,
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                            ),
                            onChanged: (_) {
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
              const SizedBox(height: 12),
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
          ),
        );
      },
    );
  }
}

String interestSelectionSummary(List<CategoryModel> categories, List<int> selectedIds) {
  if (selectedIds.isEmpty) return 'pick_interests'.tr;
  if (selectedIds.length == 1) {
    final match = categories.where((c) => c.id == selectedIds.first).firstOrNull;
    return match?.name ?? 'interests_selected_count'.trParams({'count': '1'});
  }
  return 'interests_selected_count'.trParams({'count': '${selectedIds.length}'});
}
