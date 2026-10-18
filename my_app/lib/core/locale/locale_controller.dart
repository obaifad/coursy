import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../services/push_notification_service.dart';
import 'locale_refresh.dart';
import 'locale_request_guard.dart';
import '../../widgets/app_selection_sheet.dart';
import '../../widgets/syrian_flag.dart';

import '../../theme/app_fonts.dart';

/// إدارة لغة التطبيق (عربي / إنجليزي) + RTL/LTR + Accept-Language للـ API.
class LocaleController extends GetxService {
  static const _storageKey = 'app_locale';

  /// نسخة من اللغة في SharedPreferences يقرؤها الفحص الخلفي (Workmanager) لإشعاراته —
  /// GetStorage لا يُستخدم من الـ isolate الخلفي.
  static const backgroundLocaleKey = 'app_locale';

  late final GetStorage _box;

  final RxString code = 'ar'.obs;

  Locale get locale => Locale(code.value);
  bool get isRtl => code.value == 'ar';
  String get languageLabel => code.value == 'ar' ? 'lang_arabic'.tr : 'lang_english'.tr;

  Future<void> init() async {
    _box = GetStorage();
    final saved = _box.read<String>(_storageKey);
    final initial = (saved == 'en' || saved == 'ar') ? saved! : 'ar';
    code.value = initial;
    Get.updateLocale(Locale(initial));
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().dio.options.headers['Accept-Language'] = initial;
    }
    unawaited(_mirrorForBackground(initial));
  }

  Future<void> _mirrorForBackground(String value) async {
    try {
      await SharedPreferencesAsync().setString(backgroundLocaleKey, value);
    } catch (_) {
      // غير حرج — الإشعارات الخلفية تستخدم العربية افتراضياً.
    }
  }

  Future<void> setLocale(String newCode) async {
    if (newCode != 'ar' && newCode != 'en') return;
    if (newCode == code.value) return;
    await _box.write(_storageKey, newCode);
    unawaited(_mirrorForBackground(newCode));
    await _apply(newCode, refreshData: true);
    // لا إشعار: الواجهة كلها تتبدّل أمام المستخدم — هذا أوضح دليل.
  }

  Future<void> _apply(String newCode, {required bool refreshData}) async {
    code.value = newCode;
    Get.updateLocale(Locale(newCode));

    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().dio.options.headers['Accept-Language'] = newCode;
    }

    if (refreshData) {
      if (Get.isRegistered<ApiClient>()) {
        Get.find<ApiClient>().cancelInFlightReads('locale_changed');
      }
      if (Get.isRegistered<LocaleRequestGuard>()) {
        Get.find<LocaleRequestGuard>().bump();
      }
      try {
        await LocaleRefresh.reloadAll();
      } catch (_) {
        // شاشة فشل تحديثها (انقطاع مثلاً) تعرض خطأها بنفسها؛ تغيير اللغة نفسه تمّ — لا نُسقط تأكيده.
      }
      // الخادم يحفظ لغة كل جهاز ليرسل إشعاراته بها: نعيد تسجيل التوكن باللغة الجديدة.
      if (Get.isRegistered<PushNotificationService>()) {
        unawaited(Get.find<PushNotificationService>().syncDeviceTokenIfLoggedIn(force: true));
      }
    }
  }

  /// ورقة اختيار اللغة بنفس النمط العائم الموحّد لباقي أوراق التطبيق.
  void showLanguagePicker([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;
    showAppFloatingSheet(
      context: ctx,
      builder: (_) => AppFloatingSheetFrame(
        title: 'choose_language'.tr,
        titleIcon: Icons.language_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LanguageTile(code: 'ar', label: 'lang_arabic'.tr, flag: const SyrianFlag(width: 36)),
            _LanguageTile(
              code: 'en',
              label: 'lang_english'.tr,
              flag: const Text('🇬🇧', style: TextStyle(fontSize: AppTextSize.display)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.code, required this.label, required this.flag});

  final String code;
  final String label;
  final Widget flag;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();
    return Obx(() {
      final selected = locale.code.value == code;
      return AppSelectableTile(
        label: label,
        selected: selected,
        leading: SizedBox(width: 40, height: 38, child: Center(child: flag)),
        onTap: () async {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          if (!selected) await locale.setLocale(code);
        },
      );
    });
  }
}
