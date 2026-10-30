import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// بطاقة المدرّس في شريط الرئيسية (التصميم الجديد): بطاقة بيضاء بلا رأس ملوّن، الصورة الدائرية في أعلاها بشارة
/// قبعة التخرّج، الاسم والتخصص في المنتصف، كبسولة الخبرة، وزر السعر بتدرّج الهوية وساعة رملية بعده.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  InstructorModel tutor({int experience = 3}) => InstructorModel.fromJson({
    'id': 9,
    'name_ar': 'الأستاذ أحمد سعيد',
    'name_en': 'Mr. Ahmad Saeed',
    'specialization_ar': 'مدرس اللغة العربية',
    'specialization_en': 'Arabic language teacher',
    'experience_years': experience,
    'hourly_price': 5533,
    'is_private': 1,
  });

  Future<void> pump(WidgetTester tester, InstructorModel instructor, {String locale = 'ar'}) async {
    Get.locale = Locale(locale);
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      auditApp(
        locale: locale,
        scale: 1,
        boundaryKey: GlobalKey(),
        child: Center(child: PrivateInstructorMiniCard(instructor: instructor)),
      ),
    );
  }

  Finder inCard(Finder f) => find.descendant(of: find.byType(PrivateInstructorMiniCard), matching: f);

  for (final locale in ['ar', 'en']) {
    testWidgets('plain white card: avatar at the top, cap badge, centred text ($locale)', (tester) async {
      await pump(tester, tutor(), locale: locale);
      final card = tester.getRect(find.byType(PrivateInstructorMiniCard));
      // لا رأس ملوّن ولا رسوم: التدرّج الوحيد في البطاقة هو زر السعر.
      final gradients = inCard(
        find.byWidgetPredicate(
          (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null,
        ),
      );
      expect(gradients, findsOneWidget);
      expect(find.descendant(of: gradients, matching: find.textContaining('hourly_rate_label'.tr)), findsOneWidget);
      expect(
        inCard(find.byType(CustomPaint)).evaluate().where((e) {
          final painter = (e.widget as CustomPaint).painter;
          return painter != null && painter.runtimeType.toString() == '_TutorArtPainter';
        }),
        isEmpty,
      );

      final photo = tester.getRect(inCard(find.byType(ClipOval)));
      expect(photo.center.dx, moreOrLessEquals(card.center.dx, epsilon: 0.5), reason: 'avatar centred');
      // الحلقة (2.5) والإطار الأبيض (3) حول الصورة، وأعلاها تحت أعلى البطاقة بـ 18.
      expect(photo.top - 5.5 - card.top, moreOrLessEquals(18, epsilon: 0.5));

      final cap = tester.getRect(inCard(find.byIcon(Icons.school_rounded)));
      expect(cap.center.dx, greaterThan(photo.center.dx), reason: 'badge on the right');
      expect(cap.center.dy, lessThan(photo.center.dy), reason: 'badge on the top edge');

      final name = tester.getRect(find.text(tutor().name));
      expect(name.top, greaterThan(photo.bottom));
      expect(name.center.dx, moreOrLessEquals(card.center.dx, epsilon: 1));
      expect(find.text(tutor().specializationLabel!), findsOneWidget);
    });

    testWidgets('the experience pill alone, centred, and an hourglass after the price ($locale)', (tester) async {
      await pump(tester, tutor(), locale: locale);
      expect(inCard(find.byIcon(Icons.menu_book_outlined)), findsNothing, reason: 'no book badge');
      final card = tester.getRect(find.byType(PrivateInstructorMiniCard));
      final medal = tester.getRect(inCard(find.byIcon(Icons.workspace_premium_rounded)));
      final pillRect = tester.getRect(
        find.ancestor(of: find.byIcon(Icons.workspace_premium_rounded), matching: find.byType(DecoratedBox)).first,
      );
      expect(pillRect.center.dx, moreOrLessEquals(card.center.dx, epsilon: 0.5), reason: 'pill centred');
      expect(pillRect.height, 28, reason: 'pill keeps the row height');
      expect(pillRect.contains(medal.center), isTrue);

      final button = find.ancestor(of: find.textContaining('hourly_rate_label'.tr), matching: find.byType(Container));
      final hourglass = tester.getRect(inCard(find.byIcon(Icons.hourglass_bottom_rounded)));
      final label = tester.getRect(find.textContaining('hourly_rate_label'.tr));
      expect(
        locale == 'ar' ? hourglass.right < label.left : hourglass.left > label.right,
        isTrue,
        reason: 'the hourglass trails the price',
      );
      final decoration = tester.widget<Container>(button.first).decoration! as BoxDecoration;
      expect(decoration.gradient, isNotNull, reason: 'gradient button');
    });
  }

  testWidgets('no experience: no pill, same card height', (tester) async {
    await pump(tester, tutor());
    final withExperience = tester.getSize(find.byType(PrivateInstructorMiniCard)).height;
    // GetMaterialApp لا يعيد بناء home إن تغيّر: شجرة جديدة.
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, tutor(experience: 0));
    expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
    expect(inCard(find.byIcon(Icons.menu_book_outlined)), findsNothing);
    expect(tester.getSize(find.byType(PrivateInstructorMiniCard)).height, withExperience);
  });
}
