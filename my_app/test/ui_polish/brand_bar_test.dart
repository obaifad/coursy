import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/theme/app_fonts.dart';
import 'package:my_app/widgets/design_system.dart';

import '../layout/fakes.dart';
import '../layout/layout_harness.dart';

const _title = 'All courses';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required String locale,
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Get.locale = Locale(locale);
  await tester.pumpWidget(auditApp(child: child, locale: locale, scale: 1, boundaryKey: GlobalKey()));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _scrollScene({VoidCallback? onBack}) => CustomScrollView(
  slivers: [
    AppBrandSliverAppBar(title: _title, subtitle: 'Browse every course', badge: '12 courses', onBack: onBack),
    SliverList.builder(itemCount: 60, itemBuilder: (_, i) => SizedBox(height: 64, child: Text('row $i'))),
  ],
);

/// العنوان الكبير (28px) في الجزء الممتد — لا العنوان الصغير في شريط الأدوات.
Finder _largeTitle() =>
    find.byWidgetPredicate((w) => w is Text && w.data == _title && w.style?.fontSize == AppTextSize.display);

Finder _collapsedTitle() =>
    find.byWidgetPredicate((w) => w is Text && w.data == _title && w.style?.fontSize == AppTextSize.xl);

double _opacityOf(WidgetTester tester, Finder text) =>
    tester.widget<Opacity>(find.ancestor(of: text, matching: find.byType(Opacity)).first).opacity;

void main() {
  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  group('back button alignment', () {
    for (final locale in ['ar', 'en']) {
      for (final (name, size, gutter) in [
        ('phone', const Size(360, 780), 16.0),
        ('tablet', const Size(768, 1024), 24.0),
      ]) {
        testWidgets('the 40px circle rests on the $gutter px gutter with the title ($name, $locale)', (tester) async {
          await _pump(
            tester,
            _scrollScene(onBack: () {}),
            locale: locale,
            size: size,
          );

          final circle = tester.getRect(find.byKey(AppBrandBackButton.circleKey));
          final title = tester.getRect(_largeTitle());
          expect(circle.width, 40);
          expect(circle.height, 40);
          if (locale == 'ar') {
            expect(circle.right, size.width - gutter);
            expect(title.right, size.width - gutter);
          } else {
            expect(circle.left, gutter);
            expect(title.left, gutter);
          }
        });
      }
    }

    testWidgets('the back button pops and announces itself', (tester) async {
      var popped = 0;
      await _pump(tester, _scrollScene(onBack: () => popped++), locale: 'ar');
      expect(find.bySemanticsLabel('back'.tr), findsOneWidget);
      await tester.tap(find.byKey(AppBrandBackButton.circleKey));
      expect(popped, 1);
    });

    testWidgets('without a back button the title starts on the gutter', (tester) async {
      await _pump(tester, _scrollScene(), locale: 'en');
      expect(find.byType(AppBrandBackButton), findsNothing);
      expect(tester.getRect(_largeTitle()).left, 16);
    });
  });

  group('collapse and status bar', () {
    testWidgets('collapses to a pinned toolbar and keeps white status bar icons', (tester) async {
      await _pump(tester, _scrollScene(onBack: () {}), locale: 'ar');
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
      expect(_opacityOf(tester, _largeTitle()), 1);
      expect(_opacityOf(tester, _collapsedTitle()), 0);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();

      // مطوي: شريط الأدوات فقط يبقى مثبّتاً في الأعلى (لا حشوة لشريط الحالة في الاختبار).
      expect(tester.getRect(find.byType(AppBar)).height, AppBrandSliverAppBar.toolbarHeight);
      expect(tester.getRect(find.byType(AppBar)).top, 0);
      expect(_opacityOf(tester, _collapsedTitle()), 1);
      expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
      // زر الرجوع باقٍ في مكانه بعد الانطواء.
      expect(tester.getRect(find.byKey(AppBrandBackButton.circleKey)).right, 360 - 16);
    });

    testWidgets('the bar has the original hero look: brand gradient, rounded bottom corners', (tester) async {
      await _pump(tester, _scrollScene(), locale: 'en');
      final bar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(bar.systemOverlayStyle?.statusBarIconBrightness, Brightness.light);

      final appBar = find.byType(SliverAppBar);
      final gradient = find.descendant(
        of: appBar,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient == AppGradients.heroBanner,
        ),
      );
      expect(gradient, findsOneWidget);
      final clip = find.descendant(
        of: appBar,
        matching: find.byWidgetPredicate(
          (w) =>
              w is ClipRRect &&
              w.borderRadius == const BorderRadius.vertical(bottom: Radius.circular(AppBrandSliverAppBar.bottomRadius)),
        ),
      );
      expect(clip, findsOneWidget);
    });

    Future<void> pumpRoot(WidgetTester tester, {required int tab}) async {
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(HomeController(tokens));
      Get.put(CoursesController());
      Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = tab;
      await _pump(tester, const RootView(), locale: 'ar');
      await tester.pump(const Duration(milliseconds: 600));
    }

    for (final (tab, name) in [(0, 'courses'), (1, 'institutes'), (3, 'my courses')]) {
      testWidgets('the $name tab shows the brand bar with white icons, also when scrolled', (tester) async {
        await pumpRoot(tester, tab: tab);
        expect(find.byType(AppBrandSliverAppBar), findsOneWidget);
        expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 600));
        expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);

        Get.closeAllSnackbars();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}
