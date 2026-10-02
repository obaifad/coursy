import 'package:get/get.dart';

import 'locale_controller.dart';

/// نص عدد بصيغة الجمع الصحيحة (قواعد CLDR):
/// - العربية: zero (0) · one (1) · two (2) · few (3–10) · many (11–99) · other (100+)
///   مثال: دورة واحدة · دورتان · 4 دورات · 15 دورة
/// - الإنجليزية: one (1) · other
///
/// يبحث عن المفتاح `key_form` ثم `key_other` ثم `key` نفسه. [n] متاح في النص كـ @n و@count و@years.
String pluralTr(String key, int n, {Map<String, String> params = const {}}) {
  final all = {'n': '$n', 'count': '$n', 'years': '$n', ...params};
  for (final candidate in ['${key}_${_pluralForm(n)}', '${key}_other', key]) {
    final translated = candidate.trParams(all);
    if (translated != candidate) return translated;
  }
  return key;
}

String _pluralForm(int n) {
  final isArabic = Get.isRegistered<LocaleController>()
      ? Get.find<LocaleController>().code.value == 'ar'
      : Get.locale?.languageCode != 'en';
  if (!isArabic) return n == 1 ? 'one' : 'other';
  if (n == 0) return 'zero';
  if (n == 1) return 'one';
  if (n == 2) return 'two';
  final mod = n % 100;
  if (mod >= 3 && mod <= 10) return 'few';
  if (mod >= 11 && mod <= 99) return 'many';
  return 'other';
}
