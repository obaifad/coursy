part of '../design_system.dart';

/// «Compact Row»: بطاقة صفّية بارتفاع 118px — الصورة/الشعار في جهة البداية، ثم العنوان والسطر الوصفي،
/// وسطر سفلي يجمع البيانات (المدة، التقييم…) والسعر أفقياً لقراءة سريعة. تُستخدم في قوائم المعاهد
/// والمفضلة ونتائج البحث ودوراتي. مع تكبير الخط يطول الصف بدل أن تتداخل نصوصه.
class AppRowCard extends StatelessWidget {
  const AppRowCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.footer,
    this.trailing,
    this.below,
    this.onTap,
  });

  static const double height = 118;
  static const double padding = 12;

  /// الصورة مربّعة بارتفاع الصف ناقص الحشوة.
  static const double thumbSize = height - padding * 2;

  /// الصورة أو الشعار — يُعرض مربّعاً بزوايا [AppRadius.sm].
  final Widget leading;
  final Widget title;
  final Widget? subtitle;

  /// السطر السفلي (بيانات + سعر)، ملتصق بأسفل الصف بمحاذاة أسفل الصورة.
  final Widget? footer;

  /// في نهاية سطر العنوان (زر المفضلة، شارة الحالة…).
  final Widget? trailing;

  /// محتوى إضافي تحت الصف بفاصل (أزرار الحجز في دوراتي).
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox.square(
              dimension: thumbSize,
              child: ClipRRect(borderRadius: AppCorners.sm, child: leading),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: thumbSize),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: title),
                          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                        ],
                      ),
                      if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
                    ],
                  ),
                  if (footer != null) ...[const SizedBox(height: 8), footer!],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppCorners.md,
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppCorners.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: below == null
                ? row
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      row,
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1, color: AppColors.borderNeutral),
                      ),
                      below!,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// عنوان الصف: سطران كحد أقصى، 15px بوزن العناوين.
class AppRowTitle extends StatelessWidget {
  const AppRowTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return BidiText(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle());
  }
}

/// معلومة صغيرة بأيقونة (المدينة، المدة، عدد الدورات…).
class AppRowMeta extends StatelessWidget {
  const AppRowMeta({super.key, required this.icon, required this.text, this.iconColor, this.emphasized = false});

  final IconData icon;
  final String text;
  final Color? iconColor;

  /// قيمة بارزة (التقييم): نص أغمق بوزن التسميات.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: BidiText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.sm,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
              color: emphasized ? AppColors.textBody : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// صف معلومات أفقي: كل عنصر بحجمه الطبيعي، ويُقصّ بـ «…» بدل أن يتجاوز العرض.
class AppRowMetaLine extends StatelessWidget {
  const AppRowMetaLine({super.key, required this.items, this.spacing = 12});

  final List<Widget> items;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(width: spacing), Flexible(child: items[i])],
      ],
    );
  }
}
