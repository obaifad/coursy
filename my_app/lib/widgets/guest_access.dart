import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/navigation/app_navigation.dart';
import '../core/storage/token_storage.dart';
import '../routes/app_routes.dart';
import 'app_widgets.dart';

/// زر الدخول كضيف — ينقل مباشرة للصفحة الرئيسية.
class GuestContinueButton extends StatelessWidget {
  const GuestContinueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: AppNavigation.enterAsGuest,
        icon: const Icon(Icons.explore_outlined),
        label: Text('continue_as_guest'.tr),
      ),
    );
  }
}

/// يعرض محتوى للمسجّل، أو شاشة دعوة لتسجيل الدخول للزائر.
class GuestGate extends StatelessWidget {
  const GuestGate({
    super.key,
    required this.message,
    required this.child,
    this.exploreCta,
    this.onExplore,
  });

  final String message;
  final Widget child;
  final String? exploreCta;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.find<TokenStorage>().isLoggedIn) return child;
      return RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
            EmptyStateView(
              message: message,
              cta: 'login'.tr,
              onCta: () => Get.toNamed(AppRoutes.login),
            ),
            if (exploreCta != null && onExplore != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(onPressed: onExplore, child: Text(exploreCta!)),
              ),
            ],
          ],
        ),
      );
    });
  }
}
