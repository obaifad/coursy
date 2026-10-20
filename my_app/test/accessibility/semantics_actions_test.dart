import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/widgets/design_system.dart';
import 'package:my_app/widgets/course_favorite_button.dart';
import 'package:my_app/widgets/profile_avatar.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';

/// كل زر يعلن اسمه لقارئ الشاشة يجب أن يُفعَّل منه أيضاً (TalkBack: نقر مزدوج). Semantics مع
/// excludeSemantics يُسقط إجراء النقر من الأبناء، فيُقرأ «زر» ولا يستجيب.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: child, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  void expectTappable(WidgetTester tester, Pattern label) {
    final finder = find.bySemanticsLabel(label);
    expect(finder, findsWidgets, reason: 'no separate screen-reader element named "$label"');
    final node = tester.getSemantics(finder.first);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: '"$label" is announced as a button but has no tap action',
    );
  }

  testWidgets('home: settings, category tiles and bottom navigation can be activated', (tester) async {
    final handle = tester.ensureSemantics();
    final tokens = await registerFakes(loggedIn: false, locale: 'ar');
    Get.put(HomeController(tokens));
    Get.put(CoursesController());
    Get.put(InstitutesController());
    Get.put(MyCoursesController());
    Get.put(RootController()).currentIndex.value = 2;
    await pump(tester, const RootView());

    expectTappable(tester, 'الإعدادات');
    expectTappable(tester, RegExp('^البرمجة'));
    expectTappable(tester, 'الدورات');
    expectTappable(tester, 'الرئيسية');
    handle.dispose();
  });

  testWidgets('favorite, icon and avatar camera buttons can be activated', (tester) async {
    final handle = tester.ensureSemantics();
    await registerFakes(loggedIn: true, locale: 'ar');
    await pump(
      tester,
      Column(
        children: [
          const CourseFavoriteButton(courseId: 1),
          AppIconCircleButton(onTap: () {}, icon: Icons.share_rounded, semanticLabel: 'مشاركة'),
          ProfileAvatar(size: 80, onTap: () {}, showCameraBadge: true),
        ],
      ),
    );

    expectTappable(tester, RegExp('المفضلة'));
    expectTappable(tester, 'مشاركة');
    expectTappable(tester, 'tap_to_change_photo'.tr);
    handle.dispose();
  });
}
