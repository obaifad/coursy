import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'app_widgets.dart';
import 'design_system.dart';

/// بطاقة تقييم موحّدة (صفحة الدورة وصفحة المدرّس): صورة صاحب التقييم أو أول حرف من اسمه،
/// الاسم، النجوم، واسم الدورة إن وُجد (تقييمات المدرّس تشمل كل دوراته)، ثم التعليق.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.showCourse = false});

  final ReviewModel review;
  final bool showCourse;

  @override
  Widget build(BuildContext context) {
    final name = review.studentName.trim();
    final image = review.resolvedStudentImageUrl;
    final course = review.courseTitle?.trim();
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
            ],
          ),
          if (showCourse && course != null && course.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    course,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
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
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ),
    );
  }
}
