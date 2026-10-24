import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/cache/memory_cache.dart';
import 'package:my_app/core/data/repositories/course_repository.dart';
import 'package:my_app/core/data/repositories/instructor_repository.dart';
import 'package:my_app/core/data/repositories/reference_repository.dart';
import 'package:my_app/core/locale/plural.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';
import 'package:my_app/modules/courses/controllers/category_courses_controller.dart';
import 'package:my_app/modules/courses/views/category_courses_view.dart';
import 'package:my_app/modules/instructors/controllers/private_instructors_controller.dart';
import 'package:my_app/modules/instructors/views/private_instructors_view.dart';

import 'layout/fakes.dart';
import 'layout/layout_harness.dart';

/// الشارات تعرض العدد الكلي من الخادم (`total`) لا ما حُمّل من صفحات، وتبديل تخصص المدرّسين لا يخلط
/// القوائم بردود متأخرة لتخصص سابق.

// ---------- صفحة التصنيف: 40 دورة، 12 في الصفحة ----------

class _NoRating extends CourseRatingService {
  _NoRating(super.client);
  @override
  Future<List<CourseModel>> enrich(List<CourseModel> courses) async => courses;
}

class _PagedCourses extends CourseRepository {
  _PagedCourses(ApiClient client) : super(client, _NoRating(client));

  static const total = 40;

  @override
  Future<PaginatedResult<CourseModel>> fetchCoursesPage({
    int page = 1,
    int perPage = 15,
    Map<String, dynamic>? query,
  }) async {
    final count = (total - (page - 1) * perPage).clamp(0, perPage);
    return PaginatedResult<CourseModel>(
      items: [
        for (var i = 0; i < count; i++)
          CourseModel.fromJson({'id': page * 100 + i, 'title': 'C $page-$i', 'price': 10000}),
      ],
      currentPage: page,
      lastPage: (total / perPage).ceil(),
      total: total,
      hasMore: page * perPage < total,
    );
  }
}

// ---------- المدرّسون الخصوصيون: كل تخصص 30 مدرّساً، 15 في الصفحة، والرد يُحرَّر يدوياً ----------

class _Call {
  _Call(this.subject, this.page);
  final String? subject;
  final int page;
  final reply = Completer<void>();
}

class _PagedInstructors extends InstructorRepository {
  _PagedInstructors(ApiClient client) : super(client, ReferenceRepository(client));

  final calls = <_Call>[];
  bool hold = false;

  /// المجموع لكل تخصص: يميّز من أي تخصص جاءت الشارة.
  static int totalFor(String? subject) => subject == null ? 30 : 22;

  @override
  Future<PaginatedResult<InstructorModel>> fetchInstructorsPage({
    int page = 1,
    int perPage = 15,
    bool? isPrivate,
    int? instituteId,
    String? subjectKey,
    int? specializationId,
  }) async {
    final call = _Call(subjectKey, page);
    calls.add(call);
    if (hold) await call.reply.future;
    final total = totalFor(subjectKey);
    final count = (total - (page - 1) * perPage).clamp(0, perPage);
    return PaginatedResult<InstructorModel>(
      items: [
        for (var i = 0; i < count; i++)
          InstructorModel.fromJson({
            'id': page * 100 + i + (subjectKey == null ? 0 : 5000),
            'name_ar': '${subjectKey ?? 'all'} $page-$i',
            'name_en': '${subjectKey ?? 'all'} $page-$i',
            'is_private': true,
          }),
      ],
      currentPage: page,
      lastPage: (total / perPage).ceil(),
      total: total,
      hasMore: page * perPage < total,
    );
  }

  @override
  Future<List<InstructorSubjectModel>> fetchInstructorSubjectFilters() async => const [];
}

