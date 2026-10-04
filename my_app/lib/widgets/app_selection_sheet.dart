import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// خيار واحد داخل [showAppSelectionSheet].
class AppSheetOption<T> {
  const AppSheetOption({required this.value, required this.label, required this.icon, this.subtitle});

  final T value;
  final String label;
  final IconData icon;
  final String? subtitle;
}

/// يفتح ورقة سفلية عائمة بالنمط الموحّد للتطبيق (خلفية معتمة بنفسجية، دخول ناعم وخروج أسرع).
/// المحتوى يُلفّ عادةً بـ [AppFloatingSheetFrame].
Future<void> showAppFloatingSheet({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false, // للورقة مقبضها الخاص داخل البطاقة
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x66141233),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: builder,
  );
}

/// إطار الورقة العائمة: بطاقة مدوّرة بظل ناعم، عائمة فوق حافة النظام السفلية (شريط مهام/إيماءات)
/// ومرتفعة مع لوحة المفاتيح، بمقبض ورأس (عنوان + أيقونة) اختياريين.
class AppFloatingSheetFrame extends StatelessWidget {
  const AppFloatingSheetFrame({super.key, required this.child, this.title, this.titleIcon});

  final Widget child;
  final String? title;
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + media.viewPadding.bottom + media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: AppColors.shadowPrimary, blurRadius: 32, offset: Offset(0, 10)),
                BoxShadow(color: AppColors.shadowNeutralSoft, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (titleIcon != null) ...[
                          Icon(titleIcon, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title!,
                            style: AppFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ورقة اختيار عائمة موحّدة (الترتيب، نوع البحث…): خيارات بأيقونات، ظهور متتابع،
/// نبضة واهتزاز خفيف عند الاختيار.
Future<void> showAppSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required IconData titleIcon,
  required List<AppSheetOption<T>> options,
  required T? selected,
  required ValueChanged<T> onSelected,
}) {
  return showAppFloatingSheet(
    context: context,
    builder: (sheetContext) => _SelectionSheetBody<T>(
      title: title,
      titleIcon: titleIcon,
      options: options,
      selected: selected,
      onSelected: onSelected,
    ),
  );
}

class _SelectionSheetBody<T> extends StatefulWidget {
  const _SelectionSheetBody({
    required this.title,
    required this.titleIcon,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final IconData titleIcon;
  final List<AppSheetOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  State<_SelectionSheetBody<T>> createState() => _SelectionSheetBodyState<T>();
}

class _SelectionSheetBodyState<T> extends State<_SelectionSheetBody<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late T? _current;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 560))..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Future<void> _choose(T value) async {
    if (_closing) return;
    _closing = true;
    HapticFeedback.selectionClick();
    setState(() => _current = value);
    // مهلة قصيرة ليُرى الاختيار قبل الإغلاق.
    await Future<void>.delayed(const Duration(milliseconds: 190));
    if (!mounted) return;
    Navigator.of(context).pop();
    if (value != widget.selected) widget.onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppFloatingSheetFrame(
      title: widget.title,
      titleIcon: widget.titleIcon,
      // القوائم الطويلة (مدن، جامعات…) تتمرّر داخل الورقة بدل أن تتجاوز الشاشة.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.52),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                _StaggeredRow(
                  animation: _entry,
                  index: i,
                  child: AppSelectableTile(
                    label: widget.options[i].label,
                    subtitle: widget.options[i].subtitle,
                    icon: widget.options[i].icon,
                    selected: widget.options[i].value == _current,
                    onTap: () => _choose(widget.options[i].value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ظهور متتابع: كل صف يتأخر قليلاً عن السابق (تلاشٍ + انزلاق صغير).
class _StaggeredRow extends StatelessWidget {
  const _StaggeredRow({required this.animation, required this.index, required this.child});

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.09).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// صف اختيار موحّد داخل الأوراق العائمة (اختيار منفرد أو متعدد): أيقونة/عنصر بادئ،
/// عنوان ووصف اختياري، وعلامة ✓ نابضة عند التحديد.
class AppSelectableTile extends StatelessWidget {
  const AppSelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;

  /// عنصر بادئ مخصّص بدل مربع الأيقونة (مثلاً أيقونة تصنيف).
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.985,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.09)
                    : AppColors.surfaceSoft.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  leading ??
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: selected ? Colors.white : AppColors.primary),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppFonts.tajawal(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppFonts.tajawal(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
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
