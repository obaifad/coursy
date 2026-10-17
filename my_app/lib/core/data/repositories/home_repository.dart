import 'dart:async';

import 'package:get/get.dart';

import '../../locale/locale_controller.dart';
import '../../models/app_models.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../storage/home_cache.dart';
import '../../storage/token_storage.dart';

class HomeRepository extends GetxService {
  HomeRepository(this._client, {HomeCache? cache}) : _cache = cache;

  final ApiClient _client;
  final HomeCache? _cache;

  /// طلب /homepage بدأ أثناء شاشة البداية، ينتظر أن تستهلكه الرئيسية.
  Future<HomePayload?>? _prefetched;
  DateTime? _prefetchedAt;

  /// بعدها يُعتبر الطلب المبكر قديماً ويُطلب من جديد.
  static const _prefetchTtl = Duration(seconds: 30);

  /// يحاول جلب الصفحة الرئيسية؛ إن فشل أو كانت فارغة يُرجع null ليُكمّل الـ Controller بجلب منفصل.
  /// الرد الناجح يُحفظ على الجهاز لفتح الرئيسية منه في المرة القادمة ([cachedHomepage]).
  Future<HomePayload?> fetchHomepage() async {
    try {
      return await _client.handle(() => _client.get(ApiEndpoints.homepage), (data) {
        if (data is! Map<String, dynamic>) {
          return null;
        }
        final payload = parseHomepage(data);
        final cache = _cache;
        if (cache != null && !payload.isEmpty) {
          unawaited(cache.writePayload(_lang, _audience, data));
        }
        return payload;
      });
    } catch (_) {
      return null;
    }
  }

  /// يبدأ جلب الرئيسية مبكراً (من شاشة البداية، أثناء أنيميشن الشعار) فتفتح محمّلة.
  void prefetchHomepage() {
    _prefetched = fetchHomepage();
    _prefetchedAt = DateTime.now();
  }

  /// الطلب المبكر إن بدأ قبل أقل من [_prefetchTtl] — يُستهلك مرة واحدة — وإلا طلب جديد.
  Future<HomePayload?> fetchHomepageOrPrefetched() {
    final pending = _prefetched;
    final startedAt = _prefetchedAt;
    _prefetched = null;
    _prefetchedAt = null;
    if (pending != null && startedAt != null && DateTime.now().difference(startedAt) < _prefetchTtl) {
      return pending;
    }
    return fetchHomepage();
  }

  /// آخر رد محفوظ للغة والجمهور الحاليين — متزامن فيُقرأ قبل أول إطار. null = لا شيء محفوظ.
  HomePayload? cachedHomepage() {
    final data = _cache?.readPayload(_lang, _audience);
    if (data == null) return null;
    try {
      final payload = parseHomepage(data);
      return payload.isEmpty ? null : payload;
    } catch (_) {
      return null;
    }
  }

  static HomePayload parseHomepage(Map<String, dynamic> data) {
    final map = extractObjectMap(data) ?? data;
    return HomePayload(
      courses: extractListMap(map['featured_courses'] ?? map['courses']).map(CourseModel.fromJson).toList(),
      // للزوار فقط — المسجّلون يستخدمون /student/suggested-courses
      suggestedCourses: extractListMap(
        map['latest_courses'] ?? map['suggested_courses'],
      ).map(CourseModel.fromJson).toList(),
      institutes: extractListMap(map['institutes'] ?? map['top_institutes']).map(InstituteModel.fromJson).toList(),
      categories: extractListMap(map['categories']).map(CategoryModel.fromJson).toList(),
      cities: extractListMap(map['cities']).map(CityModel.fromJson).toList(),
    );
  }

  String get _lang => Get.isRegistered<LocaleController>() ? Get.find<LocaleController>().code.value : 'ar';

  String get _audience {
    final tokens = Get.isRegistered<TokenStorage>() ? Get.find<TokenStorage>() : null;
    return HomeCache.audienceKey(loggedIn: tokens?.isLoggedIn ?? false, studentId: tokens?.studentId);
  }
}

class HomePayload {
  HomePayload({
    this.courses = const [],
    this.suggestedCourses = const [],
    this.institutes = const [],
    this.categories = const [],
    this.cities = const [],
  });

  final List<CourseModel> courses;
  final List<CourseModel> suggestedCourses;
  final List<InstituteModel> institutes;
  final List<CategoryModel> categories;
  final List<CityModel> cities;

  bool get isEmpty =>
      courses.isEmpty && suggestedCourses.isEmpty && institutes.isEmpty && categories.isEmpty && cities.isEmpty;
}
