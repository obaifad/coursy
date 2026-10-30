import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// رأس الرئيسية: الشعار (كلمته 30، بلا هوامش الصورة الشفافة) وزر الإعدادات (40) متوازنان، وحافّتاهما على
/// حافّتي شريط البحث. «دوراتي»: العودة إليها من تبويب آخر تُظهر التبويب الفرعي الأول من أول إطار — كان
/// السابق يظهر ثم ينزلق إلى الأول.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<RootController> openRoot(WidgetTester tester, {String locale = 'ar'}) async {
    Get.locale = Locale(locale);
    final tokens = await registerFakes(loggedIn: true, locale: locale);
    Get.put(HomeController(tokens));
    Get.put(CoursesController());
    Get.put(InstitutesController());
    Get.put(MyCoursesController());
    final root = Get.put(RootController());
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: const RootView(), locale: locale, scale: 1, boundaryKey: GlobalKey()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return root;
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final locale in ['ar', 'en']) {
    testWidgets('home header: logo and settings button balanced, on the search bar edges ($locale)', (tester) async {
      await openRoot(tester, locale: locale);
      final logo = tester.getRect(find.byType(AppHomeBrandLogo));
      final search = tester.getRect(find.byType(AppHomeSearchBar));
      final gear = tester.getRect(
        find.ancestor(of: find.byIcon(Icons.settings_rounded), matching: find.byType(Container)).first,
      );
      expect(gear.width, 40, reason: 'settings circle');
      // الصندوق = الكلمة نفسها (الهوامش الشفافة مقصوصة): كانت 56 وكلمتها 22.
      expect(logo.height, moreOrLessEquals(30, epsilon: 0.5), reason: 'logo word height');
      expect(logo.left, moreOrLessEquals(search.left, epsilon: 0.5), reason: 'logo on the search bar start');
      expect(gear.right, moreOrLessEquals(search.right, epsilon: 0.5), reason: 'button on the search bar end');
      expect((logo.center.dy - gear.center.dy).abs(), lessThan(1), reason: 'same centreline');
      await close(tester);
    });
  }

  testWidgets('my courses: coming back from another tab shows the first sub-tab from the first frame', (tester) async {
    final root = await openRoot(tester);
    root.changeTab(3);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.widgetWithText(Tab, 'tab_confirmed'.tr));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    root.changeTab(2);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    root.changeTab(3);

    Finder list(String status) => find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_EnrollmentList' && (w as dynamic).status.toString().endsWith('.$status'),
    );
    bool onScreen(String status) {
      final f = list(status);
      if (f.evaluate().isEmpty) return false;
      final box = tester.renderObject<RenderBox>(f.first);
      return box.attached && box.hasSize && box.localToGlobal(Offset.zero).dx.abs() < 360;
    }

    for (var frame = 0; frame < 25; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(onScreen('confirmed'), isFalse, reason: 'frame $frame: the previous sub-tab is still on screen');
      expect(tester.getTopLeft(list('pending')).dx, 0, reason: 'frame $frame: the first sub-tab slides in');
    }
    await close(tester);
  });
}
