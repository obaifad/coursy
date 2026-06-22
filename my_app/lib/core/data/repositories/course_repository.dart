import 'package:get/get.dart';

import '../../models/app_models.dart';
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
    final items = await _client.handle(
      () => _client.get(ApiEndpoints.instituteCourses(instituteId)),
      (data) => extractListMap(data).map(CourseModel.fromJson).toList(),
    );
    return _ratingService.enrich(items);
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
