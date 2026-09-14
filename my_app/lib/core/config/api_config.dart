import 'package:flutter/foundation.dart';

/// عناوين الخادم — يمكن تجاوز الـ API عند التشغيل:
/// flutter run --dart-define=API_BASE_URL=https://coursy.sy/api
///
/// تطوير الويب على Chrome: شغّل `scripts/run_web_chrome.ps1` (يبدأ بروكسي CORS محلياً).
abstract final class ApiConfig {
  /// الموقع والداشبورد (الدومين الرئيسي).
  static const String siteUrl = 'https://coursy.sy';

  /// منفذ بروكسي التطوير — يجب أن يطابق `tool/dev_cors_proxy.dart`.
  static const int webDevProxyPort = 5478;

  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// على الويب في وضع التطوير نستخدم بروكسي محلياً لتجاوز CORS (localhost → coursy.sy).
  static bool get usesWebDevProxy =>
      kIsWeb && kDebugMode && _apiBaseUrlOverride.isEmpty;

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (usesWebDevProxy) {
      return 'http://127.0.0.1:$webDevProxyPort/api';
    }
    return '$siteUrl/api';
  }

  static const Duration connectTimeout = Duration(seconds: 30);

  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get baseOrigin {
    if (usesWebDevProxy) return siteUrl;
    final raw = baseUrl;
    final idx = raw.indexOf('/api');
    if (idx > 0) return raw.substring(0, idx);
    return siteUrl;
  }

  /// يحوّل مسار صورة نسبي من الـ API إلى رابط كامل (مثل storage/categories/icons/...).
  static String? resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().replaceAll('\\', '/');
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return _rewriteLegacyMediaHost(v);
    }
    if (v.startsWith('/storage/')) return '$baseOrigin$v';
    if (v.startsWith('storage/')) return '$baseOrigin/$v';
    if (v.startsWith('/')) return '$baseOrigin$v';
    return '$baseOrigin/storage/$v';
  }

  /// يعيد كتابة روابط الاستضافة القديمة (ntempurl) إلى الدومين الحالي.
  static String _rewriteLegacyMediaHost(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      if (host.contains('ntempurl.com') || host.contains('tempurl')) {
        final path = uri.path.isEmpty ? '/' : uri.path;
        final query = uri.hasQuery ? '?${uri.query}' : '';
        return '$siteUrl$path$query';
      }
    } catch (_) {}
    return url;
  }

  /// true عند التشغيل على Chrome / Edge (ويب).
  static bool get isWeb => kIsWeb;

  /// على الويب، طلبات POST (دخول/تسجيل)
  /// غالباً تُحجب بسبب CORS ما لم يفعّلها مبرمج الـ API.
  static bool get loginNeedsNativePlatform => kIsWeb;
}
