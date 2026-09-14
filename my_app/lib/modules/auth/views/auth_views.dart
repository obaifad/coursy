import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/token_storage.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';
import '../widgets/login_hero_header.dart';
import '../widgets/login_page_metrics.dart';
import '../widgets/register_form_widgets.dart';

final List<TextInputFormatter> _phoneInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

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
      return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F1FF),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
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
      ),
    );
    });
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
        if (ApiConfig.loginNeedsNativePlatform) ...[
          const SizedBox(height: 12),
          const _WebLoginHint(),
        ],
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
              RegisterFloatingField(
                controller: controller.loginEmailController,
                label: 'email_required'.tr,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.email_outlined,
              ),
              SizedBox(height: metrics.fieldGap),
              RegisterFloatingField(
                controller: controller.loginPhoneController,
                label: 'phone_required'.tr,
                hint: 'phone_hint'.tr,
                keyboardType: TextInputType.phone,
                inputFormatters: _phoneInputFormatters,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.phone_android_rounded,
              ),
              SizedBox(height: metrics.fieldGap),
              Obx(
                () => RegisterFloatingField(
                  controller: controller.passwordController,
                  label: 'password_required'.tr,
                  obscureText: controller.hidePassword.value,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: () => controller.hidePassword.toggle(),
                    icon: Icon(
                      controller.hidePassword.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
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
        RegisterGhostButton(
          label: 'continue_as_guest'.tr,
          primaryText: true,
          onPressed: AppNavigation.enterAsGuest,
        ),
        SizedBox(height: metrics.sectionGap),
        Center(child: _CreateAccountLink()),
      ],
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
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'forgot_password'.tr,
          style: GoogleFonts.tajawal(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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
        style: GoogleFonts.tajawal(
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
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.tajawal(color: Colors.red.shade700, fontWeight: FontWeight.w600, height: 1.35),
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
      color: Colors.amber.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'web_cors_hint'.tr,
                style: GoogleFonts.tajawal(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordView extends StatelessWidget {
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + context.keyboardInset),
            children: [
            const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'forgot_phone_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'forgot_phone_desc'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SoftCard(
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'phone'.tr,
                      prefixIcon: const Icon(Icons.phone_android_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Get.offNamed(AppRoutes.login),
                    child: Text('go_to_login'.tr),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
