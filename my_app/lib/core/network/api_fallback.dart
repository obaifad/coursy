import 'api_client.dart';
import 'api_exception.dart';

/// تجربة عدة مسارات API حتى ينجح أولها (مفيد عند اختلاف إعداد Laravel).
class ApiPostAttempt {
  const ApiPostAttempt({required this.path, this.data});

  final String path;
  final Map<String, dynamic>? data;
}

Future<T> postFirstSuccess<T>(
  ApiClient client,
  List<ApiPostAttempt> attempts,
  T Function(dynamic body) mapper,
) async {
  ApiException? lastError;

  for (final attempt in attempts) {
    try {
      return await client.handle(
        () => client.post(attempt.path, data: attempt.data),
        mapper,
      );
    } on ApiException catch (e) {
      lastError = e;
      if (e.statusCode == 404 || e.statusCode == 405) {
        continue;
      }
      rethrow;
    }
  }

  throw lastError ?? ApiException('لم يتم العثور على مسار API مناسب على الخادم');
}
