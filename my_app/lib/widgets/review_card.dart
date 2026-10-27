import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';
import 'design_system.dart';

import '../theme/app_fonts.dart';

/// بطاقة تقييم موحّدة (صفحات الدورة والمدرّس والمعهد): صورة صاحب التقييم أو أول حرف من اسمه،
/// الاسم، النجوم، واسم الدورة إن وُجد (تقييمات المدرّس والمعهد تشمل دوراتهما) أو «تقييم للمعهد». التقييم نجوم فقط: تعليق قديم إن أرسله الخادم لا يُعرض.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.showCourse = false, this.onReport});

  final ReviewModel review;
  final bool showCourse;

  /// يُظهر قائمة «إبلاغ» على البطاقة (للطالب المسجّل فقط).
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final name = review.studentName.trim();
    final image = review.resolvedStudentImageUrl;
    // في قائمة المعهد: تقييم المعهد نفسه يُوسَم بذلك، وتقييم الدورة باسمها.
    final course = review.isInstituteReview ? 'review_type_institute'.tr : review.courseTitle?.trim();
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: image != null
                      ? AppNetworkImage(url: image, width: 36, height: 36, errorWidget: _initial(name))
                      : _initial(name),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'student'.tr : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.ratingStar,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (onReport != null)
                PopupMenuButton<int>(
                  tooltip: 'review_report_title'.tr,
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (_) => onReport!(),
                  itemBuilder: (_) => [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('review_report_action'.tr),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (showCourse && course != null && course.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  review.isInstituteReview ? Icons.apartment_rounded : Icons.menu_book_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    course,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _initial(String name) {
    return ColoredBox(
      color: AppColors.indicatorFill,
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryInk),
        ),
      ),
    );
  }
}
