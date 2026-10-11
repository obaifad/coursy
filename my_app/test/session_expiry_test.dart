import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/storage/token_storage.dart';

import 'layout/fakes.dart';

/// يرد بحالة ثابتة على كل طلب.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode({'message': 'Unauthenticated.'})),
      status,
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

  late int calls;

  setUp(() async {
    Get.reset();
    calls = 0;
    ApiClient.onUnauthorized = () => calls++;
  });

  tearDown(() => ApiClient.onUnauthorized = null);

  Future<ApiClient> client({required bool loggedIn, int status = 401}) async {
    await registerFakes(loggedIn: loggedIn, locale: 'ar');
    final c = Get.find<ApiClient>();
    c.dio.httpClientAdapter = _StatusAdapter(status);
    return c;
  }

  test('401 on an authenticated request reports an expired session', () async {
    final c = await client(loggedIn: true);
    await c.get('/student/enrollments');
    expect(Get.find<TokenStorage>().isLoggedIn, isTrue);
    expect(calls, 1);
  });

  test('401 without a token (guest) is ignored', () async {
    final c = await client(loggedIn: false);
    await c.get('/student/enrollments');
    expect(calls, 0);
  });

  test('401 from auth-flow endpoints (login, logout, devices) is ignored', () async {
    final c = await client(loggedIn: true);
    await c.post('/student/login', data: {});
    await c.post('/student/logout');
    await c.delete('/student/devices', data: {});
    expect(calls, 0);
  });

  test('other errors do not end the session', () async {
    final c = await client(loggedIn: true, status: 403);
    await c.get('/student/enrollments');
    expect(calls, 0);
  });
}
