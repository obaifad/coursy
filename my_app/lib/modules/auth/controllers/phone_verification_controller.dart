import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/app_toast.dart';

class PhoneVerificationController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final TokenStorage _tokenStorage = Get.find();

  final otpController = TextEditingController();
  final isLoading = false.obs;
  final isSending = false.obs;
  final errorMessage = RxnString();
  final step = 0.obs;
  final resendSeconds = 0.obs;
  final debugOtpHint = RxnString();

  Timer? _timer;

  String get phone => _tokenStorage.userPhone.value ?? '';

  @override
  void onInit() {
    super.onInit();
    final argPhone = Get.arguments?.toString();
    if (argPhone != null && argPhone.isNotEmpty) {
      _tokenStorage.userPhone.value = argPhone;
    }
  }

  Future<void> sendCode() async {
    if (phone.isEmpty) {
      AppToast.show('alert'.tr, 'no_phone_on_account'.tr);
      return;
    }

    isSending.value = true;
    errorMessage.value = null;
    try {
      final result = await _authRepository.sendMobileVerificationCode();
      step.value = 1;
      _startResendTimer(result.expiresInSeconds ?? 60);
      // رمز التطوير يُعرض في نسخة debug فقط — لا يظهر للمستخدم حتى لو أرجعه الخادم.
      if (kDebugMode && result.debugCode != null && result.debugCode!.isNotEmpty) {
        debugOtpHint.value = 'dev_otp'.trParams({'code': result.debugCode!});
      }
      AppToast.show('verified_success'.tr, result.message, kind: ToastKind.success);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      AppToast.show('error'.tr, e.message);
    } catch (_) {
      AppToast.show('error'.tr, 'otp_send_failed'.tr);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyCode() async {
    final code = otpController.text.trim();
    if (code.length < 4) {
      AppToast.show('alert'.tr, 'enter_full_otp'.tr);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.verifyMobileCode(code);
      await _tokenStorage.markPhoneVerified();
      AppNavigation.goToRoot();
      AppToast.show('verified_success'.tr, 'phone_verified_msg'.tr, kind: ToastKind.success);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      AppToast.show('otp_invalid'.tr, e.message, kind: ToastKind.error);
    } catch (_) {
      AppToast.show('error'.tr, 'otp_verify_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _startResendTimer(int seconds) {
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
    otpController.dispose();
    super.onClose();
  }
}
