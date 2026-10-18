import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/controllers/course_details_controller.dart';

import 'layout/fakes.dart';
import 'layout/sample_data.dart';

class _CountingCourses extends CourseRepository {
  _CountingCourses(super.client, super.rating);

  int pages = 0;
  int details = 0;

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    pages++;
    final items = sampleCourses();
    return PaginatedResult<CourseModel>(
      items: items,
      currentPage: page,
      lastPage: 1,
      total: items.length,
      hasMore: false,
    );
  }

  @override
  Future<CourseModel> fetchCourseById(int id) async {
    details++;
    return sampleCourses().firstWhere((c) => c.id == id);
  }

  @override
  Future<List<ScheduleModel>> fetchCourseSchedules(int courseId) async => [];
}

/// ذاكرة الصفحات: العودة إلى صفحة زرناها قبل قليل تعرض بياناتها فوراً بلا هيكل ولا طلب،
/// القديمة تُحدَّث بصمت، والسحب للتحديث يتجاوزها دائماً.
void main() {
  late _CountingCourses courses;
  late DateTime now;

  Future<void> setup() async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(MemoryCache());
    courses = _CountingCourses(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    Get.delete<CourseRepository>(force: true);
    Get.put<CourseRepository>(courses);
    now = DateTime(2026, 10, 18, 12);
    MemoryCache.clock = () => now;
  }

  tearDown(() {
    MemoryCache.clock = DateTime.now;
    Get.reset();
  });

  group('MemoryCache', () {
    test('stores and returns a value with its age', () async {
      await setup();
      final key = MemoryCache.key('x', [1]);
      expect(MemoryCache.get<String>(key), isNull);
      MemoryCache.put<String>(key, 'v');
      expect(MemoryCache.get<String>(key)!.value, 'v');
      expect(MemoryCache.get<String>(key)!.isFresh(), isTrue);
      now = now.add(MemoryCache.defaultTtl + const Duration(seconds: 1));
      expect(MemoryCache.get<String>(key)!.isFresh(), isFalse, reason: 'older than the TTL -> stale');
    });

    test('a different type under the same key is not returned', () async {
      await setup();
      MemoryCache.put<String>('k', 'v');
      expect(MemoryCache.get<int>('k'), isNull);
    });

    test('the key includes the language', () async {
      await setup();
      Get.locale = const Locale('ar');
      final ar = MemoryCache.key('s', [1]);
      Get.locale = const Locale('en');
      final en = MemoryCache.key('s', [1]);
      expect(ar, isNot(en));
    });

    test('evicts the least recently used entry beyond the cap', () async {
      await setup();
      for (var i = 0; i < MemoryCache.maxEntries; i++) {
        MemoryCache.put<int>('k$i', i);
      }
      MemoryCache.get<int>('k0'); // k0 becomes the most recently used
      MemoryCache.put<int>('extra', 1);
      expect(MemoryCache.get<int>('k0'), isNotNull);
      expect(MemoryCache.get<int>('k1'), isNull, reason: 'the oldest unused entry went out');
    });

    test('clear empties it; unregistered cache stores nothing', () async {
      await setup();
      MemoryCache.put<int>('k', 1);
      MemoryCache.clear();
      expect(MemoryCache.get<int>('k'), isNull);
      Get.reset();
      MemoryCache.put<int>('k', 1);
      expect(MemoryCache.get<int>('k'), isNull);
    });
  });

  group('category page', () {
    CategoryCoursesController open() {
      Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة'};
      return Get.put(CategoryCoursesController(), tag: 'visit-${DateTime.now().microsecondsSinceEpoch}');
    }

    Future<void> settleLoad() => Future<void>.delayed(const Duration(milliseconds: 30));

    test('first visit shows the loading state and fetches once', () async {
      await setup();
      final c = open();
      expect(c.isLoading.value, isTrue);
      await settleLoad();
      expect(c.courses, isNotEmpty);
      expect(courses.pages, 1);
    });

    test('coming back shows the list at once, no loading state, no new request', () async {
      await setup();
      final first = open();
      await settleLoad();

      final second = open();
      expect(second.isLoading.value, isFalse, reason: 'cached: no skeleton');
      expect(second.courses.length, first.courses.length, reason: 'items are there before any await');
      await settleLoad();
      expect(courses.pages, 1, reason: 'fresh cache: no second request');
    });

    test('a stale cache is shown at once and refreshed silently', () async {
      await setup();
      open();
      await settleLoad();
      now = now.add(MemoryCache.defaultTtl + const Duration(minutes: 1));

      final again = open();
      expect(again.isLoading.value, isFalse);
      expect(again.courses, isNotEmpty);
      var sawLoading = false;
      again.isLoading.listen((v) => sawLoading = sawLoading || v);
      await settleLoad();
      expect(courses.pages, 2, reason: 'stale: refreshed in the background');
      expect(sawLoading, isFalse, reason: 'never back to the loading state');
    });

    test('pull-to-refresh always fetches, even when fresh', () async {
      await setup();
      final c = open();
      await settleLoad();
      await c.loadCourses();
      expect(courses.pages, 2);
      expect(c.isLoading.value, isFalse);
    });

    test('another category does not reuse the cached list', () async {
      await setup();
      open();
      await settleLoad();
      Get.routing.args = <String, dynamic>{'id': 9, 'name': 'اللغات'};
      final other = Get.put(CategoryCoursesController(), tag: 'other');
      expect(other.isLoading.value, isTrue);
      await settleLoad();
      expect(courses.pages, 2);
    });

    test('logging out/in clears the cache', () async {
      await setup();
      open();
      await settleLoad();
      MemoryCache.clear();
      final again = open();
      expect(again.isLoading.value, isTrue);
      await settleLoad();
      expect(courses.pages, 2);
    });
  });

  group('course details', () {
    CourseDetailsController open(CourseModel seed) {
      Get.routing.args = seed;
      return Get.put(CourseDetailsController(), tag: 'c-${DateTime.now().microsecondsSinceEpoch}');
    }

    Future<void> settleLoad() => Future<void>.delayed(const Duration(milliseconds: 60));

    test('reopening a course fetches nothing while fresh and has its details at once', () async {
      await setup();
      final seed = sampleCourses().first;
      open(seed);
      await settleLoad();
      expect(courses.details, 1);

      final again = open(seed);
      expect(again.course.value, isNotNull);
      await settleLoad();
      expect(courses.details, 1, reason: 'fresh cache: no new /courses/{id} request');
    });

    test('after the (short) details TTL it refetches in the background', () async {
      await setup();
      final seed = sampleCourses().first;
      open(seed);
      await settleLoad();
      now = now.add(const Duration(minutes: 3));
      final again = open(seed);
      expect(again.course.value, isNotNull);
      await settleLoad();
      expect(courses.details, 2);
    });

    test('pull-to-refresh refetches even when fresh', () async {
      await setup();
      final seed = sampleCourses().first;
      final c = open(seed);
      await settleLoad();
      await c.refreshDetails();
      expect(courses.details, greaterThan(1), reason: 'the pull bypasses the cache');
    });
  });
}
