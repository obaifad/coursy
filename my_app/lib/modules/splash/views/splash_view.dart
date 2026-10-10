import '../../../theme/app_fonts.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_flags.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/design_system.dart';
import '../widgets/splash_logo_animation.dart';

/// مدة أنيميشن الشعار (≈1.9s: كافية للحكاية وقصيرة كي لا تؤخّر فتح التطبيق).
const _kSplashAnimationDuration = Duration(milliseconds: 1900);
const _kSplashReducedMotionDuration = Duration(milliseconds: 250);
const _kPostAnimationHold = Duration(milliseconds: 150);

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kSplashAnimationDuration);

    const curve = Curves.easeOutCubic;
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.9, curve: curve),
    );
    _loaderOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1, curve: curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // احترام إعداد "تقليل الحركة" في النظام: انتقال سريع بدل الأنيميشن الكامل.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.duration = _kSplashReducedMotionDuration;
    }
    _controller.forward().then((_) {
      Future<void>.delayed(_kPostAnimationHold, _navigateAway);
    });
  }

  void _navigateAway() {
    if (!mounted) return;
    if (!AppFlags.requireLogin || Get.find<TokenStorage>().isLoggedIn) {
      AppNavigation.goToRoot();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    // بعد الانتقال: offAll كان سيُزيل أي حوار يُفتح فوق شاشة البداية.
    if (Get.isRegistered<AppConfigService>()) {
      unawaited(Get.find<AppConfigService>().presentIfNeeded());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.splash),
          child: SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SplashLogoAnimation(progress: _controller),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Text(
                          'app_tagline'.tr,
                          textAlign: TextAlign.center,
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: const AppDotsLoader(color: Colors.white, size: AppLoaderSize.large),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
