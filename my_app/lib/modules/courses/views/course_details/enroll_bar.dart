part of '../course_details_view.dart';

class _StickyEnrollBar extends StatelessWidget {
  const _StickyEnrollBar({
    required this.item,
    required this.hasRegisteredEnrollment,
    required this.enrollmentResolved,
    required this.onBook,
    required this.onRegistrationClosed,
  });

  final CourseModel item;
  final bool hasRegisteredEnrollment;
  final bool enrollmentResolved;
  final VoidCallback onBook;
  final VoidCallback onRegistrationClosed;

  @override
  Widget build(BuildContext context) {
    final registrationClosed = item.isRegistrationClosed;
    final alreadyRegistered = hasRegisteredEnrollment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: const [
          BoxShadow(color: AppColors.shadowPrimary, blurRadius: 18, offset: Offset(0, -6)),
          BoxShadow(color: AppColors.shadowNeutral, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          // السعر في جهة البداية والزر في جهة النهاية — يتبع اتجاه اللغة (كان مثبتاً على RTL حتى بالإنجليزية).
          // المفضلة في شريط الغلاف المثبّت فوق، بنفس زر البطاقات.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StickyPriceColumn(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: registrationClosed
                    ? OutlinedButton(
                        onPressed: onRegistrationClosed,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppColors.warningText,
                          side: const BorderSide(color: AppColors.warningBorder),
                          backgroundColor: AppColors.warningSoft,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        child: Text(
                          'registration_closed_action'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.md),
                        ),
                      )
                    : RegisterGradientButton(
                        label: alreadyRegistered ? 'enrollment_registered'.tr : 'book_now'.tr,
                        // الحالة غير معروفة بعد → زر بمؤشر تحميل بدل عرض حالة مؤقتة ثم تبديلها.
                        loading: !enrollmentResolved,
                        onPressed: alreadyRegistered || !enrollmentResolved ? null : onBook,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyStrikethroughPrice extends StatelessWidget {
  const _StickyStrikethroughPrice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: AppTextSize.xs,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        text,
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(widthFactor: 1, child: Container(height: 1.1, color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }
}

class _StickyPriceColumn extends StatelessWidget {
  const _StickyPriceColumn({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.hasDiscount && item.originalPriceLabel != null)
          _StickyStrikethroughPrice(label: item.originalPriceLabel!),
        CoursePriceText(price: item.price, amountSize: AppTextSize.xxl, currencySize: AppTextSize.xs),
      ],
    );
  }
}
