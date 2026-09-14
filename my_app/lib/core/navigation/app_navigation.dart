import 'package:get/get.dart';

import '../../modules/root/controllers/root_controller.dart';
import '../../routes/app_routes.dart';
import '../bindings/root_binding.dart';

/// تنقل آمن إلى الشاشة الرئيسية مع تسجيل RootBinding دائماً.
abstract final class AppNavigation {
  static void ensureRootBinding() {
    RootBinding().dependencies();
  }

  static void goToRoot({int? tab}) {
    ensureRootBinding();
    final root = Get.find<RootController>();
    if (Get.currentRoute != AppRoutes.root) {
      Get.offAllNamed(AppRoutes.root);
    }
    final targetTab = tab ?? root.currentIndex.value;
    if (root.currentIndex.value != targetTab) {
      root.changeTab(targetTab);
    } else {
      root.refreshTabData(targetTab);
    }
  }

  static void switchToTab(int index) {
    ensureRootBinding();
    Get.find<RootController>().changeTab(index);
  }

  /// تصفّح التطبيق كضيف بدون تسجيل — يفتح الصفحة الرئيسية دائماً.
  static void enterAsGuest() => goToRoot(tab: 2);
}
