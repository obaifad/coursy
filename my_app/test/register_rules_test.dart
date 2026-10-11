import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/modules/auth/controllers/auth_controller.dart';

import 'layout/fakes.dart';

/// يملأ الخطوة الأولى بقيم صحيحة وينتقل للخطوة الثانية (الأمان والملف).
Future<AuthController> _atStepTwo({required String password, String? confirm}) async {
  await registerFakes(loggedIn: false, locale: 'ar');
  final controller = Get.put(AuthController());
  controller.firstNameController.text = 'أحمد';
  controller.lastNameController.text = 'علي';
  controller.emailController.text = 'ahmad@example.com';
  controller.phoneController.text = '0933123456';
  await controller.nextRegisterStep();
  expect(controller.registerStep.value, 1, reason: 'step 1 should pass');

  controller.registerPasswordController.text = password;
  controller.confirmPasswordController.text = confirm ?? password;
  return controller;
}

void main() {
  setUp(() => Get.locale = const Locale('ar'));
  tearDown(Get.reset);

  test('a 6-character password of any kind is accepted', () async {
    for (final password in ['123456', 'abcdef', '!@#\$%^', 'ab12cd']) {
      final controller = await _atStepTwo(password: password);
      await controller.nextRegisterStep();

      expect(controller.registerFieldErrors, isEmpty, reason: password);
      expect(controller.registerStep.value, 2, reason: password);
      Get.reset();
    }
  });

  test('fewer than 6 characters is rejected', () async {
    final controller = await _atStepTwo(password: '12345');
    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors['password'], isNotNull);
    expect(controller.registerStep.value, 1);
  });

  test('gender and date of birth can be left empty', () async {
    final controller = await _atStepTwo(password: 'abcdef');
    expect(controller.selectedGender.value, isNull);
    expect(controller.birthDate.value, isNull);

    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors.containsKey('gender'), isFalse);
    expect(controller.registerFieldErrors.containsKey('birthDate'), isFalse);
    expect(controller.registerStep.value, 2);
  });

  test('a mismatching confirmation is still rejected', () async {
    final controller = await _atStepTwo(password: 'abcdef', confirm: 'abcdeg');
    await controller.nextRegisterStep();

    expect(controller.registerFieldErrors['confirmPassword'], isNotNull);
    expect(controller.registerStep.value, 1);
  });
}
