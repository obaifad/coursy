import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/register_payload.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';
import '../../storage/token_storage.dart';

class OtpSendResult {
  OtpSendResult({required this.message, this.expiresInSeconds, this.debugCode});

  final String message;
  final int? expiresInSeconds;
  final String? debugCode;
}

class AuthRepository extends GetxService {
  AuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  void _printTokenForDebug(String source, String token) {
    if (!kDebugMode) return;
    debugPrint('================ AUTH TOKEN ($source) ================');
    debugPrint(token);
    debugPrint('=====================================================');
  }

  /// طباعة رمز OTP في التيرمنال للتجربة (بيئة local/testing).
  static void printOtpToTerminal({required String code, String? phone}) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('══════════════════════════════════════════════');
    debugPrint('  📱 OTP VERIFICATION CODE (testing)');
    debugPrint('  Phone: ${phone ?? '—'}');
    debugPrint('  Code:  $code');
    debugPrint('══════════════════════════════════════════════');
    debugPrint('');
  }

  String _deviceName() {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWindows) return 'windows';
    return 'flutter';
  }

  /// تسجيل دخول بالبريد ورقم الهاتف وكلمة المرور.
  Future<Map<String, dynamic>?> login({
    required String email,
    required String phone,
    required String password,
  }) async {
    final body = await _client.handle(
      () => _client.post(
        ApiEndpoints.studentLogin,
        data: {
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
          'device_name': _deviceName(),
        },
      ),
      (data) => normalizeApiBody(data),
    );

    await _saveSessionFromBody(body);
    return extractUserMap(body);
  }

  Future<bool> isEmailTaken(String email) {
    final normalized = email.trim().toLowerCase();
    return _userExists(
      (user) => user['email']?.toString().trim().toLowerCase() == normalized,
    );
  }

  Future<bool> isPhoneTaken(String phone) {
    final normalized = _normalizePhone(phone);
    return _userExists(
      (user) => _normalizePhone(user['phone']?.toString() ?? '') == normalized,
    );
  }

  Future<bool> _userExists(bool Function(Map<String, dynamic> user) matches) async {
    var page = 1;
    var lastPage = 1;

    while (page <= lastPage) {
      final body = await _client.handle(
        () => _client.get(ApiEndpoints.users, query: {'page': page}),
        (data) => normalizeApiBody(data),
      );

      final users = extractListMap(body);
      if (users.any(matches)) return true;

      final meta = body is Map<String, dynamic> ? extractPagination(body) : null;
      lastPage = meta?.lastPage ?? page;
      if (users.isEmpty) break;
      page++;
    }

    return false;
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('09')) return digits;
    if (digits.length == 11 && digits.startsWith('0')) return digits.substring(0, 10);
    return digits;
  }

  Future<bool> register(RegisterPayload payload) async {
    dynamic body;
    try {
      body = await _client.handle(
        () => _client.post(ApiEndpoints.studentRegister, data: payload.toJson()),
        (data) => normalizeApiBody(data),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        body = await _client.handle(
          () => _client.post(ApiEndpoints.users, data: payload.toJson()),
          (data) => normalizeApiBody(data),
        );
      } else {
        rethrow;
      }
    }

    final token = extractToken(body);
    if (token != null && token.isNotEmpty) {
      await _saveSessionFromBody(body);
      _printTokenForDebug('register', token);
      return true;
    }
    return false;
  }

  Future<OtpSendResult> sendMobileVerificationCode() async {
    return _client.handle(
      () => _client.post(ApiEndpoints.studentMobileVerificationSend),
      (data) {
        final map = normalizeApiBody(data);
        if (map is! Map<String, dynamic>) {
          return OtpSendResult(message: 'تم إرسال رمز التحقق');
        }
        final debugCode = map['verification_code']?.toString();
        if (debugCode != null && debugCode.isNotEmpty) {
          printOtpToTerminal(
            code: debugCode,
            phone: _tokenStorage.userPhone.value,
          );
        }
        return OtpSendResult(
          message: map['message']?.toString() ?? 'تم إرسال رمز التحقق بنجاح',
          expiresInSeconds: map['expires_in_seconds'] is int
              ? map['expires_in_seconds'] as int
              : int.tryParse(map['expires_in_seconds']?.toString() ?? ''),
          debugCode: debugCode,
        );
      },
    );
  }

  Future<Map<String, dynamic>?> verifyMobileCode(String code) async {
    return _client.handle(
      () => _client.post(
        ApiEndpoints.studentMobileVerificationVerify,
        data: {'code': code.trim()},
      ),
      (data) {
        final normalized = normalizeApiBody(data);
        final user = extractUserMap(normalized);
        if (user != null) {
          final token = _tokenStorage.token;
          if (token != null) {
            _tokenStorage.markPhoneVerified();
          }
        }
        return user;
      },
    );
  }

  Future<void> _saveSessionFromBody(dynamic body) async {
    final token = extractToken(body);
    if (token == null || token.isEmpty) {
      throw ApiException('لم يتم استلام رمز الدخول من الخادم');
    }
    final user = extractUserMap(body);
    final name = extractUserDisplayName(body);
    final phone = user?['phone']?.toString();
    final studentId = extractStudentIdFromBody(body) ?? extractStudentId(user);
    await _tokenStorage.saveSession(
      token: token,
      name: name,
      phone: phone,
      verifiedPhone: true,
      studentId: studentId,
    );
    _printTokenForDebug('auth', token);
  }

  Future<void> logout() async {
    try {
      await _client.handle(
        () => _client.post(ApiEndpoints.studentLogout),
        (data) => normalizeApiBody(data),
      );
    } catch (_) {
      try {
        await _client.handle(
          () => _client.post(ApiEndpoints.logout),
          (data) => normalizeApiBody(data),
        );
      } catch (_) {}
    } finally {
      await _tokenStorage.clearSession();
    }
  }
}
