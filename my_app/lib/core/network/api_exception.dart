import 'package:get/get.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors, this.code});

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  /// رمز خطأ ثابت من الخادم (مثل `transaction_already_used`) — للمطابقة بدل نص الرسالة.
  final String? code;

  @override
  String toString() => message;
}

/// طلب أُلغي (CancelToken) — لا يُعرض كخطأ ولا يُحدّث الـ UI.
class ApiCancelledException implements Exception {
  const ApiCancelledException();
}

/// نص خطأ مناسب للعرض: رسالة الخادم لـ [ApiException]، ونص عام مترجم لغيرها
/// (بدل `e.toString()` الذي كان يعرض تفاصيل تقنية مثل TypeError للمستخدم).
String userErrorMessage(Object error) => error is ApiException ? error.message : 'error_unexpected'.tr;
