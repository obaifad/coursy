import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../config/api_config.dart';
import '../../models/student_profile_payload.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../storage/token_storage.dart';

class ProfileRepository extends GetxService {
  ProfileRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> fetchMe() async {
    final map = await _client.handle(
      () => _client.get(ApiEndpoints.studentMe),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
    final studentId = extractStudentId(map) ?? extractStudentId(extractUserMap(map));
    if (studentId != null && studentId > 0) {
      await _tokenStorage.saveStudentId(studentId);
    }
    return map;
  }

  Future<Map<String, dynamic>> updateProfile(StudentProfilePayload payload) async {
    if (kDebugMode) {
      final token = _tokenStorage.token;
      debugPrint('========== PROFILE PATCH ==========');
      debugPrint('Endpoint: ${ApiEndpoints.studentProfile}');
      debugPrint('Token exists: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        debugPrint('Bearer $token');
      }
      debugPrint('Payload: ${payload.toJson()}');
      debugPrint('===================================');
    }
    try {
      return await _client.handle(
        () => _client.patch(ApiEndpoints.studentProfile, data: payload.toJson()),
        (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
      );
    } catch (_) {
      try {
        return await _client.handle(
          () => _client.post(ApiEndpoints.studentProfile, data: payload.toJson()),
          (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
        );
      } catch (_) {
        final queryPath =
            '${ApiEndpoints.studentProfile}?first_name=${Uri.encodeQueryComponent(payload.firstName ?? '')}'
            '&last_name=${Uri.encodeQueryComponent(payload.lastName ?? '')}'
            '&phone=${Uri.encodeQueryComponent(payload.phone ?? '')}'
            '${payload.gender == null ? '' : '&gender=${Uri.encodeQueryComponent(payload.gender!)}'}'
            '${payload.birthDate == null ? '' : '&birth_date=${Uri.encodeQueryComponent(payload.birthDate!)}'}'
            '${payload.cityId == null ? '' : '&city_id=${payload.cityId}'}';
        return _client.handle(
          () => _client.post(queryPath, data: const <String, dynamic>{}),
          (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
        );
      }
    }
  }

  Future<void> syncNameFromUser(Map<String, dynamic> user) async {
    await syncProfileToSession(
      firstName: user['first_name']?.toString(),
      lastName: user['last_name']?.toString(),
      phone: user['phone']?.toString(),
    );
  }

  String? extractAvatarUrl(Map<String, dynamic> user) {
    for (final key in ['avatar', 'avatar_url', 'image', 'profile_image', 'photo']) {
      final value = user[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Future<Map<String, dynamic>> uploadAvatarBytes(List<int> bytes, {String filename = 'avatar.jpg'}) async {
    final formData = dio.FormData.fromMap({
      'avatar': dio.MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _client.handle(
      () => _client.postMultipart(ApiEndpoints.studentProfile, formData),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = dio.FormData.fromMap({
      'avatar': await dio.MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _client.handle(
      () => _client.postMultipart(ApiEndpoints.studentProfile, formData),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
  }

  Future<void> syncProfileToSession({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final token = _tokenStorage.token;
    if (token == null || token.isEmpty) return;

    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    final resolvedAvatar = avatarUrl == null ? null : ApiConfig.resolveMediaUrl(avatarUrl) ?? avatarUrl;
    await _tokenStorage.saveSession(
      token: token,
      name: fullName.isNotEmpty ? fullName : _tokenStorage.userName.value,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : _tokenStorage.userPhone.value,
      avatarUrl: resolvedAvatar,
    );
  }
}
