import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
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
    AppDebugLog.secret('AUTH TOKEN ($source): $token');
  }

  /// طباعة رمز OTP في التيرمنال للتجربة (بيئة local/testing).
  static void printOtpToTerminal({required String code, String? phone}) {
    AppDebugLog.otp('OTP phone=${phone ?? '—'} code=$code');
  }

  String _deviceName() {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWindows) return 'windows';
    return 'flutter';
  }

  /// تسجيل دخول بالبريد ورقم الهاتف وكلمة المرور.
  Future<Map<String, dynamic>?> login({required String email, required String phone, required String password}) async {
    final body = await _client.handle(
      () => _client.post(
        ApiEndpoints.studentLogin,
        data: {'email': email.trim(), 'phone': phone.trim(), 'password': password, 'device_name': _deviceName()},
      ),
      (data) => normalizeApiBody(data),
    );

    await _saveSessionFromBody(body);
    return extractUserMap(body);
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
    return _client.handle(() => _client.post(ApiEndpoints.studentMobileVerificationSend), (data) {
      final map = normalizeApiBody(data);
      if (map is! Map<String, dynamic>) {
        return OtpSendResult(message: 'otp_sent_default'.tr);
      }
      final debugCode = map['verification_code']?.toString();
      if (debugCode != null && debugCode.isNotEmpty) {
        printOtpToTerminal(code: debugCode, phone: _tokenStorage.userPhone.value);
      }
      return OtpSendResult(
        message: map['message']?.toString() ?? 'otp_sent_success'.tr,
        expiresInSeconds: map['expires_in_seconds'] is int
            ? map['expires_in_seconds'] as int
            : int.tryParse(map['expires_in_seconds']?.toString() ?? ''),
        debugCode: debugCode,
      );
    });
  }

  Future<Map<String, dynamic>?> verifyMobileCode(String code) async {
    return _client.handle(
      () => _client.post(ApiEndpoints.studentMobileVerificationVerify, data: {'code': code.trim()}),
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
      throw ApiException('error_no_login_token'.tr);
    }
    final user = extractUserMap(body);
    final name = extractUserDisplayName(body);
    final phone = user?['phone']?.toString();
    final studentId = extractStudentIdFromBody(body) ?? extractStudentId(user);
    // الحالة الفعلية من الخادم (null = لم يُرسلها) — كانت تُحفظ true دائماً فيتعطّل التحقق.
    await _tokenStorage.saveSession(
      token: token,
      name: name,
      phone: phone,
      verifiedPhone: phoneVerificationStatus(user),
      studentId: studentId,
    );
    _printTokenForDebug('auth', token);
  }

  Future<void> logout() async {
    try {
      await _client.handle(() => _client.post(ApiEndpoints.studentLogout), (data) => normalizeApiBody(data));
    } catch (_) {
      try {
        await _client.handle(() => _client.post(ApiEndpoints.logout), (data) => normalizeApiBody(data));
      } catch (_) {}
    } finally {
      await _tokenStorage.clearSession();
    }
  }
}
