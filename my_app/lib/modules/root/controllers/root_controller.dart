import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/navigation/home_scroll_reset.dart';
import '../../../core/storage/token_storage.dart';
import '../../../routes/app_routes.dart';
import '../../profile/controllers/my_courses_controller.dart';

class RootController extends GetxController {
  final currentIndex = 2.obs;
  final pageStorageBucket = PageStorageBucket();

  void changeTab(int index) {
    if (index == 4 && !Get.find<TokenStorage>().isLoggedIn) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    currentIndex.value = index;
    if (index == 2) {
      HomeScrollReset.notifyIfHomeVisible();
    }
    if ((index == 3 || index == 4) && Get.isRegistered<MyCoursesController>()) {
      Get.find<MyCoursesController>().load();
    }
  }
}
