import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../config/app_debug_log.dart';
import '../locale/locale_controller.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'dio_adapter.dart';
import 'json_parser.dart';

class ApiClient extends GetxService {
  ApiClient(this._tokenStorage);

  final TokenStorage _tokenStorage;
  late final Dio dio;

  /// يُستدعى عند 401 على طلب كان يحمل توكن (الجلسة أُلغيت من الخادم). يُضبط في main.
  static void Function()? onUnauthorized;

  /// يُستدعى عند 403 `{"code": "account_inactive"}` على طلب كان يحمل توكن (الإدارة أوقفت حساب الطالب)
  /// مع رسالة الخادم: مثل 401 — مسح الجلسة وشاشة الدخول — لكن بنص الخادم بدل «انتهت الجلسة».
  /// يُضبط في main (SessionRefresh.onAccountInactive)؛ إن لم يُضبط يُستخدم مسار 401 ([onUnauthorized]).
  static void Function(String message)? onAccountInactive;

  static const accountInactiveCode = 'account_inactive';

  /// مسارات تُرجع 401 كجزء طبيعي من عملها (دخول/خروج/كلمة مرور) فلا تعني انتهاء الجلسة.
  static const _authFlowPaths = <String>[
    '/student/login',
    '/student/register',
    '/student/logout',
    '/logout',
    '/student/password/',
    '/student/devices',
  ];
  CancelToken _readCancelToken = CancelToken();

  /// يلغي طلبات GET الجارية (مثلاً عند تبديل اللغة) لمنع race condition.
  void cancelInFlightReads([String reason = 'superseded']) {
    if (!_readCancelToken.isCancelled) {
      _readCancelToken.cancel(reason);
    }
    _readCancelToken = CancelToken();
  }

  @override
  void onInit() {
    super.onInit();
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    setupDioAdapter(dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode == 401) _maybeSessionExpired(response.requestOptions);
          if (response.statusCode == 403) _maybeAccountInactive(response);
          handler.next(response);
        },
        onError: (e, handler) {
          final response = e.response;
          if (response?.statusCode == 401) _maybeSessionExpired(e.requestOptions);
          if (response != null && response.statusCode == 403) _maybeAccountInactive(response);
          handler.next(e);
        },
        onRequest: (options, handler) {
          final lang = Get.isRegistered<LocaleController>() ? Get.find<LocaleController>().code.value : 'ar';
          options.headers['Accept-Language'] = lang;
          // لا نضيف lang كـ query على POST/PATCH/PUT — Laravel قد يدمجه في body ويكسر insert (مثل enrollments).
          if (options.method.toUpperCase() == 'GET') {
            options.queryParameters = Map<String, dynamic>.from(options.queryParameters);
            options.queryParameters['lang'] = lang;
            // لا نستبدل cancelToken مخصّصاً (مثل جلب كل صفحات pagination).
            options.cancelToken ??= _readCancelToken;
          }

          final token = _tokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            AppDebugLog.api(options.method.toUpperCase(), options.uri.path);
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query, CancelToken? cancelToken}) {
    return dio.get<dynamic>(path, queryParameters: query, cancelToken: cancelToken);
  }

  Future<Response<dynamic>> post(String path, {dynamic data, Map<String, dynamic>? query}) {
    return dio.post<dynamic>(path, data: data, queryParameters: query);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) {
    return dio.put<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return dio.patch<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data, Map<String, dynamic>? query}) {
    return dio.delete<dynamic>(path, data: data, queryParameters: query);
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
        // صفحة حماية الاستضافة بدل JSON.
        throw ApiException('error_invalid_server_response'.tr, statusCode: status);
      }

      if (status >= 400) {
        throw ApiException(
          messageFromErrorBody(body, fallback: _statusFallback(status)),
          statusCode: status,
          fieldErrors: fieldErrorsFromBody(body),
          code: errorCodeFromBody(body),
          retryAfterSeconds: _retryAfter(response.headers),
        );
      }

      try {
        normalizeApiBody(body);
      } on FormatException {
        throw ApiException('error_invalid_server_response'.tr, statusCode: status);
      }

      return mapper(body);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const ApiCancelledException();
      }
      final status = e.response?.statusCode;
      final raw = e.response?.data;
      if (_isHostingChallengeHtml(raw)) {
        throw ApiException('error_invalid_server_response'.tr, statusCode: status);
      }
      final msg = messageFromErrorBody(raw, fallback: _dioMessage(e));
      throw ApiException(
        msg,
        statusCode: status,
        fieldErrors: fieldErrorsFromBody(raw),
        code: errorCodeFromBody(raw),
        retryAfterSeconds: _retryAfter(e.response?.headers),
      );
    }
  }

  static int? _retryAfter(Headers? headers) {
    final value = int.tryParse(headers?.value('retry-after')?.trim() ?? '');
    return value != null && value > 0 ? value : null;
  }

  void _maybeSessionExpired(RequestOptions options) {
    if (!_endsSession(options)) return;
    onUnauthorized?.call();
  }

  /// حساب موقوف: الجلسة لم تعد صالحة لأي طلب — نعاملها مثل 401 ونعرض رسالة الخادم.
  void _maybeAccountInactive(Response<dynamic> response) {
    if (!isAccountInactiveBody(response.data) || !_endsSession(response.requestOptions)) return;
    final message = messageFromErrorBody(response.data, fallback: 'account_inactive_msg'.tr);
    final handler = onAccountInactive;
    if (handler != null) {
      handler(message);
    } else {
      onUnauthorized?.call();
    }
  }

  static bool isAccountInactiveBody(dynamic body) => errorCodeFromBody(body) == accountInactiveCode;

  /// طلب كان يحمل توكن وليس من مسارات الدخول/الخروج (التي تُرجع 401/403 كجزء طبيعي من عملها).
  bool _endsSession(RequestOptions options) {
    final hadToken = options.headers['Authorization']?.toString().startsWith('Bearer ') ?? false;
    if (!hadToken) return false;
    return !_authFlowPaths.any(options.path.startsWith);
  }

  bool _isHostingChallengeHtml(dynamic body) {
    if (body is! String) return false;
    final s = body.trim().toLowerCase();
    return s.contains('<html') && (s.contains('aes.js') || s.contains('__test'));
  }

  String _dioMessage(DioException e) {
    if (kIsWeb &&
        (e.type == DioExceptionType.connectionError ||
            e.message?.contains('XMLHttpRequest') == true ||
            e.message?.toLowerCase().contains('cors') == true)) {
      if (ApiConfig.usesWebDevProxy) {
        return 'web_cors_proxy_down'.tr;
      }
      return 'web_cors_blocked'.tr;
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // لا نعرض عنوان الـ API للمستخدم — يظهر في سجل التطوير فقط.
        AppDebugLog.api('CONNECTION FAILED', ApiConfig.baseUrl);
        return 'error_connection_timeout'.tr;
      case DioExceptionType.badCertificate:
        return 'error_bad_certificate'.tr;
      default:
        // مثل أخطاء 5xx — نص Dio التقني (بالإنجليزية) لا يُعرض للمستخدم.
        final status = e.response?.statusCode;
        return status == null ? 'connection_error'.tr : _statusFallback(status);
    }
  }

  /// نص الخطأ حين لا يرسل الخادم رسالة صالحة للعرض: 5xx = مشكلة مؤقتة في الخادم (لا «فشل الطلب (500)»).
  static String _statusFallback(int status) =>
      status >= 500 ? 'error_server_unavailable'.tr : 'error_request_failed'.trParams({'status': '$status'});
}
