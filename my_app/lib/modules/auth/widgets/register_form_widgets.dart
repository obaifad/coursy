import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/interest_picker_sheet.dart';
import 'login_page_metrics.dart';

/// خلفية ناعمة متدرجة لشاشة التسجيل.
abstract final class RegisterDecor {
  static const LinearGradient background = LinearGradient(
    colors: [Color(0xFFF3F1FF), Color(0xFFE9E6FF), Color(0xFFF6F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient button = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x336C63FF), blurRadius: 28, offset: Offset(0, 14)),
        BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
      ];

  static TextStyle heading(BuildContext context) {
    return GoogleFonts.tajawal(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF111827),
    );
  }

  static TextStyle subheading(BuildContext context) {
    return GoogleFonts.tajawal(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.4,
    );
  }

  static TextStyle sectionLabel() {
    return GoogleFonts.tajawal(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      letterSpacing: 0.2,
    );
  }

  static InputDecoration fieldDecoration({
    required String label,
    String? hint,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool focused = false,
  }) {
    final borderColor = focused ? AppColors.primary : const Color(0xFFE5E7EB);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: focused ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
      labelStyle: GoogleFonts.tajawal(
        fontWeight: FontWeight.w600,
        color: focused ? AppColors.primary : AppColors.textSecondary,
      ),
      floatingLabelStyle: GoogleFonts.tajawal(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}

/// غلاف أبيض بعرض ثابت — يُستخدم على الموبايل فقط عند الحاجة.
class AuthUnifiedShell extends StatelessWidget {
  const AuthUnifiedShell({super.key, required this.metrics, required this.child});

  final LoginPageMetrics metrics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: RegisterDecor.cardShadow,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.horizontalPadding,
              vertical: metrics.formVerticalPadding,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class RegisterFloatingCard extends StatelessWidget {
  const RegisterFloatingCard({super.key, required this.child, this.elevated = true});

  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    if (!elevated) return child;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RegisterDecor.cardShadow,
      ),
      child: child,
    );
  }
}

class RegisterSegmentedProgress extends StatelessWidget {
  const RegisterSegmentedProgress({super.key, required this.currentStep});
  final int currentStep;

