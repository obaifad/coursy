import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// مخزن صور التطبيق على القرص، ومعرفة ما فيه دون انتظار.
///
/// الصور لا يُعاد تنزيلها (الخادم يرسلها `max-age` أسبوعاً، والملفات تبقى بين التشغيلات). لكن بعد إعادة
/// فتح التطبيق كانت كل صورة تمرّ بالمربع البنفسجي ثم تتلاشى فوقه، كأنها تُنزَّل: قراءتها من القرص وفكّها
/// غير متزامنين. [isOnDisk] يعرف مسبقاً ما خُزّن (من فهرس المخزن عند الإقلاع)، فتظهر تلك الصور فوراً بلا
/// مربع ولا تلاشٍ؛ التلاشي يبقى للصور الجديدة فعلاً.
abstract final class AppImageCache {
  AppImageCache._();

  /// مفتاح المخزن الافتراضي لـ cached_network_image نفسه: الصور المنزّلة قبل هذا الإصدار تبقى صالحة.
  static const key = 'libCachedImageData';

  /// كانت 200 (الافتراضي): بعدها يحذف المخزن الأقدم استخداماً — قليل لقوائم الدورات والمعاهد والمدرّسين.
  static const maxObjects = 1000;

  /// ما لم يُعرض منذ هذه المدة يُحذف من القرص.
  static const stalePeriod = Duration(days: 30);

  static final CacheObjectProvider _index = CacheObjectProvider(databaseName: key);

  static final CacheManager manager = CacheManager(
    Config(key, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxObjects, repo: _index),
  );

  static final Set<String> _onDisk = {};

  /// صورة نُزّلت من قبل وما زالت في المخزن (حسب فهرسه عند الإقلاع).
  static bool isOnDisk(String url) => _onDisk.contains(url);

  /// يقرأ فهرس المخزن مرة عند الإقلاع (قاعدة sqlite صغيرة، أجزاء من الثانية). فشله لا يمسّ شيئاً: الصور
  /// تُعرض كما كانت.
  static Future<void> warmUp() async {
    try {
      await _index.open();
      for (final object in await _index.getAllObjects()) {
        _onDisk.add(object.key);
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void markOnDiskForTest(Iterable<String> urls) => _onDisk
    ..clear()
    ..addAll(urls);
}
