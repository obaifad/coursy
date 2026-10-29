import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// بطاقة المدرّس في شريط الرئيسية (التصميم الجديد): رأس بتدرّج باستيل عليه رسوم خطّية باهتة، الصورة على حافّته
/// السفلى بشارة قبعة التخرّج، الاسم والتخصص في المنتصف، شارتا الكتاب والخبرة، وزر السعر بساعة رملية بعده.
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
    testWidgets('pastel header, avatar on its bottom edge, cap badge, centred text ($locale)', (tester) async {
      await pump(tester, tutor(), locale: locale);
      final card = tester.getRect(find.byType(PrivateInstructorMiniCard));
      final header = find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null,
      );
      final headerRect = tester.getRect(inCard(header).first);
      expect(headerRect.top, card.top);
      expect(headerRect.width, card.width, reason: 'the gradient spans the card');
      // الرسوم الخطّية: رسم واحد مخزّن (لا أيقونات تُخطَّط في كل بطاقة).
      final art = find.descendant(
        of: inCard(header).first,
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_TutorArtPainter',
        ),
      );
      expect(art, findsOneWidget);

      final photo = tester.getRect(inCard(find.byType(ClipOval)));
      expect(photo.center.dx, moreOrLessEquals(card.center.dx, epsilon: 0.5), reason: 'avatar centred');
      expect(photo.top, lessThan(headerRect.bottom));
      expect(photo.bottom, greaterThan(headerRect.bottom), reason: 'the avatar overlaps the header edge');

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
