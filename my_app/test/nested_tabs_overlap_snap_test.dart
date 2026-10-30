import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/course_details_view.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/modules/instructors/views/instructor_details_view.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/modules/root/controllers/root_controller.dart';
import 'package:my_app/modules/root/views/root_view.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// (1) تبويبات NestedScrollView («دوراتي»، المعهد، المدرّس): الرأس مطويّ والقائمة في أولها ⇒ أول عنصر كامل
/// تحت شريط التبويبات المثبّت (كان 117–132px منه مختفياً تحته؛ تبويب ببطاقة واحدة يبدو فارغاً).
/// (2) الرأس لا يتوقف نصف مطويّ: يكمل إلى الأقرب (مفتوح/مطويّ)، والمحتوى الأطول من الشاشة بقليل يسمح
/// بطيّه كاملاً (كان غلاف الدورة يتوقف والعنوان مقطوع تحت التبويبات).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> settle(WidgetTester tester, [int steps = 12]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, Widget view, {double height = 780}) async {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: view, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label.tr).first);
    await settle(tester, 6);
  }

  /// يطوي الرأس كاملاً والقائمة في أولها، ثم يعيد أعلى أول عنصر مرسوم في التبويب الظاهر وأسفل شريط التبويبات.
  Future<(double, double)> collapsedFirstItem(WidgetTester tester, Finder item) async {
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView).first);
    for (final p in nested.innerController.positions) {
      p.jumpTo(0);
    }
    nested.outerController.jumpTo(nested.outerController.position.maxScrollExtent);
    await settle(tester, 4);
    final tabsBottom = tester.getRect(find.byType(TabBar).first).bottom;
    final first = item.evaluate().map((e) => (e.renderObject! as RenderBox)).where((b) => b.attached && b.hasSize);
    final top = first.map((b) => b.localToGlobal(Offset.zero).dy).reduce((a, b) => a < b ? a : b);
    return (top, tabsBottom);
  }

  group('(1) first item below the pinned tab bar', () {
    testWidgets('my courses', (tester) async {
      Get.locale = const Locale('ar');
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(HomeController(tokens));
      Get.put(CoursesController());
      Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = 3;
      await open(tester, const RootView());
      final cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_EnrollmentCard');
      final (top, tabs) = await collapsedFirstItem(tester, cards);
      expect(top, greaterThanOrEqualTo(tabs), reason: 'the booking card hid under the tabs');
      await close(tester);
    });

    for (final (label, card) in [
      ('tab_info', 'SoftCard'),
      ('tab_courses', 'CourseRowCard'),
      ('tab_instructors', 'PrivateInstructorListCard'),
    ]) {
      testWidgets('institute details: $label', (tester) async {
        Get.locale = const Locale('ar');
        await registerFakes(loggedIn: true, locale: 'ar');
        Get.routing.args = sampleInstitutes().first;
        Get.put(InstituteDetailsController(), tag: 'i');
        await open(tester, const InstituteDetailsView(controllerTag: 'i'));
        await tapTab(tester, label);
        final items = find.descendant(
          of: find.byType(TabBarView),
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == card),
        );
        final (top, tabs) = await collapsedFirstItem(tester, items);
        expect(top, greaterThanOrEqualTo(tabs));
        await close(tester);
      });
    }

    for (final (label, card) in [
      ('tab_info', 'SoftCard'),
      ('tab_courses', 'CourseRowCard'),
      ('tab_institutes', 'InstituteListCard'),
    ]) {
      testWidgets('instructor details: $label', (tester) async {
        Get.locale = const Locale('ar');
        await registerFakes(loggedIn: true, locale: 'ar');
        Get.routing.args = sampleInstructors().first;
        Get.put(InstructorDetailsController(), tag: 'x');
        await open(tester, const InstructorDetailsView(controllerTag: 'x'));
        await tapTab(tester, label);
        final items = find.descendant(
          of: find.byType(TabBarView),
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == card),
        );
        final (top, tabs) = await collapsedFirstItem(tester, items);
        expect(top, greaterThanOrEqualTo(tabs), reason: 'a single institute card looked like an empty tab');
        await close(tester);
      });
    }
  });

  group('(2) the header never stays half folded', () {
    Future<ScrollPosition> openCourse(WidgetTester tester) async {
      Get.locale = const Locale('ar');
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = sampleCourses().first;
      Get.put(CourseDetailsController(), tag: 'c');
      await open(tester, const CourseDetailsView(controllerTag: 'c'));
      return tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    }

    testWidgets('course details: a short overview still collapses the cover fully', (tester) async {
      final position = await openCourse(tester);
      const collapse = 320 - kToolbarHeight;
      expect(position.maxScrollExtent, greaterThanOrEqualTo(collapse));
      await tester.dragFrom(const Offset(180, 500), const Offset(0, -180));
      await settle(tester);
      expect(position.pixels, moreOrLessEquals(collapse, epsilon: 0.5), reason: 'past half: completes the fold');
      await close(tester);
    });

    testWidgets('course details: released before half, the cover opens again', (tester) async {
      final position = await openCourse(tester);
      await tester.dragFrom(const Offset(180, 500), const Offset(0, -80));
      await settle(tester);
      expect(position.pixels, 0);
      await close(tester);
    });

    testWidgets('courses tab: a list barely taller than the screen folds the header fully', (tester) async {
      Get.locale = const Locale('ar');
      final tokens = await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(HomeController(tokens));
      final courses = Get.put(CoursesController());
      Get.put(InstitutesController());
      Get.put(MyCoursesController());
      Get.put(RootController()).currentIndex.value = 0;
      // شاشة أقصر قليلاً من الشبكة: القائمة تتمرّر بأقل من مسافة طيّ الرأس.
      await open(tester, const RootView(), height: 700);
      final position = courses.scrollController.position;
      final collapse = AppBrandSliverAppBar.collapseDistance(tester.element(find.byType(RootView)));
      expect(position.maxScrollExtent, greaterThanOrEqualTo(collapse));
      await tester.dragFrom(const Offset(180, 500), Offset(0, -(collapse * 0.7)));
      await settle(tester);
      expect(position.pixels, moreOrLessEquals(collapse, epsilon: 0.5));
      await close(tester);
    });

    testWidgets('institute details (NestedScrollView): a half fold snaps to the nearest end', (tester) async {
      Get.locale = const Locale('ar');
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = sampleInstitutes().first;
      Get.put(InstituteDetailsController(), tag: 'i');
      await open(tester, const InstituteDetailsView(controllerTag: 'i'));
      final outer = tester.state<NestedScrollViewState>(find.byType(NestedScrollView)).outerController;
      final collapse = outer.position.maxScrollExtent;
      await tester.dragFrom(const Offset(180, 600), Offset(0, -(collapse * 0.3)));
      await settle(tester);
      expect(outer.offset, 0, reason: 'before half: opens');
      await tester.dragFrom(const Offset(180, 600), Offset(0, -(collapse * 0.7)));
      await settle(tester);
      expect(outer.offset, moreOrLessEquals(collapse, epsilon: 0.5), reason: 'past half: folds');
      await close(tester);
    });

    testWidgets('a short tab that fits the screen gets no extra scroll', (tester) async {
      final position = await openCourse(tester);
      await tapTab(tester, 'tab_instructor');
      expect(position.maxScrollExtent, 0, reason: 'no runway when nothing scrolls');
      await close(tester);
    });
  });
}
