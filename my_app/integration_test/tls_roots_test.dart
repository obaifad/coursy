import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/core/network/trusted_roots.dart';

/// على الجهاز نفسه (لا في محاكاة): هل يصل التطبيق إلى خادم TLS الحقيقي؟
///
/// flutter drive --profile --no-dds --driver=test_driver/integration_test.dart \
///   --target=integration_test/tls_roots_test.dart -d DEVICE_ID
///
/// على Android 6.0–7.0 يفشل التحقق بمخزن النظام وحده (لا جذور ISRG)، وينجح بعد TrustedRoots.install().
/// أي رد HTTP (200 أو 403 من صفحة تحقق الاستضافة) يعني أن مصافحة TLS نجحت.
const _url = 'https://coursy.sy/api/app/config';

Future<String> _probe(HttpClient client) async {
  try {
    final request = await client.getUrl(Uri.parse(_url)).timeout(const Duration(seconds: 20));
    final response = await request.close().timeout(const Duration(seconds: 20));
    await response.drain<void>();
    return 'http ${response.statusCode}';
  } on HandshakeException catch (e) {
    return 'tls-failed: ${e.osError?.message ?? e.message}';
  } catch (e) {
    return 'error: $e';
  } finally {
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TLS to coursy.sy succeeds with the bundled ISRG roots', (tester) async {
    final systemOnly = await _probe(HttpClient(context: SecurityContext(withTrustedRoots: true)));
    await TrustedRoots.install();
    final withBundled = await _probe(HttpClient());
    debugPrint('TLS_PROBE system_store_only=$systemOnly bundled_roots=$withBundled');
    expect(withBundled, startsWith('http '), reason: 'handshake still fails with the bundled roots');
  });
}
