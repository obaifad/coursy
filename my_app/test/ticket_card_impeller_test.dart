import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// بطاقة التذكرة بلا قصّ بمسار معقّد (Path.combine + ClipPath): كان يُرسم خطأً بمحرّك Impeller على Adreno 618
/// (Redmi Note 9 Pro) فتظهر كبسولة الحسم فارغة. القصّتان دائرتان بلون خلفية الصفحة.
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  final course = CourseModel.fromJson({
    'id': 4,
    'title_ar': 'تصميم واجهات تطبيقات الموبايل',
    'title_en': 'Mobile UI',
    'price': '20000.00',
    'discount_price': '19000.00',
    'study_type': 'offline',
    'level': 'beginner',
    'category': {'id': 1, 'name_ar': 'الأعمال', 'name_en': 'Business'},
    'institute_name': 'Al-Sham Private University',
  });

  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(
      auditApp(
        locale: 'ar',
        scale: scale,
        boundaryKey: GlobalKey(),
        child: Builder(
          builder: (context) => Center(
            child: SizedBox(
              width: CourseCardMetrics.featuredCardWidth(context),
              height: CourseCardMetrics.featuredCardHeight(context),
              child: CourseCard(course: course, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no path clip in the card; two notch circles on the card edges', (tester) async {
    await pump(tester);
    // Material(transparency) يضيف ClipPath بلا قصّ (Clip.none) — لا يُرسم. المطلوب: لا قصّ فعلي بمسار.
    final realPathClips = find.descendant(
      of: find.byType(CourseCard),
      matching: find.byWidgetPredicate((w) => w is ClipPath && w.clipBehavior != Clip.none),
    );
    expect(realPathClips, findsNothing);
    final notches = find.byKey(const ValueKey('ticket-notch'));
    expect(notches, findsNWidgets(2));
    final card = tester.getRect(find.byType(CourseCard));
    final a = tester.getRect(notches.at(0));
    final b = tester.getRect(notches.at(1));
    final centers = [a.center.dx, b.center.dx]..sort();
    expect(centers.first, closeTo(card.left, 0.5));
    expect(centers.last, closeTo(card.right, 0.5));
    expect(a.center.dy, closeTo(b.center.dy, 0.01));
  });

  testWidgets('the discount pill and both prices are there', (tester) async {
    await pump(tester);
    expect(find.text('-5%'), findsOneWidget);
    expect(find.text('20,000'), findsOneWidget);
  });

  testWidgets('taps still reach the card', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(
      auditApp(
        locale: 'ar',
        scale: 1,
        boundaryKey: GlobalKey(),
        child: Center(
          child: SizedBox(
            width: 230,
            height: 330,
            child: CourseCard(course: course, onTap: () => taps++),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(course.title));
    expect(taps, 1);
  });

  testWidgets('fits at text scale 1.3', (tester) async {
    await pump(tester, scale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
