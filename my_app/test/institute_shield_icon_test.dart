import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/widgets/design_system.dart';

import 'layout/layout_harness.dart';

/// شارة «الأعلى تقييماً» (تقييم 4.5 فأكثر) بأيقونة درع التوثيق لا الكأس، في بطاقة القائمة وبطاقة الرئيسية.
InstituteModel _institute(double rating) => InstituteModel.fromJson({
  'id': 5,
  'name_ar': 'معهد',
  'name_en': 'Institute',
  'average_rating': rating,
  'is_verified': false,
});

void main() {
  setUpAll(loadAuditFonts);

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: child, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.pump();
  }

  testWidgets('list card: top-rated institute shows the shield, no trophy', (tester) async {
    await pump(tester, InstituteListCard(institute: _institute(4.8)));
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
  });

  testWidgets('list card: a lower rating shows neither', (tester) async {
    await pump(tester, InstituteListCard(institute: _institute(4.0)));
    expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
  });

  testWidgets('home card: top-rated chip uses the shield', (tester) async {
    await pump(tester, SizedBox(height: 260, child: InstituteMiniCard(institute: _institute(4.8))));
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
  });
}
