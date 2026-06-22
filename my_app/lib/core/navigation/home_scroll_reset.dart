import 'package:get/get.dart';

import '../../modules/home/controllers/home_controller.dart';
import '../../modules/root/controllers/root_controller.dart';

/// يعيد ضبط موضع تمرير الصفحة الرئيسية (عمودي + أفقي) عند العودة إليها.
abstract final class HomeScrollReset {
  static void notifyIfHomeVisible() {
    if (!Get.isRegistered<HomeController>() || !Get.isRegistered<RootController>()) {
      return;
    }
    if (Get.find<RootController>().currentIndex.value != 2) return;
    Get.find<HomeController>().resetScrollPosition();
  }
}
