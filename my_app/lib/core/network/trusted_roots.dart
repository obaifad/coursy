import 'trusted_roots_stub.dart' if (dart.library.io) 'trusted_roots_io.dart' as impl;

/// جذور Let's Encrypt التي تقوم عليها شهادة coursy.sy (ISRG Root X1 وX2).
///
/// Android 6.0–7.0 (API 23–24) لا تحتويهما في مخزن النظام (أُضيف X1 في Android 7.1.1)، وطلبات Dart تثق
/// بمخزن النظام فقط على Android — فكان كل طلب للخادم يفشل بخطأ TLS («تعذّر الاتصال بالخادم») على هذه
/// الأجهزة رغم أن minSdk = 23. نضيفهما إلى سياق TLS الافتراضي عند الإقلاع (Dio وصور cached_network_image
/// يستعملانه). لا يُضعف التحقق: يُضاف جذران عامّان معروفان فقط، والسلسلة تُتحقق كاملة كالمعتاد.
abstract final class TrustedRoots {
  // شهادات عامة (لا مفاتيح): امتداد .crt لأن ‎*.pem مستثنى في ‎.gitignore لحماية المفاتيح الخاصة.
  static const assets = ['assets/certs/isrg_root_x1.crt', 'assets/certs/isrg_root_x2.crt'];

  static Future<void> install() => impl.installTrustedRoots(assets);
}
