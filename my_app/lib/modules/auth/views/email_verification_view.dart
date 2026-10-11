import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/otp_code_field.dart';
import '../controllers/email_verification_controller.dart';
import '../widgets/register_form_widgets.dart';

/// شاشة تأكيد البريد: أيقونة، البريد مع «تعديل»، 6 خانات للرمز (تأكيد تلقائي عند اكتمالها)،
/// عدّاد إعادة الإرسال، زر التأكيد، و«تخطي الآن».
class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeroHeader(
            title: 'verify_email_title'.tr,
            subtitle: 'verify_email_header_subtitle'.tr,
            badge: 'optional_step_badge'.tr,
            // بعد التسجيل لا صفحة للرجوع إليها — «تخطي الآن» هو المخرج.
            onBack: controller.fromRegister ? null : Get.back,
          ),
          Expanded(
            child: AppMaxWidth(
              maxWidth: ResponsiveModals.dialogMaxWidth(context),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + context.keyboardInset),
                children: [
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: controller.verified.value
                            ? const _VerifiedState(key: ValueKey('done'))
                            : _CodeForm(key: const ValueKey('form'), controller: controller),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.verified.value
                        ? const SizedBox.shrink()
                        : Center(
                            child: TextButton(
                              onPressed: controller.leave,
                              child: Text(
                                'skip_for_now'.tr,
                                style: AppFonts.tajawal(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeForm extends StatelessWidget {
  const _CodeForm({super.key, required this.controller});

  final EmailVerificationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _MailIllustration()),
        const SizedBox(height: 18),
        Text(
          'verify_email_instruction'.tr,
          textAlign: TextAlign.center,
          style: AppFonts.tajawal(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 4),
        Obx(
          () => Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                controller.email.value.isEmpty ? '—' : controller.email.value,
                textDirection: TextDirection.ltr,
                style: AppFonts.tajawal(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => _showEditEmailSheet(context, controller),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text('edit_email'.tr, style: AppFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Obx(
          () => OtpCodeField(
            controller: controller.codeController,
            focusNode: controller.codeFocus,
            length: EmailVerificationController.codeLength,
            hasError: controller.errorMessage.value != null,
            shakeTrigger: controller.errorTick.value,
            enabled: !controller.isVerifying.value,
            semanticsLabel: 'verify_email_code_label'.tr,
          ),
        ),
        Obx(() {
          final error = controller.errorMessage.value;
          final hint = controller.debugCodeHint.value;
          return AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: error == null && hint == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error ?? hint!,
                      textAlign: TextAlign.center,
                      style: AppFonts.tajawal(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: error != null ? AppColors.dangerText : AppColors.successText,
                      ),
                    ),
                  ),
          );
        }),
        const SizedBox(height: 20),
        Obx(
          () => RegisterGradientButton(
            label: 'verify_email_button'.tr,
            loading: controller.isVerifying.value,
            onPressed: controller.isVerifying.value ? null : controller.verify,
          ),
        ),
        const SizedBox(height: 14),
        _ResendRow(controller: controller),
      ],
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.controller});

  final EmailVerificationController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _buildRow());

  Widget _buildRow() {
    final muted = AppFonts.tajawal(fontSize: 13, color: AppColors.textSecondary);
    if (controller.isSending.value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('email_code_sending'.tr, style: muted),
        ],
      );
    }
    if (controller.resendSeconds.value > 0) {
      return Text(
        'resend_code_in'.trParams({'time': controller.resendCountdown}),
        textAlign: TextAlign.center,
        style: muted,
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('didnt_get_code'.tr, style: muted),
        TextButton(
          onPressed: controller.sendCode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('resend_code'.tr, style: AppFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

/// مربع متدرّج بنفسجي ناعم بأيقونة بريد، وشارة درع صغيرة في الزاوية.
class _MailIllustration extends StatelessWidget {
  const _MailIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: AppColors.shadowPrimaryStrong, blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 42),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedState extends StatelessWidget {
  const _VerifiedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 46),
          ),
          const SizedBox(height: 16),
          Text(
            'email_verified_title'.tr,
            style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'email_verified_msg'.tr,
            textAlign: TextAlign.center,
            style: AppFonts.tajawal(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// تعديل البريد ثم إرسال رمز جديد إليه.
Future<void> _showEditEmailSheet(BuildContext context, EmailVerificationController controller) async {
  final field = TextEditingController(text: controller.email.value);
  final password = TextEditingController();
  final errors = <String, String>{}.obs;
  final hidePassword = true.obs;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'edit_email_title'.tr,
            style: AppFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'edit_email_hint'.tr,
            style: AppFonts.tajawal(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Obx(
            () => TextField(
              controller: field,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'email'.tr,
                errorText: errors['email'],
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: password,
              obscureText: hidePassword.value,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'current_password'.tr,
                errorText: errors['current_password'],
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: 'toggle_password_visibility'.tr,
                  onPressed: hidePassword.toggle,
                  icon: Icon(hidePassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => RegisterGradientButton(
              label: 'save_and_send_code'.tr,
              loading: controller.isSavingEmail.value,
              onPressed: controller.isSavingEmail.value
                  ? null
                  : () async {
                      final result = await controller.changeEmail(field.text, password.text);
                      if (result == null) {
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      } else {
                        errors.assignAll(result);
                      }
                    },
            ),
          ),
        ],
      ),
    ),
  );
  field.dispose();
  password.dispose();
}
