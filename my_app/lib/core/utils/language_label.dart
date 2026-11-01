/// لغة الدورة كما يرسلها الخادم (رمز مثل `ar` أو اسم جاهز) ← اسم يقرؤه الطالب بلغة التطبيق.
/// كانت شارة الدورة تعرض الرمز نفسه («ar»).
String courseLanguageLabel(String value, {required String locale}) {
  final names = _names[value.trim().toLowerCase()];
  if (names == null) return value.trim();
  return locale == 'en' ? names.$2 : names.$1;
}

const _names = <String, (String, String)>{
  'ar': ('العربية', 'Arabic'),
  'arabic': ('العربية', 'Arabic'),
  'en': ('الإنجليزية', 'English'),
  'english': ('الإنجليزية', 'English'),
  'fr': ('الفرنسية', 'French'),
  'french': ('الفرنسية', 'French'),
  'de': ('الألمانية', 'German'),
  'german': ('الألمانية', 'German'),
  'tr': ('التركية', 'Turkish'),
  'turkish': ('التركية', 'Turkish'),
  'ru': ('الروسية', 'Russian'),
  'russian': ('الروسية', 'Russian'),
  'es': ('الإسبانية', 'Spanish'),
  'spanish': ('الإسبانية', 'Spanish'),
  'ar_en': ('العربية والإنجليزية', 'Arabic & English'),
  'ar,en': ('العربية والإنجليزية', 'Arabic & English'),
};
