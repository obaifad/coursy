import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/auth_repository.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/auth/controllers/email_verification_controller.dart';
import 'package:my_app/modules/auth/views/email_verification_view.dart';

import 'layout/fakes.dart';

class _FakeAuth extends AuthRepository {
  _FakeAuth(super.client, super.tokenStorage);

  int sends = 0;
  final verifiedCodes = <String>[];
  ApiException? sendError;
  ApiException? verifyError;

  @override
  Future<OtpSendResult> sendEmailVerificationCode() async {
    sends++;
    if (sendError != null) throw sendError!;
    return OtpSendResult(message: 'sent', resendAfterSeconds: 60);
  }

  @override
  Future<void> verifyEmailCode(String code) async {
    verifiedCodes.add(code);
    if (verifyError != null) throw verifyError!;
  }
}

Future<(_FakeAuth, EmailVerificationController)> _open(WidgetTester tester, {void Function(_FakeAuth)? setup}) async {
  Get.locale = const Locale('ar');
  await registerFakes(loggedIn: true, locale: 'ar');
  final auth = _FakeAuth(ApiClient(Get.find<TokenStorage>()), Get.find<TokenStorage>());
  setup?.call(auth);
  Get.delete<AuthRepository>(force: true);
  Get.put<AuthRepository>(auth);

  await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
  final controller = Get.put(EmailVerificationController(initialEmail: 'student@example.com'));
  Get.to<void>(() => const EmailVerificationView());
  await tester.pumpAndSettle();
  return (auth, controller);
}

void main() {
  tearDown(Get.reset);

  testWidgets('sends a code on open and locks resend during the countdown', (tester) async {
    final (auth, c) = await _open(tester);

    expect(auth.sends, 1);
    expect(c.resendSeconds.value, 60);
    expect(c.resendCountdown, '1:00');

    await c.sendCode(); // ما زال العدّاد يعمل — لا إرسال ثانٍ.
    expect(auth.sends, 1);

    await tester.pump(const Duration(seconds: 61));
    expect(c.resendSeconds.value, 0);
    await c.sendCode();
    expect(auth.sends, 2);

    Get.back<void>();
    await tester.pumpAndSettle();
    // في التطبيق يُحذف المتحكّم مع الصفحة فيتوقف العدّاد؛ هنا أُنشئ يدوياً.
    Get.delete<EmailVerificationController>();
  });

  testWidgets('typing all 6 digits verifies automatically', (tester) async {
    final (auth, c) = await _open(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(auth.verifiedCodes, ['123456']);
    expect(c.verified.value, isTrue);
    expect(find.text('email_verified_title'), findsWidgets);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('a wrong code shows the error, shakes and clears the field', (tester) async {
    final (auth, c) = await _open(tester, setup: (a) => a.verifyError = ApiException('bad', statusCode: 422));

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();

    expect(c.errorMessage.value, 'email_code_invalid');
    expect(c.errorTick.value, 1);
    expect(c.codeController.text, isEmpty);
    expect(c.verified.value, isFalse);

    // الكتابة من جديد تُخفي الخطأ.
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    expect(c.errorMessage.value, isNull);

    Get.back<void>();
    await tester.pumpAndSettle();
    // في التطبيق يُحذف المتحكّم مع الصفحة فيتوقف العدّاد؛ هنا أُنشئ يدوياً.
    Get.delete<EmailVerificationController>();
  });

  testWidgets('an already verified email (409) is treated as success', (tester) async {
    final (_, c) = await _open(tester, setup: (a) => a.sendError = ApiException('verified', statusCode: 409));

    expect(c.verified.value, isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
