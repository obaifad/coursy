import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDioAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);
      return client;
    },
  );
}
