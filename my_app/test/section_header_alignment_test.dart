import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// عناوين أقسام الرئيسية: العنوان و«عرض الكل» على سطر واحد (خط أساس واحد)، بالعربية والإنجليزية.
void main() {
  setUpAll(loadAuditFonts);

  Future<void> pump(WidgetTester tester, {String? subtitle, TextDirection dir = TextDirection.rtl}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppSectionHeader(
                title: 'أحدث الدورات',
                subtitle: subtitle,
                actionLabel: 'عرض الكل',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// خط أساس النص على الشاشة: أعلى صندوقه + بُعد خط الأساس بنفس النص والنمط (TextPainter مستقل؛
  /// قراءة خط أساس RenderParagraph خارج التخطيط ممنوعة).
  double baselineOf(WidgetTester tester, String text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout();
    final top = paragraph.localToGlobal(Offset.zero).dy;
    final baseline = top + painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.dispose();
    return baseline;
  }

  for (final dir in TextDirection.values) {
    for (final subtitle in [null, 'سطر فرعي يشرح القسم']) {
      testWidgets('title and "show all" share one baseline (${dir.name}, subtitle: ${subtitle != null})', (
        tester,
      ) async {
        await pump(tester, subtitle: subtitle, dir: dir);
        expect(baselineOf(tester, 'عرض الكل'), closeTo(baselineOf(tester, 'أحدث الدورات'), 0.5));
      });
    }
  }
}
