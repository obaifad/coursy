import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';

class DeviceRepository extends GetxService {
  DeviceRepository(this._client);

  final ApiClient _client;

  String get _platform {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<void> registerDeviceToken(String deviceToken) async {
    final token = deviceToken.trim();
    if (token.isEmpty) return;

    // التوكن في جسم الطلب أولاً — الـ query يُحفظ في سجلات الخوادم. query احتياط فقط
    // (Laravel يقرأ الاثنين عبر $request->input).
    try {
      await _register(data: {'token': token, 'device_token': token, 'platform': _platform});
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405 && e.statusCode != 422) rethrow;
      AppDebugLog.fcm('device register via body failed (${e.statusCode}) — retrying via query');
    }

    await _register(query: {'token': token, 'platform': _platform});
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    final token = deviceToken.trim();
    if (token.isEmpty) return;

    try {
      await _unregister(data: {'token': token, 'device_token': token});
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405 && e.statusCode != 422) rethrow;
    }

    await _unregister(query: {'token': token});
  }

  Future<void> _register({Map<String, dynamic>? query, Map<String, dynamic>? data}) async {
    await _client.handle(() => _client.post(ApiEndpoints.studentDevices, query: query, data: data), _parseResponse);
  }

  Future<void> _unregister({Map<String, dynamic>? query, Map<String, dynamic>? data}) async {
    await _client.handle(() => _client.delete(ApiEndpoints.studentDevices, query: query, data: data), (_) => null);
  }

  /// الاستجابة قد تكون فارغة (204) — لا نفترض وجود id، وإلا اعتُبر النجاح فشلاً وأُعيد الإرسال.
  Null _parseResponse(dynamic data) {
    final body = normalizeApiBody(data);
    Object? id;
    if (body is Map) {
      final nested = body['data'];
      id = body['id'] ?? (nested is Map ? nested['id'] : null);
    }
    AppDebugLog.fcm('device saved on server id=${id ?? '-'} platform=$_platform');
    return null;
  }
}
