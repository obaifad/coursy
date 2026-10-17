import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// آخر رد لـ `/homepage` على الجهاز، لكل لغة ولكل جمهور (زائر / طالب بعينه) لأن الخادم قد يخصّص الرد
/// بحسب التوكن. تُرسم الرئيسية منه فوراً عند فتح التطبيق ثم يُستبدل بالرد الجديد من الشبكة.
class HomeCache extends GetxService {
  HomeCache({GetStorage? box}) : _box = box;

  static const _payloadPrefix = 'home_payload_v1';
  static const _studentMarker = ':student_';

  GetStorage? _box;

  /// يُفتح عند أول استخدام (بعد GetStorage.init في main) لا عند الإنشاء.
  GetStorage get _storage => _box ??= GetStorage();

  /// مفتاح الجمهور: `guest` أو `student_<id>`.
  static String audienceKey({required bool loggedIn, int? studentId}) =>
      loggedIn ? 'student_${studentId ?? 0}' : 'guest';

  Map<String, dynamic>? readPayload(String lang, String audience) {
    try {
      final raw = _storage.read<Object?>('$_payloadPrefix:$lang:$audience');
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writePayload(String lang, String audience, Map<String, dynamic> payload) async {
    try {
      await _storage.write('$_payloadPrefix:$lang:$audience', payload);
    } catch (_) {
      // الكاش تحسين فقط — فشل الكتابة لا يؤثر على الرئيسية.
    }
  }

  /// عند تسجيل الخروج: يحذف كل ما خُزّن لحسابات الطلاب، ويبقى رد الزائر العام.
  Future<void> clearStudentEntries() async {
    try {
      final keys = _storage
          .getKeys<Iterable<String>>()
          .where((k) => k.startsWith(_payloadPrefix) && k.contains(_studentMarker))
          .toList();
      for (final key in keys) {
        await _storage.remove(key);
      }
    } catch (_) {}
  }
}
