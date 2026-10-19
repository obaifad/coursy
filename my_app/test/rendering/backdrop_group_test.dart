import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/navigation/route_motion_builder.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';
import 'package:my_app/widgets/app_widgets.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';

/// شبكة بطاقات Aurora: تمويه ألواح البطاقات كلها بمفتاح خلفية واحد (BackdropGroup) — على Impeller قراءة واحدة
/// للخلفية للشبكة كلها بدل واحدة لكل بطاقة (أغلى ما في الإطار أثناء التمرير)، بنفس الشكل.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    RouteMotion.resetForTest();
    FakeApi.reset();
    Get.reset();
  });

  testWidgets('aurora card panels share one backdrop key per grid', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        getPages: AppPages.pages,
        navigatorObservers: [RouteMotionObserver()],
        home: const Scaffold(body: Text('home')),
      ),
    );
    Get.toNamed<void>(AppRoutes.categoryCourses, arguments: {'id': 3, 'name': 'البرمجة'});
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final cards = find.byType(CourseAuroraCard);
    expect(cards, findsWidgets);
    final keys = <BackdropKey?>[];
    for (final card in cards.evaluate()) {
      // لوح البطاقة: أول BackdropFilter تحت البطاقة من جهة الأسفل (زر القلب له تمويه مستقل بمرشّح مختلف).
      final panels = find.descendant(of: find.byWidget(card.widget), matching: find.byType(BackdropFilter));
      final renders = panels.evaluate().map((e) => e.renderObject! as RenderBackdropFilter).toList();
      final panel = renders.reduce((a, b) => a.localToGlobal(Offset.zero).dy > b.localToGlobal(Offset.zero).dy ? a : b);
      keys.add(panel.backdropKey);
    }
    expect(keys.first, isNotNull, reason: 'each card blurs its own backdrop copy');
    expect(keys.toSet(), hasLength(1), reason: 'panels of one grid should share a single backdrop key');
  });
}
