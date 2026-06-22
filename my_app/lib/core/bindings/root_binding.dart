import 'package:get/get.dart';

import '../storage/token_storage.dart';
import '../../modules/courses/controllers/courses_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/institutes/controllers/institutes_controller.dart';
import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/root/controllers/root_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RootController>()) {
      Get.put(RootController(), permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(() => HomeController(Get.find<TokenStorage>()), fenix: true);
    }
    if (!Get.isRegistered<CoursesController>()) {
      Get.lazyPut<CoursesController>(() => CoursesController(), fenix: true);
    }
    if (!Get.isRegistered<InstitutesController>()) {
      Get.lazyPut<InstitutesController>(() => InstitutesController(), fenix: true);
    }
    if (!Get.isRegistered<MyCoursesController>()) {
      Get.lazyPut<MyCoursesController>(() => MyCoursesController(), fenix: true);
    }
  }
}
