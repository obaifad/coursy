import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';

import 'layout/fakes.dart';
import 'layout/sample_data.dart';

/// الترتيب على الخادم (`sort`): طلب واحد لكل صفحة، ولكل ترتيب قائمته وكاشه، بدل تحميل كل الصفحات (حتى 30)
/// وترتيبها على الجهاز.
class _Request {
  _Request(this.page, this.query);
  final int page;
  final Map<String, dynamic> query;
  final reply = Completer<void>();
  String? get sort => query['sort'] as String?;
}

class _RecordingCourses extends CourseRepository {
  _RecordingCourses(ApiClient client) : super(client, _NoRating(client));

  final requests = <_Request>[];

  /// true = كل طلب ينتظر [release] (لاختبار ردّ متأخر).
  bool hold = false;

  /// كل صفحة فيها دورتان، والعدد الكلي كبير: الخادم يقول إن هناك المزيد دائماً.
  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final request = _Request(page, {...?query});
    requests.add(request);
    if (hold) {
      await request.reply.future;
    }
    // عنوان كل دورة يحمل الترتيب والصفحة: يُعرف من أي طلب جاءت.
    final courses = sampleCourses().take(2).toList();
    final tagged = [
      for (final (i, c) in courses.indexed)
        CourseModel.fromJson({
          'id': page * 100 + i + (request.sort == null ? 0 : request.sort.hashCode % 50 * 1000),
          'title': '${request.sort ?? 'newest'}-$page-$i',
          'price': c.effectivePrice,
        }),
    ];
    return PaginatedResult<CourseModel>(items: tagged, currentPage: page, lastPage: 50, total: 100, hasMore: true);
  }
}

class _NoRating extends CourseRatingService {
  _NoRating(super.client);
  @override
  Future<List<CourseModel>> enrich(List<CourseModel> courses) async => courses;
}

void main() {
  late _RecordingCourses repo;

  setUp(() async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(MemoryCache()); // غير المسجّلة = لا تخزين
    repo = replaceFake<_RecordingCourses>(_RecordingCourses(Get.find<ApiClient>()));
    Get.delete<CourseRepository>(force: true);
    Get.put<CourseRepository>(repo);
  });
  tearDown(() {
    MemoryCache.clear();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('enum -> API value: newest sends nothing', () {
    expect(CourseSortOption.newest.apiValue, isNull);
    expect(CourseSortOption.priceLow.apiValue, 'price_asc');
    expect(CourseSortOption.priceHigh.apiValue, 'price_desc');
    expect(CourseSortOption.ratingHigh.apiValue, 'rating');
  });

  group('courses tab', () {
    test('default load sends no sort; choosing a sort makes ONE request for page 1', () async {
      final c = Get.put(CoursesController());
      await settle();
      expect(repo.requests.where((r) => r.page == 1).every((r) => r.sort == null), isTrue);
      final before = repo.requests.length;

      c.selectSort(CourseSortOption.priceLow);
      await settle();
      expect(repo.requests.length, before + 1, reason: 'no loop over all the pages any more');
      final request = repo.requests.last;
      expect(request.page, 1);
      expect(request.sort, 'price_asc');
      expect(c.courses.map((e) => e.title), ['price_asc-1-0', 'price_asc-1-1'], reason: 'server order is kept as is');
    });

    test('the category filter and the sort go together, and load-more keeps both', () async {
      final c = Get.put(CoursesController());
      await settle();
      c.selectCategory(3);
      await settle();
      c.selectSort(CourseSortOption.ratingHigh);
      await settle();
      expect(repo.requests.last.query, {'category_id': 3, 'sort': 'rating'});

      await c.loadMoreCourses();
      expect(repo.requests.last.page, 2);
      expect(repo.requests.last.query['sort'], 'rating');
      expect(repo.requests.last.query['category_id'], 3);
      expect(c.courses.length, 4);
    });

    test('going back to a sort seen a moment ago uses its own cache: no request', () async {
      final c = Get.put(CoursesController());
      await settle();
      c.selectSort(CourseSortOption.priceHigh);
      await settle();
      c.selectSort(CourseSortOption.newest);
      await settle();
      final before = repo.requests.length;
      expect(c.courses.first.title, 'newest-1-0');

      c.selectSort(CourseSortOption.priceHigh);
      await settle();
      expect(repo.requests.length, before, reason: 'cached by category + sort');
      expect(c.courses.first.title, 'price_desc-1-0');
      expect(c.isLoading.value, isFalse);
    });

    test('choosing the same sort again does nothing', () async {
      final c = Get.put(CoursesController());
      await settle();
      c.selectSort(CourseSortOption.priceLow);
      await settle();
      final before = repo.requests.length;
      c.selectSort(CourseSortOption.priceLow);
      await settle();
      expect(repo.requests.length, before);
    });

    test('a slow reply for the previous sort is dropped', () async {
      final c = Get.put(CoursesController());
      await settle();
      repo.hold = true;
      c.selectSort(CourseSortOption.priceLow);
      await settle();
      c.selectSort(CourseSortOption.priceHigh);
      await settle();
      final low = repo.requests.firstWhere((r) => r.sort == 'price_asc');
      final high = repo.requests.firstWhere((r) => r.sort == 'price_desc');
      high.reply.complete();
      await settle();
      low.reply.complete(); // الأقدم يصل بعد الأحدث
      await settle();

      expect(c.courses.map((e) => e.title), ['price_desc-1-0', 'price_desc-1-1']);
      expect(c.selectedSort.value, CourseSortOption.priceHigh);
    });

    test('the list is shown empty (skeleton) while a new sort loads', () async {
      final c = Get.put(CoursesController());
      await settle();
      repo.hold = true;
      c.selectSort(CourseSortOption.priceLow);
      expect(c.courses, isEmpty, reason: 'the previous order must not stay on screen');
      expect(c.isLoading.value, isTrue);
      repo.requests.last.reply.complete();
      await settle();
      expect(c.isLoading.value, isFalse);
      expect(c.courses, isNotEmpty);
    });
  });

  group('category page', () {
    CategoryCoursesController open() {
      Get.routing.args = <String, dynamic>{'id': 7, 'name': 'البرمجة'};
      return Get.put(CategoryCoursesController());
    }

    test('sort goes to the server together with the category, page by page', () async {
      final c = open();
      await settle();
      expect(repo.requests.last.query.containsKey('sort'), isFalse);

      c.selectSort(CourseSortOption.priceLow);
      await settle();
      expect(repo.requests.last.query, {'category_id': 7, 'sort': 'price_asc'});
      expect(c.courses.first.title, 'price_asc-1-0');

      await c.loadMore();
      expect(repo.requests.last.page, 2);
      expect(repo.requests.last.query['sort'], 'price_asc');
    });

    test('each sort has its own cache and stale replies are dropped', () async {
      final c = open();
      await settle();
      repo.hold = true;
      c.selectSort(CourseSortOption.priceLow);
      await settle();
      c.selectSort(CourseSortOption.ratingHigh);
      await settle();
      final low = repo.requests.firstWhere((r) => r.sort == 'price_asc');
      final rating = repo.requests.firstWhere((r) => r.sort == 'rating');
      rating.reply.complete();
      await settle();
      low.reply.complete();
      await settle();
      expect(c.courses.first.title, 'rating-1-0');

      repo.hold = false;
      final before = repo.requests.length;
      c.selectSort(CourseSortOption.newest);
      await settle();
      c.selectSort(CourseSortOption.ratingHigh);
      await settle();
      expect(repo.requests.length, before, reason: 'the first (newest) was fetched before; rating is cached');
    });
  });
}
