import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/data/repositories/auth_repository.dart';
import 'package:my_app/core/data/repositories/review_repository.dart';
import 'package:my_app/core/models/app_models.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/services/student_id_resolver.dart';
import 'package:my_app/core/storage/token_storage.dart';

import 'layout/fakes.dart';

/// يسجّل الطلبات ويرد بحسب المسار.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.respond);
  final Map<String, dynamic> Function(RequestOptions o) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(respond(options))),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);

  test('review parses short name, profile image and course title', () {
    final r = ReviewModel.fromJson({
      'id': 1,
      'rating': 4,
      'comment': 'جيد',
      'student': {
        'id': 9,
        'name': 'Sara H.',
        'first_name': 'Sara',
        'last_name': 'H',
        'profile_image': 'students/a.jpg',
      },
      'course': {'id': 3, 'title': 'Laravel API'},
    });
    expect(r.studentName, 'Sara H.');
    expect(r.studentImageUrl, 'students/a.jpg');
    expect(r.resolvedStudentImageUrl, endsWith('/storage/students/a.jpg'));
    expect(r.courseTitle, 'Laravel API');
  });

  test('instructor reviews use the dedicated endpoint and read all pages', () async {
    await registerFakes(loggedIn: false, locale: 'ar');
    final client = Get.find<ApiClient>();
    final adapter = _RecordingAdapter((o) {
      final page = int.parse('${o.queryParameters['page'] ?? 1}');
      return {
        'data': [
          {
            'id': page,
            'rating': 5,
            'student': {'name': 'S$page'},
          },
        ],
        'current_page': page,
        'last_page': 2,
        'total': 2,
      };
    });
    client.dio.httpClientAdapter = adapter;
    final repo = ReviewRepository(client, Get.find<StudentIdResolver>());

    final reviews = await repo.fetchReviews(instructorId: 7);

    expect(adapter.requests.map((r) => r.path).toSet(), {'/instructors/7/reviews'});
    expect(reviews.map((r) => r.studentName), ['S1', 'S2']);
  });

  test('login sends a single "login" field', () async {
    await registerFakes(loggedIn: false, locale: 'ar');
    final client = Get.find<ApiClient>();
    final adapter = _RecordingAdapter(
      (_) => {
        'token': 'abc',
        'user': {'id': 1, 'first_name': 'A'},
      },
    );
    client.dio.httpClientAdapter = adapter;
    final repo = AuthRepository(client, Get.find<TokenStorage>());

    await repo.login(login: '0912345678', password: 'secret');

    final body = adapter.requests.single.data as Map;
    expect(adapter.requests.single.path, '/student/login');
    expect(body['login'], '0912345678');
    expect(body.containsKey('email'), isFalse);
    expect(body.containsKey('phone'), isFalse);
    expect(Get.find<TokenStorage>().isLoggedIn, isTrue);
  });
}
