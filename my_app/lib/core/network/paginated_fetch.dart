import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/app_debug_log.dart';
import '../models/paginated_result.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// يجلب كل صفحات endpoint مرقّم (Laravel pagination) حتى يطابق [total] من الـ API.
/// لا يفترض عدداً ثابتاً — يعمل مع أي حجم (82، 150، …) ويستمر عبر كل الصفحات.
/// [strict] = false يُرجع ما جُمع إن نقص العدد عن total بدل رمي خطأ (لقوائم يكفي فيها الجزء المتاح).
Future<List<T>> fetchAllPages<T>(
  ApiClient client,
  String path,
  T Function(Map<String, dynamic>) mapper, {
  Map<String, dynamic>? query,
  int perPage = 50,
  int maxPages = 500,
  bool strict = true,
}) async {
  final baseQuery = <String, dynamic>{...?query};
  final all = <T>[];
  final cancelToken = CancelToken();
  var page = 1;
  var expectedTotal = 0;

  while (page <= maxPages) {
    final result = await client.handle(
      () => client.get(path, query: {...baseQuery, 'page': page, 'per_page': perPage}, cancelToken: cancelToken),
      (data) => PaginatedResult<T>.fromBody(data, mapper),
    );
    if (result.total > 0) expectedTotal = result.total;
    all.addAll(result.items);

    if (expectedTotal > 0 && all.length >= expectedTotal) break;
    if (result.items.isEmpty) break;

    if (page >= result.lastPage) {
      if (strict && expectedTotal > 0 && all.length < expectedTotal) {
        AppDebugLog.api('INCOMPLETE PAGES', '$path: ${all.length} of $expectedTotal (page $page/${result.lastPage})');
        throw ApiException('error_incomplete_list'.tr);
      }
      break;
    }

    page++;
  }

  if (strict && expectedTotal > 0 && all.length < expectedTotal) {
    // التفاصيل التقنية لسجل التطوير فقط؛ المستخدم يرى نصاً مترجماً (كانت تظهر بالإنجليزية في القوائم).
    AppDebugLog.api('INCOMPLETE PAGES', '$path: ${all.length} of $expectedTotal');
    throw ApiException('error_incomplete_list'.tr);
  }

  return all;
}
