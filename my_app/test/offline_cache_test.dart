import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_app/core/cache/app_image_cache.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/storage/api_disk_cache.dart';
import 'package:my_app/modules/courses/controllers/courses_controller.dart';
import 'package:my_app/modules/home/controllers/home_controller.dart';
import 'package:my_app/modules/institutes/controllers/institutes_controller.dart';
import 'package:my_app/modules/profile/controllers/my_courses_controller.dart';
import 'package:my_app/widgets/app_widgets.dart';

import 'layout/fakes.dart';

/// بعد أن يُغلق النظام التطبيق في الخلفية تضيع الذاكرة كلها: الشاشات الرئيسية كانت تبدأ بهياكل تحميل،
/// والصور المخزّنة على القرص تمرّ بالمربع ثم التلاشي كأنها تُنزَّل. الآن آخر رد للصفحة الأولى من قوائمها
/// على القرص يُرسم فوراً ثم يُحدَّث، والصورة المخزّنة تظهر بلا مربع ولا تلاشٍ.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body, {this.status = 200});
  final Object body;
  final int status;
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'data': items,
  'meta': {'current_page': 1, 'last_page': 1, 'per_page': 10, 'total': items.length},
};

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('offline_cache_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    await GetStorage.init();
    await ApiDiskCache.init();
  });

  setUp(() async {
    await GetStorage(ApiDiskCache.boxName).erase();
  });
  tearDown(() {
    FakeApi.reset();
    Get.reset();
  });

  group('ApiDiskCache', () {
    test('key: query order and lang do not matter; language and audience do', () {
      final a = ApiDiskCache.keyFor(
        '/courses',
        {'page': 1, 'per_page': 10, 'lang': 'ar'},
        lang: 'ar',
        audience: 'guest',
      );
      final b = ApiDiskCache.keyFor('/courses', {'per_page': 10, 'page': 1}, lang: 'ar', audience: 'guest');
      expect(a, b);
      expect(ApiDiskCache.keyFor('/courses', {'page': 1}, lang: 'en', audience: 'guest'), isNot(a));
      expect(ApiDiskCache.keyFor('/courses', {'page': 1, 'per_page': 10}, lang: 'ar', audience: 'student_1'), isNot(a));
    });

    test('keeps the newest entries only', () async {
      final cache = ApiDiskCache();
      for (var i = 0; i < ApiDiskCache.maxEntries + 5; i++) {
        await cache.write('k$i', {'i': i});
      }
      expect(cache.read('k0'), isNull, reason: 'the oldest is evicted');
      expect(cache.read('k${ApiDiskCache.maxEntries + 4}'), {'i': ApiDiskCache.maxEntries + 4});
    });

    test('logging out drops what was stored for students, keeps the guest entries', () async {
      final cache = ApiDiskCache();
      final guest = ApiDiskCache.keyFor('/courses', {}, lang: 'ar', audience: 'guest');
      final student = ApiDiskCache.keyFor('/student/enrollments', {}, lang: 'ar', audience: 'student_7');
      await cache.write(guest, {'g': 1});
      await cache.write(student, {'s': 1});
      await cache.clearStudentEntries();
      expect(cache.read(guest), {'g': 1});
      expect(cache.read(student), isNull);
    });
  });

  group('ApiClient', () {
    Future<(ApiClient, _JsonAdapter)> client({bool loggedIn = false, Object? body, int status = 200}) async {
      final tokens = await registerFakes(loggedIn: loggedIn, locale: 'ar');
      Get.put(ApiDiskCache());
      final c = Get.find<ApiClient>();
      final adapter = _JsonAdapter(
        body ??
            _page([
              {'id': 1},
            ]),
        status: status,
      );
      c.dio.httpClientAdapter = adapter;
      expect(tokens.isLoggedIn, loggedIn);
      return (c, adapter);
    }

    Object? cachedBody(ApiClient c, String path, Map<String, dynamic> query) =>
        c.cached(path, query: query, mapper: (b) => b);

    test('the first page of a listed path is kept on disk, under its query', () async {
      final (c, _) = await client();
      await c.get('/courses', query: {'page': 1, 'per_page': 10});
      await Future<void>.delayed(Duration.zero);
      expect(cachedBody(c, '/courses', {'per_page': 10, 'page': 1}), isNotNull);
      expect(cachedBody(c, '/courses', {'page': 1, 'per_page': 20}), isNull, reason: 'another query');
    });

    test('later pages, other paths and errors are not kept', () async {
      final (c, _) = await client();
      await c.get('/courses', query: {'page': 2, 'per_page': 10});
      await c.get('/notifications');
      await Future<void>.delayed(Duration.zero);
      expect(cachedBody(c, '/courses', {'page': 2, 'per_page': 10}), isNull);
      expect(cachedBody(c, '/notifications', {}), isNull);

      final (c2, _) = await client(status: 404);
      await c2.get('/institutes', query: {'page': 1, 'per_page': 12});
      await Future<void>.delayed(Duration.zero);
      expect(cachedBody(c2, '/institutes', {'page': 1, 'per_page': 12}), isNull);
    });

    test('a student never reads what another account stored', () async {
      final (c, _) = await client(loggedIn: true);
      await c.get('/student/enrollments', query: {'page': 1, 'per_page': 50});
      await Future<void>.delayed(Duration.zero);
      expect(cachedBody(c, '/student/enrollments', {'page': 1, 'per_page': 50}), isNotNull);
      final (guest, _) = await client();
      expect(cachedBody(guest, '/student/enrollments', {'page': 1, 'per_page': 50}), isNull);
    });
  });

  group('screens draw from disk before the network answers', () {
    String key(String path, Map<String, dynamic> query, {bool student = false}) =>
        ApiDiskCache.keyFor(path, query, lang: 'ar', audience: student ? 'student_1' : 'guest');

    Future<ApiDiskCache> seed(Map<String, Object> entries) async {
      final cache = Get.put(ApiDiskCache());
      for (final e in entries.entries) {
        await cache.write(e.key, e.value);
      }
      // الشبكة لا تردّ: ما يظهر الآن من القرص وحده.
      FakeApi.gate = Completer<void>();
      return cache;
    }

    test('courses tab', () async {
      await registerFakes(loggedIn: false, locale: 'ar');
      await seed({
        key('/courses', {'page': 1, 'per_page': 10}): _page([
          {'id': 501, 'title_ar': 'دورة من القرص', 'title_en': 'From disk', 'price': '1000'},
        ]),
      });
      final c = Get.put(CoursesController());
      expect(c.isLoading.value, isFalse, reason: 'no skeleton');
      expect(c.courses.map((x) => x.id), [501]);
      FakeApi.gate!.complete();
    });

    test('institutes tab', () async {
      await registerFakes(loggedIn: false, locale: 'ar');
      await seed({
        key('/institutes', {'page': 1, 'per_page': 12}): _page([
          {'id': 601, 'name_ar': 'معهد من القرص', 'name_en': 'From disk'},
        ]),
        key('/cities', {'page': 1, 'per_page': 100}): _page([
          {'id': 1, 'name_ar': 'دمشق', 'name_en': 'Damascus'},
          {'id': 2, 'name_ar': 'حلب', 'name_en': 'Aleppo'},
        ]),
      });
      final c = Get.put(InstitutesController());
      expect(c.isLoading.value, isFalse);
      expect(c.institutes.map((x) => x.id), [601]);
      expect(c.cities.length, 2);
      FakeApi.gate!.complete();
    });

    test('my courses (this student only)', () async {
      await registerFakes(loggedIn: true, locale: 'ar');
      await seed({
        key('/student/enrollments', {'page': 1, 'per_page': 50}, student: true): _page([
          {'id': 701, 'status': 'pending', 'course_id': 1},
        ]),
      });
      final c = Get.put(MyCoursesController());
      expect(c.isLoading.value, isFalse);
      expect(c.enrollments.map((x) => x.id), [701]);
      FakeApi.gate!.complete();
    });

    test('home: the tutors rail from disk, then still refreshed from the network', () async {
      final tokens = await registerFakes(loggedIn: false, locale: 'ar');
      await seed({
        key('/instructors', {'page': 1, 'per_page': 12, 'is_private': 1}): _page([
          {'id': 801, 'name_ar': 'مدرّس من القرص', 'name_en': 'From disk', 'is_private': 1},
        ]),
      });
      final c = Get.put(HomeController(tokens));
      expect(c.privateInstructors.map((x) => x.id), [801]);
      FakeApi.gate!.complete();
      FakeApi.gate = null;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(FakeApi.count('fetchInstructorsPage'), greaterThan(0), reason: 'drawn from disk is not "fresh"');
      expect(c.privateInstructors.map((x) => x.id), isNot(contains(801)), reason: 'the network list replaced it');
    });

    test('nothing on disk: the skeleton as before', () async {
      await registerFakes(loggedIn: false, locale: 'ar');
      await seed({});
      final c = Get.put(CoursesController());
      expect(c.isLoading.value, isTrue);
      expect(c.courses, isEmpty);
      FakeApi.gate!.complete();
    });
  });

  group('images', () {
    const url = 'https://coursy.sy/storage/courses/a.jpg';

    CachedNetworkImage image(WidgetTester tester) => tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 100, height: 100, child: AppNetworkImage(url: url, width: 100, height: 100)),
      ),
    );

    testWidgets('already on disk: no placeholder, no fade', (tester) async {
      AppImageCache.markOnDiskForTest([url]);
      await pump(tester);
      final w = image(tester);
      expect(w.placeholder, isNull);
      expect(w.fadeInDuration, Duration.zero);
      expect(w.cacheManager, same(AppImageCache.manager));
    });

    testWidgets('new image: the placeholder and the short fade', (tester) async {
      AppImageCache.markOnDiskForTest(const []);
      await pump(tester);
      final w = image(tester);
      expect(w.placeholder, isNotNull);
      expect(w.fadeInDuration, greaterThan(Duration.zero));
    });

    test('the image store keeps 1000 images (was 200), under the same key as before', () {
      expect(AppImageCache.maxObjects, 1000);
      expect(AppImageCache.key, 'libCachedImageData');
      expect(AppImageCache.manager.config.maxNrOfCacheObjects, 1000);
    });
  });
}
