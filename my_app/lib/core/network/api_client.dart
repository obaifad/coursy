import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../locale/locale_controller.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'dio_adapter.dart';
import 'json_parser.dart';

class ApiClient extends GetxService {
  ApiClient(this._tokenStorage);

  final TokenStorage _tokenStorage;
  late final Dio dio;

  @override
  void onInit() {
    super.onInit();
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    setupDioAdapter(dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final lang = Get.isRegistered<LocaleController>()
              ? Get.find<LocaleController>().code.value
              : 'ar';
          options.headers['Accept-Language'] = lang;
          // لا نضيف lang كـ query على POST/PATCH/PUT — Laravel قد يدمجه في body ويكسر insert (مثل enrollments).
          if (options.method.toUpperCase() == 'GET') {
            options.queryParameters = Map<String, dynamic>.from(options.queryParameters);
            options.queryParameters['lang'] = lang;
          }

          final token = _tokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            final hasAuth = options.headers['Authorization'] != null;
            debugPrint('[API] ${options.method} ${options.baseUrl}${options.path}');
            debugPrint('[API] Auth header attached: $hasAuth');
            if (hasAuth) {
              debugPrint('[API] Authorization: ${options.headers['Authorization']}');
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return dio.get<dynamic>(path, queryParameters: query);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return dio.post<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) {
    return dio.put<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return dio.patch<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> delete(String path) {
    return dio.delete<dynamic>(path);
  }

  Future<Response<dynamic>> postMultipart(String path, FormData data) {
    return dio.post<dynamic>(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<T> handle<T>(Future<Response<dynamic>> Function() call, T Function(dynamic body) mapper) async {
    try {
      final response = await call();
      final status = response.statusCode ?? 0;
      final body = response.data;

      if (_isHostingChallengeHtml(body)) {
        throw ApiException(
          'الخادم لم يرجع JSON (غالباً حماية الاستضافة على POST). '
          'جرّب التطبيق على Android أو Windows، أو اطلب من مبرمج الـ API تفعيل CORS ودعم POST.',
          statusCode: status,
        );
      }

      if (status >= 400) {
        throw ApiException(
          messageFromErrorBody(body, fallback: 'فشل الطلب ($status)'),
          statusCode: status,
          fieldErrors: fieldErrorsFromBody(body),
        );
      }

      try {
        normalizeApiBody(body);
      } on FormatException catch (e) {
        throw ApiException(e.message, statusCode: status);
      }

      return mapper(body);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final raw = e.response?.data;
      if (_isHostingChallengeHtml(raw)) {
        throw ApiException(
          'الخادم لم يرجع JSON على طلب POST. شغّل التطبيق على Android/Windows وليس Chrome.',
          statusCode: status,
        );
      }
      final msg = messageFromErrorBody(
        raw,
        fallback: _dioMessage(e),
      );
      throw ApiException(
        msg,
        statusCode: status,
        fieldErrors: fieldErrorsFromBody(raw),
      );
    }
  }

  bool _isHostingChallengeHtml(dynamic body) {
    if (body is! String) return false;
    final s = body.trim().toLowerCase();
    return s.contains('<html') && (s.contains('aes.js') || s.contains('__test'));
  }

  String _dioMessage(DioException e) {
    if (kIsWeb &&
        (e.type == DioExceptionType.connectionError ||
            e.message?.contains('XMLHttpRequest') == true)) {
      return 'تعذر إرسال طلب الدخول من المتصفح (CORS). '
          'شغّل التطبيق على Android أو Windows: '
          'flutter run -d android أو flutter run -d windows';
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'تعذر الاتصال بالخادم. تحقق من الإنترنت وعنوان API: ${ApiConfig.baseUrl}';
      case DioExceptionType.badCertificate:
        return 'خطأ في شهادة HTTPS للخادم.';
      default:
        return e.message ?? 'فشل الاتصال بالخادم';
    }
  }
}
