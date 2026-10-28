import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// القصّتان على الخط المتقطع فتحتان حقيقيتان: يظهر منهما ما خلف البطاقة (هنا خلفية حمراء)، لا دائرة
/// بلون خلفية الصفحة مرسومة فوق البطاقة (كانت تظهر كقرص فاتح فوق ظلّ البطاقة).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  const ratio = 3.0;
  const behind = Color(0xFFE53935);

  testWidgets('the notches show what is behind the card', (tester) async {
    tester.view.physicalSize = const Size(360 * ratio, 600 * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: false, locale: 'ar');
    final key = GlobalKey();
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
    await tester.pumpWidget(
      auditApp(
        locale: 'ar',
        scale: 1,
        boundaryKey: key,
        child: ColoredBox(
          color: behind,
          child: Center(
            child: Builder(
              builder: (context) => SizedBox(
                width: CourseCardMetrics.featuredCardWidth(context),
                height: CourseCardMetrics.featuredCardHeight(context),
                child: CourseCard(course: course, showFavorite: false),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final card = tester.getRect(find.byType(CourseCard));
    final spec = CourseCardMetrics.ticketSpec(card.width, textScale: 1);
    final notchY = card.bottom - spec.notchFromBottom;
    final image = await tester.runAsync(
      () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: ratio),
    );
    final rgba = (await tester.runAsync(() => image!.toByteData()))!;
    Color pixel(Offset p) {
      final i = ((p.dy * ratio).round() * image!.width + (p.dx * ratio).round()) * 4;
      return Color.fromARGB(rgba.getUint8(i + 3), rgba.getUint8(i), rgba.getUint8(i + 1), rgba.getUint8(i + 2));
    }

    bool nearBehind(Color c) =>
        (c.r - behind.r).abs() < 0.08 && (c.g - behind.g).abs() < 0.08 && (c.b - behind.b).abs() < 0.08;

    // داخل الفتحتين (3 من الحافة): لون ما خلف البطاقة.
    expect(
      nearBehind(pixel(Offset(card.left + 3, notchY))),
      isTrue,
      reason: 'left notch: ${pixel(Offset(card.left + 3, notchY))}',
    );
    expect(
      nearBehind(pixel(Offset(card.right - 3, notchY))),
      isTrue,
      reason: 'right notch: ${pixel(Offset(card.right - 3, notchY))}',
    );
    // جسم البطاقة بجانب الفتحة أبيض.
    expect(pixel(Offset(card.left + 3, notchY - 20)), const Color(0xFFFFFFFF));
    image!.dispose();
  });
}
