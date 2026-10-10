import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_refresh.dart';
import '../../../theme/app_colors.dart';

class DeleteAccountController extends GetxController {
  final AuthRepository _authRepository = Get.find();

  final passwordController = TextEditingController();
  final hidePassword = true.obs;
  final isDeleting = false.obs;
  final passwordError = RxnString();

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }

  Future<void> deleteAccount() async {
    if (isDeleting.value) return;
    final password = passwordController.text;
    if (password.isEmpty) {
      passwordError.value = 'delete_account_password_required'.tr;
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await _confirm()) return;

    passwordError.value = null;
    isDeleting.value = true;
    try {
      await _authRepository.deleteAccount(password);
      // الخادم ألغى كل الجلسات وحذف توكنات الأجهزة؛ هنا ننظّف ما بقي محلياً فقط.
      await SessionRefresh.onLogout();
      AppNavigation.enterAsGuest();
      SessionRefresh.reloadAsGuest();
      Get.snackbar('account_deleted_title'.tr, 'account_deleted_msg'.tr);
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 422:
          passwordError.value = e.fieldErrors?['password'] ?? e.message;
        case 429:
          Get.snackbar('error'.tr, 'payment_error_rate_limit'.tr);
        default:
          Get.snackbar('error'.tr, e.message);
      }
    } catch (_) {
      Get.snackbar('error'.tr, 'error_unexpected'.tr);
    } finally {
      isDeleting.value = false;
    }
  }

  Future<bool> _confirm() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_account_confirm_title'.tr),
        content: Text('delete_account_confirm_msg'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46), backgroundColor: AppColors.danger),
            onPressed: () => Get.back(result: true),
            child: Text('delete_account'.tr),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
