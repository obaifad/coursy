import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/views/category_courses_view.dart';
import 'package:my_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:my_app/modules/favorites/views/favorites_view.dart';
import 'package:my_app/modules/instructors/controllers/instructor_details_controller.dart';
import 'package:my_app/modules/instructors/views/instructor_details_view.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/course_favorite_button.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// بطاقة صفحة الدورات (Aurora) هي الشكل المعتمد في المفضلة وصفحة التصنيف،
/// ورأس المدرّس (بلا صورة) يتبع الجنس في البطاقات وفي صفحة التفاصيل.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: screen, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('category page shows Aurora cards (not posters)', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة'};
    Get.put(CategoryCoursesController());
    await pumpScreen(tester, const CategoryCoursesView());

    expect(find.byType(CourseAuroraCard), findsWidgets);
    expect(find.byType(CoursePosterCard), findsNothing);
  });

  testWidgets('favorites shows Aurora cards and the heart removes the course', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final controller = Get.put(FavoritesController());
    await pumpScreen(tester, const FavoritesView());

    final before = controller.courses.length;
    expect(before, greaterThan(0));
    expect(find.byType(CourseAuroraCard), findsNWidgets(before));
    expect(find.byType(CourseRowCard), findsNothing);

    await tester.tap(find.byType(CourseFavoriteButton).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.courses.length, before - 1);
    expect(find.text('undo'.tr), findsOneWidget);
  });

  test('initials: first and last name, titles and the article dropped, letters kept apart', () {
    expect(instructorInitials('د. عبد الرحمن محمد الخطيب الحسيني'), 'ع‌ح');
    expect(instructorInitials('أ. سارة الأحمد'), 'س‌أ');
    expect(instructorInitials('Dr. john smith'), 'J‌S');
    expect(instructorInitials('ليلى'), 'ل');
    expect(instructorInitials('الياس'), 'ي', reason: 'a leading article is skipped even in a single name');
    expect(instructorInitials('  '), isEmpty);
    expect(instructorInitials('د.'), isEmpty);
    expect(instructorInitials(null), isEmpty);
  });

  const faces = [Icons.face_6_rounded, Icons.face_3_rounded, Icons.face_rounded];

  for (final (name, expected) in [('سامر الخطيب', 'س‌خ'), ('', null)]) {
    testWidgets('instructor details without a photo, name "$name" -> ${expected ?? 'neutral person icon'}', (
      tester,
    ) async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.routing.args = InstructorModel.fromJson({
        'id': 7,
        'name_ar': name,
        'name_en': name,
        'is_private': true,
        'gender': 'male',
      });
      Get.put(InstructorDetailsController(), tag: 'placeholder-test');
      await pumpScreen(tester, const InstructorDetailsView(controllerTag: 'placeholder-test'));

      for (final face in faces) {
        expect(find.byIcon(face), findsNothing, reason: 'no cartoon faces');
      }
      expect(find.byType(InstructorPlaceholder), findsWidgets);
      if (expected != null) {
        expect(find.text(expected), findsWidgets);
      } else {
        expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
      }
    });
  }
}
