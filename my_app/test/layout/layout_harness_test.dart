import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'layout_harness.dart';

/// فحص التخطيط نفسه: يفشل عند أي فيض (حتى أسفل الصفحة، خارج أول شاشة)، ويسمح بالقصّ بـ "…".
void main() {
  setUpAll(loadAuditFonts);
  setUp(Get.reset);

  Future<List<LayoutIssue>> audit(WidgetTester tester, Widget Function() scene) => auditScene(
    tester,
    'harness',
    scene,
    viewports: const [AuditViewport('phone-360', Size(360, 780))],
    scales: const [1.0],
    locales: const ['ar'],
  );

  testWidgets('a RenderFlex overflow below the first screen fails the audit', (tester) async {
    Object? failure;
    try {
      await audit(
        tester,
        () => ListView(
          children: [
            for (var i = 0; i < 30; i++) const SizedBox(height: 60, child: Text('سطر')),
            const Row(children: [SizedBox(width: 400, height: 20)]),
          ],
        ),
      );
    } on TestFailure catch (e) {
      failure = e;
    }
    expect(failure, isNotNull, reason: 'an overflow that only shows after scrolling went unnoticed');
    expect('$failure', contains('overflowed'));
  });

  testWidgets('text cut with an ellipsis is allowed', (tester) async {
    final issues = await audit(
      tester,
      () => const SizedBox(
        width: 120,
        child: Text('اسم طويل جداً لا يتسع في سطر واحد', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    expect(issues.map((i) => i.kind), contains('truncated'));
  });
}
