import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../network/api_client.dart';
import 'locale_refresh.dart';

/// إدارة لغة التطبيق (عربي / إنجليزي) + RTL/LTR + Accept-Language للـ API.
class LocaleController extends GetxService {
  static const _storageKey = 'app_locale';
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
  }

  Future<void> setLocale(String newCode) async {
    if (newCode != 'ar' && newCode != 'en') return;
    if (newCode == code.value) return;
    await _box.write(_storageKey, newCode);
    await _apply(newCode, refreshData: true);
    Get.snackbar('language_changed'.tr, 'language_changed_desc'.tr);
  }

  Future<void> _apply(String newCode, {required bool refreshData}) async {
    code.value = newCode;
    Get.updateLocale(Locale(newCode));

    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().dio.options.headers['Accept-Language'] = newCode;
    }

    if (refreshData) {
      await LocaleRefresh.reloadAll();
    }
  }

  void showLanguagePicker() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('choose_language'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _LanguageTile(code: 'ar', label: 'lang_arabic'.tr, flag: '🇸🇾'),
              const SizedBox(height: 8),
              _LanguageTile(code: 'en', label: 'lang_english'.tr, flag: '🇬🇧'),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.code, required this.label, required this.flag});

  final String code;
  final String label;
  final String flag;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();
    return Obx(() {
      final selected = locale.code.value == code;
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: selected ? const Color(0x146C63FF) : null,
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6C63FF)) : null,
        onTap: () async {
          Get.back();
          await locale.setLocale(code);
        },
      );
    });
  }
}
