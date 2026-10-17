import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/register_payload.dart';
import 'package:my_app/modules/auth/controllers/auth_controller.dart';
import 'package:my_app/modules/auth/widgets/register_form_widgets.dart';

import 'layout/fakes.dart';

/// خادم بلا بيانات مرجعية (مدن، تصنيفات): قائمة فارغة ليست خطأ اتصال، ولا تمنع إنشاء الحساب.
Future<AuthController> _atLastStep() async {
  await registerFakes(loggedIn: false, locale: 'ar');
  final controller = Get.put(AuthController());
  controller.firstNameController.text = 'أحمد';
  controller.lastNameController.text = 'علي';
  controller.emailController.text = 'ahmad@example.com';
  controller.phoneController.text = '0933123456';
  await controller.nextRegisterStep();
  controller.registerPasswordController.text = 'abcdef';
  controller.confirmPasswordController.text = 'abcdef';
  await controller.nextRegisterStep();
  expect(controller.registerStep.value, 2);
  // انتظار تحميل القوائم الذي يبدأ عند الوصول للخطوة الأخيرة، قبل تعديلها في الاختبار.
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return controller;
}

void main() {
  setUp(() => Get.locale = const Locale('ar'));
  tearDown(Get.reset);

  test('no cities on the server: the city is not required', () async {
    final controller = await _atLastStep();
    controller.cities.clear();

    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors.containsKey('city'), isFalse);
  });

  test('cities available but none picked: still required', () async {
    final controller = await _atLastStep();
    expect(controller.cities, isNotEmpty);

    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors['city'], isNotNull);
  });

  test('no universities to pick from: university fields do not block sign-up', () async {
    final controller = await _atLastStep();
    controller.cities.clear();
    controller.setEducationLevel('Bachelor');
    expect(controller.requiresUniversityFields, isTrue);
    controller.universities.clear();
    controller.specializations.clear();

    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors.containsKey('university'), isFalse);
    expect(controller.registerFieldErrors.containsKey('specialization'), isFalse);
  });

  test('without a city the payload has no city_id', () {
    final json = RegisterPayload(
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.c',
      password: 'secret12',
      passwordConfirmation: 'secret12',
    ).toJson();
    expect(json.containsKey('city_id'), isFalse);
  });

  Future<void> pumpInterests(WidgetTester tester, {String? errorText}) async {
    await registerFakes(loggedIn: false, locale: 'ar');
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: RegisterInterestPicker(
            categories: const [],
            selectedIds: const [],
            errorText: errorText,
            onReload: () {},
            onApply: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no interests on the server: the field is hidden, no connection error', (tester) async {
    await pumpInterests(tester);
    expect(find.text('connection_error'.tr), findsNothing);
    expect(find.text('reload_interests'.tr), findsNothing);
  });

  testWidgets('a real load failure still shows its error and a retry button', (tester) async {
    await pumpInterests(tester, errorText: 'connection_error'.tr);
    expect(find.text('connection_error'.tr), findsOneWidget);
    expect(find.text('reload_interests'.tr), findsOneWidget);
  });
}
