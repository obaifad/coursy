import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/config/api_config.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/token_storage.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/design_system.dart';
import '../controllers/auth_controller.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_split_layout.dart';
import '../widgets/login_hero_header.dart';
import '../widgets/login_page_metrics.dart';
import '../widgets/register_form_widgets.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.find<TokenStorage>().isLoggedIn && Get.currentRoute == AppRoutes.login) {
        AppNavigation.goToRoot(tab: 2);
      }
    });

    return Obx(() {
      final _ = localeRebuildToken;
      return AppStatusBar(
        child: Theme(
          data: Theme.of(context).copyWith(textTheme: AppFonts.tajawalTextTheme(Theme.of(context).textTheme)),
          child: Scaffold(
            backgroundColor: const Color(0xFFF3F1FF),
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                SafeArea(
                  child: Builder(
                    builder: (context) {
                      final metrics = LoginPageMetrics.of(context);
                      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                      final bottomPad = keyboardInset > 0 ? keyboardInset + 12 : 32.0;

                      if (metrics.useSplitLayout) {
                        return AuthSplitLayout(
                          metrics: metrics,
                          heroVariant: AuthSplitHeroVariant.login,
                          bottomInset: keyboardInset,
                          form: _LoginSplitFormBody(metrics: metrics),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, viewport) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.only(bottom: bottomPad),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: viewport.maxHeight),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LoginHeroHeader(metrics: metrics),
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(gradient: RegisterDecor.background),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: metrics.horizontalPadding,
                                          vertical: metrics.formVerticalPadding,
                                        ),
                                        child: _LoginFormBody(metrics: metrics),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const _AuthBackButton(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// زر رجوع يظهر فقط عندما تُفتح الشاشة فوق شاشة أخرى (الضيف يضغط "دخول" من داخل التطبيق).
class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton();

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return PositionedDirectional(
      top: MediaQuery.paddingOf(context).top + 4,
      start: 8,
      child: IconButton(
        onPressed: Get.back,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
    );
  }
}

class _LoginSplitFormBody extends StatelessWidget {
  const _LoginSplitFormBody({required this.metrics});

  final LoginPageMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLogo(height: metrics.logoHeight, alignment: AlignmentDirectional.centerStart),
        SizedBox(height: metrics.sectionGap + 4),
        _LoginFormBody(metrics: metrics),
      ],
    );
  }
}

class _LoginFormBody extends GetView<AuthController> {
  const _LoginFormBody({required this.metrics});

  final LoginPageMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final flatCard = metrics.useSplitLayout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('login_title'.tr, style: RegisterDecor.heading(context)),
        const SizedBox(height: 6),
        Text('login_subtitle_email_phone'.tr, style: RegisterDecor.subheading(context)),
        if (ApiConfig.loginNeedsNativePlatform) ...[const SizedBox(height: 12), const _WebLoginHint()],
        Obx(() {
          final err = controller.errorMessage.value;
          if (err == null || err.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _LoginErrorBanner(message: err),
          );
        }),
        SizedBox(height: metrics.sectionGap),
        RegisterFloatingCard(
          elevated: !flatCard,
          child: Column(
            children: [
              // «البريد الإلكتروني أو رقم الهاتف» ومثاله كانا يُقصّان («…الهـ») على هاتف 1080px:
              // نص أقصر ومثال أقصر بخط أصغر قليلاً.
              _CompactHint(
                child: RegisterFloatingField(
                  controller: controller.loginIdController,
                  label: 'login_identifier_short'.tr,
                  hint: 'login_identifier_hint_short'.tr,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ),
              SizedBox(height: metrics.fieldGap),
              Obx(
                () => RegisterFloatingField(
                  controller: controller.passwordController,
                  label: 'password_required'.tr,
                  obscureText: controller.hidePassword.value,
                  textInputAction: TextInputAction.done,
                  // «تم» يسجّل الدخول (كان لا يفعل شيئاً)؛ نفس قفل الزر أثناء الطلب.
                  onSubmitted: (_) {
                    if (!controller.isLoading.value) controller.login();
                  },
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    tooltip: 'toggle_password_visibility'.tr,
                    onPressed: () => controller.hidePassword.toggle(),
                    icon: Icon(
                      controller.hidePassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _LoginForgotPasswordLink(),
            ],
          ),
        ),
        SizedBox(height: metrics.sectionGap),
        Obx(
          () => RegisterGradientButton(
            label: controller.isLoading.value ? 'logging_in'.tr : 'enter'.tr,
            loading: controller.isLoading.value,
            onPressed: controller.isLoading.value ? null : controller.login,
          ),
        ),
        const SizedBox(height: 12),
        RegisterGhostButton(label: 'continue_as_guest'.tr, primaryText: true, onPressed: AppNavigation.enterAsGuest),
        SizedBox(height: metrics.sectionGap),
        Center(child: _CreateAccountLink()),
      ],
    );
  }
}

/// مثال الحقل (يظهر عند التركيز والحقل فارغ) بخط 13 بدل 15 كي يتسع في عرض الحقل على الهواتف الشائعة.
class _CompactHint extends StatelessWidget {
  const _CompactHint({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(hintStyle: const TextStyle(fontSize: 13)),
      ),
      child: child,
    );
  }
}

class _LoginForgotPasswordLink extends StatelessWidget {
  const _LoginForgotPasswordLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(48, 44),
        ),
        child: Text(
          'forgot_password'.tr,
          style: AppFonts.tajawal(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _CreateAccountLink extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        controller.registerStep.value = 0;
        controller.clearRegisterValidation();
        Get.toNamed(AppRoutes.register);
      },
      child: Text(
        'register'.tr,
        style: AppFonts.tajawal(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.tajawal(color: AppColors.dangerText, fontWeight: FontWeight.w700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebLoginHint extends StatelessWidget {
  const _WebLoginHint();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ratingStar.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.ratingStar, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('web_cors_hint'.tr, style: AppFonts.tajawal(fontSize: 13, height: 1.4))),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('forgot_title'.tr)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: AppMaxWidth(
          maxWidth: ResponsiveModals.dialogMaxWidth(context),
          child: Obx(() {
            final _ = localeRebuildToken;
            final codeStep = controller.step.value == 1;
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + context.keyboardInset),
              children: [
                const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  (codeStep ? 'reset_code_heading' : 'forgot_email_heading').tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  codeStep
                      ? 'reset_code_desc'.trParams({'email': controller.emailController.text.trim()})
                      : 'forgot_email_desc'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                SoftCard(
                  child: codeStep ? _ResetStep(controller: controller) : _EmailStep(controller: controller),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// كل خطوة داخل Obx خاص بها: قراءات `.value` هنا لا يتتبّعها Obx الأب (يُبنى هذا الويدجت لاحقاً)،
/// فكان الزر يبقى في حالة التحميل والأخطاء والعدّاد لا تتحدّث.
class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => controller.clearError('email'),
            onSubmitted: (_) => controller.sendCode(),
            decoration: RegisterDecor.fieldDecoration(
              label: 'email'.tr,
              errorText: controller.errors['email'],
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          RegisterGradientButton(
            label: 'send_reset_code'.tr,
            loading: controller.isSending.value,
            onPressed: controller.isSending.value ? null : controller.sendCode,
          ),
        ],
      ),
    );
  }
}

class _ResetStep extends StatelessWidget {
  const _ResetStep({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final hidden = controller.hidePassword.value;
    final waiting = controller.resendIn.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller.codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          onChanged: (_) => controller.clearError('code'),
          decoration: RegisterDecor.fieldDecoration(
            label: 'reset_code_label'.tr,
            errorText: controller.errors['code'],
            prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.passwordController,
          obscureText: hidden,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => controller.clearError('password'),
          decoration: RegisterDecor.fieldDecoration(
            label: 'new_password_label'.tr,
            errorText: controller.errors['password'],
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              tooltip: 'toggle_password_visibility'.tr,
              onPressed: controller.hidePassword.toggle,
              icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.confirmController,
          obscureText: hidden,
          textInputAction: TextInputAction.done,
          onChanged: (_) => controller.clearError('password_confirmation'),
          onSubmitted: (_) => controller.resetPassword(),
          decoration: RegisterDecor.fieldDecoration(
            label: 'confirm_password'.tr,
            errorText: controller.errors['password_confirmation'],
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        RegisterGradientButton(
          label: 'reset_password_button'.tr,
          loading: controller.isResetting.value,
          onPressed: controller.isResetting.value ? null : controller.resetPassword,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(onPressed: controller.editEmail, child: Text('change_email'.tr)),
            TextButton(
              onPressed: waiting > 0 || controller.isSending.value ? null : controller.sendCode,
              child: Text(waiting > 0 ? 'resend_after'.trParams({'sec': '$waiting'}) : 'resend_otp'.tr),
            ),
          ],
        ),
      ],
    );
  }
}
