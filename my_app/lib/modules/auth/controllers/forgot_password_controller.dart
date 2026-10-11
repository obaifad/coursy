import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/network/api_exception.dart';
import '../../../routes/app_routes.dart';
import 'auth_controller.dart';

/// استعادة كلمة المرور: رمز من 6 أرقام يصل بالبريد، ثم كلمة مرور جديدة.
class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepository = Get.find();

  static const _resendSeconds = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _codePattern = RegExp(r'^\d{6}$');

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  /// 0 = إدخال البريد، 1 = الرمز وكلمة المرور الجديدة.
  final step = 0.obs;
  final isSending = false.obs;
  final isResetting = false.obs;
  final hidePassword = true.obs;
  final resendIn = 0.obs;
  final errors = <String, String>{}.obs;

  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  void clearError(String field) => errors.remove(field);

  Future<void> sendCode() async {
    if (isSending.value || resendIn.value > 0) return;
    final email = emailController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      errors['email'] = 'enter_valid_email'.tr;
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    errors.clear();
    isSending.value = true;
    try {
      final message = await _authRepository.requestPasswordReset(email);
      step.value = 1;
      _startCountdown();
      Get.snackbar('reset_code_sent_title'.tr, message ?? 'reset_code_sent_msg'.tr);
    } on ApiException catch (e) {
      _showError(e);
    } catch (_) {
      Get.snackbar('error'.tr, 'error_unexpected'.tr);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (isResetting.value) return;
    final code = codeController.text.trim();
    final password = passwordController.text;
    errors.clear();
    if (!_codePattern.hasMatch(code)) errors['code'] = 'reset_code_invalid'.tr;
    final passwordError = passwordRuleError(password);
    if (passwordError != null) errors['password'] = passwordError;
    if (password.isNotEmpty && password != confirmController.text) {
      errors['password_confirmation'] = 'passwords_do_not_match'.tr;
    }
    if (errors.isNotEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isResetting.value = true;
    try {
      await _authRepository.resetPassword(
        email: emailController.text.trim(),
        code: code,
        password: password,
        passwordConfirmation: confirmController.text,
      );
      Get.offNamed(AppRoutes.login);
      Get.snackbar('password_reset_done_title'.tr, 'password_reset_done_msg'.tr);
    } on ApiException catch (e) {
      _showError(e);
    } catch (_) {
      Get.snackbar('error'.tr, 'error_unexpected'.tr);
    } finally {
      isResetting.value = false;
    }
  }

  /// نفس شرط التسجيل: 6 خانات على الأقل ([AuthController.minPasswordLength]).
  static String? passwordRuleError(String password) {
    if (password.isEmpty) return 'reset_password_required'.tr;
    if (password.length < AuthController.minPasswordLength) return 'password_min_6'.tr;
    return null;
  }

  /// يعود لتعديل البريد (إن كُتب خطأً).
  void editEmail() {
    step.value = 0;
    errors.clear();
  }

  void _showError(ApiException e) {
    if (e.statusCode == 429) {
      Get.snackbar('error'.tr, 'payment_error_rate_limit'.tr);
      return;
    }
    final fields = e.fieldErrors;
    if (fields != null && fields.isNotEmpty) {
      errors.addAll(fields);
      return;
    }
    Get.snackbar('error'.tr, e.message);
  }

  void _startCountdown() {
    resendIn.value = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendIn.value <= 1) {
        resendIn.value = 0;
        t.cancel();
      } else {
        resendIn.value--;
      }
    });
  }
}
