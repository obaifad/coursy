import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_flags.dart';
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
  final pages = const [
    _PageData(title: 'اكتشف المعاهد', subtitle: 'معاهد ومراكز تدريب موثوقة من كل المحافظات في مكان واحد.', icon: Icons.apartment_rounded),
    _PageData(title: 'ابحث وقارن الدورات', subtitle: 'صُفِّ الدورات حسب المستوى والسعر والمدة بسهولة.', icon: Icons.search_rounded),
    _PageData(title: 'سجّل وطوّر مهاراتك', subtitle: 'خطط تعلّمك، تابع تقدّمك، واحصل على إشعارات ذكية.', icon: Icons.rocket_launch_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    if (AppFlags.requireLogin) {
                      Get.offAllNamed(AppRoutes.login);
                    } else {
                      AppNavigation.goToRoot();
                    }
                  },
                  child: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const Center(child: AppLogo(height: 44, alignment: Alignment.center)),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (value) => setState(() => index = value),
                  itemCount: pages.length,
                  itemBuilder: (context, i) {
                    final p = pages[i];
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
                              boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 24, offset: Offset(0, 14))],
                            ),
                            child: Icon(p.icon, size: 100, color: Colors.white.withValues(alpha: 0.95)),
                          ),
                          const SizedBox(height: 32),
                          Text(p.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Text(
                            p.subtitle,
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
                  pages.length,
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
                    if (index == pages.length - 1) {
                      if (AppFlags.requireLogin) {
                        Get.offAllNamed(AppRoutes.login);
                      } else {
                        AppNavigation.goToRoot();
                      }
                      return;
                    }
                    controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
                  },
                  child: Text(index == pages.length - 1 ? 'ابدأ الآن' : 'التالي'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
}
