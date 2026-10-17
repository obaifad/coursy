import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/auth/controllers/auth_controller.dart';
import 'package:my_app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/auth/views/auth_views.dart';
import 'package:my_app/routes/app_pages.dart';
import 'package:my_app/routes/app_routes.dart';
import 'package:my_app/widgets/dismiss_keyboard.dart';

import 'layout/fakes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('Register -> Login keeps the shared AuthController and its fields alive', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: false, locale: 'ar');

    await tester.pumpWidget(GetMaterialApp(getPages: AppPages.pages, initialRoute: AppRoutes.register));
    await tester.pumpAndSettle();
    final controller = Get.find<AuthController>();

    // «لديك حساب؟ سجّل الدخول» يستبدل صفحة التسجيل بصفحة الدخول.
    Get.offNamed<void>(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(Get.isRegistered<AuthController>(), isTrue);
    expect(identical(Get.find<AuthController>(), controller), isTrue);
    await tester.enterText(find.byType(TextField).first, 'student@example.com');
    await tester.pump();
    expect(controller.loginIdController.text, 'student@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('logging out clears the login and register fields', (tester) async {
    await registerFakes(loggedIn: false, locale: 'ar');
    AuthController.ensureRegistered();
    final c = Get.find<AuthController>();
    c.loginIdController.text = 'a@b.co';
    c.passwordController.text = 'secret';
    c.emailController.text = 'a@b.co';
    c.registerPasswordController.text = 'secret';

    c.resetAfterLogout();

    expect(c.loginIdController.text, isEmpty);
    expect(c.passwordController.text, isEmpty);
    expect(c.emailController.text, isEmpty);
    expect(c.registerPasswordController.text, isEmpty);
  });

  group('Forgot password reacts to its state', () {
    Future<ForgotPasswordController> pump(WidgetTester tester) async {
      await registerFakes(loggedIn: false, locale: 'ar');
      final c = Get.put(ForgotPasswordController());
      await tester.pumpWidget(const GetMaterialApp(home: ForgotPasswordView()));
      await tester.pump();
      return c;
    }

    testWidgets('email step: errors and the loading button update', (tester) async {
      final c = await pump(tester);

      c.errors['email'] = 'بريد غير صالح';
      await tester.pump();
      expect(find.text('بريد غير صالح'), findsOneWidget);

      c.isSending.value = true;
      await tester.pump();
      expect(find.text('send_reset_code'), findsNothing); // الزر يعرض مؤشر التحميل

      c.isSending.value = false;
      await tester.pump();
      expect(find.text('send_reset_code'), findsOneWidget);
    });

    testWidgets('code step: countdown and password toggle update', (tester) async {
      final c = await pump(tester);
      c.step.value = 1;
      c.resendIn.value = 42;
      await tester.pump();
      expect(find.text('resend_after'), findsOneWidget);

      c.resendIn.value = 0;
      await tester.pump();
      expect(find.text('resend_otp'), findsOneWidget);

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });
  });

  testWidgets('tapping outside a text field closes the keyboard; tapping a button does not steal the tap', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboardOnTapOutside(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(),
              TextButton(onPressed: () => pressed++, child: const Text('go')),
              const SizedBox(height: 300, width: double.infinity),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('go'));
    await tester.pump();
    expect(pressed, 1);

    await tester.tapAt(tester.getCenter(find.byType(SizedBox).last));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.context?.widget is EditableText, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });
  testWidgets('"Done" on the login password submits the form', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await registerFakes(loggedIn: false, locale: 'ar');
    AuthController.ensureRegistered();
    await tester.pumpWidget(const GetMaterialApp(home: LoginView()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'not-a-login');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    // التحقق من المعرّف يعمل — أي أن login() استُدعي.
    expect(find.text('enter_valid_login'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('category page accepts an id sent as text', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    Get.routing.args = <String, dynamic>{'id': '3', 'name': 'البرمجة'};
    final c = Get.put(CategoryCoursesController());
    await tester.pump();
    expect(c.categoryId, 3);
  });
}
