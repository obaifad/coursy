import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/navigation/home_scroll_reset.dart';
import '../../../core/services/enrollment_sync_service.dart';
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
    final alreadyHere = currentIndex.value == index;
    currentIndex.value = index;
    // العودة للرئيسية من تبويب آخر تحفظ موضع التمرير؛ الضغط على "الرئيسية" وأنت فيها يعيدها للأعلى.
    refreshTabData(index, scrollHomeToTop: alreadyHere);
  }

  void refreshTabData(int index, {bool scrollHomeToTop = true}) {
    if (index == 2) {
      HomeScrollReset.notifyIfHomeVisible(scrollToTop: scrollHomeToTop);
    }
    if ((index == 3 || index == 4) && Get.isRegistered<MyCoursesController>()) {
      Get.find<MyCoursesController>().loadIfStale();
    }
    if (Get.find<TokenStorage>().isLoggedIn && Get.isRegistered<EnrollmentSyncService>()) {
      unawaited(Get.find<EnrollmentSyncService>().checkForStatusChanges());
    }
  }
}
