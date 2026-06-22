import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/storage/token_storage.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/design_system.dart';

/// مدة أنيميشن الشعار — 2 ثانية كحد أقصى.
const _kSplashAnimationDuration = Duration(milliseconds: 2000);
const _kPostAnimationHold = Duration(milliseconds: 320);

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kSplashAnimationDuration);

    const curve = Curves.easeOutCubic;

    _reveal = Tween<double>(begin: 0.06, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.78, curve: curve),
      ),
    );

    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.04, 0.82, curve: curve),
      ),
    );

    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1, curve: curve),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.9, curve: curve),
      ),
    );

    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1, curve: curve),
      ),
    );

    _controller.forward().then((_) {
      Future<void>.delayed(_kPostAnimationHold, _navigateAway);
    });
  }

  void _navigateAway() {
    if (!mounted) return;
    if (!AppFlags.requireLogin) {
      AppNavigation.goToRoot();
      return;
    }
    final storage = Get.find<TokenStorage>();
    if (storage.isLoggedIn) {
      AppNavigation.goToRoot();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    _CoursySplashLogo(
                      reveal: _reveal.value,
                      scale: _scale.value,
                      glow: _glow.value,
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: _taglineOpacity.value,
                      child: Text(
                        'app_tagline'.tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
  }
}

/// شعار Coursy: كشف أفقي (يسار → يمين) + تكبير خفيف + توهج ناعم في النهاية.
class _CoursySplashLogo extends StatelessWidget {
  const _CoursySplashLogo({
    required this.reveal,
    required this.scale,
    required this.glow,
  });

  final double reveal;
  final double scale;
  final double glow;

  static const double _logoHeight = 88;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.logo,
      height: _logoHeight,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
    );

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        height: _logoHeight + 24,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: glow * 0.42,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  width: 160,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: reveal.clamp(0.001, 1),
                  child: logo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
