import 'package:flutter/foundation.dart';

/// عنوان الـ API — يمكن تغييره عند التشغيل:
/// flutter run --dart-define=API_BASE_URL=http://alaamr22-001-site1.ntempurl.com/api

abstract final class ApiConfig {

  static const String baseUrl =
      String.fromEnvironment(

    'API_BASE_URL',

    defaultValue:
        'http://alaamr22-001-site1.ntempurl.com/api',
  );

  static const Duration connectTimeout =
      Duration(seconds: 30);

  static const Duration receiveTimeout =
      Duration(seconds: 30);

  static String get baseOrigin {
    final raw = baseUrl;
    final idx = raw.indexOf('/api');
    if (idx > 0) return raw.substring(0, idx);
    return raw;
  }

  /// يحوّل مسار صورة نسبي من الـ API إلى رابط كامل (مثل storage/categories/icons/...).
  static String? resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().replaceAll('\\', '/');
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('/storage/')) return '$baseOrigin$v';
    if (v.startsWith('storage/')) return '$baseOrigin/$v';
    if (v.startsWith('/')) return '$baseOrigin$v';
    return '$baseOrigin/storage/$v';
  }

  /// true عند التشغيل على Chrome / Edge (ويب).
  static bool get isWeb => kIsWeb;

  /// على الويب، طلبات POST (دخول/تسجيل)
  /// غالباً تُحجب بسبب CORS ما لم يفعّلها مبرمج الـ API.
  static bool get loginNeedsNativePlatform =>
      kIsWeb;
}