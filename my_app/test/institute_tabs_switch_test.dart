import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/widgets/app_skeletons.dart';
import 'package:my_app/widgets/design_system.dart';
import 'package:my_app/widgets/filter_chips.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// تبديل التبويبات في صفحات المعاهد:
/// - تفاصيل المعهد: الضغط على تبويب ينقل فوراً (لا انزلاق يُبقي السابق ظاهراً)، كل تبويب يعود إلى موضع
///   تمريره، وتحديث بيانات المعهد لا يعيد بناء شريط التبويبات وجسم الصفحة.
/// - شرائح المدن: مدينة جديدة تُظهر الهيكل فوراً (لا قائمة المدينة السابقة وعددها)، ومدينة زرتها تعود فوراً
///   من الذاكرة بلا طلب، والقائمة تبدأ من أولها.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  group('institute details tabs', () {
    Future<InstituteDetailsController> open(WidgetTester tester) async {
      Get.locale = const Locale('ar');
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = sampleInstitutes().first;
      final c = Get.put(InstituteDetailsController(), tag: 'i');
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        auditApp(
          child: const InstituteDetailsView(controllerTag: 'i'),
          locale: 'ar',
          scale: 1,
          boundaryKey: GlobalKey(),
        ),
      );
      await settle(tester);
      return c;
    }

    Finder tab(String type) => find.byWidgetPredicate((w) => w.runtimeType.toString() == type);

    Future<void> tapTab(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(Tab, label.tr));
      await tester.pump();
    }

    testWidgets('tapping a tab shows it on the next frame, the previous one is gone', (tester) async {
      await open(tester);
      await tapTab(tester, 'tab_courses');
      await tester.pump(const Duration(milliseconds: 16));
      expect(tab('_InfoTab'), findsNothing, reason: 'no slide keeping the info tab on screen');
      expect(tester.getTopLeft(tab('_CoursesTab')).dx, 0);
      await close(tester);
    });

    testWidgets('each tab comes back at its scroll position', (tester) async {
      final c = await open(tester);
      c.courses.assignAll([for (var i = 0; i < 6; i++) ...sampleCourses()]);
      await tapTab(tester, 'tab_courses');
      await settle(tester);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -900));
      await settle(tester);
      ScrollPosition coursesPosition() => tester
          .state<ScrollableState>(find.descendant(of: tab('_CoursesTab'), matching: find.byType(Scrollable)))
          .position;
      final offset = coursesPosition().pixels;
      expect(offset, greaterThan(200));

      await tapTab(tester, 'tab_instructors');
      await settle(tester);
      await tapTab(tester, 'tab_courses');
      await settle(tester);
      expect(coursesPosition().pixels, moreOrLessEquals(offset, epsilon: 1));
      await close(tester);
    });

    testWidgets('an update to the institute does not rebuild the tab bar and the page body', (tester) async {
      final c = await open(tester);
      final rebuilt = <String>{};
      debugOnRebuildDirtyWidget = (element, _) => rebuilt.add(element.widget.runtimeType.toString());
      addTearDown(() => debugOnRebuildDirtyWidget = null);
      c.institute.value = c.institute.value!.copyWith(rating: 3.9);
      await tester.pump();
      debugOnRebuildDirtyWidget = null;
      expect(rebuilt, isNot(contains('AppSegmentedTabBar')));
      expect(rebuilt, isNot(contains('NestedScrollView')));
      expect(rebuilt, contains('InstituteDetailHero'), reason: 'the hero still shows the new data');
      await close(tester);
    });
  });

  group('city filters', () {
    Future<InstitutesController> open(WidgetTester tester) async {
      Get.locale = const Locale('ar');
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(MemoryCache());
      Get.put(HomeController(tokens));
      Get.put(CoursesController());
      final c = Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = 1;
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(auditApp(child: const RootView(), locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
      await settle(tester);
      return c;
    }

    Finder chip(int i) => find.descendant(of: find.byType(HorizontalCityFilters), matching: find.byType(InkWell)).at(i);

    testWidgets('a new city shows the skeleton at once, not the previous city', (tester) async {
      final c = await open(tester);
      expect(find.byType(InstituteListCard), findsWidgets);
      FakeApi.gate = Completer<void>();
      await tester.tap(chip(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InstituteListCard), findsNothing, reason: 'the previous city stayed on screen');
      expect(find.byType(AppSliverRowListSkeleton), findsOneWidget);
      expect(c.displayCount, 0, reason: 'the badge kept the previous count');
      FakeApi.gate!.complete();
      FakeApi.gate = null;
      await settle(tester);
      expect(find.byType(InstituteListCard), findsWidgets);
      await close(tester);
    });

    testWidgets('a city visited a moment ago comes back at once, without a request', (tester) async {
      await open(tester);
      await tester.tap(chip(1));
      await settle(tester);
      await tester.tap(chip(0));
      await settle(tester);
      final requests = FakeApi.count('fetchInstitutesPage');
      FakeApi.gate = Completer<void>();
      await tester.tap(chip(1));
      await tester.pump();
      expect(find.byType(InstituteListCard), findsWidgets, reason: 'from memory, no skeleton');
      expect(FakeApi.count('fetchInstitutesPage'), requests);
      FakeApi.gate!.complete();
      FakeApi.gate = null;
      await close(tester);
    });

    testWidgets('tapping the selected city does nothing', (tester) async {
      await open(tester);
      final requests = FakeApi.count('fetchInstitutesPage');
      await tester.tap(chip(0));
      await settle(tester);
      expect(FakeApi.count('fetchInstitutesPage'), requests);
      await close(tester);
    });

    testWidgets('a new city starts at the top of the list', (tester) async {
      final c = await open(tester);
      c.institutes.assignAll([for (var i = 0; i < 8; i++) ...sampleInstitutes()]);
      await tester.pump();
      ScrollPosition list() => tester
          .state<ScrollableState>(
            find
                .descendant(of: find.byKey(const PageStorageKey('institutes_tab')), matching: find.byType(Scrollable))
                .first,
          )
          .position;
      list().jumpTo(400);
      await tester.pump();
      FakeApi.gate = Completer<void>();
      await tester.tap(chip(1));
      await tester.pump();
      expect(list().pixels, 0);
      FakeApi.gate!.complete();
      FakeApi.gate = null;
      await settle(tester);
      await close(tester);
    });
  });
}
