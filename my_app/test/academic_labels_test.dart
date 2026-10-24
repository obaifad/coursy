import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/modules/profile/controllers/profile_controller.dart';
import 'package:my_app/modules/profile/views/profile_views.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// المستوى التعليمي والجامعة والاختصاص في «المعلومات الأكاديمية» بلا «(اختياري)»: الجامعة والاختصاص
/// إلزاميان حين يظهران أصلاً (التحقق يرفض الحفظ بدونهما).
void main() {
  setUpAll(loadAuditFonts);
  tearDown(Get.reset);

  for (final (locale, level, university, specialization, optional) in [
    ('ar', 'المستوى التعليمي', 'الجامعة', 'الاختصاص', 'اختياري'),
    ('en', 'Education level', 'University', 'Specialization', 'optional'),
  ]) {
    testWidgets('edit profile academic section, $locale: no "$optional" on the three labels', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await registerFakes(loggedIn: true, locale: locale);
      final c = Get.put<ProfileController>(ProfileController());
      // مستوى يُظهر حقلَي الجامعة والاختصاص.
      c.setEducationLevel(ProfileController.educationLevels.firstWhere((e) => true && _needsUniversity(c, e)));
      await tester.pumpWidget(
        GetMaterialApp(translations: AppTranslations(), locale: Locale(locale), home: const EditProfileView()),
      );
      await tester.pumpAndSettle();

      expect(c.requiresUniversityFields, isTrue, reason: 'university and specialization are shown');
      for (final label in [level, university, specialization]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.textContaining('($optional)'), findsOneWidget, reason: 'only the interests label stays optional');
      expect(find.textContaining('$level ($optional)'), findsNothing);
      expect(find.textContaining('$university ($optional)'), findsNothing);
      expect(find.textContaining('$specialization ($optional)'), findsNothing);
    });
  }

  test('the registration form keeps its own (optional) labels', () {
    final ar = AppTranslations().keys['ar']!;
    final en = AppTranslations().keys['en']!;
    expect(ar['education_level_optional'], 'المستوى التعليمي (اختياري)');
    expect(ar['university_optional'], 'الجامعة (اختياري)');
    expect(ar['specialization_optional'], 'الاختصاص (اختياري)');
    expect(en['education_level_optional'], 'Education level (optional)');
    expect(en['university_optional'], 'University (optional)');
    expect(en['specialization_optional'], 'Specialization (optional)');
  });
}

bool _needsUniversity(ProfileController c, String level) {
  c.setEducationLevel(level);
  return c.requiresUniversityFields;
}
