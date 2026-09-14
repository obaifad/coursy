import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../config/api_config.dart';
import '../../models/json_helpers.dart';
import '../../config/app_debug_log.dart';
import '../../models/student_profile_payload.dart';
import '../../storage/academic_profile_cache.dart';
import '../../network/api_client.dart';
import '../../network/api_endpoints.dart';
import '../../network/json_parser.dart';
import '../../storage/token_storage.dart';

class ProfileRepository extends GetxService {
  ProfileRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> fetchMe() => fetchFullStudentUser();

  /// `/student/me` + `/student/profile` + الكاش المحلي.
  Future<Map<String, dynamic>> fetchFullStudentUser() async {
    final meFuture = _client.handle(
      () => _client.get(ApiEndpoints.studentMe),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
    final profileFuture = _tryFetchStudentProfileRecord();

    late Map<String, dynamic> meMap;
    Map<String, dynamic>? profileRecord;
    await Future.wait([
      meFuture.then((value) => meMap = value),
      profileFuture.then((value) => profileRecord = value),
    ]);

    final studentId = extractStudentId(meMap) ?? extractStudentId(extractUserMap(meMap));
    if (studentId != null && studentId > 0) {
      await _tokenStorage.saveStudentId(studentId);
    }

    var user = mergeProfileUserData(meMap);
    final profile = profileRecord;
    if (profile != null && profile.isNotEmpty) {
      final existing = extractNestedStudentProfile(user) ?? <String, dynamic>{};
      user = {
        ...user,
        'student_profile': {...existing, ...profile},
      };
    }

    final cached = await _tokenStorage.loadAcademicCache();
    if (cached != null && !cached.isEmpty) {
      user = _mergeAcademicCache(user, cached);
    }
    if (_hasAcademicFields(user)) {
      await _persistAcademicCacheFromUser(user);
    }

    return user;
  }

  /// يملأ الحقول الأكاديمية الناقصة من الكاش المحلي (مثلاً الاهتمامات بعد التسجيل).
  Map<String, dynamic> _mergeAcademicCache(Map<String, dynamic> user, AcademicProfileCache cache) {
    final profile = Map<String, dynamic>.from(extractNestedStudentProfile(user) ?? {});

    if ((profile['education_level']?.toString().trim().isEmpty ?? true) &&
        cache.educationLevel != null &&
        cache.educationLevel!.isNotEmpty) {
      profile['education_level'] = cache.educationLevel;
      user['education_level'] ??= cache.educationLevel;
    }
    if (profile['university_id'] == null && cache.universityId != null) {
      profile['university_id'] = cache.universityId;
      user['university_id'] ??= cache.universityId;
    }
    if (profile['specialization_id'] == null && cache.specializationId != null) {
      profile['specialization_id'] = cache.specializationId;
      user['specialization_id'] ??= cache.specializationId;
    }
    if (extractPreferredInterestIds({...profile, ...user}).isEmpty &&
        cache.preferredCategoryIds.isNotEmpty) {
      profile['preferred_tags'] = cache.preferredCategoryIds;
      user['preferred_tags'] = cache.preferredCategoryIds;
    }

    return {...user, 'student_profile': profile};
  }

  Future<void> syncAcademicAfterRegister({
    String? educationLevel,
    int? universityId,
    int? specializationId,
    List<int>? preferredTags,
  }) async {
    final tagIds = preferredTags ?? const [];
    final cache = AcademicProfileCache(
      educationLevel: educationLevel,
      universityId: universityId,
      specializationId: specializationId,
      preferredCategoryIds: tagIds,
    );
    if (!cache.isEmpty) {
      await _tokenStorage.saveAcademicCache(cache);
    }

    final payload = StudentProfilePayload(
      educationLevel: educationLevel,
      universityId: universityId,
      specializationId: specializationId,
      preferredTags: tagIds.isEmpty ? null : tagIds,
    );
    if (cache.isEmpty) return;

    try {
      await updateProfile(payload);
    } catch (_) {
      // يبقى الكاش المحلي حتى نجاح حفظ لاحق من البروفايل.
    }
  }

  Future<void> _persistAcademicCacheFromUser(Map<String, dynamic> user) async {
    final profile = extractNestedStudentProfile(user);
    if (profile == null) return;
    final cache = AcademicProfileCache(
      educationLevel: profile['education_level']?.toString(),
      universityId: JsonHelpers.parseIntOrNull(profile['university_id']),
      specializationId: JsonHelpers.parseIntOrNull(profile['specialization_id']),
      preferredCategoryIds: extractPreferredInterestIds({...profile, ...user}),
    );
    if (!cache.isEmpty) {
      await _tokenStorage.saveAcademicCache(cache);
    }
  }

  bool _hasAcademicFields(Map<String, dynamic> user) {
    if (user['education_level']?.toString().trim().isNotEmpty == true) return true;
    if (extractPreferredInterestIds(user).isNotEmpty) return true;

    final profile = extractNestedStudentProfile(user);
    if (profile == null) return false;
    final hasEducation = profile['education_level']?.toString().trim().isNotEmpty == true;
    final hasUniversity = profile['university_id'] != null;
    final hasSpecialization = profile['specialization_id'] != null;
    final hasTags = extractPreferredInterestIds({...profile, ...user}).isNotEmpty;
    return hasEducation || hasUniversity || hasSpecialization || hasTags;
  }

  Future<Map<String, dynamic>?> _tryFetchStudentProfileRecord() async {
    try {
      return await _client.handle(
        () => _client.get(ApiEndpoints.studentProfile),
        (data) => extractObjectMap(normalizeApiBody(data)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(StudentProfilePayload payload) async {
    if (kDebugMode) {
      AppDebugLog.repo('Profile', 'PATCH ${ApiEndpoints.studentProfile}');
      AppDebugLog.repo('Profile', payload.toJson().toString());
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
