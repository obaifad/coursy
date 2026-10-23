import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/app_models.dart';
import '../models/paginated_result.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/json_parser.dart';

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
  Map<int, CityModel>? _cities;
  Map<int, CategoryModel>? _categories;
  Future<void>? _loading;
  DateTime? _loadedAt;

  void invalidateCache() {
    _instituteRatings = null;
    _instituteCoursesCounts = null;
    _instituteProfiles = null;
    _cities = null;
    _categories = null;
    _loading = null;
    _loadedAt = null;
  }

  /// الانتظار الأقصى لإكمال الكاش قبل أن تُعرض القائمة بلا إكماله (يستمر التحميل في الخلفية). بطء هذه
  /// الطلبات الثلاثة كان يؤخر أول قائمة دورات، وهي معلومات تكميلية (تقييم المعهد، اسم المدينة والتصنيف).
  static const defaultMaxWait = Duration(seconds: 4);

  @visibleForTesting
  Duration maxWait = defaultMaxWait;

  /// الساعة: تُستبدل في الاختبارات.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// بعد فشل جزئي (مدن أو تصنيفات لم تصل) يُعاد المحاولة بعد هذه المدة بدل انتظار [_cacheTtl] كاملة.
  static const _retryAfterPartial = Duration(minutes: 1);

  bool _refreshing = false;

  /// يبدأ تحميل الكاش مبكراً (عند الإقلاع) كي يكون جاهزاً حين تطلب أول قائمة إكماله.
  Future<void> warmUp() => _ensureLoaded().catchError((Object _) {});

  /// الكاش الصالح يُعاد فوراً. القديم (> [_cacheTtl]) يُخدَّم كما هو ويُجدَّد في الخلفية: كان يُمسح فتنتظر
  /// أول قائمة بعده ثلاثة طلبات كاملة.
  Future<void> _ensureLoaded() {
    final loadedAt = _loadedAt;
    if (loadedAt != null && clock().difference(loadedAt) > _cacheTtl) {
      _refreshInBackground();
      return Future<void>.value();
    }
    return _loading ??= _loadCaches().catchError((Object e) {
      // لا نحتفظ بمستقبل فاشل — المحاولة التالية تعيد الجلب.
      _loading = null;
      throw e;
    });
  }

  void _refreshInBackground() {
    if (_refreshing) return;
    _refreshing = true;
    _loadCaches().catchError((Object _) {}).whenComplete(() => _refreshing = false);
  }

  /// المعاهد والمدن والتصنيفات مستقلة: تُطلق معاً (كانت تُجلب واحدة بعد أخرى)، وتُطبَّق نتائجها دفعة واحدة.
  Future<void> _loadCaches() async {
    final stats = _fetchInstituteStats();
    final cities = _fetchMap<CityModel>(ApiEndpoints.cities, CityModel.fromJson, (c) => c.id);
    final categories = _fetchMap<CategoryModel>(ApiEndpoints.categories, CategoryModel.fromJson, (c) => c.id);

    final instituteStats = await stats;
    final loadedCities = await cities;
    final loadedCategories = await categories;

    _instituteRatings = instituteStats.ratings;
    _instituteCoursesCounts = instituteStats.coursesCounts;
    _cities = loadedCities ?? _cities ?? {};
    _categories = loadedCategories ?? _categories ?? {};
    _instituteProfiles = {for (final entry in instituteStats.profiles.entries) entry.key: _withCity(entry.value)};
    final complete = loadedCities != null && loadedCategories != null && !instituteStats.failed;
    // ناقص: يُعدّ قديماً بعد دقيقة فقط فيُعاد جلبه بدل أن يبقى فارغاً نصف ساعة.
    _loadedAt = complete ? clock() : clock().subtract(_cacheTtl - _retryAfterPartial);
  }

  /// قوائم مرجعية صغيرة (مدن/تصنيفات). null = فشل الطلب (لا خريطة فارغة تُحفَظ كأنها نجاح).
  Future<Map<int, T>?> _fetchMap<T>(String path, T Function(Map<String, dynamic>) parse, int Function(T) idOf) async {
    try {
      final items = await _client.handle(() => _client.get(path), (data) => extractListMap(data).map(parse).toList());
      return {for (final item in items) idOf(item): item};
    } catch (_) {
      return null;
    }
  }

  /// الخادم يعيد city_id فقط في قائمة المعاهد — نحوّله إلى اسم المدينة.
  InstituteModel _withCity(InstituteModel institute) {
    if (institute.cityAr.isNotEmpty || institute.cityEn.isNotEmpty) return institute;
    final city = _cities?[institute.cityId];
    if (city == null) return institute;
    return institute.copyWith(cityAr: city.nameAr, cityEn: city.nameEn);
  }

  Future<PaginatedResult<InstituteModel>?> _fetchInstitutesPage(int page) async {
    try {
      return await _client.handle(
        () => _client.get(ApiEndpoints.institutes, query: {'page': page, 'per_page': 100}),
        (data) => PaginatedResult<InstituteModel>.fromBody(data, InstituteModel.fromJson),
      );
    } catch (_) {
      return null;
    }
  }

  /// الصفحة الأولى ثم بقية الصفحات معاً (عددها معروف من الصفحة الأولى)، لا صفحة بعد صفحة.
  Future<({Map<int, double> ratings, Map<int, int> coursesCounts, Map<int, InstituteModel> profiles, bool failed})>
  _fetchInstituteStats() async {
    final ratings = <int, double>{};
    final coursesCounts = <int, int>{};
    final profiles = <int, InstituteModel>{};
    var failed = false;

    void absorb(PaginatedResult<InstituteModel> result) {
      for (final institute in result.items) {
        profiles[institute.id] = institute;
        if (institute.rating > 0) ratings[institute.id] = institute.rating;
        if (institute.coursesCount > 0) coursesCounts[institute.id] = institute.coursesCount;
      }
    }

    final first = await _fetchInstitutesPage(1);
    if (first == null) {
      failed = true;
    } else {
      absorb(first);
      if (first.hasMore) {
        if (first.lastPage > 1) {
          final last = first.lastPage < _maxInstitutePages ? first.lastPage : _maxInstitutePages;
          final rest = await Future.wait([for (var p = 2; p <= last; p++) _fetchInstitutesPage(p)]);
          for (final result in rest) {
            if (result == null) {
              failed = true;
            } else {
              absorb(result);
            }
          }
        } else {
          // عدد الصفحات غير معروف: نتابع تتابعياً كما كان (حدّه الأقصى [_maxInstitutePages]).
          var page = 2;
          while (page <= _maxInstitutePages) {
            final result = await _fetchInstitutesPage(page);
            if (result == null) {
              failed = true;
              break;
            }
            absorb(result);
            if (!result.hasMore) break;
            page++;
          }
        }
      }
    }

    return (ratings: ratings, coursesCounts: coursesCounts, profiles: profiles, failed: failed);
  }

  double resolve(CourseModel course) {
    if (course.rating > 0) return course.rating;
    // الخادم أرسل عدد تقييمات الدورة: صفر يعني «لا تقييم بعد»، لا تقييم المعهد.
    if (course.reviewsCount != null) return course.rating;

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
      await _ensureLoaded().timeout(maxWait);
    } catch (_) {
      return courses;
    }

    return courses
        .map((course) {
          final rating = resolve(course);
          var updated = rating > 0 && rating != course.rating ? course.copyWith(rating: rating) : course;
          final institute = _instituteProfiles?[updated.instituteId];
          if (institute != null) {
            updated = updated.copyWith(
              instituteAr: updated.instituteAr.isEmpty ? institute.nameAr : null,
              instituteEn: updated.instituteEn.isEmpty ? institute.nameEn : null,
              instituteCityAr: updated.instituteCity == null && institute.cityAr.isNotEmpty ? institute.cityAr : null,
              instituteCityEn: updated.instituteCity == null && institute.cityEn.isNotEmpty ? institute.cityEn : null,
            );
          }
          final category = _categories?[updated.categoryId];
          if (category != null && (updated.categoryName ?? '').isEmpty) {
            updated = updated.copyWith(categoryName: category.name);
          }
          return updated;
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
      phone: institute.phone ?? cached.phone,
      whatsapp: institute.whatsapp ?? cached.whatsapp,
      website: institute.website ?? cached.website,
      facebook: institute.facebook ?? cached.facebook,
      instagram: institute.instagram ?? cached.instagram,
    );
  }

  Future<List<InstituteModel>> enrichInstitutes(List<InstituteModel> institutes) async {
    if (institutes.isEmpty) return institutes;

    try {
      await _ensureLoaded().timeout(maxWait);
    } catch (_) {
      return institutes;
    }

    return institutes
        .map((institute) {
          var updated = _withCity(_mergeInstituteFromCache(institute));
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
