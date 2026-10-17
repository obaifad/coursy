part of '../app_widgets.dart';

/// الدورة كبطاقة صفّية ([AppRowCard]): الصورة في جهة البداية، العنوان والمعهد، ثم سطر يجمع
/// المدة والتقييم في جهة البداية والسعر في جهة النهاية. للمفضلة ونتائج البحث.
class CourseRowCard extends StatelessWidget {
  const CourseRowCard({super.key, required this.course, this.onTap, this.trailing});

  final CourseModel course;
  final VoidCallback? onTap;

  /// في نهاية سطر العنوان (زر القلب في المفضلة).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final city = course.instituteCity?.trim() ?? '';
    final institute = [course.institute.trim(), city].where((p) => p.isNotEmpty).join(' • ');
    final duration = course.duration;
    final percent = course.originalPriceLabel == null ? null : course.discountPercent;

    return AppRowCard(
      onTap: onTap,
      leading: _CourseCardImage(course: course, borderRadius: BorderRadius.zero, fallbackSize: 26),
      title: AppRowTitle(course.title),
      trailing: trailing,
      subtitle: institute.isEmpty ? null : AppRowMeta(icon: Icons.apartment_rounded, text: institute),
      // البيانات تأخذ 5/9 من العرض والسعر حتى 4/9 (يصغر بدل أن يدفع البيانات خارج البطاقة).
      footer: Row(
        children: [
          Expanded(
            flex: 5,
            child: AppRowMetaLine(
              items: [
                if (duration.isNotEmpty && duration != '—') AppRowMeta(icon: Icons.schedule_rounded, text: duration),
                CourseRatingBadge(course: course, showCount: false),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (percent != null) ...[_DiscountPill(percent: percent), const SizedBox(width: 6)],
                    CoursePriceText(price: course.price, amountSize: AppTextSize.lg, currencySize: AppTextSize.xs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
