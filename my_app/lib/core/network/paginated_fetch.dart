import 'package:dio/dio.dart';

import '../models/paginated_result.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// يجلب كل صفحات endpoint مرقّم (Laravel pagination) حتى يطابق [total] من الـ API.
/// لا يفترض عدداً ثابتاً — يعمل مع أي حجم (82، 150، …) ويستمر عبر كل الصفحات.
Future<List<T>> fetchAllPages<T>(
  ApiClient client,
  String path,
  T Function(Map<String, dynamic>) mapper, {
  Map<String, dynamic>? query,
  int perPage = 50,
  int maxPages = 500,
}) async {
  final baseQuery = <String, dynamic>{...?query};
  final all = <T>[];
  final cancelToken = CancelToken();
  var page = 1;
  var expectedTotal = 0;

  while (page <= maxPages) {
    final result = await client.handle(
      () => client.get(
        path,
        query: {...baseQuery, 'page': page, 'per_page': perPage},
        cancelToken: cancelToken,
      ),
      (data) => PaginatedResult<T>.fromBody(data, mapper),
    );
    if (result.total > 0) expectedTotal = result.total;
    all.addAll(result.items);

    if (expectedTotal > 0 && all.length >= expectedTotal) break;
    if (result.items.isEmpty) break;

    if (page >= result.lastPage) {
      if (expectedTotal > 0 && all.length < expectedTotal) {
        throw ApiException(
          'Incomplete paginated fetch for $path: got ${all.length} of $expectedTotal (page $page/${result.lastPage})',
        );
      }
      break;
    }

    page++;
  }

  if (expectedTotal > 0 && all.length < expectedTotal) {
    throw ApiException(
      'Incomplete paginated fetch for $path: got ${all.length} of $expectedTotal',
    );
  }

  return all;
}
