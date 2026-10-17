import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/profile/controllers/profile_controller.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';

import 'layout/fakes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('reopening Home with offAllNamed keeps the live tab controllers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: false, locale: 'ar');

    await tester.pumpWidget(GetMaterialApp(getPages: AppPages.pages, initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();
    final home = Get.find<HomeController>();

    // ضيف يفتح تسجيل الدخول فوق الرئيسية ثم ينجح الدخول: AppNavigation.goToRoot → offAllNamed(root).
    Get.toNamed<void>(AppRoutes.login);
    await tester.pumpAndSettle();
    Get.offAllNamed<void>(AppRoutes.root);
    await tester.pumpAndSettle();

    expect(identical(Get.find<HomeController>(), home), isTrue);
    expect(home.scrollController.hasClients, isTrue);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the profile controller releases its change watchers', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final c = Get.put(ProfileController());
    await tester.pump();

    Get.delete<ProfileController>();
    // بعد الإغلاق لا يعيد أي مراقب حساب التغييرات على متحكّم مُتخلّص منه.
    c.selectedGender.value = 'female';
    c.selectedCityId.value = 3;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
