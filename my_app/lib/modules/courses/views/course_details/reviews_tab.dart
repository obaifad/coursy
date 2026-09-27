part of '../course_details_view.dart';

class _ReviewsTab extends GetView<CourseDetailsController> {
  const _ReviewsTab({required this.item});
  final CourseModel item;

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
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'reviews_total'.trParams({'count': '${reviews.length}'}),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                                Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: AppColors.indicatorFill,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                    child: _ReviewCard(review: r),
                  ),
                ),
          ] else
            _SectionCard(
              title: 'student_reviews'.tr,
              child: Text('no_description'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 16),
          _ReviewFormSection(item: item),
        ],
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.indicatorFill,
                child: Text(
                  review.studentName.isNotEmpty ? review.studentName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.studentName.trim().isEmpty ? 'student'.tr : review.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _ReviewFormSection extends GetView<CourseDetailsController> {
  const _ReviewFormSection({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
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
          if (item.instituteId != null) ...[
            const SizedBox(height: 8),
            _RatingRow(label: 'rate_institute'.tr, rating: controller.instituteRating),
          ],
          if (item.instructor != null) ...[
            const SizedBox(height: 8),
            _RatingRow(label: 'rate_instructor'.tr, rating: controller.instructorRating),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: controller.reviewCommentController,
            maxLines: 3,
            decoration: InputDecoration(hintText: 'review_comment_hint'.tr),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isSubmittingReview.value ? null : controller.submitReviews,
                child: Text(controller.isSubmittingReview.value ? 'submitting_review'.tr : 'submit_review'.tr),
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
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Obx(
          () => Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => rating.value = star,
                icon: Icon(
                  star <= rating.value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
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
