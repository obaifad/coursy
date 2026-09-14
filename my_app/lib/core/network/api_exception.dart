class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}

/// طلب أُلغي (CancelToken) — لا يُعرض كخطأ ولا يُحدّث الـ UI.
class ApiCancelledException implements Exception {
  const ApiCancelledException();
}
