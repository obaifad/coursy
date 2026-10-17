import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';

/// تأكيد البريد برمز من 6 أرقام. اختياري: يمكن تخطيه دائماً.
///
/// المعاملات (Get.arguments كخريطة): `email` البريد الحالي، و`fromRegister` = true بعد إنشاء الحساب
/// مباشرة (التخطي/النجاح يفتح الرئيسية بدل الرجوع).
class EmailVerificationController extends GetxController {
  /// [initialEmail] و[openedFromRegister] يتقدّمان على Get.arguments (للاختبار أو الاستدعاء المباشر).
  EmailVerificationController({this.initialEmail, this.openedFromRegister});

  final String? initialEmail;
  final bool? openedFromRegister;

  final AuthRepository _auth = Get.find();

  static const int codeLength = 6;
  static const int defaultResendSeconds = 60;

  final codeController = TextEditingController();
  final codeFocus = FocusNode();

  final email = ''.obs;
  final isSending = false.obs;
  final isVerifying = false.obs;
  final isSavingEmail = false.obs;
  final verified = false.obs;
  final errorMessage = RxnString();

  /// يزيد مع كل رمز خاطئ — يهزّ حقل الرمز.
  final errorTick = 0.obs;
  final resendSeconds = 0.obs;

  /// هل أُرسل رمز واحد على الأقل بنجاح (يغيّر نص التعليمات).
  final codeSent = false.obs;
  final debugCodeHint = RxnString();

  bool fromRegister = false;
  Timer? _timer;

  String get resendCountdown {
    final s = resendSeconds.value;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      email.value = args['email']?.toString().trim() ?? '';
      fromRegister = args['fromRegister'] == true;
    }
    if (initialEmail != null) email.value = initialEmail!.trim();
    if (openedFromRegister != null) fromRegister = openedFromRegister!;
    codeController.addListener(_onCodeChanged);
    unawaited(_start());
  }

  Future<void> _start() async {
    if (email.value.isEmpty) await _loadEmail();
    await sendCode();
  }

  Future<void> _loadEmail() async {
    if (!Get.isRegistered<ProfileRepository>()) return;
    try {
      final user = await Get.find<ProfileRepository>().fetchMe();
      email.value = user['email']?.toString().trim() ?? '';
    } catch (_) {}
  }

  void _onCodeChanged() {
    if (errorMessage.value != null && codeController.text.isNotEmpty) errorMessage.value = null;
    if (codeController.text.length == codeLength && !isVerifying.value && !verified.value) {
      unawaited(verify());
    }
  }

  Future<void> sendCode() async {
    if (isSending.value || resendSeconds.value > 0 || verified.value) return;
    isSending.value = true;
    errorMessage.value = null;
    try {
      final result = await _auth.sendEmailVerificationCode();
      codeSent.value = true;
      _startTimer(result.resendAfterSeconds ?? defaultResendSeconds);
      // رمز التطوير يظهر في نسخة debug فقط.
      if (kDebugMode && (result.debugCode ?? '').isNotEmpty) {
        debugCodeHint.value = 'dev_otp'.trParams({'code': result.debugCode!});
      }
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // الخادم: البريد مؤكد مسبقاً.
        await _onVerified();
        return;
      }
      // نصوصنا المترجمة بدل رسالة Laravel الإنجليزية («Too Many Attempts.»).
      switch (e.statusCode) {
        case 429:
          _startTimer(e.retryAfterSeconds ?? defaultResendSeconds);
          errorMessage.value = 'email_code_too_many'.tr;
        case 503:
          errorMessage.value = 'email_code_send_failed'.tr;
        default:
          errorMessage.value = e.message;
      }
    } catch (_) {
      errorMessage.value = 'email_code_send_failed'.tr;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verify() async {
    if (isVerifying.value || verified.value) return;
    final code = codeController.text.trim();
    if (code.length != codeLength) {
      _showCodeError('enter_full_otp'.tr);
      return;
    }
    isVerifying.value = true;
    errorMessage.value = null;
    try {
      await _auth.verifyEmailCode(code);
      await _onVerified();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        await _onVerified();
        return;
      }
      _showCodeError(switch (e.statusCode) {
        422 => 'email_code_invalid'.tr,
        429 => 'email_code_too_many'.tr,
        _ => e.message,
      });
    } catch (_) {
      _showCodeError('connection_error'.tr);
    } finally {
      isVerifying.value = false;
    }
  }

  void _showCodeError(String message) {
    errorMessage.value = message;
    errorTick.value++;
    codeController.clear();
    codeFocus.requestFocus();
  }

  Future<void> _onVerified() async {
    verified.value = true;
    // 409 (مؤكد مسبقاً) لا يمر بـ verifyEmailCode — فيُحفظ هنا ليختفي خيار «تأكيد البريد».
    if (Get.isRegistered<TokenStorage>()) unawaited(Get.find<TokenStorage>().saveEmailVerified(true));
    _timer?.cancel();
    resendSeconds.value = 0;
    codeFocus.unfocus();
    // لحظة لرؤية علامة النجاح قبل المغادرة.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (isClosed) return;
    Get.snackbar('email_verified_title'.tr, 'email_verified_msg'.tr);
    leave();
  }

  /// تخطٍّ أو انتهاء: بعد التسجيل → الرئيسية؛ وإلا رجوع.
  void leave() {
    if (fromRegister) {
      AppNavigation.goToRoot(tab: 2);
    } else {
      Get.back<void>();
    }
  }

  /// يغيّر البريد (بكلمة المرور الحالية) ثم يرسل رمزاً جديداً.
  /// يُرجع أخطاء الحقول (`email` / `current_password`) أو null عند النجاح.
  Future<Map<String, String>?> changeEmail(String value, String currentPassword) async {
    final next = value.trim();
    final invalid = ProfileRepository.emailChangeFieldErrors(next, currentPassword);
    // البريد نفسه: لا شيء يتغيّر (ولا حاجة لكلمة المرور).
    if (next == email.value && invalid?['email'] == null) return null;
    if (invalid != null) return invalid;
    if (!Get.isRegistered<ProfileRepository>()) return {'email': 'error_unexpected'.tr};
    isSavingEmail.value = true;
    try {
      final errors = await Get.find<ProfileRepository>().changeEmail(next, currentPassword);
      if (errors != null) return errors;
      email.value = next;
      codeController.clear();
      errorMessage.value = null;
      _timer?.cancel();
      resendSeconds.value = 0;
      unawaited(sendCode());
      return null;
    } finally {
      isSavingEmail.value = false;
    }
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    resendSeconds.value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        resendSeconds.value = 0;
        t.cancel();
      } else {
        resendSeconds.value--;
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    codeFocus.dispose();
    super.onClose();
  }
}
