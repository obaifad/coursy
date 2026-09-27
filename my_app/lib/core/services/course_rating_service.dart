import 'package:get/get.dart';

import '../models/app_models.dart';
import '../models/paginated_result.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// يكمّل تقييم الدورات (من تقييم المعهد) وبيانات المعاهد الناقصة من كاش قائمة المعاهد.
class CourseRatingService extends GetxService {
  CourseRatingService(this._client);

  final ApiClient _client;

  /// أقصى عدد صفحات لقائمة المعاهد — حماية من حلقة لا تنتهي إن أعاد الخادم next_page_url دائماً.
  static const _maxInstitutePages = 10;

  /// مدة صلاحية الكاش قبل إعادة الجلب.
  static const _cacheTtl = Duration(minutes: 30);

  Map<int, double>? _instituteRatings;
  Map<int, int>? _instituteCoursesCounts;
  Map<int, InstituteModel>? _instituteProfiles;
  Future<void>? _loading;
  DateTime? _loadedAt;

  void invalidateCache() {
    _instituteRatings = null;
    _instituteCoursesCounts = null;
    _instituteProfiles = null;
    _loading = null;
    _loadedAt = null;
  }

  Future<void> _ensureLoaded() {
    final loadedAt = _loadedAt;
    if (loadedAt != null && DateTime.now().difference(loadedAt) > _cacheTtl) {
      invalidateCache();
    }
    return _loading ??= _loadCaches().catchError((Object e) {
      // لا نحتفظ بمستقبل فاشل — المحاولة التالية تعيد الجلب.
      _loading = null;
      throw e;
    });
  }

  /// تقييم الدورة يأتي من الخادم (`average_rating`) — لا ننزّل كل تقييمات المنصة لحسابه محلياً.
  Future<void> _loadCaches() async {
    final instituteStats = await _fetchInstituteStats();
    _instituteRatings = instituteStats.ratings;
    _instituteCoursesCounts = instituteStats.coursesCounts;
    _instituteProfiles = instituteStats.profiles;
    _loadedAt = DateTime.now();
  }

  Future<({Map<int, double> ratings, Map<int, int> coursesCounts, Map<int, InstituteModel> profiles})>
  _fetchInstituteStats() async {
    final ratings = <int, double>{};
    final coursesCounts = <int, int>{};
    final profiles = <int, InstituteModel>{};
    var page = 1;

    while (page <= _maxInstitutePages) {
      try {
        final pageResult = await _client.handle(
          () => _client.get(ApiEndpoints.institutes, query: {'page': page, 'per_page': 100}),
          (data) => PaginatedResult<InstituteModel>.fromBody(data, InstituteModel.fromJson),
        );

        for (final institute in pageResult.items) {
          profiles[institute.id] = institute;
          if (institute.rating > 0) {
            ratings[institute.id] = institute.rating;
          }
          if (institute.coursesCount > 0) {
            coursesCounts[institute.id] = institute.coursesCount;
          }
        }

        if (!pageResult.hasMore) break;
        page++;
      } catch (_) {
        break;
      }
    }

    return (ratings: ratings, coursesCounts: coursesCounts, profiles: profiles);
  }

  double resolve(CourseModel course) {
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

  double resolveInstituteRating(InstituteModel institute) {
    if (institute.rating > 0) return institute.rating;
    return _instituteRatings?[institute.id] ?? 0;
  }

  int resolveInstituteCoursesCount(InstituteModel institute) {
    if (institute.coursesCount > 0) return institute.coursesCount;
    return _instituteCoursesCounts?[institute.id] ?? 0;
  }

  InstituteModel _mergeInstituteFromCache(InstituteModel institute) {
    final cached = _instituteProfiles?[institute.id];
    if (cached == null) return institute;

    return institute.copyWith(
      nameAr: institute.nameAr.isNotEmpty ? institute.nameAr : cached.nameAr,
      nameEn: institute.nameEn.isNotEmpty ? institute.nameEn : cached.nameEn,
      cityAr: institute.cityAr.isNotEmpty ? institute.cityAr : cached.cityAr,
      cityEn: institute.cityEn.isNotEmpty ? institute.cityEn : cached.cityEn,
      rating: institute.rating > 0 ? institute.rating : cached.rating,
      coursesCount: institute.coursesCount > 0 ? institute.coursesCount : cached.coursesCount,
      isVerified: institute.isVerified || cached.isVerified,
      logoUrl: institute.logoUrl ?? cached.logoUrl,
      coverImageUrl: institute.coverImageUrl ?? cached.coverImageUrl,
    );
  }

  Future<List<InstituteModel>> enrichInstitutes(List<InstituteModel> institutes) async {
    if (institutes.isEmpty) return institutes;

    try {
      await _ensureLoaded();
    } catch (_) {
      return institutes;
    }

    return institutes
        .map((institute) {
          var updated = _mergeInstituteFromCache(institute);
          final rating = resolveInstituteRating(updated);
          if (rating > 0 && rating != updated.rating) {
            updated = updated.copyWith(rating: rating);
          }
          final coursesCount = resolveInstituteCoursesCount(updated);
          if (coursesCount > 0 && coursesCount != updated.coursesCount) {
            updated = updated.copyWith(coursesCount: coursesCount);
          }
          return updated;
        })
        .toList(growable: false);
  }
}
