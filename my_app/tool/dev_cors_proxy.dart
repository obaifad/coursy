import 'dart:async';
import 'dart:io';

/// بروكسي تطوير لتجاوز CORS على Chrome (localhost → coursy.sy).
///
/// التشغيل:
///   dart run tool/dev_cors_proxy.dart
const int proxyPort = 5478;
const String targetHost = 'coursy.sy';
const String targetScheme = 'https';

final Set<String> _hopByHopHeaders = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailers',
  'transfer-encoding',
  'upgrade',
  'host',
  'content-length',
};

Future<void> main() async {
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    proxyPort,
    shared: true,
  );
  stdout.writeln(
    'CORS dev proxy listening on http://127.0.0.1:$proxyPort -> $targetScheme://$targetHost',
  );
  await for (final request in server) {
    unawaited(_handleRequest(request));
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers
    ..add('Access-Control-Allow-Origin', '*')
    ..add(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD',
    )
    ..add(
      'Access-Control-Allow-Headers',
      'Origin, Content-Type, Accept, Authorization, Accept-Language, X-Requested-With',
    )
    ..add('Access-Control-Max-Age', '86400');
}

Future<void> _handleRequest(HttpRequest request) async {
  _addCorsHeaders(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  final path = request.uri.path;
  final query = request.uri.hasQuery ? '?${request.uri.query}' : '';
  final targetUri = Uri.parse('$targetScheme://$targetHost$path$query');

  final client = HttpClient();
  try {
    final outbound = await client.openUrl(request.method, targetUri);

    request.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (_hopByHopHeaders.contains(lower)) return;
      for (final value in values) {
        outbound.headers.add(name, value);
      }
    });
    outbound.headers.set('Host', targetHost);

    await request.cast<List<int>>().pipe(outbound);
    final upstream = await outbound.close();

    request.response.statusCode = upstream.statusCode;
    upstream.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (_hopByHopHeaders.contains(lower)) return;
      for (final value in values) {
        request.response.headers.add(name, value);
      }
    });
    _addCorsHeaders(request.response);

    await upstream.pipe(request.response);
  } catch (e) {
    try {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Proxy error: $e');
      await request.response.close();
    } catch (_) {}
  } finally {
    client.close(force: true);
  }
}