void main() {
  setUpAll(loadAuditFonts);
  tearDown(() {
    MemoryCache.clear();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> pumpView(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(auditApp(child: view, locale: 'ar', scale: 1, boundaryKey: GlobalKey()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('category page', () {
    Future<CategoryCoursesController> open() async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(MemoryCache());
      replaceFake<CourseRepository>(_PagedCourses(Get.find<ApiClient>()));
      Get.routing.args = <String, dynamic>{'id': 3, 'name': 'البرمجة'};
      // النوع صريحاً: داخل دالة async يُستنتج FutureOr<…> فيُسجَّل بنوع لا تجده الصفحة.
      return Get.put<CategoryCoursesController>(CategoryCoursesController());
    }

    test('count is the server total (40), not the 12 loaded, and survives load-more', () async {
      final c = await open();
      await settle();
      expect(c.courses.length, 12);
      expect(c.displayCount, 40);
      await c.loadMore();
      expect(c.courses.length, 24);
      expect(c.displayCount, 40);
    });

    test('a cached list keeps its total', () async {
      final c = await open();
      await settle();
      c.selectSort(CourseSortOption.priceLow);
      await settle();
      c.selectSort(CourseSortOption.newest); // من الكاش
      expect(c.displayCount, 40);
    });

    test('without a server total it falls back to what is loaded', () async {
      final c = await open();
      await settle();
      c.totalCount.value = 0;
      expect(c.displayCount, c.courses.length);
    });

    testWidgets('header badge shows 40', (tester) async {
      await open();
      await pumpView(tester, const CategoryCoursesView());
      expect(find.text(pluralTr('category_courses_count', 40)), findsOneWidget);
      expect(find.text(pluralTr('category_courses_count', 12)), findsNothing);
    });
  });

  group('private instructors', () {
    late _PagedInstructors repo;

    Future<PrivateInstructorsController> open() async {
      await registerFakes(loggedIn: true, locale: 'ar');
      Get.put(MemoryCache());
      repo = _PagedInstructors(Get.find<ApiClient>());
      Get.routing.args = null;
      return Get.put<PrivateInstructorsController>(PrivateInstructorsController(repo));
    }

    test('count is the server total (30), not the 15 loaded', () async {
      final c = await open();
      await settle();
      expect(c.instructors.length, 15);
      expect(c.displayCount, 30);
      await c.loadMore();
      expect(c.instructors.length, 30);
      expect(c.displayCount, 30);
    });

    test('a slow first page for the previous subject does not replace the new list', () async {
      final c = await open();
      await settle();
      c.selectSubject('math');
      await settle();
      // نعود إلى «الكل» (في الكاش) بينما طلب أحدث لـ math متأخر
      repo.hold = true;
      c.selectSubject(null);
      c.selectSubject('physics');
      await settle();
      c.selectSubject(null); // من الكاش
      final physics = repo.calls.lastWhere((r) => r.subject == 'physics');
      physics.reply.complete(); // رد physics يصل متأخراً
      await settle();

      expect(c.selectedSubjectKey.value, isNull);
      expect(c.instructors.every((i) => i.name.startsWith('all')), isTrue, reason: 'stale physics reply dropped');
      expect(c.displayCount, 30);
    });

    test('a load-more of the previous subject is not appended to the new list', () async {
      final c = await open();
      await settle();
      repo.hold = true;
      final more = c.loadMore(); // صفحة 2 لـ «الكل»، معلّقة
      await settle();
      c.selectSubject('math');
      await settle();
      final mathFirst = repo.calls.lastWhere((r) => r.subject == 'math' && r.page == 1);
      mathFirst.reply.complete();
      await settle();
      repo.calls.firstWhere((r) => r.subject == null && r.page == 2).reply.complete();
      await more;
      await settle();

      expect(c.instructors.every((i) => i.name.startsWith('math')), isTrue, reason: 'no "all" page 2 mixed in');
      expect(c.instructors.length, 15);
      expect(c.displayCount, 22);
      expect(c.isLoadingMore.value, isFalse);
    });

    test('a new subject shows the skeleton instead of the old list', () async {
      final c = await open();
      await settle();
      repo.hold = true;
      c.selectSubject('math');
      expect(c.instructors, isEmpty);
      expect(c.isLoading.value, isTrue);
      expect(c.displayCount, 0);
      repo.calls.last.reply.complete();
      await settle();
      expect(c.instructors, isNotEmpty);
    });

    test('pull-to-refresh during load-more does not leave the spinner stuck', () async {
      final c = await open();
      await settle();
      repo.hold = true;
      final more = c.loadMore();
      await settle();
      final refresh = c.loadInstructors(); // يُبطل «المزيد» الجاري
      await settle();
      for (final call in repo.calls.where((r) => !r.reply.isCompleted)) {
        call.reply.complete();
      }
      await Future.wait([more, refresh]);
      expect(c.isLoadingMore.value, isFalse);
      repo.hold = false;
      await c.loadMore();
      expect(c.instructors.length, 30, reason: 'load-more still works after the refresh');
    });

    testWidgets('header badge shows 30', (tester) async {
      await open();
      await pumpView(tester, const PrivateInstructorsView());
      expect(find.text(pluralTr('instructor_subject_count', 30)), findsOneWidget);
      expect(find.text(pluralTr('instructor_subject_count', 15)), findsNothing);
    });
  });
}
