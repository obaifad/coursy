import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_flags.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/design_system.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final controller = PageController();
  int index = 0;

  static const _pageIcons = [
    Icons.apartment_rounded,
    Icons.search_rounded,
    Icons.rocket_launch_rounded,
  ];

  static const _pageTitleKeys = [
    'onboarding_title_1',
    'onboarding_title_2',
    'onboarding_title_3',
  ];

  static const _pageSubtitleKeys = [
    'onboarding_subtitle_1',
    'onboarding_subtitle_2',
    'onboarding_subtitle_3',
  ];

  void _finish() {
    if (AppFlags.requireLogin) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      AppNavigation.goToRoot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.screenBg),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text('onboarding_skip'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const Center(child: AppLogo(height: 44, alignment: Alignment.center)),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    onPageChanged: (value) => setState(() => index = value),
                    itemCount: _pageIcons.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: const [
                                  BoxShadow(color: AppColors.shadowPurple, blurRadius: 24, offset: Offset(0, 14)),
                                ],
                              ),
                              child: Icon(
                                _pageIcons[i],
                                size: 100,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _pageTitleKeys[i].tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _pageSubtitleKeys[i].tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pageIcons.length,
                    (dot) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: dot == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dot == index ? AppColors.primary : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () {
                      if (index == _pageIcons.length - 1) {
                        _finish();
                        return;
                      }
                      controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
                    },
                    child: Text(index == _pageIcons.length - 1 ? 'onboarding_start'.tr : 'next'.tr),
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
