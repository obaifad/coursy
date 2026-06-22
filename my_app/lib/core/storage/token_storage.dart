import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'legacy_session_cleanup.dart';
import 'secure_session_store.dart';
import 'session_keys.dart';

/// إدارة جلسة المستخدم — Token وبيانات الحساب في Secure Storage فقط.
class TokenStorage extends GetxService {
  TokenStorage({SecureSessionStore? secureStore}) : _secure = secureStore ?? SecureSessionStore();

  final SecureSessionStore _secure;
  late final GetStorage _legacyBox;

  final RxnString _token = RxnString();
  final RxnInt _studentId = RxnInt();
  final RxnString userName = RxnString();
  final RxnString userPhone = RxnString();
  final RxnString userAvatarUrl = RxnString();
  final RxnString userAvatarLocalPath = RxnString();
  final RxBool phoneVerified = false.obs;

  int? get studentId => _studentId.value;
  String? get token => _token.value;
  bool get isLoggedIn => _token.value != null && _token.value!.isNotEmpty;

  Future<void> init() async {
    _legacyBox = GetStorage();
    await _migrateLegacyIfNeeded();
    await LegacySessionCleanup.purge(_legacyBox);
    await _loadFromSecure();
  }

  Future<void> _migrateLegacyIfNeeded() async {
    final version = await _secure.read(SessionKeys.storageVersion);
    if (version == SessionKeys.currentStorageVersion) return;

    if (version != null && version.isNotEmpty) {
      await _secure.deleteAll();
    }

    final legacyToken = _legacyBox.read<String>(LegacySessionKeys.token);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secure.write(SessionKeys.accessToken, legacyToken);
    }

    final legacyName = _legacyBox.read<String>(LegacySessionKeys.name);
    if (legacyName != null && legacyName.isNotEmpty) {
      await _secure.write(SessionKeys.userName, legacyName);
    }

    final legacyPhone = _legacyBox.read<String>(LegacySessionKeys.phone);
    if (legacyPhone != null && legacyPhone.isNotEmpty) {
      await _secure.write(SessionKeys.userPhone, legacyPhone);
    }

    final legacyStudentId = _legacyBox.read(LegacySessionKeys.studentId);
    final parsedStudentId = legacyStudentId is int
        ? legacyStudentId
        : int.tryParse(legacyStudentId?.toString() ?? '');
    if (parsedStudentId != null && parsedStudentId > 0) {
      await _secure.write(SessionKeys.studentId, '$parsedStudentId');
    }

    if (_legacyBox.read<bool>(LegacySessionKeys.phoneVerified) == true) {
      await _secure.write(SessionKeys.phoneVerified, 'true');
    }

    final legacyAvatarUrl = _legacyBox.read<String>(LegacySessionKeys.avatarUrl);
    if (legacyAvatarUrl != null && legacyAvatarUrl.isNotEmpty) {
      await _secure.write(SessionKeys.avatarUrl, legacyAvatarUrl);
    }

    final legacyAvatarLocal = _legacyBox.read<String>(LegacySessionKeys.avatarLocal);
    if (legacyAvatarLocal != null && legacyAvatarLocal.isNotEmpty) {
      await _secure.write(SessionKeys.avatarLocalPath, legacyAvatarLocal);
    }

    await _secure.write(SessionKeys.storageVersion, SessionKeys.currentStorageVersion);
  }

  Future<void> _loadFromSecure() async {
    _token.value = await _secure.read(SessionKeys.accessToken);
    userName.value = await _secure.read(SessionKeys.userName);
    userPhone.value = await _secure.read(SessionKeys.userPhone);
    userAvatarUrl.value = await _secure.read(SessionKeys.avatarUrl);
    userAvatarLocalPath.value = await _secure.read(SessionKeys.avatarLocalPath);
    phoneVerified.value = (await _secure.read(SessionKeys.phoneVerified)) == 'true';

    final sidRaw = await _secure.read(SessionKeys.studentId);
    final sid = int.tryParse(sidRaw ?? '');
    _studentId.value = (sid != null && sid > 0) ? sid : null;
  }

  Future<void> saveStudentId(int id) async {
    _studentId.value = id;
    await _secure.write(SessionKeys.studentId, '$id');
  }

  Future<void> saveAvatar({String? url, String? localPath}) async {
    if (url != null) {
      userAvatarUrl.value = url.isEmpty ? null : url;
      if (url.isEmpty) {
        await _secure.delete(SessionKeys.avatarUrl);
      } else {
        await _secure.write(SessionKeys.avatarUrl, url);
      }
    }
    if (localPath != null) {
      userAvatarLocalPath.value = localPath.isEmpty ? null : localPath;
      if (localPath.isEmpty) {
        await _secure.delete(SessionKeys.avatarLocalPath);
      } else {
        await _secure.write(SessionKeys.avatarLocalPath, localPath);
      }
    }
  }

  Future<void> saveSession({
    required String token,
    String? name,
    String? phone,
    String? avatarUrl,
    bool? verifiedPhone,
    int? studentId,
  }) async {
    _token.value = token;
    await _secure.write(SessionKeys.accessToken, token);
    await _secure.write(SessionKeys.storageVersion, SessionKeys.currentStorageVersion);

    if (name != null && name.isNotEmpty) {
      userName.value = name;
      await _secure.write(SessionKeys.userName, name);
    }
    if (phone != null && phone.isNotEmpty) {
      userPhone.value = phone;
      await _secure.write(SessionKeys.userPhone, phone);
    }
    if (avatarUrl != null) {
      await saveAvatar(url: avatarUrl);
    }
    if (verifiedPhone != null) {
      phoneVerified.value = verifiedPhone;
      await _secure.write(SessionKeys.phoneVerified, verifiedPhone ? 'true' : 'false');
    }
    if (studentId != null && studentId > 0) {
      await saveStudentId(studentId);
    }

    await LegacySessionCleanup.purge(_legacyBox);
  }

  Future<void> markPhoneVerified() async {
    phoneVerified.value = true;
    await _secure.write(SessionKeys.phoneVerified, 'true');
  }

  Future<void> clearSession() async {
    _token.value = null;
    userName.value = null;
    userPhone.value = null;
    userAvatarUrl.value = null;
    userAvatarLocalPath.value = null;
    phoneVerified.value = false;
    _studentId.value = null;

    await _secure.deleteAll();
    await LegacySessionCleanup.purge(_legacyBox);
  }

  Future<void> saveToken(String token) => saveSession(token: token);

  Future<void> clearToken() => clearSession();
}
