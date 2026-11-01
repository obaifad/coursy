import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// سطر المعلومات في البطاقات الصفّية (نجمة + «5.0 (2)»، كتاب + «دورة واحدة»): النص كان أوطأ من منتصف
/// الأيقونة ~1.4 لأن ثيم Material 3 يوزّع المسافة الإضافية بالتساوي، وصعود Tajawal أكبر من نزوله.
/// يُقاس هنا ما يُرسم فعلاً: منتصف حبر النص مقابل منتصف حبر النجمة.
void main() {
  setUpAll(loadAuditFonts);

  const ratio = 4.0;

  /// أعلى وأسفل صفّ فيه حبر (بكسل يختلف عن الخلفية) داخل [rect]، بوحدات منطقية.
  (double, double) inkRows(ByteData rgba, int width, Rect rect, ui.Color background) {
    int? first;
    int? last;
    final x0 = (rect.left * ratio).floor(), x1 = (rect.right * ratio).ceil();
    final y0 = ((rect.top - 6) * ratio).floor(), y1 = ((rect.bottom + 6) * ratio).ceil();
    final bg = [background.r, background.g, background.b].map((c) => (c * 255).round()).toList();
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        final i = (y * width + x) * 4;
        final d =
            (rgba.getUint8(i) - bg[0]).abs() +
            (rgba.getUint8(i + 1) - bg[1]).abs() +
            (rgba.getUint8(i + 2) - bg[2]).abs();
        if (d > 60) {
          first ??= y;
          last = y;
          break;
        }
      }
    }
    return (first! / ratio, (last! + 1) / ratio);
  }

  for (final locale in ['ar', 'en']) {
    testWidgets('meta text sits on the icon centreline ($locale)', (tester) async {
      tester.view.physicalSize = const Size(300 * ratio, 120 * ratio);
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        auditApp(
          locale: locale,
          scale: 1,
          boundaryKey: key,
          child: const ColoredBox(
            color: Colors.white,
            child: Center(
              child: AppRowMeta(icon: Icons.star_rounded, text: '5.0 (2)', emphasized: true),
            ),
          ),
        ),
      );
      final star = tester.getRect(find.byIcon(Icons.star_rounded));
      final text = tester.getRect(find.text('5.0 (2)'));
      final image = await tester.runAsync(
        () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: ratio),
      );
      final rgba = (await tester.runAsync(() => image!.toByteData()))!;
      final (starTop, starBottom) = inkRows(rgba, image!.width, star, Colors.white);
      final (textTop, textBottom) = inkRows(rgba, image.width, text, Colors.white);
      image.dispose();
      final starCentre = (starTop + starBottom) / 2;
      final textCentre = (textTop + textBottom) / 2;
      expect(textCentre, moreOrLessEquals(starCentre, epsilon: 0.6), reason: 'star $starCentre, text $textCentre');
    });
  }
}
