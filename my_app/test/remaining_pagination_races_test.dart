import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/city_repository.dart';
import 'package:my_app/core/data/repositories/enrollment_repository.dart';
import 'package:my_app/core/data/repositories/instructor_repository.dart';
import 'package:my_app/core/data/repositories/reference_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/models/paginated_result.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/modules/courses/controllers/instructor_courses_controller.dart';
import 'package:my_app/modules/institutes/controllers/city_details_controller.dart';
import 'package:my_app/modules/instructors/controllers/instructor_subject_instructors_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';

import 'layout/fakes.dart';

/// آخر بنود التدقيق: «دوراتي» بكل الحجوزات (لا أول 50)، وحماية الصفحات الثانوية من تداخل السحب للتحديث
/// مع «المزيد» (رد متأخر يُلصق صفحة لاحقة بالقائمة الجديدة، أو تحديث أقدم يستبدل أحدث).

// ---------- طلب يُحرَّر يدوياً ----------

class _Call {
  _Call(this.page);
  final int page;
  final reply = Completer<void>();
}

PaginatedResult<T> _page<T>(int page, int total, int perPage, T Function(int id) make) {
  final count = (total - (page - 1) * perPage).clamp(0, perPage);
  return PaginatedResult<T>(
    items: [for (var i = 0; i < count; i++) make(page * 100 + i)],
    currentPage: page,
    lastPage: (total / perPage).ceil(),
    total: total,
    hasMore: page * perPage < total,
  );
}

// ---------- «دوراتي»: خادم وهمي بصفحتين (50 + 10) ----------

class _EnrollmentsServer implements HttpClientAdapter {
  final pages = <int>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    final page = int.parse('${o.queryParameters['page'] ?? 1}');
    pages.add(page);
    const total = 60, perPage = 50;
    final count = (total - (page - 1) * perPage).clamp(0, perPage);
    final body = {
      'current_page': page,
      'last_page': 2,
      'total': total,
      'per_page': perPage,
      'next_page_url': page < 2 ? 'https://x/api/student/enrollments?page=${page + 1}' : null,
      'data': [
        for (var i = 0; i < count; i++)
          {
            'id': page * 1000 + i,
            'status': 'approved',
            'payment_status': 'paid',
            'course': {'id': page * 1000 + i, 'title': 'C $page-$i', 'price': '10000'},
          },
      ],
    };
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------- المدينة ----------

class _HeldCity extends CityRepository {
  _HeldCity(super.client);
  final calls = <_Call>[];
  bool hold = false;

  @override
  Future<CityModel> fetchCityById(int id) async => CityModel.fromJson({'id': id, 'name_ar': 'دمشق', 'name_en': 'D'});

  @override
  Future<PaginatedResult<InstituteModel>> fetchInstitutesByCity(int cityId, {int page = 1, int perPage = 15}) async {
    final call = _Call(page);
    calls.add(call);
    if (hold) {
      await call.reply.future;
    } else {
      call.reply.complete();
    }
    return _page(
      page,
      40,
      perPage,
      (id) => InstituteModel.fromJson({'id': id, 'name_ar': 'I $id', 'name_en': 'I $id'}),
    );
  }
}

// ---------- دورات المدرّس ومدرّسو التخصص ----------

class _HeldInstructors extends InstructorRepository {
  _HeldInstructors(ApiClient client) : super(client, ReferenceRepository(client));
  final calls = <_Call>[];
  bool hold = false;

  /// ما يرجعه كل طلب لمدرّسي التخصص بالترتيب (يميّز الرد الأقدم من الأحدث).
  final subjectReplies = <List<InstructorModel>>[];
  final subjectCalls = <Completer<void>>[];

  @override
  Future<PaginatedResult<CourseModel>> fetchInstructorCoursesPage({
    required int instructorId,
    int page = 1,
    int perPage = 15,
  }) async {
    final call = _Call(page);
    calls.add(call);
    if (hold) {
      await call.reply.future;
    } else {
      call.reply.complete();
    }
    return _page(page, 40, perPage, (id) => CourseModel.fromJson({'id': id, 'title': 'C $id', 'price': 1}));
  }

