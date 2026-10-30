import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// آخر رد ناجح لطلبات GET مختارة على القرص — لكل مسار واستعلام ولغة وجمهور (زائر / طالب بعينه)، لأن
/// الخادم قد يخصّص الرد بحسب التوكن. حين يُغلق النظام التطبيق في الخلفية (أو يعيد إنشاء شاشته) تضيع الذاكرة
/// كلها؛ من هنا ترسم الشاشات الرئيسية فوراً عند الفتح ثم تُحدَّث من الشبكة بصمت.
///
/// يكتبه [ApiClient] (للمسارات في [ApiClient.diskCachedPaths] فقط) وتقرؤه المستودعات قبل أول طلب.
/// الصور لها مخزنها الخاص ([AppImageCache]).
class ApiDiskCache extends GetxService {
  ApiDiskCache({GetStorage? box}) : _box = box;

  static const boxName = 'api_cache';

  /// الأقدم يُحذف بعد هذا العدد (كل مدخل صفحة أولى من قائمة، بضعة عشرات من KB).
  static const maxEntries = 40;

  static const _studentMarker = '|student_';

  GetStorage? _box;

  /// يُفتح عند أول استخدام (بعد [init] في main) لا عند الإنشاء.
  GetStorage get _storage => _box ??= GetStorage(boxName);

  static Future<bool> init() => GetStorage.init(boxName);

  /// مفتاح الجمهور: `guest` أو `student_<id>`.
  static String audience({required bool loggedIn, int? studentId}) => loggedIn ? 'student_${studentId ?? 0}' : 'guest';

  /// المفتاح: المسار والاستعلام مرتّباً (بلا `lang`، فهو جزء منفصل) واللغة والجمهور.
  static String keyFor(String path, Map<String, dynamic> query, {required String lang, required String audience}) {
    final parts = [
      for (final e in query.entries)
        if (e.key != 'lang' && e.value != null) '${e.key}=${e.value}',
    ]..sort();
    return '$path?${parts.join('&')}|$lang|$audience';
  }

  /// جسم الرد المحفوظ كما فكّه Dio (Map/List)، أو null.
  dynamic read(String key) {
    try {
      final entry = _storage.read<Object?>(key);
      if (entry is Map && entry.containsKey('b')) return entry['b'];
    } catch (_) {}
    return null;
  }

  Future<void> write(String key, dynamic body) async {
    try {
      await _storage.write(key, {'t': DateTime.now().millisecondsSinceEpoch, 'b': body});
      await _evictOldest();
    } catch (_) {
      // الكاش تحسين فقط — فشل الكتابة لا يمسّ الطلب.
    }
  }

  Future<void> _evictOldest() async {
    final keys = _storage.getKeys<Iterable<String>>().toList();
    if (keys.length <= maxEntries) return;
    int savedAt(String k) {
      final e = _storage.read<Object?>(k);
      return e is Map && e['t'] is int ? e['t'] as int : 0;
    }

    keys.sort((a, b) => savedAt(a).compareTo(savedAt(b)));
    for (final k in keys.take(keys.length - maxEntries)) {
      await _storage.remove(k);
    }
  }

  /// عند تسجيل الخروج: يحذف ما خُزّن لحسابات الطلاب (الحجوزات، المقترحات…)، ويبقى ما يراه الزائر.
  Future<void> clearStudentEntries() async {
    try {
      for (final k in _storage.getKeys<Iterable<String>>().where((k) => k.contains(_studentMarker)).toList()) {
        await _storage.remove(k);
      }
    } catch (_) {}
  }
}
