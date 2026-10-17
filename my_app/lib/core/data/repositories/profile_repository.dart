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
import '../../network/api_exception.dart';
import '../../network/json_parser.dart';
import '../../storage/token_storage.dart';

class ProfileRepository extends GetxService {
  ProfileRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> fetchMe() => fetchFullStudentUser();

  /// أخطاء حقول تغيير البريد قبل الإرسال، أو null إن كانت سليمة.
  static Map<String, String>? emailChangeFieldErrors(String email, String currentPassword) {
    if (!RegExp(r'^[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}$').hasMatch(email.trim())) {
      return {'email': 'enter_valid_email'.tr};
    }
    if (currentPassword.isEmpty) return {'current_password': 'current_password_required'.tr};
    return null;
  }

  /// يغيّر البريد بكلمة المرور الحالية. يُرجع أخطاء الحقول (`email` / `current_password`) أو null عند النجاح.
  /// الخادم يعيد البريد الجديد غير مؤكد (`email_verified_at` = null)، فتُحفظ الحالة محلياً كذلك.
  Future<Map<String, String>?> changeEmail(String email, String currentPassword) async {
    final invalid = emailChangeFieldErrors(email, currentPassword);
    if (invalid != null) return invalid;
    try {
      final result = await updateProfile(StudentProfilePayload(email: email.trim(), currentPassword: currentPassword));
      // البريد نفسه لا يغيّر شيئاً على الخادم، لذا نحفظ ما أرسله بدل افتراض «غير مؤكد».
      await _tokenStorage.saveEmailVerified(emailVerificationStatus(extractUserMap(result) ?? result) ?? false);
      return null;
    } on ApiException catch (e) {
      final fields = e.fieldErrors ?? const {};
      if (fields.containsKey('current_password')) return {'current_password': fields['current_password']!};
      return {'email': fields['email'] ?? e.message};
    } catch (_) {
      return {'email': 'connection_error'.tr};
    }
  }

  /// `/student/me` (يحمل الملف الأكاديمي `student_profile`) + الكاش المحلي.
  /// (`GET /student/profile` غير موجود على الخادم — المسار للتعديل فقط — فكان كل تحميل يفشل بـ 405.)
  Future<Map<String, dynamic>> fetchFullStudentUser() async {
    final meMap = await _client.handle(
      () => _client.get(ApiEndpoints.studentMe),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );

    final studentId = extractStudentId(meMap) ?? extractStudentId(extractUserMap(meMap));
    if (studentId != null && studentId > 0) {
      await _tokenStorage.saveStudentId(studentId);
    }
    final phoneVerified = phoneVerificationStatus(extractUserMap(meMap) ?? meMap);
    if (phoneVerified != null) {
      await _tokenStorage.savePhoneVerified(phoneVerified);
    }
    final emailVerified = emailVerificationStatus(extractUserMap(meMap) ?? meMap);
    if (emailVerified != null) {
      await _tokenStorage.saveEmailVerified(emailVerified);
    }

    var user = mergeProfileUserData(meMap);

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
    if (extractPreferredInterestIds({...profile, ...user}).isEmpty && cache.preferredCategoryIds.isNotEmpty) {
      profile['preferred_categories'] = cache.preferredCategoryIds;
      user['preferred_categories'] = cache.preferredCategoryIds;
    }

    return {...user, 'student_profile': profile};
  }

  Future<void> syncAcademicAfterRegister({
    String? educationLevel,
    int? universityId,
    int? specializationId,
    List<int>? preferredCategories,
  }) async {
    final categoryIds = preferredCategories ?? const [];
    final cache = AcademicProfileCache(
      educationLevel: educationLevel,
      universityId: universityId,
      specializationId: specializationId,
      preferredCategoryIds: categoryIds,
    );
    if (!cache.isEmpty) {
      await _tokenStorage.saveAcademicCache(cache);
    }

    final payload = StudentProfilePayload(
      educationLevel: educationLevel,
      universityId: universityId,
      specializationId: specializationId,
      preferredCategories: categoryIds.isEmpty ? null : categoryIds,
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

  Future<Map<String, dynamic>> updateProfile(StudentProfilePayload payload) async {
    if (kDebugMode) {
      AppDebugLog.repo('Profile', 'PATCH ${ApiEndpoints.studentProfile}');
      AppDebugLog.repo('Profile', payload.toJson().toString());
    }
    Map<String, dynamic> mapper(dynamic data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{};
    try {
      return await _client.handle(() => _client.patch(ApiEndpoints.studentProfile, data: payload.toJson()), mapper);
    } on ApiException catch (e) {
      // POST فقط إن كان الخادم لا يدعم PATCH على هذا المسار. أخطاء التحقق (422) تُعرض كما هي.
      // (أُزيلت محاولة ثالثة كانت ترسل الاسم والهاتف وتاريخ الميلاد داخل رابط الطلب.)
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      return _client.handle(() => _client.post(ApiEndpoints.studentProfile, data: payload.toJson()), mapper);
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
    final formData = dio.FormData.fromMap({'avatar': dio.MultipartFile.fromBytes(bytes, filename: filename)});
    return _client.handle(
      () => _client.postMultipart(ApiEndpoints.studentProfile, formData),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = dio.FormData.fromMap({'avatar': await dio.MultipartFile.fromFile(filePath, filename: fileName)});
    return _client.handle(
      () => _client.postMultipart(ApiEndpoints.studentProfile, formData),
      (data) => extractObjectMap(normalizeApiBody(data)) ?? <String, dynamic>{},
    );
  }

  Future<void> syncProfileToSession({String? firstName, String? lastName, String? phone, String? avatarUrl}) async {
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
