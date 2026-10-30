import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../core/models/app_models.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/review_card.dart';
import '../../../widgets/review_report.dart';
import '../controllers/institutes_controller.dart';

/// تبويب «التقييمات» في صفحة المعهد: الملخّص (المتوسط والعدد من الخادم)، تقييم الطالب أو نموذج
/// التقييم (نجوم فقط، بلا تعليق مكتوب)، ثم القائمة — تقييمات المعهد نفسه وتقييمات دوراته، كلٌّ موسوم بنوعه.
class InstituteReviewsTab extends StatelessWidget {
  const InstituteReviewsTab({super.key, required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final institute = controller.institute.value;
      final reviews = controller.reviews.toList(growable: false);
      final error = controller.reviewsError.value;
      if (reviews.isEmpty && error != null) {
        return AppNestedTabScrollView(
          slivers: [
            AppEmptyState.sliver(
              message: error,
              icon: Icons.cloud_off_outlined,
              action: FilledButton(onPressed: controller.loadDetails, child: Text('retry'.tr)),
            ),
          ],
        );
      }
      final padding = AppLayout.scrollPadding(context, top: 16);
      if (reviews.isEmpty && controller.isLoading.value) {
        return AppNestedTabScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            Skeletonizer.sliver(
              enabled: true,
              child: SliverPadding(
                padding: padding,
                sliver: SliverList.list(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewCard(review: _skeletonReview),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      return AppNestedTabScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverList.list(
              children: [
                _ReviewsSummary(institute: institute, reviews: reviews),
                const SizedBox(height: 16),
                _InstituteReviewForm(controller: controller),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('recent_reviews'.tr, style: AppTypography.sectionTitle()),
                  const SizedBox(height: 10),
                  for (final r in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReviewCard(
                        review: r,
                        showCourse: true,
                        onReport: controller.isLoggedIn ? () => ReviewReportFlow.start(context, r) : null,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  static final _skeletonReview = ReviewModel(id: 0, rating: 5, comment: '', studentName: 'اسم الطالب');
}

class _ReviewsSummary extends StatelessWidget {
  const _ReviewsSummary({required this.institute, required this.reviews});
  final InstituteModel? institute;
  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    // المتوسط والعدد من الخادم (يشملان كل الصفحات)؛ القائمة احتياط إن لم يرسلهما.
    final count = institute?.reviewsCount ?? reviews.length;
    final listAverage = reviews.isEmpty ? 0.0 : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final serverRating = institute?.rating ?? 0;
    final average = serverRating > 0 ? serverRating : listAverage;

    if (count <= 0 || average <= 0) {
      return SoftCard(
        child: Row(
          children: [
            const Icon(Icons.star_outline_rounded, color: AppColors.ratingStar, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'institute_no_reviews_yet'.tr,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final distribution = <int, int>{};
    for (final review in reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    return SoftCard(
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
                pluralTr('reviews_total', count),
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
                  final starCount = distribution[star] ?? 0;
                  final ratio = reviews.isEmpty ? 0.0 : starCount / reviews.length;
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
                          '$starCount',
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
    );
  }
}

/// حالات بطاقة التقييم: غير مسجّل، غير مؤهّل، له تقييم (عرض مع تعديل/حذف)، أو النموذج.
class _InstituteReviewForm extends StatelessWidget {
  const _InstituteReviewForm({required this.controller});
  final InstituteDetailsController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final institute = controller.institute.value;
    if (institute == null) return const SizedBox.shrink();

    if (!controller.isLoggedIn) {
      return _HintCard(
        title: 'institute_rate_title'.tr,
        message: 'institute_review_login_hint'.tr,
        action: TextButton(onPressed: controller.loginToReview, child: Text('login'.tr)),
      );
    }

    final mine = institute.myReview;
    final editing = controller.isEditingReview.value;

    if (mine != null && !editing) {
      final deleting = controller.isDeletingReview.value;
      return _Card(
        title: 'institute_your_review'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < mine.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.ratingStar,
                  size: 22,
                );
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: deleting ? null : controller.startEditingReview,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('institute_review_edit'.tr),
                ),
                TextButton.icon(
                  onPressed: deleting ? null : () => _confirmDelete(context),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size(0, 44)),
                  icon: deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('institute_review_delete'.tr),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (mine == null && !institute.canReview) {
      return _HintCard(title: 'institute_rate_title'.tr, message: 'institute_review_not_eligible'.tr);
    }

    final submitting = controller.isSubmittingReview.value;
    return _Card(
      title: editing && mine != null ? 'institute_review_edit_title'.tr : 'institute_rate_title'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                tooltip: 'rate_n_of_5'.trParams({'n': '$star'}),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => controller.reviewRating.value = star,
                icon: Icon(
                  star <= controller.reviewRating.value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.ratingStar,
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: RegisterGradientButton(
              label: editing && mine != null ? 'institute_review_save'.tr : 'submit_review'.tr,
              loading: submitting,
              onPressed: submitting ? null : controller.submitReview,
            ),
          ),
          if (editing && mine != null) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: submitting ? null : controller.cancelEditingReview,
                child: Text('cancel'.tr),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('institute_review_delete'.tr, style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
        content: Text('institute_review_delete_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46), backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('institute_review_delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteMyReview();
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle()),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(height: 1.4, color: AppColors.textSecondary)),
              ),
            ],
          ),
          if (action != null) Align(alignment: AlignmentDirectional.centerEnd, child: action),
        ],
      ),
    );
  }
}
