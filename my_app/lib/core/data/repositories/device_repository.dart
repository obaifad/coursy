import 'package:get/get.dart';

import '../../config/app_debug_log.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
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

    // Postman يستخدم query — نجرّبها أولاً ثم body كاحتياط.
    try {
      await _register(query: {'token': token, 'platform': _platform});
      return;
    } catch (e) {
      AppDebugLog.fcm('device register via query failed: $e');
    }

    await _register(
      data: {
        'token': token,
        'device_token': token,
        'platform': _platform,
      },
    );
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    final token = deviceToken.trim();
    if (token.isEmpty) return;

    try {
      await _unregister(query: {'token': token});
      return;
    } catch (_) {}

    await _unregister(
      data: {
        'token': token,
        'device_token': token,
      },
    );
  }

  Future<void> _register({Map<String, dynamic>? query, Map<String, dynamic>? data}) async {
    await _client.handle(
      () => _client.post(
        ApiEndpoints.studentDevices,
        query: query,
        data: data,
      ),
      _parseResponse,
    );
  }

  Future<void> _unregister({Map<String, dynamic>? query, Map<String, dynamic>? data}) async {
    await _client.handle(
      () => _client.delete(
        ApiEndpoints.studentDevices,
        query: query,
        data: data,
      ),
      (_) => null,
    );
  }

  Null _parseResponse(dynamic data) {
    final body = normalizeApiBody(data);
    final id = body['id'] ?? body['data']?['id'];
    AppDebugLog.fcm('device saved on server id=$id platform=$_platform');
    return null;
  }
}
