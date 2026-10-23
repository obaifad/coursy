import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/institutes/views/institutes_views.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// الروابط الخارجية تفشل بهدوء ومع رسالة: جهاز بلا تطبيق اتصال (لوحي، بلا شريحة).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  testWidgets('institute "Call" without a dialer copies the number and says so', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    // لا تطبيق يفتح tel: (Android يرجع false).
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, (call) async => false);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, null));

    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(InstituteDetailsController(), tag: 't').institute.value = sampleInstitutes().first.copyWith(
      phone: '0912 345 678',
    );
    await tester.pumpWidget(
      auditApp(
        child: const InstituteDetailsView(controllerTag: 't'),
        locale: 'ar',
        scale: 1,
        boundaryKey: GlobalKey(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final call = find.text('contact_call'.tr);
    await tester.scrollUntilVisible(call, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(call);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('call_failed'.tr), findsOneWidget, reason: 'nothing happened and nothing was said');
    expect(copied, '0912 345 678');
    // الرسالة تُغلق قبل تفكيك الشجرة (مؤقّت حركتها).
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
