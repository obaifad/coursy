import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_debug_log.dart';
import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_refresh.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';

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
    // القفل قبل نافذة التأكيد: ضغطتان سريعتان كانتا تفتحان نافذتين وترسلان طلبَي حذف.
    isDeleting.value = true;
    try {
      if (!await _confirm()) return;
      passwordError.value = null;
      await _authRepository.deleteAccount(password);
      // الخادم ألغى كل الجلسات وحذف توكنات الأجهزة؛ هنا ننظّف ما بقي محلياً فقط.
      // الحذف نجح: أي فشل في التنظيف بعده لا يُعرض كخطأ — المستخدم يصل خارج الحساب دائماً.
      await _cleanUpAfterDeletion();
      AppToast.show('account_deleted_title'.tr, 'account_deleted_msg'.tr, kind: ToastKind.success);
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 422:
          passwordError.value = e.fieldErrors?['password'] ?? e.message;
        case 429:
          AppToast.show('error'.tr, 'payment_error_rate_limit'.tr);
        default:
          AppToast.show('error'.tr, e.message);
      }
    } catch (_) {
      AppToast.show('error'.tr, 'error_unexpected'.tr);
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> _cleanUpAfterDeletion() async {
    Future<void> step(String name, FutureOr<void> Function() run) async {
      try {
        await run();
      } catch (e) {
        AppDebugLog.repo('DeleteAccount', '$name failed after deletion: $e');
      }
    }

    await step('session', _authRepository.clearLocalSession);
    await step('logout', SessionRefresh.onLogout);
    await step('navigation', AppNavigation.enterAsGuest);
    await step('reload', SessionRefresh.reloadAsGuest);
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
