import 'package:flutter/foundation.dart';

/// اختبارات التوقيت (متى تبدأ الطلبات) لا تُفشلها أخطاء «RenderFlex overflowed»: التخطيط تغطيه اختبارات
/// التخطيط (test/layout) التي تفشل عند أي overflow. أي خطأ آخر يُفشل الاختبار كالعادة.
Future<void> ignoringOverflow(Future<void> Function() body) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = original;
  }
}
