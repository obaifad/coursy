import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/modules/instructors/views/instructor_details_view.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// بطاقة واحدة لكل نوع في التطبيق: معاهد المدرّس بنفس بطاقة تبويب المعاهد ([InstituteListCard]) — بلا عدد
/// دورات لأن الربط لا يحمله — ودورات المعهد والمدرّس بنفس بطاقة نتائج البحث ([CourseRowCard]).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  Future<void> open(WidgetTester tester, Widget view, String tab) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: view, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.widgetWithText(Tab, tab.tr));
    // التبويب يطلب دوراته عند فتحه أول مرة.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('instructor → institutes: the institutes-tab card, without a courses count', (tester) async {
    Get.locale = const Locale('ar');
    await registerFakes(loggedIn: true, locale: 'ar');
    final instructor = sampleInstructors().first;
    Get.put(InstructorDetailsController(), tag: 'x').instructor.value = instructor;
    await open(tester, const InstructorDetailsView(controllerTag: 'x'), 'tab_institutes');
    final card = find.byType(InstituteListCard);
    expect(card, findsNWidgets(instructor.institutes.length));
    expect(find.descendant(of: card, matching: find.byIcon(Icons.menu_book_outlined)), findsNothing);
    expect(find.descendant(of: card, matching: find.text(instructor.institutes.first.name)), findsOneWidget);
    await close(tester);
  });

  testWidgets('instructor → courses: the search-results row card', (tester) async {
    Get.locale = const Locale('ar');
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = sampleInstructors().first;
    Get.put(InstructorDetailsController(), tag: 'x');
    await open(tester, const InstructorDetailsView(controllerTag: 'x'), 'tab_courses');
    expect(find.byType(CourseRowCard), findsWidgets);
    expect(find.byType(CourseCard), findsNothing);
    await close(tester);
  });

  testWidgets('institute → courses: the search-results row card', (tester) async {
    Get.locale = const Locale('ar');
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(InstituteDetailsController(), tag: 'i').institute.value = sampleInstitutes().first;
    await open(tester, const InstituteDetailsView(controllerTag: 'i'), 'tab_courses');
    final tabView = find.byType(TabBarView);
    expect(find.descendant(of: tabView, matching: find.byType(CourseRowCard)), findsWidgets);
    expect(find.descendant(of: tabView, matching: find.byType(ListTile)), findsNothing);
    await close(tester);
  });
}
