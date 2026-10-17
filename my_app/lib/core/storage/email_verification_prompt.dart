import 'package:get_storage/get_storage.dart';

/// حين لا يسجّل الخادم دخول الطالب بعد إنشاء الحساب، تُفتح شاشة تأكيد البريد مرة واحدة بعد أول
/// تسجيل دخول بالبريد نفسه (وإلا بقي خيار «حسابي» الطريق الوحيد إليها).
abstract final class EmailVerificationPrompt {
  static const _key = 'email_verification_prompt';

  static String _normalize(String value) => value.trim().toLowerCase();

  /// يتذكّر البريد الذي أُنشئ به الحساب على هذا الجهاز.
  static Future<void> remember(String email) async {
    final value = _normalize(email);
    if (value.isEmpty) return;
    try {
      await GetStorage().write(_key, value);
    } catch (_) {}
  }

  /// true مرة واحدة إن كان [login] هو البريد المحفوظ؛ تُنسى العلامة بعد أي تسجيل دخول.
  static Future<bool> takeFor(String login) async {
    try {
      final box = GetStorage();
      final pending = box.read<String>(_key);
      if (pending == null) return false;
      await box.remove(_key);
      return pending == _normalize(login);
    } catch (_) {
      return false;
    }
  }
}
