import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';

/// للزائر غير المسجّل: دعوة لإنشاء حساب أو تصفّح الدورات.
class GuestSignUpBanner extends StatelessWidget {
  const GuestSignUpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [BoxShadow(color: AppColors.shadowPrimary, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'guest_banner_title'.tr,
                      style: AppFonts.tajawal(
                        fontSize: AppTextSize.xl,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'guest_banner_subtitle'.tr,
                      style: AppFonts.tajawal(
                        fontSize: AppTextSize.sm,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.event_seat_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // الزر المرئي 44 كما هو، ومساحة اللمس 48 (tapTargetSize.padded) — كان SizedBox(44) يحصر اللمس في 44.
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    textStyle: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('register'.tr, maxLines: 1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => AppNavigation.switchToTab(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    textStyle: AppFonts.tajawal(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('browse_courses_short'.tr, maxLines: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
