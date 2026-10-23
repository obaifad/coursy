import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/course_rating_service.dart';

import 'layout/fakes.dart';

/// يرد بحسب المسار بعد [latency]، ويسجّل الطلبات وأقصى عدد منها كان جارياً معاً.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.latency = const Duration(milliseconds: 60)});

  Duration latency;
  final requests = <String>[];
  int inFlight = 0;
  int maxInFlight = 0;

  /// مسارات تفشل بـ 500.
  final failing = <String>{};

  /// عدد صفحات المعاهد التي يعلنها الخادم (0 = لا يعلن last_page).
  int institutePages = 1;
  bool announceLastPage = true;

  /// مسارات تتأخر أكثر.
  final slow = <String, Duration>{};

  Map<String, dynamic> _body(RequestOptions o) {
    switch (o.path) {
      case '/institutes':
        final page = (o.queryParameters['page'] as int?) ?? 1;
        return {
          'data': [
            {
              'id': page,
              'name_ar': 'معهد $page',
              'name_en': 'Institute $page',
              'rating': 4.0 + page / 10,
              'city_id': 1,
            },
          ],
          'current_page': page,
          if (announceLastPage) 'last_page': institutePages,
          'next_page_url': page < institutePages ? 'x' : null,
          'total': institutePages,
        };
      case '/cities':
        return {
          'data': [
            {'id': 1, 'name_ar': 'دمشق', 'name_en': 'Damascus'},
          ],
        };
      case '/categories':
        return {
          'data': [
            {'id': 3, 'name_ar': 'البرمجة', 'name_en': 'Programming'},
          ],
        };
    }
    return {'data': []};
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(slow[options.path] ?? latency);
    inFlight--;
    if (failing.contains(options.path)) {
      return ResponseBody.fromString(
        '{}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(_body(options))),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  int count(String path) => requests.where((p) => p == path).length;
}

CourseModel _course({int institute = 1}) => CourseModel.fromJson({
  'id': 9,
  'title_ar': 'دورة',
  'title_en': 'Course',
  'price': '1000',
  'institute_id': institute,
  'category_id': 3,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;
  late CourseRatingService service;
  late DateTime now;

  Future<void> setup({_Adapter? custom}) async {
    await registerFakes(loggedIn: false, locale: 'ar');
    adapter = custom ?? _Adapter();
    final client = Get.find<ApiClient>();
    client.dio.httpClientAdapter = adapter;
    service = CourseRatingService(client);
    now = DateTime(2026, 10, 23, 12);
    CourseRatingService.clock = () => now;
  }

  tearDown(() {
    CourseRatingService.clock = DateTime.now;
    Get.reset();
  });

  test('institutes, cities and categories are requested together, not one after another', () async {
    await setup();
    await service.enrich([_course()]);
    expect(adapter.maxInFlight, greaterThanOrEqualTo(3), reason: 'was 1: three sequential round trips');
    expect(adapter.count('/institutes'), 1);
    expect(adapter.count('/cities'), 1);
    expect(adapter.count('/categories'), 1);
  });

  test('first list pays about one round trip, not three', () async {
    await setup(custom: _Adapter(latency: const Duration(milliseconds: 120)));
    final watch = Stopwatch()..start();
    await service.enrich([_course()]);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(120 * 2), reason: 'sequential would take ~360 ms');
  });

  test('the remaining institute pages are fetched together once the first one says how many there are', () async {
    final a = _Adapter()..institutePages = 4;
    await setup(custom: a);
    final result = await service.enrich([_course(institute: 4)]);
    expect(a.count('/institutes'), 4);
    expect(result.single.rating, closeTo(4.4, 0.001), reason: 'ratings from every page are merged');
  });

  test('unknown page count falls back to following next_page_url one by one', () async {
    final a = _Adapter()
      ..institutePages = 3
      ..announceLastPage = false;
    await setup(custom: a);
    final result = await service.enrich([_course(institute: 3)]);
    expect(a.count('/institutes'), 3);
    expect(result.single.rating, closeTo(4.3, 0.001));
  });

  test('enrich fills rating, city and category as before', () async {
    await setup();
    final result = (await service.enrich([_course()])).single;
    expect(result.rating, closeTo(4.1, 0.001));
    expect(result.categoryName, isNotEmpty);
  });

  test('a stale cache is served at once and refreshed in the background', () async {
    await setup();
    await service.enrich([_course()]);
    adapter.requests.clear();

    now = now.add(const Duration(minutes: 31));
    final watch = Stopwatch()..start();
    final result = await service.enrich([_course()]);
    watch.stop();
    expect(result.single.rating, greaterThan(0), reason: 'old data is still used');
    expect(watch.elapsedMilliseconds, lessThan(40), reason: 'not waiting for the refresh');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(adapter.count('/institutes'), 1, reason: 'refreshed once in the background');
  });

  test('a fresh cache costs no request at all', () async {
    await setup();
    await service.enrich([_course()]);
    adapter.requests.clear();
    now = now.add(const Duration(minutes: 10));
    await service.enrich([_course()]);
    expect(adapter.requests, isEmpty);
  });

  test('a partial failure is retried after a minute, not cached for half an hour', () async {
    final a = _Adapter()..failing.add('/cities');
    await setup(custom: a);
    await service.enrich([_course()]);
    expect(a.count('/cities'), 1);

    a.failing.clear();
    a.requests.clear();
    now = now.add(const Duration(seconds: 30));
    await service.enrich([_course()]);
    expect(a.requests, isEmpty, reason: 'too early to retry');

    now = now.add(const Duration(minutes: 2));
    await service.enrich([_course()]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(a.count('/cities'), 1, reason: 'retried in the background after the short window');
  });

  test('a very slow lookup does not hold the list: it is returned as is, the cache keeps loading', () async {
    final a = _Adapter()..slow['/cities'] = const Duration(milliseconds: 600);
    await setup(custom: a);
    service.maxWait = const Duration(milliseconds: 100);
    final watch = Stopwatch()..start();
    final courses = [_course()];
    final result = await service.enrich(courses);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(400));
    expect(result, same(courses), reason: 'returned unenriched');

    await Future<void>.delayed(const Duration(milliseconds: 700));
    final later = await service.enrich([_course()]);
    expect(later.single.rating, greaterThan(0), reason: 'the same load finished meanwhile; no duplicate requests');
    expect(a.count('/institutes'), 1);
  });

  test('warmUp starts loading early and the first list reuses it', () async {
    await setup();
    final warm = service.warmUp();
    await warm;
    adapter.requests.clear();
    await service.enrich([_course()]);
    expect(adapter.requests, isEmpty);
  });

  test('invalidateCache (login/logout) clears everything', () async {
    await setup();
    await service.enrich([_course()]);
    service.invalidateCache();
    adapter.requests.clear();
    await service.enrich([_course()]);
    expect(adapter.count('/institutes'), 1);
  });
}
