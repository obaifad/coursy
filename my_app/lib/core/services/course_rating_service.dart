import 'package:get/get.dart';

import '../models/app_models.dart';
import '../models/json_helpers.dart';
import '../models/paginated_result.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/json_parser.dart';

/// يكمّل تقييم الدورات عندما لا يُرجعه endpoint القائمة (/courses).
class CourseRatingService extends GetxService {
  CourseRatingService(this._client);

  final ApiClient _client;

  Map<int, double>? _reviewAverages;
  Map<int, double>? _instituteRatings;
  Future<void>? _loading;

  void invalidateCache() {
    _reviewAverages = null;
    _instituteRatings = null;
    _loading = null;
  }

  Future<void> _ensureLoaded() {
    return _loading ??= _loadCaches();
  }

  Future<void> _loadCaches() async {
    final results = await Future.wait([
      _fetchReviewAverages(),
      _fetchInstituteRatings(),
    ]);
    _reviewAverages = results[0];
    _instituteRatings = results[1];
  }

  Future<Map<int, double>> _fetchReviewAverages() async {
    final sums = <int, double>{};
    final counts = <int, int>{};
    var page = 1;

    while (true) {
      try {
        final pageResult = await _client.handle(
          () => _client.get(ApiEndpoints.reviews, query: {'page': page, 'per_page': 100}),
          (data) {
            final parsed = PaginatedResult<Map<String, dynamic>>.fromBody(
              data,
              (json) => json,
            );
            if (parsed.items.isNotEmpty) return parsed;
            final items = extractListMap(data);
            return PaginatedResult<Map<String, dynamic>>(
              items: items,
              currentPage: page,
              lastPage: page,
              total: items.length,
              hasMore: false,
            );
          },
        );

        for (final item in pageResult.items) {
          final courseId = JsonHelpers.parseIntOrNull(item['course_id']);
          if (courseId == null || courseId <= 0) continue;
          sums[courseId] = (sums[courseId] ?? 0) + JsonHelpers.parseDouble(item['rating']);
          counts[courseId] = (counts[courseId] ?? 0) + 1;
        }

        if (!pageResult.hasMore) break;
        page++;
      } catch (_) {
        break;
      }
    }

    return {
      for (final id in sums.keys)
        if (counts[id] != null && counts[id]! > 0) id: sums[id]! / counts[id]!,
    };
  }

  Future<Map<int, double>> _fetchInstituteRatings() async {
    final ratings = <int, double>{};
    var page = 1;

    while (true) {
      try {
        final pageResult = await _client.handle(
          () => _client.get(ApiEndpoints.institutes, query: {'page': page, 'per_page': 100}),
          (data) => PaginatedResult<InstituteModel>.fromBody(data, InstituteModel.fromJson),
        );

        for (final institute in pageResult.items) {
          if (institute.rating > 0) {
            ratings[institute.id] = institute.rating;
          }
        }

        if (!pageResult.hasMore) break;
        page++;
      } catch (_) {
        break;
      }
    }

    return ratings;
  }

  double resolve(CourseModel course) {
    final reviewAvg = _reviewAverages?[course.id];
    if (reviewAvg != null && reviewAvg > 0) return reviewAvg;

    if (course.rating > 0) return course.rating;

    final instituteId = course.instituteId;
    if (instituteId != null) {
      final instituteRating = _instituteRatings?[instituteId];
      if (instituteRating != null && instituteRating > 0) return instituteRating;
    }

    return 0;
  }

  Future<List<CourseModel>> enrich(List<CourseModel> courses) async {
    if (courses.isEmpty) return courses;

    try {
      await _ensureLoaded();
    } catch (_) {
      return courses;
    }

    return courses
        .map((course) {
          final rating = resolve(course);
          return rating > 0 && rating != course.rating ? course.copyWith(rating: rating) : course;
        })
        .toList(growable: false);
  }
}
