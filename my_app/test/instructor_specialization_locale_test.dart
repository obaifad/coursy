import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_app/core/models/app_models.dart';

/// التخصص يتبع لغة الواجهة عند العرض (كان عربياً على بطاقة المدرّس بالإنجليزية).
void main() {
  tearDown(Get.reset);

  InstructorModel parsedIn(String locale, Map<String, dynamic> json) {
    Get.locale = Locale(locale);
    return InstructorModel.fromJson(json);
  }

  test('a plain Arabic "specialization" field does not beat specialization_en in English', () {
    final instructor = parsedIn('en', {
      'id': 19,
      'name': 'Tarek Nasser',
      'specialization': 'تطوير تطبيقات الموبايل',
      'specialization_ar': 'تطوير تطبيقات الموبايل',
      'specialization_en': 'Mobile App Development',
    });
    expect(instructor.specializationLabel, 'Mobile App Development');
  });

  test('parsed in Arabic, then the language switches to English', () {
    final instructor = parsedIn('ar', {
      'id': 19,
      'specialization': {'id': 3, 'name_ar': 'تطوير تطبيقات الموبايل', 'name_en': 'Mobile App Development'},
    });
    expect(instructor.specializationLabel, 'تطوير تطبيقات الموبايل');

    Get.locale = const Locale('en');
    expect(instructor.specializationLabel, 'Mobile App Development');
  });

  test('only one language from the server: shown as is, never empty', () {
    final instructor = parsedIn('en', {'id': 19, 'specialization': 'تطوير تطبيقات الموبايل'});
    expect(instructor.specializationLabel, 'تطوير تطبيقات الموبايل');
    expect(parsedIn('en', {'id': 20}).specializationLabel, isNull);
  });
}
