import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';
import '../controllers/phone_verification_controller.dart';

class PhoneVerificationView extends GetView<PhoneVerificationController> {
  const PhoneVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('verify_phone_title'.tr)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: Obx(
          () => AppMaxWidth(
            maxWidth: ResponsiveModals.dialogMaxWidth(context),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + context.keyboardInset),
              children: [
                _StepIndicator(current: controller.step.value),
                const SizedBox(height: 20),
                SoftCard(
                  child: controller.step.value == 0
                      ? _SendStep(controller: controller)
                      : _VerifyStep(controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    Widget step(String n, String label, bool active) {
      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: active ? AppColors.primary : AppColors.indicatorFill,
              child: Text(n, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        step('1', 'verify_step_send'.tr, current == 0),
        Container(width: 24, height: 2, color: AppColors.borderSoft),
        step('2', 'verify_step_enter'.tr, current == 1),
      ],
    );
  }
}

class _SendStep extends StatelessWidget {
  const _SendStep({required this.controller});
  final PhoneVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phone_android_rounded, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('confirm_phone'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'otp_will_send'.trParams({'phone': controller.phone}),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        Obx(
          () => FilledButton(
            onPressed: controller.isSending.value ? null : controller.sendCode,
            child: Text(controller.isSending.value ? 'sending_otp'.tr : 'send_otp'.tr),
          ),
        ),
      ],
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({required this.controller});
  final PhoneVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('enter_otp'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text('otp_sent_to'.trParams({'phone': controller.phone}), style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            border: OutlineInputBorder(),
          ),
        ),
        Obx(() {
          final hint = controller.debugOtpHint.value;
          if (hint == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          );
        }),
        const SizedBox(height: 12),
        Obx(
          () => FilledButton(
            onPressed: controller.isLoading.value ? null : controller.verifyCode,
            child: Text(controller.isLoading.value ? 'verifying'.tr : 'confirm_code'.tr),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextButton(
            onPressed: controller.resendSeconds.value > 0 || controller.isSending.value ? null : controller.sendCode,
            child: Text(
              controller.resendSeconds.value > 0
                  ? 'resend_after'.trParams({'sec': '${controller.resendSeconds.value}'})
                  : 'resend_otp'.tr,
            ),
          ),
        ),
        TextButton(onPressed: () => controller.step.value = 0, child: Text('change_number'.tr)),
      ],
    );
  }
}
