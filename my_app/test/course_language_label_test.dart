import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/language_label.dart';

/// شارة لغة الدورة: كانت تعرض رمز الخادم كما هو («ar»).
void main() {
  test('language codes become readable names in the app language', () {
    expect(courseLanguageLabel('ar', locale: 'ar'), 'العربية');
    expect(courseLanguageLabel('ar', locale: 'en'), 'Arabic');
    expect(courseLanguageLabel('EN', locale: 'ar'), 'الإنجليزية');
    expect(courseLanguageLabel(' fr ', locale: 'en'), 'French');
  });

  test('a ready-made name from the server is shown as is', () {
    expect(courseLanguageLabel('العربية', locale: 'ar'), 'العربية');
    expect(courseLanguageLabel('Kurdish', locale: 'en'), 'Kurdish');
  });
}
