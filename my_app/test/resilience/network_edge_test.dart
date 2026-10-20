import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:my_app/core/locale/app_translations.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/core/network/api_exception.dart';
import 'package:my_app/core/network/trusted_roots.dart';
import 'package:my_app/core/network/trusted_roots_io.dart';
import 'package:my_app/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en');
  });
  tearDown(Get.reset);

  test("the hosting CDN's 'Checking your browser' page is reported as an unexpected server response", () async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = ApiClient(Get.put(TokenStorage()));
    const page =
        '<!DOCTYPE html><html lang="en"><head><meta http-equiv="refresh" content="30"></head>'
        '<body><h1>Checking your browser before accessing</h1></body></html>';
    Object? error;
    try {
      await client.handle(
        () async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 403,
          data: page,
        ),
        (body) => body,
      );
    } catch (e) {
      error = e;
    }
    expect(error, isA<ApiException>());
    expect(
      (error! as ApiException).message,
      'error_invalid_server_response'.tr,
      reason: 'shown as "Request failed (403)"',
    );
  });

  test('the bundled ISRG roots load and can be trusted (twice without throwing)', () async {
    expect(TrustedRoots.assets, hasLength(2));
    for (final asset in TrustedRoots.assets) {
      final pem = (await rootBundle.load(asset)).buffer.asUint8List();
      expect(String.fromCharCodes(pem), contains('BEGIN CERTIFICATE'));
      final context = SecurityContext(withTrustedRoots: false);
      expect(addTrustedRoot(context, pem), isTrue);
      // جذر موجود أصلاً: بعض إصدارات BoringSSL ترمي CERT_ALREADY_IN_HASH_TABLE وبعضها يقبله — لا رمي في الحالتين.
      expect(() => addTrustedRoot(context, pem), returnsNormally);
    }
  });
}
