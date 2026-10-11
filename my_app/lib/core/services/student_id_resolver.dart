import 'package:get/get.dart';

import '../data/repositories/profile_repository.dart';
import '../models/json_helpers.dart';
import '../network/api_exception.dart';
import '../network/json_parser.dart';
import '../storage/token_storage.dart';

/// يحل معرّف الطالب من الجلسة أو من GET /student/me.
class StudentIdResolver extends GetxService {
  StudentIdResolver(this._tokenStorage, this._profileRepository);

  final TokenStorage _tokenStorage;
  final ProfileRepository _profileRepository;

  Future<int> resolve() async {
    final cached = _tokenStorage.studentId;
    if (cached != null && cached > 0) return cached;

    final me = await _profileRepository.fetchMe();
    final id = extractStudentId(me) ?? extractStudentId(extractUserMap(me));
    if (id == null || id <= 0) {
      throw ApiException('error_student_id_missing'.tr);
    }
    await _tokenStorage.saveStudentId(id);
    return id;
  }

  int? _userId;
  String? _userIdToken;

  /// معرّف حساب المستخدم (users.id) — وهو `student_id` في التقييمات، بخلاف [resolve] الذي قد
  /// يُرجع معرّف ملف الطالب. محفوظ في الذاكرة لكل جلسة (توكن)، و null لغير المسجّل.
  Future<int?> resolveUserId() async {
    final token = _tokenStorage.token;
    if (token == null || token.isEmpty) return null;
    if (_userIdToken == token && _userId != null) return _userId;

    final me = await _profileRepository.fetchMe();
    final user = extractUserMap(me) ?? me;
    final id = JsonHelpers.parseIntOrNull(user['id']);
    if (id == null || id <= 0) return null;
    _userId = id;
    _userIdToken = token;
    return id;
  }
}
