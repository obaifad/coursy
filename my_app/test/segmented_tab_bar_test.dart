import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// شريط التبويبات الموحّد: يملأ العرض بخلايا متساوية ما دامت النصوص تتّسع (صفحة المدرّس بـ 4 تبويبات
/// كانت تتحوّل للتمرير على هاتف 360dp فتنكمش لجهة واحدة)، ولا يمرّر إلا حين لا تتّسع فعلاً.
void main() {
  setUpAll(loadAuditFonts);

  Future<TabBar> pumpBar(
    WidgetTester tester, {
    required double width,
    required List<String> labels,
    double textScale = 1.0,
    TextDirection direction = TextDirection.rtl,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: DefaultTabController(
                length: labels.length,
                child: Builder(
                  builder: (context) => Padding(
                    // نفس حشوة صفحتي المدرّس والمعهد.
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: AppSegmentedTabBar(
                      controller: DefaultTabController.of(context),
                      tabs: [for (final l in labels) Tab(text: l)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tester.widget<TabBar>(find.byType(TabBar));
  }

  const instructorEn = ['Info', 'Courses', 'Institutes', 'Reviews'];
  const instructorAr = ['المعلومات', 'الدورات', 'المعاهد', 'التقييمات'];

  testWidgets('instructor page: 4 English tabs fill a 360dp phone', (tester) async {
    final bar = await pumpBar(tester, width: 360, labels: instructorEn, direction: TextDirection.ltr);
    expect(bar.isScrollable, isFalse);
    expect(bar.tabAlignment, TabAlignment.fill);
  });

  testWidgets('instructor page: 4 Arabic tabs fill a 360dp phone', (tester) async {
    final bar = await pumpBar(tester, width: 360, labels: instructorAr);
    expect(bar.isScrollable, isFalse);
  });

  testWidgets('institute page: 3 tabs fill a 320dp phone', (tester) async {
    final bar = await pumpBar(tester, width: 320, labels: const ['المعلومات', 'الدورات', 'المدرّسون']);
    expect(bar.isScrollable, isFalse);
  });

  testWidgets('falls back to scrolling only when the labels really do not fit', (tester) async {
    final bar = await pumpBar(tester, width: 320, labels: instructorEn, textScale: 1.3, direction: TextDirection.ltr);
    expect(bar.isScrollable, isTrue);
    expect(tester.takeException(), isNull);
  });
}
