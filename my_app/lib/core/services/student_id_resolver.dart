import 'package:get/get.dart';

import '../data/repositories/profile_repository.dart';
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
      throw ApiException('لم يتم العثور على معرّف الطالب. أعد تسجيل الدخول.');
    }
    await _tokenStorage.saveStudentId(id);
    return id;
  }
}
