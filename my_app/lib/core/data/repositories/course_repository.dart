import 'package:get/get.dart';

import '../../models/app_models.dart';
import '../../models/json_helpers.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../services/course_rating_service.dart';

class CourseRepository extends GetxService {
  CourseRepository(this._client, this._ratingService);

  final ApiClient _client;
  final CourseRatingService _ratingService;

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

  /// دورات مقترحة مخصّصة للطالب (اهتمامات + تسجيلات + مفضلة) مع ترتيب وفلترة من الخادم.
  Future<List<CourseModel>> fetchSuggestedCourses({int limit = 10}) async {
    final items = await _client.handle(
      () => _client.get(
        ApiEndpoints.studentSuggestedCourses,
        query: {'limit': limit},
      ),
      (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
    );
    return _ratingService.enrich(items);
  }

  Future<List<CourseModel>> fetchInstituteCourses(int instituteId) async {
    try {
      final items = await _client.handle(
        () => _client.get(ApiEndpoints.instituteCourses(instituteId)),
        (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
      );
      if (items.isNotEmpty) {
        return _ratingService.enrich(items);
      }
    } catch (_) {}

    final fallback = await fetchCourses(query: {'institute_id': instituteId});
    return fallback.where((course) => course.instituteId == instituteId).toList();
  }

  /// عدد دورات المعهد — طلب خفيف واحد (pagination total) بدون جلب كل الدورات.
  Future<int> countInstituteCourses(int instituteId) async {
    if (instituteId <= 0) return 0;

    try {
      final count = await _client.handle(
        () => _client.get(
          ApiEndpoints.instituteCourses(instituteId),
          query: const {'page': 1, 'per_page': 1},
        ),
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
        () => _client.get(
          ApiEndpoints.courses,
          query: {'institute_id': instituteId, 'page': 1, 'per_page': 1},
        ),
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
    final course = await _client.handle(
      () => _client.get(ApiEndpoints.resourceById(ApiEndpoints.courses, id)),
      (data) {
        final map = extractObjectMap(data);
        if (map == null) {
          throw Exception('بيانات الدورة غير صالحة');
        }
        return CourseModel.fromJson(map);
      },
    );
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
