import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/app_models.dart';
import '../core/models/json_helpers.dart';
import '../core/responsive/responsive.dart';
import '../theme/app_colors.dart';

/// نافذة منبثقة عند انتهاء فترة التسجيل في الدورة.
class RegistrationClosedDialog extends StatelessWidget {
  const RegistrationClosedDialog({super.key, required this.course});

  final CourseModel course;

  static Future<void> show(CourseModel course) {
    return Get.dialog<void>(
      RegistrationClosedDialog(course: course),
      barrierDismissible: true,
    );
  }

  Future<void> _callInstitute(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^\d+]+'), '');
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    await Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      'registration_closed_phone_copied_title'.tr,
      'registration_closed_phone_copied_msg'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contact = course.primaryInstituteContact;
    final deadline = course.registrationDeadline;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveModals.dialogMaxWidth(context)),
        child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'registration_closed_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text(
              'registration_closed_message'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (deadline != null && deadline.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD8A8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFE67700)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'registration_closed_deadline'.trParams({
                          'date': JsonHelpers.formatDisplayDate(deadline),
                        }),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9C4A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'registration_closed_institute_label'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.institute,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  if (contact != null) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _callInstitute(contact),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'registration_closed_phone_label'.tr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      contact,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      'registration_closed_no_phone'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back<void>(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('cancel'.tr),
                  ),
                ),
                if (contact != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _callInstitute(contact),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text('registration_closed_call'.tr),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}
