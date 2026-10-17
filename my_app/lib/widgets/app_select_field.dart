import 'package:flutter/material.dart';

import '../modules/auth/widgets/register_form_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_selection_sheet.dart';

/// حقل اختيار موحّد يحلّ محل القوائم المنسدلة القديمة (Dropdown): نفس شكل حقول النماذج،
/// وعند الضغط تفتح ورقة الاختيار العائمة ([showAppSelectionSheet]).
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
    this.sheetTitle,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<AppSheetOption<T>> options;

  /// القيمة الحالية (null = لا شيء محدد بعد).
  final T? value;
  final ValueChanged<T> onChanged;

  /// عنوان الورقة (افتراضياً نص الحقل بلا النجمة).
  final String? sheetTitle;
  final String? errorText;
  final bool enabled;

  AppSheetOption<T>? get _selectedOption {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    final hasValue = selected != null; // خيار قيمته null (مثل «الكل») يُعرض كاختيار فعلي
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: !enabled || options.isEmpty
            ? null
            : () => showAppSelectionSheet<T>(
                context: context,
                title: sheetTitle ?? label.replaceAll('*', '').trim(),
                titleIcon: icon,
                options: options,
                selected: value,
                onSelected: onChanged,
              ),
        child: InputDecorator(
          isEmpty: false,
          decoration: RegisterDecor.fieldDecoration(
            label: label,
            errorText: errorText,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
          ),
          child: Text(
            hasValue ? selected.label : hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
              color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
