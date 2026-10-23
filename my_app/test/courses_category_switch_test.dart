import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/courses/views/courses_views.dart';
import 'package:my_app/widgets/app_skeletons.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';
import 'layout/sample_data.dart';

/// تبويب الدورات: ضغط التصنيف المحدد لا يجلب شيئاً، لكل تصنيف كاشه (العودة فورية)، والتصنيف الجديد
/// يُفرَّغ فيه المحتوى فيظهر الهيكل بدل بقاء قائمة التصنيف السابق.
class _ByCategory extends CourseRepository {
  _ByCategory(super.client, super.rating);

  /// category_id (null = الكل) ← الدورات.
  final List<int?> requests = [];

  /// يوقف الرد لتصنيف حتى يُكمله الاختبار.
  final Map<int?, Completer<void>> gates = {};

  static List<CourseModel> forCategory(int? id) {
    final all = sampleCourses();
    return switch (id) {
      3 => all.sublist(0, 2),
      5 => all.sublist(2),
      _ => all,
    };
  }

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final id = query?['category_id'] as int?;
    requests.add(id);
    final gate = gates[id];
    if (gate != null) await gate.future;
    final items = forCategory(id);
    return PaginatedResult<CourseModel>(
      items: items,
      currentPage: page,
      lastPage: 1,
      total: items.length,
      hasMore: false,
    );
  }
}

void main() {
  setUpAll(loadAuditFonts);

  late _ByCategory repo;
  late CoursesController c;
  late DateTime now;

  Future<void> setup() async {
    await registerFakes(loggedIn: true, locale: 'ar');
    Get.put(MemoryCache());
    repo = _ByCategory(Get.find<ApiClient>(), Get.find<CourseRatingService>());
    replaceFake<CourseRepository>(repo);
    now = DateTime(2026, 10, 23, 12);
    MemoryCache.clock = () => now;
    c = Get.put(CoursesController());
    await settle();
  }

  tearDown(() {
    MemoryCache.clock = DateTime.now;
    FakeApi.reset();
    Get.reset();
  });

  List<int> ids() => c.courses.map((e) => e.id).toList();

  test('first load: all courses, one request', () async {
    await setup();
    expect(repo.requests, [null]);
    expect(ids(), _ByCategory.forCategory(null).map((e) => e.id).toList());
  });

  test('tapping the selected chip fetches nothing', () async {
    await setup();
    c.selectCategory(null); // «الكل» محدد أصلاً
    await settle();
    expect(repo.requests, [null]);

    c.selectCategory(3);
    await settle();
    final after = repo.requests.length;
    c.selectCategory(3);
    c.selectCategory(3);
    await settle();
    expect(repo.requests.length, after, reason: 'no request for the already selected category');
  });

  test('a new category empties the list at once (skeleton), then loads it', () async {
    await setup();
    repo.gates[3] = Completer<void>();
    c.selectCategory(3);
    expect(c.courses, isEmpty, reason: 'the previous category must not stay on screen');
    expect(c.isLoading.value, isTrue, reason: 'skeleton condition: loading and empty');

    repo.gates[3]!.complete();
    await settle();
    expect(ids(), _ByCategory.forCategory(3).map((e) => e.id).toList());
    expect(c.isLoading.value, isFalse);
  });

  test('coming back to a visited category is instant, no skeleton, no request', () async {
    await setup();
    c.selectCategory(3);
    await settle();
    c.selectCategory(null);
    await settle();
    final before = repo.requests.length;

    var sawSkeleton = false;
    c.isLoading.listen((v) => sawSkeleton = sawSkeleton || v);
    c.selectCategory(3);
    expect(ids(), _ByCategory.forCategory(3).map((e) => e.id).toList(), reason: 'restored before any await');
    expect(c.isLoading.value, isFalse);
    await settle();
    expect(repo.requests.length, before, reason: 'cached category: no request');
    expect(sawSkeleton, isFalse);
  });

  test('"All" is cached too', () async {
    await setup();
    c.selectCategory(5);
    await settle();
    final before = repo.requests.length;
    c.selectCategory(null);
    expect(c.courses.length, _ByCategory.forCategory(null).length);
    await settle();
    expect(repo.requests.length, before);
  });

  test('a stale category is shown at once and refreshed silently', () async {
    await setup();
    c.selectCategory(3);
    await settle();
    c.selectCategory(null);
    await settle();
    now = now.add(MemoryCache.defaultTtl + const Duration(minutes: 1));
    final before = repo.requests.length;

    var sawSkeleton = false;
    c.isLoading.listen((v) => sawSkeleton = sawSkeleton || v);
    c.selectCategory(3);
    expect(ids(), isNotEmpty, reason: 'shown at once');
    await settle();
    expect(repo.requests.length, before + 1, reason: 'one silent refresh');
    expect(sawSkeleton, isFalse);
  });

  test('a late answer for the previous category never replaces the new list', () async {
    await setup();
    repo.gates[3] = Completer<void>();
    c.selectCategory(3); // طلب معلّق
    repo.gates[5] = Completer<void>();
    c.selectCategory(5);
    repo.gates[5]!.complete();
    await settle();
    expect(ids(), _ByCategory.forCategory(5).map((e) => e.id).toList());

    repo.gates[3]!.complete(); // يصل متأخراً
    await settle();
    expect(ids(), _ByCategory.forCategory(5).map((e) => e.id).toList(), reason: 'category 3 answer was dropped');
  });

  test('pull to refresh (loadCourses) always fetches and refreshes the category cache', () async {
    await setup();
    final before = repo.requests.length;
    await c.loadCourses();
    expect(repo.requests.length, before + 1);
  });

  testWidgets('the page: tapping the selected chip does nothing; a new chip shows the skeleton first', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.runAsync(setup); // الانتظار الحقيقي داخل setup لا يعمل في الزمن الوهمي
    // التصنيفات من المتحكّم الحقيقي (الكاش الوهمي): نختار أول تصنيف ظاهر.
    await tester.pumpWidget(auditApp(locale: 'ar', scale: 1, boundaryKey: GlobalKey(), child: const CoursesView()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.categories, isNotEmpty);
    final first = c.categories.first;

    final before = repo.requests.length;
    await tester.tap(find.text('filter_all'.tr));
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.requests.length, before, reason: '«All» was already selected');

    repo.gates[first.id] = Completer<void>();
    await tester.tap(find.text(first.name).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppSliverGridSkeleton), findsOneWidget, reason: 'skeleton while the new category loads');
    expect(find.byType(CourseAuroraCard), findsNothing, reason: 'no cards of the previous category');

    repo.gates[first.id]!.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppSliverGridSkeleton), findsNothing);
  });
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));
