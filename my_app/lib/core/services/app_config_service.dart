import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../theme/app_colors.dart';
import '../config/app_debug_log.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/json_parser.dart';
import '../utils/external_launcher.dart';

/// إعدادات التطبيق من الخادم (`GET /app/config`): الإصدار الأدنى والأحدث ورسالة الصيانة.
/// تُعدَّل من لوحة التحكم دون رفع نسخة جديدة.
class AppConfig {
  const AppConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.maintenance,
    this.maintenanceMessage,
  });

  final String? minVersion;
  final String? latestVersion;
  final String? storeUrl;
  final bool maintenance;
  final String? maintenanceMessage;

  factory AppConfig.fromJson(Map<String, dynamic> json, String platform) {
    final p = json[platform];
    final platformMap = p is Map ? Map<String, dynamic>.from(p) : const <String, dynamic>{};
    String? text(dynamic v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    final maintenance = json['maintenance'];
    return AppConfig(
      minVersion: text(platformMap['min_version']),
      latestVersion: text(platformMap['latest_version']),
      storeUrl: text(platformMap['store_url']),
      maintenance: maintenance == true || maintenance == 1 || maintenance == '1' || maintenance == 'true',
      maintenanceMessage: text(json['maintenance_message']),
    );
  }
}

/// يقارن إصدارين بصيغة 1.2.3 (الأجزاء الناقصة = 0، وما بعد + يُتجاهل).
int compareVersions(String a, String b) {
  List<int> parts(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

enum AppConfigAction { none, maintenance, forceUpdate, suggestUpdate }

/// ما يجب عرضه حسب الإعدادات ونسخة التطبيق الحالية.
AppConfigAction decideAppConfigAction(AppConfig config, String currentVersion) {
  if (config.maintenance) return AppConfigAction.maintenance;
  final min = config.minVersion;
  if (min != null && compareVersions(currentVersion, min) < 0) return AppConfigAction.forceUpdate;
  final latest = config.latestVersion;
  if (latest != null && compareVersions(currentVersion, latest) < 0) return AppConfigAction.suggestUpdate;
  return AppConfigAction.none;
}

class AppConfigService extends GetxService {
  AppConfigService(this._client);

  final ApiClient _client;

  static const _dismissedKey = 'app_config.dismissed_latest_version';

  Future<AppConfig?>? _loading;

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// يبدأ الجلب مبكراً (من main) دون انتظار؛ العرض يحدث بعد الانتقال من شاشة البداية.
  Future<AppConfig?> load() => _loading ??= _fetch();

  Future<AppConfig?> _fetch() async {
    if (kIsWeb) return null;
    try {
      return await _client.handle(() => _client.get(ApiEndpoints.appConfig), (data) {
        final body = normalizeApiBody(data);
        final map = body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{};
        final inner = map['data'];
        return AppConfig.fromJson(inner is Map ? Map<String, dynamic>.from(inner) : map, _platform);
      });
    } catch (e) {
      AppDebugLog.repo('AppConfig', 'load failed: $e');
      return null;
    }
  }

  /// يُستدعى بعد مغادرة شاشة البداية (حتى لا يُزال الحوار مع offAll).
  Future<void> presentIfNeeded() async {
    final config = await load();
    if (config == null) return;
    final version = (await PackageInfo.fromPlatform()).version;
    switch (decideAppConfigAction(config, version)) {
      case AppConfigAction.maintenance:
        await _showBlocking(
          title: 'maintenance_title'.tr,
          message: config.maintenanceMessage ?? 'maintenance_default_msg'.tr,
          actionLabel: 'retry'.tr,
          onAction: () async {
            _loading = null;
            final fresh = await load();
            if (fresh != null && !fresh.maintenance && Get.isDialogOpen == true) Get.back<void>();
          },
        );
      case AppConfigAction.forceUpdate:
        await _showBlocking(
          title: 'update_required_title'.tr,
          message: 'update_required_msg'.tr,
          actionLabel: 'update_now'.tr,
          onAction: () => _openStore(config),
        );
      case AppConfigAction.suggestUpdate:
        final storage = GetStorage();
        if (storage.read<String>(_dismissedKey) == config.latestVersion) return;
        final update = await Get.dialog<bool>(
          AlertDialog(
            title: Text('update_available_title'.tr),
            content: Text('update_available_msg'.tr),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: Text('later'.tr)),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
                onPressed: () => Get.back(result: true),
                child: Text('update_now'.tr),
              ),
            ],
          ),
        );
        if (update == true) {
          await _openStore(config);
        } else {
          await storage.write(_dismissedKey, config.latestVersion);
        }
      case AppConfigAction.none:
        return;
    }
  }

  Future<void> _openStore(AppConfig config) async {
    final url = config.storeUrl;
    if (url != null) await ExternalLauncher.openWebPage(url);
  }

  /// حوار لا يُغلق بالرجوع ولا بالضغط خارجه.
  Future<void> _showBlocking({
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Get.dialog<void>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          icon: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 36),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
