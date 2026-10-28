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
    final duration = _shortDuration(course);
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
              spacing: 8,
              items: [
                if (duration != null) AppRowMeta(icon: Icons.schedule_rounded, text: duration),
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

/// المدة مختصرة («120 س» / «16 ج»): بجانب التقييم والسعر لا يبقى للمدة على هاتف 360 إلا ~40، فكانت
/// «120 ساعة» تُقصّ إلى «120…».
String? _shortDuration(CourseModel course) {
  final hours = course.durationHours ?? 0;
  if (hours > 0) return 'hours_short'.trParams({'n': '$hours'});
  final sessions = course.sessionsCount ?? 0;
  if (sessions > 0) return 'sessions_short'.trParams({'n': '$sessions'});
  return null;
}
