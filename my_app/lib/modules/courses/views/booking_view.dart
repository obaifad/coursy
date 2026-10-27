import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/app_widgets.dart';
import '../controllers/booking_controller.dart';
import '../../auth/widgets/register_form_widgets.dart';

import '../../../theme/app_fonts.dart';

class CourseBookingView extends GetView<BookingController> {
  const CourseBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller.course;
    return Scaffold(
      appBar: AppBar(title: Text('booking_confirm_title'.tr)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(c.institute, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.bar_chart_rounded, label: c.level),
                    if (c.studyType != null) _InfoChip(icon: Icons.laptop_mac_rounded, label: c.studyType!),
                  ],
                ),
                const SizedBox(height: 14),
                CoursePriceText(price: c.price, amountSize: AppTextSize.xxl, currencySize: AppTextSize.sm),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('after_booking_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text('• ${'after_booking_1'.tr}', style: const TextStyle(height: 1.5)),
                Text('• ${'after_booking_2'.tr}', style: const TextStyle(height: 1.5)),
                Text('• ${'after_booking_3'.tr}', style: const TextStyle(height: 1.5)),
                if (c.requiresAdvancePayment)
                  Text(
                    '• ${(c.isOnline ? 'after_booking_advance_online' : 'after_booking_advance').tr}',
                    style: const TextStyle(height: 1.5, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => RegisterGradientButton(
              label: 'confirm_booking'.tr,
              loading: controller.isSubmitting.value,
              onPressed: controller.isSubmitting.value ? null : controller.confirmBooking,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: AppTextSize.xs, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
