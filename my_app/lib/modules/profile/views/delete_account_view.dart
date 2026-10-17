import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/design_system.dart';
import '../../auth/widgets/register_form_widgets.dart';
import '../controllers/delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        appBar: AppBar(title: Text('delete_account'.tr)),
        body: AppMaxWidth(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('delete_account_title'.tr, style: AppTypography.sectionTitle())),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'delete_account_intro'.tr,
                      style: AppFonts.tajawal(fontWeight: FontWeight.w700, color: AppColors.textBody, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    for (final key in const [
                      'delete_account_item_data',
                      'delete_account_item_enrollments',
                      'delete_account_item_payments',
                      'delete_account_item_devices',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 7),
                              child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                key.tr,
                                style: AppFonts.tajawal(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                  fontSize: AppTextSize.md,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                padding: const EdgeInsets.all(18),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: controller.passwordController,
                        obscureText: controller.hidePassword.value,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => controller.passwordError.value = null,
                        onSubmitted: (_) => controller.deleteAccount(),
                        decoration: RegisterDecor.fieldDecoration(
                          label: 'delete_account_password'.tr,
                          errorText: controller.passwordError.value,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                          suffixIcon: IconButton(
                            tooltip: 'toggle_password_visibility'.tr,
                            onPressed: controller.hidePassword.toggle,
                            icon: Icon(
                              controller.hidePassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: controller.isDeleting.value ? null : controller.deleteAccount,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.5),
                        ),
                        icon: controller.isDeleting.value
                            ? const AppInlineLoader(color: Colors.white)
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text('delete_account_button'.tr),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
