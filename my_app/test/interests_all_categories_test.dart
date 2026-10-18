import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:my_app/core/data/repositories/interest_repository.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_endpoints.dart';

import 'layout/fakes.dart';

/// يسجّل الطلبات ويرد بصفحة واحدة.
class _RecordingClient extends ApiClient {
  _RecordingClient(super.tokens);

  final queries = <Map<String, dynamic>?>[];

  @override
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query, CancelToken? cancelToken}) async {
    expect(path, ApiEndpoints.categories);
    queries.add(query);
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'data': [
          {'id': 1, 'name_ar': 'البرمجة', 'name_en': 'Programming', 'courses_count': 3},
          {'id': 2, 'name_ar': 'التصميم', 'name_en': 'Design', 'courses_count': 0},
        ],
        'current_page': 1,
        'last_page': 1,
        'total': 2,
      },
    );
  }
}

void main() {
  tearDown(Get.reset);

  test('interests ask the server for ALL categories (all=1), including those without courses', () async {
    final tokens = await registerFakes(loggedIn: false, locale: 'ar');
    final client = _RecordingClient(tokens);
    final interests = await InterestRepository(client).fetchInterests();

    expect(client.queries, isNotEmpty);
    for (final query in client.queries) {
      expect(query?['all'], 1);
    }
    expect(interests.map((c) => c.id), [1, 2], reason: 'a category with 0 courses is still pickable');
  });
}
