import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/data/repositories/search_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/network/paginated_fetch.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/search/controllers/search_controller.dart';

import 'layout/fakes.dart';
import 'layout/sample_data.dart';

Response<dynamic> _response(int status, dynamic data) =>
    Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: status, data: data);

/// عميل يرجع صفحة واحدة بعنصر واحد بينما «total» يقول 5.
class _ShortPagesClient extends ApiClient {
  _ShortPagesClient(super.tokens);

  @override
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query, CancelToken? cancelToken}) async =>
      _response(200, {
        'data': [
          {'id': 1},
        ],
        'current_page': 1,
        'last_page': 1,
        'total': 5,
      });
}

class _PageTwoFails extends CourseRepository {
  _PageTwoFails(super.client, super.rating);

  int calls = 0;

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    calls++;
    if (page > 1) throw ApiException('error_connection_timeout', statusCode: null);
    return PaginatedResult(items: sampleCourses(), currentPage: 1, lastPage: 3, total: 12, hasMore: true);
  }
}

class _SlowSearch extends SearchRepository {
  _SlowSearch(super.client, super.rating);

  final gate = Completer<void>();

  @override
  Future<SearchResult> search({
    required String query,
    SearchScope scope = SearchScope.all,
    int limit = 12,
    int? categoryId,
    int? cityId,
    String? level,
    String? studyType,
    int? instituteId,
    bool? featured,
    bool? verified,
  }) async {
    await gate.future;
    return SearchResult(courses: sampleCourses());
  }
}

void main() {
  tearDown(Get.reset);

  group('server error messages', () {
    test("a 5xx with Laravel's generic English text shows our translated message", () async {
      final client = ApiClient((await registerFakes(loggedIn: false, locale: 'ar')));
      await expectLater(
        client.handle(() async => _response(500, {'message': 'Server Error'}), (b) => b),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'error_server_unavailable')),
      );
      await expectLater(
        client.handle(() async => _response(502, '<html>Bad Gateway</html>'), (b) => b),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'error_server_unavailable')),
      );
    });

    test('a 5xx with a real (localized) server message keeps it', () async {
      final client = ApiClient((await registerFakes(loggedIn: false, locale: 'ar')));
      await expectLater(
        client.handle(() async => _response(503, {'message': 'تعذّر إرسال البريد الآن.'}), (b) => b),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'تعذّر إرسال البريد الآن.')),
      );
    });

    test('an incomplete paginated list is a translated message, not developer text', () async {
      final tokens = await registerFakes(loggedIn: false, locale: 'ar');
      await expectLater(
        fetchAllPages(_ShortPagesClient(tokens), '/cities', (m) => m),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'error_incomplete_list')),
      );
    });
  });

  testWidgets('courses: a failed "load more" keeps the list open and offers Retry', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _PageTwoFails(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    Get.delete<CourseRepository>(force: true);
    Get.put<CourseRepository>(repo);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));

    final c = Get.put(CoursesController());
    await tester.pumpAndSettle();
    expect(c.courses, isNotEmpty);

    await c.loadMoreCourses();
    expect(c.loadMoreFailed.value, isTrue);
    expect(c.hasMore.value, isTrue);

    // إعادة تحميل القائمة تمسح حالة الفشل.
    await c.loadCourses();
    expect(c.loadMoreFailed.value, isFalse);
  });

  testWidgets('search: clearing the box drops a search that is still running', (tester) async {
    await registerFakes(loggedIn: true, locale: 'ar');
    final repo = _SlowSearch(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    Get.delete<SearchRepository>(force: true);
    Get.put<SearchRepository>(repo);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    final c = Get.put(SearchPageController());

    final pending = c.runSearch(overrideQuery: 'فلاتر', saveRecent: false);
    await tester.pump();
    expect(c.isSearching.value, isTrue);

    await c.runSearch(overrideQuery: '', saveRecent: false);
    expect(c.isSearching.value, isFalse);

    repo.gate.complete();
    await pending;
    expect(c.courses, isEmpty);
    expect(Get.find<TokenStorage>().isLoggedIn, isTrue);
  });
}