  @override
  Future<List<InstructorModel>> fetchInstructorsBySubject({required String subjectKey, bool privateOnly = true}) async {
    final index = subjectCalls.length;
    final gate = Completer<void>();
    subjectCalls.add(gate);
    await gate.future;
    return subjectReplies[index];
  }
}

List<InstructorModel> _instructors(String tag, int n) => [
  for (var i = 0; i < n; i++)
    InstructorModel.fromJson({'id': i + 1, 'name_ar': '$tag $i', 'name_en': '$tag $i', 'is_private': true}),
];

void main() {
  tearDown(Get.reset);

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  group('My Courses', () {
    test('loads every page (60), not just the first 50', () async {
      await registerFakes(loggedIn: true, locale: 'ar');
      final client = Get.find<ApiClient>();
      final server = _EnrollmentsServer();
      client.dio.httpClientAdapter = server;
      replaceFake<EnrollmentRepository>(EnrollmentRepository(client));

      final c = Get.put<MyCoursesController>(MyCoursesController());
      // ينتظر الشرط لا زمناً ثابتاً: طلبان فعليان عبر المحوّل قد يتأخران تحت ضغط الاختبارات كلها.
      for (var i = 0; i < 200 && (c.isLoading.value || c.enrollments.length < 60); i++) {
        await settle();
      }

      expect(server.pages, [1, 2]);
      expect(c.enrollments.length, 60, reason: 'the badge counts enrollments.length');
      expect(c.isLoading.value, isFalse);
    });
  });

  group('city page', () {
    late _HeldCity repo;

    Future<CityDetailsController> open() async {
      await registerFakes(loggedIn: true, locale: 'ar');
      repo = _HeldCity(Get.find<ApiClient>());
      replaceFake<CityRepository>(repo);
      Get.routing.args = <String, dynamic>{'id': 1, 'name': 'دمشق'};
      final c = Get.put<CityDetailsController>(CityDetailsController());
      await c.load();
      expect(c.institutes.length, 12);
      return c;
    }

    test('a refresh during load-more drops the late page (no page 2 glued to the new first page)', () async {
      final c = await open();
      repo.hold = true;
      final more = c.loadMore(); // الصفحة 2
      await settle();
      final refresh = c.load(); // تحديث بالسحب أثناءه
      await settle();
      repo.calls.lastWhere((r) => r.page == 1).reply.complete();
      await refresh;
      repo.calls.lastWhere((r) => r.page == 2).reply.complete(); // «المزيد» يصل بعد التحديث
      await more;

      expect(c.institutes.length, 12, reason: 'only the fresh first page');
      expect(c.isLoadingMore.value, isFalse);
      repo.hold = false;
      await c.loadMore();
      expect(c.institutes.length, 24, reason: 'paging continues from page 2');
      expect(c.institutes.map((i) => i.id).toSet().length, 24, reason: 'no duplicates');
    });

    test('load-more does not start while a refresh is running', () async {
      final c = await open();
      repo.hold = true;
      final refresh = c.load();
      await settle();
      final before = repo.calls.length;
      await c.loadMore();
      expect(repo.calls.length, before, reason: 'would page from a number about to be reset');
      repo.calls.last.reply.complete();
      await refresh;
    });

    test('two overlapping refreshes: the late older one does not leave loading stuck', () async {
      final c = await open();
      repo.hold = true;
      final first = c.load();
      await settle();
      final second = c.load();
      await settle();
      final calls = repo.calls.where((r) => r.page == 1 && !r.reply.isCompleted).toList();
      calls.last.reply.complete();
      await second;
      expect(c.isLoading.value, isFalse);
      calls.first.reply.complete();
      await first;
      expect(c.institutes.length, 12);
      expect(c.isLoading.value, isFalse);
    });
  });

  group('instructor courses', () {
    late _HeldInstructors repo;

    Future<InstructorCoursesController> open() async {
      await registerFakes(loggedIn: true, locale: 'ar');
      repo = _HeldInstructors(Get.find<ApiClient>());
      replaceFake<InstructorRepository>(repo);
      Get.routing.args = <String, dynamic>{'id': 9, 'name': 'سامر'};
      final c = Get.put<InstructorCoursesController>(InstructorCoursesController());
      await c.loadCourses();
      expect(c.courses.length, 12);
      return c;
    }

    test('a refresh during load-more drops the late page', () async {
      final c = await open();
      repo.hold = true;
      final more = c.loadMore();
      await settle();
      final refresh = c.loadCourses();
      await settle();
      repo.calls.lastWhere((r) => r.page == 1).reply.complete();
      await refresh;
      repo.calls.lastWhere((r) => r.page == 2).reply.complete();
      await more;

      expect(c.courses.length, 12);
      expect(c.totalCourses.value, 40);
      expect(c.isLoadingMore.value, isFalse);
      repo.hold = false;
      await c.loadMore();
      expect(c.courses.map((e) => e.id).toSet().length, 24);
    });

    test('load-more does not start while a refresh is running', () async {
      final c = await open();
      repo.hold = true;
      final refresh = c.loadCourses();
      await settle();
      final before = repo.calls.length;
      await c.loadMore();
      expect(repo.calls.length, before);
      repo.calls.last.reply.complete();
      await refresh;
    });
  });

  group('subject instructors', () {
    test('an older refresh arriving late does not replace the newer list', () async {
      await registerFakes(loggedIn: true, locale: 'ar');
      final repo = _HeldInstructors(Get.find<ApiClient>());
      replaceFake<InstructorRepository>(repo);
      repo.subjectReplies
        ..add(_instructors('old', 5))
        ..add(_instructors('new', 7));
      Get.routing.args = <String, dynamic>{'key': 'math', 'name': 'رياضيات'};
      // onInit يبدأ الجلب بعد استقرار الصفحة (فوراً هنا): هو الطلب الأقدم.
      final c = Get.put<InstructorSubjectInstructorsController>(InstructorSubjectInstructorsController());
      await settle();
      expect(repo.subjectCalls, hasLength(1));
      final refresh = c.loadInstructors(); // سحب للتحديث: الأحدث
      await settle();
      repo.subjectCalls[1].complete(); // الأحدث يصل أولاً
      await refresh;
      repo.subjectCalls[0].complete(); // الأقدم متأخراً
      await settle();

      expect(c.instructorsCount.value, 7);
      expect(c.instructors.every((i) => i.name.startsWith('new')), isTrue);
      expect(c.isLoading.value, isFalse);
    });
  });
}
