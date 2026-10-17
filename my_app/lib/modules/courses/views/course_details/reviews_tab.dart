part of '../course_details_view.dart';

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.item, required this.controller});
  final CourseModel item;
  final CourseDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reviews = controller.reviews;
      final average = _reviewAverage(reviews);
      final distribution = _ratingDistribution(reviews);

      return _CourseTabScrollBody(
        children: [
          if (reviews.isNotEmpty) ...[
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: AppTextSize.display,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryInk,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.ratingStar,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pluralTr('reviews_total', reviews.length),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'rating_distribution'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.sm),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(5, (i) {
                          final star = 5 - i;
                          final count = distribution[star] ?? 0;
                          final ratio = reviews.isEmpty ? 0.0 : count / reviews.length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text(
                                  '$star',
                                  style: const TextStyle(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: AppColors.indicatorFill,
                                      color: AppColors.ratingStar,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$count',
                                  style: const TextStyle(fontSize: AppTextSize.xs, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('recent_reviews'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 10),
            ...reviews
                .take(8)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReviewCard(
                      review: r,
                      onReport: controller.isLoggedIn ? () => ReviewReportFlow.start(context, r) : null,
                    ),
                  ),
                ),
          ] else
            _SectionCard(
              title: 'student_reviews'.tr,
              child: Text('no_reviews_yet'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 16),
          _ReviewFormSection(item: item, controller: controller),
        ],
      );
    });
  }
}

/// داخل Obx خاص به: Obx الأب يتتبّع التقييمات فقط، فكان الهيكل (أو «غير مسجّل») يبقى بعد انتهاء
/// التحقق من التسجيل حتى تبديل التبويب.
class _ReviewFormSection extends StatelessWidget {
  const _ReviewFormSection({required this.item, required this.controller});
  final CourseModel item;
  final CourseDetailsController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    if (!controller.isLoggedIn) return const SizedBox.shrink();

    if (controller.isCheckingEnrollment.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Skeletonizer(
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, width: double.infinity, color: AppColors.indicatorFill),
              const SizedBox(height: 10),
              Container(height: 80, width: double.infinity, color: AppColors.indicatorFill),
            ],
          ),
        ),
      );
    }

    if (!controller.isEnrolled.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.hasCourseEnrollment.value ? 'review_completed_required'.tr : 'review_not_enrolled_hint'.tr,
                style: const TextStyle(height: 1.4, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.hasSubmittedReview.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('review_once_only'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'add_review'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatingRow(label: 'rate_course'.tr, rating: controller.courseRating),
          const SizedBox(height: 12),
          TextField(
            controller: controller.reviewCommentController,
            maxLines: 3,
            // منطقة التمرير تمتد تحت لوحة المفاتيح: نرفع الحقل وزر الإرسال فوقها.
            scrollPadding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 96),
            decoration: InputDecoration(hintText: 'review_comment_hint'.tr),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: RegisterGradientButton(
                label: 'submit_review'.tr,
                loading: controller.isSubmittingReview.value,
                onPressed: controller.isSubmittingReview.value ? null : controller.submitReviews,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.rating});
  final String label;
  final RxInt rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Obx(
          () => Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                tooltip: 'rate_n_of_5'.trParams({'n': '$star'}),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => rating.value = star,
                icon: Icon(
                  star <= rating.value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.ratingStar,
                  size: 22,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

double _reviewAverage(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
}

Map<int, int> _ratingDistribution(List<ReviewModel> reviews) {
  final map = <int, int>{};
  for (final review in reviews) {
    map[review.rating] = (map[review.rating] ?? 0) + 1;
  }
  return map;
}
