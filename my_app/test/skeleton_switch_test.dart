import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/views/category_courses_view.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/skeleton_switch.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// الهيكل ثم المحتوى بتلاشٍ (فقط إن سبقه هيكل)، وصفحة التصنيف بـ Obx صغيرة لا تعيد بناء الشبكة لتغيّرات
/// لا تخصّها.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  double opacityOf(WidgetTester tester) =>
      tester.widget<FadeTransition>(find.byType(FadeTransition).last).opacity.value;

  Widget host(bool loading, {int built = 0, void Function()? onBuilt, bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: AppSkeletonSwitch(
        loading: loading,
        skeleton: const Text('skeleton'),
        contentBuilder: (_) {
          onBuilt?.call();
          return const Text('content');
        },
      ),
    ),
  );

  group('AppSkeletonSwitch', () {
    testWidgets('content ready from the start (cache): shown at once, no fade', (tester) async {
      await tester.pumpWidget(host(false));
      expect(find.text('content'), findsOneWidget);
      expect(opacityOf(tester), 1);
    });

    testWidgets('while loading only the skeleton shows and the content is never built', (tester) async {
      var built = 0;
      await tester.pumpWidget(host(true, onBuilt: () => built++));
      expect(find.text('skeleton'), findsOneWidget);
      expect(find.text('content'), findsNothing);
      expect(built, 0);
    });

    testWidgets('skeleton -> content: the content fades in from transparent to opaque', (tester) async {
      await tester.pumpWidget(host(true));
      await tester.pumpWidget(host(false));
      expect(find.text('skeleton'), findsNothing);
      expect(opacityOf(tester), 0, reason: 'starts transparent');
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacityOf(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacityOf(tester), 1);
    });

    testWidgets('content that changes while shown does not fade again', (tester) async {
      await tester.pumpWidget(host(true));
      await tester.pumpWidget(host(false));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(host(false, built: 1));
      expect(opacityOf(tester), 1);
    });

    testWidgets('reduced motion: no fade', (tester) async {
      await tester.pumpWidget(host(true, disableAnimations: true));
      await tester.pumpWidget(host(false, disableAnimations: true));
      expect(opacityOf(tester), 1);
    });

    testWidgets('closed while still on the skeleton: no ticker assertion', (tester) async {
      await tester.pumpWidget(host(true));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('sliver variant works inside a CustomScrollView', (tester) async {
      Widget page(bool loading) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            AppSkeletonSwitch(
              sliver: true,
              loading: loading,
              skeleton: const SliverToBoxAdapter(child: Text('skeleton')),
              contentBuilder: (_) => const SliverToBoxAdapter(child: Text('content')),
            ),
          ],
        ),
      );
      await tester.pumpWidget(page(true));
      expect(find.text('skeleton'), findsOneWidget);
      await tester.pumpWidget(page(false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('category page', () {
    Future<CategoryCoursesController> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360 * 2, 780 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة'};
      final c = Get.put(CategoryCoursesController());
      await tester.pumpWidget(
        auditApp(locale: 'ar', scale: 1, boundaryKey: GlobalKey(), child: const CategoryCoursesView()),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 400));
      return c;
    }

    testWidgets('cards show after loading', (tester) async {
      final c = await open(tester);
      expect(c.courses, isNotEmpty);
      expect(find.byType(CourseAuroraCard), findsWidgets);
    });

    testWidgets('load-more state changes do not rebuild the grid', (tester) async {
      final c = await open(tester);
      final before = tester.widget(find.byType(CourseAuroraCard).first);
      c.isLoadingMore.value = true;
      c.loadMoreFailed.value = true;
      c.hasMore.value = true;
      await tester.pump();
      expect(identical(tester.widget(find.byType(CourseAuroraCard).first), before), isTrue);
    });
  });
}
