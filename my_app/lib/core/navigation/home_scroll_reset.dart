import 'package:get/get.dart';

import '../../modules/home/controllers/home_controller.dart';
import '../../modules/root/controllers/root_controller.dart';
import '../../theme/app_motion.dart';

/// يعيد ضبط موضع تمرير الصفحة الرئيسية (عمودي + أفقي) عند العودة إليها.
abstract final class HomeScrollReset {
  static void notifyIfHomeVisible({bool scrollToTop = true}) {
    if (!Get.isRegistered<HomeController>() || !Get.isRegistered<RootController>()) {
      return;
    }
    if (Get.find<RootController>().currentIndex.value != 2) return;
    if (scrollToTop) Get.find<HomeController>().resetScrollPosition();
    // يُستدعى عند كل عودة للرئيسية (تبديل تبويب / زر رجوع) — نعيد التحميل فقط إن كانت البيانات قديمة.
    // بعد انتهاء حركة الرجوع/تبديل التبويب: التحديث يغيّر الواجهة، وهي تتحرك.
    Future<void>.delayed(AppMotion.normal, () {
      if (Get.isRegistered<HomeController>() && Get.find<RootController>().currentIndex.value == 2) {
        Get.find<HomeController>().refreshIfStale();
      }
    });
  }
}
