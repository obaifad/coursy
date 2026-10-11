import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_fonts.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../theme/app_colors.dart';
import 'login_hero_header.dart';
import 'login_page_metrics.dart';

enum AuthSplitHeroVariant { login, register }

/// تخطيط نصفين: لوحة الفورم + لوحة ترحيب/جرافيك (50/50 على التابلت).
class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.metrics,
    required this.heroVariant,
    required this.form,
    this.bottomInset = 0,
  });

  final LoginPageMetrics metrics;
  final AuthSplitHeroVariant heroVariant;
  final Widget form;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final bottomPad = bottomInset > 0 ? bottomInset + 16 : metrics.pageVerticalPadding + 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                metrics.splitPanelPadding,
                metrics.pageVerticalPadding + 8,
                metrics.splitPanelPadding,
                bottomPad,
              ),
              child: form,
            ),
          ),
        ),
        Expanded(
          child: AuthSplitHeroPanel(variant: heroVariant, metrics: metrics),
        ),
      ],
    );
  }
}

/// اللوحة الجانبية — ترحيب كبير + جرافيك على خلفية متدرجة.
class AuthSplitHeroPanel extends StatelessWidget {
  const AuthSplitHeroPanel({super.key, required this.variant, required this.metrics});

  final AuthSplitHeroVariant variant;
  final LoginPageMetrics metrics;

  static const _heroGradient = LinearGradient(
    colors: [AppColors.surfaceSoft, Color(0xFFEFEAFF), Color(0xFFE0D6FF)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final isRegister = variant == AuthSplitHeroVariant.register;

      return DecoratedBox(
        decoration: const BoxDecoration(gradient: _heroGradient),
        child: Center(
          // قابلة للتمرير عند ضيق الارتفاع (الوضع الأفقي + تكبير الخط) بدل أن تفيض.
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: metrics.splitPanelPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthSecurityIllustration(size: metrics.illustrationSize),
                SizedBox(height: metrics.sectionGap + 8),
                Text(
                  isRegister ? 'register_title'.tr : 'login_welcome_back'.tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(
                    fontSize: metrics.welcomeTitleSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.authHeroTitle,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: metrics.sectionGap * 0.5),
                Text(
                  'app_tagline'.tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(
                    fontSize: metrics.welcomeSubtitleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: metrics.sectionGap),
                Text(
                  isRegister ? 'auth_hero_register_desc'.tr : 'auth_hero_login_desc'.tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(
                    fontSize: metrics.welcomeSubtitleSize - 1,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
