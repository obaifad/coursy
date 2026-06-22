class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}
