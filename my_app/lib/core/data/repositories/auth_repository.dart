import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../models/register_payload.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';
import '../../storage/token_storage.dart';

class OtpSendResult {
  OtpSendResult({required this.message, this.expiresInSeconds, this.resendAfterSeconds, this.debugCode});

  final String message;
  final int? expiresInSeconds;

  /// متى يُسمح بطلب رمز جديد (عدّاد «إعادة الإرسال»).
  final int? resendAfterSeconds;
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
  /// [login] بريد إلكتروني أو رقم هاتف بأي صيغة شائعة (`0912345678` · `+963912345678` · `00963…`).
  /// الخادم يحدد الحساب بكلمة المرور (الهاتف غير فريد). الأخطاء: 422 `errors.login[0]`، 403 حساب موقوف، 429.
  Future<Map<String, dynamic>?> login({required String login, required String password}) async {
    final body = await _client.handle(
      () => _client.post(
        ApiEndpoints.studentLogin,
        data: {'login': login.trim(), 'password': password, 'device_name': _deviceName()},
      ),
      (data) => normalizeApiBody(data),
    );

    await _saveSessionFromBody(body);
    return extractUserMap(body);
  }

  Future<bool> register(RegisterPayload payload) async {
    final body = await _client.handle(
      () => _client.post(ApiEndpoints.studentRegister, data: payload.toJson()),
      (data) => normalizeApiBody(data),
    );

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

  /// يرسل رمز تأكيد من 6 أرقام إلى بريد الطالب المسجّل (التوكن يحدد الطالب، بلا جسم).
  Future<OtpSendResult> sendEmailVerificationCode() {
    return _client.handle(() => _client.post(ApiEndpoints.studentEmailVerificationSend), (data) {
      final map = normalizeApiBody(data);
      if (map is! Map) return OtpSendResult(message: 'email_code_sent'.tr);
      int? seconds(String key) => map[key] is int ? map[key] as int : int.tryParse(map[key]?.toString() ?? '');
      final debugCode = map['verification_code']?.toString();
      if (debugCode != null && debugCode.isNotEmpty) AppDebugLog.otp('EMAIL OTP code=$debugCode');
      return OtpSendResult(
        message: map['message']?.toString() ?? 'email_code_sent'.tr,
        expiresInSeconds: seconds('expires_in_seconds'),
        resendAfterSeconds: seconds('resend_after_seconds'),
        debugCode: debugCode,
      );
    });
  }

  /// يتحقق من الرمز. 422 = رمز خاطئ أو منتهٍ. يحفظ الحالة محلياً عند النجاح.
  Future<void> verifyEmailCode(String code) async {
    await _client.handle(
      () => _client.post(ApiEndpoints.studentEmailVerificationVerify, data: {'code': code.trim()}),
      (data) => normalizeApiBody(data),
    );
    await _tokenStorage.saveEmailVerified(true);
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

  /// يرسل رمز إعادة تعيين كلمة المرور (6 أرقام) إلى البريد. يُرجع رسالة الخادم إن وُجدت.
  Future<String?> requestPasswordReset(String email) {
    return _client.handle(() => _client.post(ApiEndpoints.studentPasswordForgot, data: {'email': email}), (data) {
      final body = normalizeApiBody(data);
      return body is Map ? body['message']?.toString() : null;
    });
  }

  /// يعيّن كلمة مرور جديدة بالرمز. الخادم يسجّل خروج الطالب من كل الأجهزة.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.handle(
      () => _client.post(
        ApiEndpoints.studentPasswordReset,
        data: {'email': email, 'code': code, 'password': password, 'password_confirmation': passwordConfirmation},
      ),
      (data) => data,
    );
  }

  /// حذف الحساب نهائياً بعد التحقق من كلمة المرور. الخادم يلغي كل الجلسات ويحذف توكنات الأجهزة.
  /// يرمي فقط إن رفض الخادم الحذف؛ مسح الجلسة المحلية بعده في [clearLocalSession] (فشله لا يعني فشل الحذف).
  Future<void> deleteAccount(String password) async {
    await _client.handle(
      () => _client.delete(ApiEndpoints.studentAccount, data: {'password': password}),
      (data) => null,
    );
  }

  Future<void> clearLocalSession() => _tokenStorage.clearSession();

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
