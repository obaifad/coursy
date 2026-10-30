import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/json_helpers.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';
import '../../network/paginated_fetch.dart';
import '../../services/course_rating_service.dart';

class CourseRepository extends GetxService {
  CourseRepository(this._client, this._ratingService);

  final ApiClient _client;
  final CourseRatingService _ratingService;

  /// الصفحة كما حُفظت على القرص بعد آخر جلب ناجح (بلا إكمال التقييمات — الشبكة تكمله)، أو null.
  PaginatedResult<CourseModel>? cachedCoursesPage({int page = 1, int perPage = 15, Map<String, dynamic>? query}) {
    return _client.cached(
      ApiEndpoints.courses,
      query: <String, dynamic>{...?query, 'page': page, 'per_page': perPage},
      mapper: (data) => PaginatedResult<CourseModel>.fromBody(data, CourseModel.fromJson),
    );
  }

  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final mergedQuery = <String, dynamic>{...?query, 'page': page, 'per_page': perPage};
    final result = await _client.handle(
      () => _client.get(ApiEndpoints.courses, query: mergedQuery),
      (data) => PaginatedResult<CourseModel>.fromBody(data, CourseModel.fromJson),
    );
    final enriched = await _ratingService.enrich(result.items);
    return PaginatedResult<CourseModel>(
      items: enriched,
      currentPage: result.currentPage,
      lastPage: result.lastPage,
      total: result.total,
      hasMore: result.hasMore,
    );
  }

  /// المقترحات كما حُفظت على القرص لهذا الطالب، أو null.
  List<CourseModel>? cachedSuggestedCourses({int limit = 10}) {
    return _client.cached(
      ApiEndpoints.studentSuggestedCourses,
      query: {'limit': limit},
      mapper: (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
    );
  }

  /// دورات مقترحة مخصّصة للطالب (اهتمامات + تسجيلات + مفضلة) مع ترتيب وفلترة من الخادم.
  Future<List<CourseModel>> fetchSuggestedCourses({int limit = 10}) async {
    final items = await _client.handle(
      () => _client.get(ApiEndpoints.studentSuggestedCourses, query: {'limit': limit}),
      (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
    );
    return _ratingService.enrich(items);
  }

  Future<List<CourseModel>> fetchInstituteCourses(int instituteId) async {
    // كل الصفحات: الصفحة الأولى وحدها تُظهر 15 دورة فقط لمعهد عنده أكثر.
    try {
      final items = await fetchAllPages(
        _client,
        ApiEndpoints.instituteCourses(instituteId),
        CourseModel.fromJson,
        strict: false,
      );
      if (items.isNotEmpty) {
        return await _ratingService.enrich(items);
      }
    } catch (_) {}

    final fallback = await fetchAllPages(
      _client,
      ApiEndpoints.courses,
      CourseModel.fromJson,
      query: {'institute_id': instituteId},
      strict: false,
    );
    return _ratingService.enrich(fallback.where((course) => course.instituteId == instituteId).toList());
  }

  /// عدد دورات المعهد — طلب خفيف واحد (pagination total) بدون جلب كل الدورات.
  Future<int> countInstituteCourses(int instituteId) async {
    if (instituteId <= 0) return 0;

    try {
      final count = await _client.handle(
        () => _client.get(ApiEndpoints.instituteCourses(instituteId), query: const {'page': 1, 'per_page': 1}),
        (data) {
          final meta = extractPagination(normalizeApiBody(data));
          if (meta != null && meta.total > 0) return meta.total;
          return extractListMap(data).length;
        },
      );
      if (count > 0) return count;
    } catch (_) {}

    try {
      final page = await _client.handle(
        () => _client.get(ApiEndpoints.courses, query: {'institute_id': instituteId, 'page': 1, 'per_page': 1}),
        (data) {
          final meta = extractPagination(normalizeApiBody(data));
          if (meta != null && meta.total > 0) return meta.total;
          final items = extractListMap(data);
          return items.where((item) {
            final id = JsonHelpers.parseIntOrNull(item['institute_id']);
            return id == null || id == instituteId;
          }).length;
        },
      );
      return page;
    } catch (_) {
      return 0;
    }
  }

  Future<List<CourseModel>> fetchCourses({Map<String, dynamic>? query}) async {
    final items = await _client.handle(
      () => _client.get(ApiEndpoints.courses, query: query),
      (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
    );
    return _ratingService.enrich(items);
  }

  Future<CourseModel> fetchCourseById(int id) async {
    final course = await _client.handle(() => _client.get(ApiEndpoints.resourceById(ApiEndpoints.courses, id)), (data) {
      final map = extractObjectMap(data);
      if (map == null) {
        throw ApiException('error_invalid_data'.tr);
      }
      return CourseModel.fromJson(map);
    });
    final enriched = await _ratingService.enrich([course]);
    return enriched.first;
  }

  Future<List<ScheduleModel>> fetchCourseSchedules(int courseId) async {
    return _client.handle(
      () => _client.get(ApiEndpoints.courseSchedules, query: {'course_id': courseId}),
      (data) => extractListMap(data)
          .where((item) {
            final id = item['course_id']?.toString();
            return id == null || id.isEmpty || id == courseId.toString();
          })
          .map(ScheduleModel.fromJson)
          .toList(),
    );
  }
}
