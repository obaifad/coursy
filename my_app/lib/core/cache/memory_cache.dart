import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// قيمة محفوظة مع وقت حفظها.
class CacheEntry<T> {
  CacheEntry(this.value) : savedAt = MemoryCache.clock();

  CacheEntry.at(this.value, this.savedAt);

  final T value;
  final DateTime savedAt;

  /// طازجة: لا حاجة لإعادة الجلب. قديمة: نعرضها فوراً ونحدّثها بصمت في الخلفية.
  bool isFresh([Duration ttl = MemoryCache.defaultTtl]) => MemoryCache.clock().difference(savedAt) < ttl;
}

/// صفحة قائمة محفوظة: العناصر المحمّلة حتى الآن + حالة الترقيم، كي يُستأنف التمرير من حيث توقّف.
class PagedSnapshot<T> {
  PagedSnapshot({required Iterable<T> items, required this.hasMore, required this.page, this.total = 0})
    : items = List<T>.unmodifiable(items);

  final List<T> items;
  final bool hasMore;
  final int page;
  final int total;
}

/// ذاكرة مؤقتة داخل التطبيق (لا قرص) لبيانات الصفحات العامة: العودة إلى صفحة زرناها قبل قليل تعرض ما جُلب
/// فوراً بلا هيكل تحميل (stale-while-revalidate):
///  - طازجة (أقل من [defaultTtl]): لا طلب شبكة.
///  - قديمة: تُعرض فوراً ويُحدَّث المحتوى بصمت.
///  - السحب للتحديث يتجاوز الذاكرة دائماً ويكتب النتيجة فوقها.
///
/// المفتاح يتضمّن اللغة (الأسماء تُترجَم). تُمسح عند تسجيل الدخول/الخروج. حدّ أقصى [maxEntries] مدخلاً
/// (الأقدم استعمالاً يخرج أولاً). غير المسجّلة (الاختبارات) = لا تخزين.
class MemoryCache extends GetxService {
  static const Duration defaultTtl = Duration(minutes: 3);
  static const int maxEntries = 80;

  /// الساعة: تُستبدل في الاختبارات لتقديم الزمن دون انتظار.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final LinkedHashMap<String, CacheEntry<Object?>> _entries = LinkedHashMap();

  static MemoryCache? get _instance => Get.isRegistered<MemoryCache>() ? Get.find<MemoryCache>() : null;

  /// مفتاح موحّد: النطاق + اللغة + معرّفات الصفحة.
  static String key(String scope, [List<Object?> parts = const []]) =>
      [scope, Get.locale?.languageCode ?? 'ar', ...parts.map((p) => p ?? '')].join('|');

  static CacheEntry<T>? get<T>(String key) => _instance?._read<T>(key);

  static void put<T>(String key, T value) => _instance?._write<T>(key, value);

  static void clear() => _instance?._entries.clear();

  CacheEntry<T>? _read<T>(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    if (entry.value is! T) return null;
    _entries[key] = entry; // الأحدث استعمالاً في الآخر
    return CacheEntry<T>.at(entry.value as T, entry.savedAt);
  }

  void _write<T>(String key, T value) {
    _entries.remove(key);
    _entries[key] = CacheEntry<T>(value);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}
