import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../models/app_models.dart';
import '../../models/paginated_result.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/api_fallback.dart';
import '../../network/json_parser.dart';
import '../../services/student_id_resolver.dart';

class ReviewRepository extends GetxService {
  ReviewRepository(this._client, this._studentIdResolver);

  final ApiClient _client;
  final StudentIdResolver _studentIdResolver;

  void _log(String action, dynamic body, {String? path}) {
    if (path != null) AppDebugLog.repo('Reviews', '$action $path');
    AppDebugLog.repo('Reviews', body.toString());
  }

  Future<List<ReviewModel>> fetchReviews({
    int? courseId,
    int? instituteId,
    int? instructorId,
  }) async {
    final query = <String, dynamic>{
      if (courseId != null) 'course_id': courseId,
      if (instituteId != null) 'institute_id': instituteId,
      if (instructorId != null) 'instructor_id': instructorId,
    };

    final paths = [
      if (courseId != null) ApiEndpoints.courseReviews(courseId),
      ApiEndpoints.studentReviews,
      ApiEndpoints.reviews,
    ];
    for (final path in paths) {
      try {
        return await _client.handle(
          () => _client.get(
            path,
            query: path == ApiEndpoints.courseReviews(courseId ?? 0) ? null : query,
          ),
          (data) {
            _log('LIST', data, path: path);
            final page = PaginatedResult<ReviewModel>.fromBody(data, ReviewModel.fromJson);
            if (page.items.isNotEmpty) return page.items;
            return extractListMap(data).map(ReviewModel.fromJson).toList();
          },
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
        rethrow;
      }
    }
    return [];
  }

  Future<ReviewModel> submitReview({
    required int rating,
    required String comment,
    int? courseId,
    int? instituteId,
    int? instructorId,
  }) async {
    final safeRating = rating.clamp(1, 5);

    if (courseId != null) {
      final path = '${ApiEndpoints.courseReviews(courseId)}?rating=$safeRating';
      return _client.handle(
        () => _client.post(
          path,
          data: comment.trim().isEmpty ? const <String, dynamic>{} : {'comment': comment.trim()},
        ),
        (raw) {
          final body = normalizeApiBody(raw);
          _log('SUBMIT', body, path: path);
          final map = extractObjectMap(body) ?? (body is Map<String, dynamic> ? body : <String, dynamic>{});
          if (map.isEmpty) {
            return ReviewModel(id: 0, rating: safeRating, comment: comment.trim(), studentName: 'أنت');
          }
          return ReviewModel.fromJson(map);
        },
      );
    }

    final data = <String, dynamic>{
      'rating': safeRating,
      if (instituteId != null) 'institute_id': instituteId,
      if (instructorId != null) 'instructor_id': instructorId,
    };

    try {
      final studentId = await _studentIdResolver.resolve();
      data['student_id'] = studentId;
    } catch (_) {}

    final attempts = <ApiPostAttempt>[
      ApiPostAttempt(path: ApiEndpoints.studentReviews, data: data),
      ApiPostAttempt(path: ApiEndpoints.reviews, data: data),
    ];

    return postFirstSuccess(_client, attempts, (raw) {
      final body = normalizeApiBody(raw);
      _log('SUBMIT', body);
      final map = extractObjectMap(body) ?? (body is Map<String, dynamic> ? body : <String, dynamic>{});
      if (map.isEmpty) {
        return ReviewModel(id: 0, rating: safeRating, comment: comment.trim(), studentName: 'أنت');
      }
      return ReviewModel.fromJson(map);
    });
  }
}