  static const _labels = [
    'register_step_personal',
    'register_step_security',
    'register_step_interests',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i <= currentStep;
            final current = i == currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 4, end: i == 2 ? 0 : 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: active
                        ? (current
                            ? RegisterDecor.button
                            : const LinearGradient(colors: [AppColors.primaryLight, AppColors.primaryLight]))
                        : null,
                    color: active ? null : AppColors.indicatorFill,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (i) {
            final active = i == currentStep;
            final done = i < currentStep;
            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active || done ? AppColors.primary : AppColors.indicatorFill,
                      border: Border.all(
                        color: active ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.tajawal(
                                color: active ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i].tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RegisterFloatingField extends StatefulWidget {
  const RegisterFloatingField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  State<RegisterFloatingField> createState() => _RegisterFloatingFieldState();
}

class _RegisterFloatingFieldState extends State<RegisterFloatingField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      style: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: RegisterDecor.fieldDecoration(
        label: widget.label,
        hint: widget.hint,
        errorText: widget.errorText,
        focused: _focused,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, color: _focused ? AppColors.primary : AppColors.textSecondary),
        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}

class RegisterGradientButton extends StatelessWidget {
  const RegisterGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.success = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading && !success;
    return AnimatedOpacity(
      opacity: enabled || loading || success ? 1 : 0.65,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: (enabled || loading || success)
              ? RegisterDecor.button
              : const LinearGradient(colors: [Color(0xFFB8B5E8), Color(0xFFB8B5E8)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: (enabled || loading || success)
              ? const [BoxShadow(color: Color(0x446C63FF), blurRadius: 16, offset: Offset(0, 8))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 52,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: AppInlineLoader(color: Colors.white),
                      )
                    : success
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                        : Text(
                            label,
                            style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterGhostButton extends StatelessWidget {
  const RegisterGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primaryText = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primaryText;

  @override
  Widget build(BuildContext context) {
    final color = primaryText ? AppColors.primary : AppColors.textSecondary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: color,
        side: BorderSide(color: primaryText ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.transparent,
      ),
      child: Text(label, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
    );
  }
}

class RegisterChoiceChip extends StatelessWidget {
  const RegisterChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Material(
        color: selected ? AppColors.primary : AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Text(
                  label,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : const Color(0xFF374151),
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

Future<void> showCityPickerSheet({
  required BuildContext context,
  required List<CityModel> cities,
  required int? initialSelected,
  required ValueChanged<int> onPick,
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
        builder: (context) {
          var selected = initialSelected;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'pick_city'.tr,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (_, i) {
                      final city = cities[i];
                      final isSelected = selected == city.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                        title: Text(city.name, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          onPick(city.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class RegisterCityPicker extends StatelessWidget {
  const RegisterCityPicker({
    super.key,
    required this.cities,
    required this.selectedId,
    required this.onChanged,
    this.loading = false,
    this.errorText,
    this.onReload,
  });

  final List<CityModel> cities;
  final int? selectedId;
  final ValueChanged<int> onChanged;
  final bool loading;
  final String? errorText;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return LocaleRebuild(
      builder: (context) {
        final label = '${'city'.tr} *';

        if (loading && cities.isEmpty) {
          return Skeletonizer(
            enabled: true,
            child: InputDecorator(
              decoration: RegisterDecor.fieldDecoration(
                label: label,
                prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
              ),
              child: Text(
                'loading_cities'.tr,
                style: GoogleFonts.tajawal(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        if (cities.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputDecorator(
                decoration: RegisterDecor.fieldDecoration(
                  label: label,
                  errorText: errorText ?? 'connection_error'.tr,
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                ),
                child: Text('pick_city'.tr, style: GoogleFonts.tajawal(color: AppColors.textSecondary)),
              ),
              if (onReload != null) ...[
                const SizedBox(height: 8),
                RegisterGhostButton(
                  label: 'reload_cities'.tr,
                  onPressed: onReload,
                ),
              ],
            ],
          );
        }

        final selected = cities.where((c) => c.id == selectedId).firstOrNull;

        return InkWell(
          onTap: () {
            showCityPickerSheet(
              context: context,
              cities: cities,
              initialSelected: selectedId,
              onPick: onChanged,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: RegisterDecor.fieldDecoration(
              label: label,
              errorText: errorText,
              prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
            ),
            child: Text(
              selected?.name ?? 'pick_city'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
                color: selected == null ? AppColors.textSecondary : const Color(0xFF111827),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RegisterInterestPicker extends StatelessWidget {
  const RegisterInterestPicker({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onApply,
    this.loading = false,
    this.errorText,
    this.onReload,
  });

  final List<CategoryModel> categories;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onApply;
  final bool loading;
  final String? errorText;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return LocaleRebuild(
      builder: (context) {
    if (loading) {
      return Skeletonizer(
        enabled: true,
        child: InputDecorator(
          decoration: RegisterDecor.fieldDecoration(
            label: 'interests_optional'.tr,
            prefixIcon: const Icon(Icons.interests_rounded, color: AppColors.primary),
          ),
          child: Text('pick_interests'.tr, style: GoogleFonts.tajawal(color: AppColors.textSecondary)),
        ),
      );
    }

    if (categories.isEmpty) {
      final summary = selectedIds.isEmpty
          ? 'pick_interests'.tr
          : interestSelectionSummary(categories, selectedIds);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: RegisterDecor.fieldDecoration(
              label: 'interests_optional'.tr,
              errorText: selectedIds.isEmpty ? (errorText ?? 'connection_error'.tr) : errorText,
              prefixIcon: const Icon(Icons.interests_rounded, color: AppColors.primary),
            ),
            child: Text(
              summary,
              style: GoogleFonts.tajawal(
                color: selectedIds.isEmpty ? AppColors.textSecondary : const Color(0xFF111827),
                fontWeight: selectedIds.isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          if (onReload != null) ...[
            const SizedBox(height: 8),
            RegisterGhostButton(
              label: 'reload_interests'.tr,
              onPressed: onReload,
            ),
          ],
        ],
      );
    }

    final summary = interestSelectionSummary(categories, selectedIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            showInterestPickerSheet(
              context: context,
              categories: categories,
              initialSelected: selectedIds.toSet(),
              onApply: (ids) => onApply(ids.toList()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: RegisterDecor.fieldDecoration(
              label: 'interests_optional'.tr,
              errorText: errorText,
              prefixIcon: const Icon(Icons.interests_rounded, color: AppColors.primary),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
            ),
            child: Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
                color: selectedIds.isEmpty ? AppColors.textSecondary : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

class RegisterInterestChips extends StatelessWidget {
  const RegisterInterestChips({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    this.loading = false,
  });

  final List<CategoryModel> categories;
  final List<int> selectedIds;
  final ValueChanged<int> onToggle;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return LocaleRebuild(
      builder: (context) {
    if (loading) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          5,
          (_) => Container(
            width: 96,
            height: 38,
            decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final selected = selectedIds.contains(category.id);
        return RegisterChoiceChip(
          label: category.name,
          selected: selected,
          leading: CategoryIcon(category: category, size: 22, borderRadius: BorderRadius.circular(6)),
          onTap: () => onToggle(category.id),
        );
      }).toList(),
    );
      },
    );
  }
}

class RegisterDateField extends StatelessWidget {
  const RegisterDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: RegisterDecor.fieldDecoration(
              label: label,
              errorText: errorText,
              prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            ),
            child: Text(
              value ?? 'pick_date'.tr,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
                color: value == null ? AppColors.textSecondary : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
