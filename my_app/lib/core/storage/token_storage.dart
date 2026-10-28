import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../session/session_diagnostics.dart';
import 'legacy_session_cleanup.dart';
import 'academic_profile_cache.dart';
import 'secure_session_store.dart';
import 'session_keys.dart';

/// إدارة جلسة المستخدم — Token وبيانات الحساب في Secure Storage فقط.
class TokenStorage extends GetxService {
  TokenStorage({SecureSessionStore? secureStore}) : _secure = secureStore ?? SecureSessionStore();

  /// علامة في GetStorage (تُحذف مع التطبيق) — غيابها مع صندوق فارغ يعني تثبيتاً جديداً.
  static const _installMarkerKey = 'install_marker';

  /// علامة «كان مسجّلاً» خارج التخزين الآمن (ليست سراً): إن وُجدت ولم يوجد التوكن عند الإقلاع فقد ضاعت
  /// الجلسة من التخزين الآمن، لا خروجاً من المستخدم ([SessionDiagnostics]).
  static const _signedInMarkerKey = 'session_signed_in';

  final SecureSessionStore _secure;
  late final GetStorage _legacyBox;
  bool _boxReady = false;

  final RxnString _token = RxnString();
  final RxnInt _studentId = RxnInt();
  final RxnString userName = RxnString();
  final RxnString userPhone = RxnString();
  final RxnString userAvatarUrl = RxnString();

  /// حالة التحقق من الهاتف: true/false من الخادم، أو null إن لم يُعرف بعد (الخادم لم يرسل الحقل).
  final RxnBool phoneVerified = RxnBool();

  /// حالة تأكيد البريد بنفس المنطق: null = الخادم لم يرسل `email_verified_at` بعد.
  final RxnBool emailVerified = RxnBool();

  int? get studentId => _studentId.value;
  String? get token => _token.value;
  bool get isLoggedIn => _token.value != null && _token.value!.isNotEmpty;

  Future<void> init() async {
    _legacyBox = GetStorage();
    _boxReady = true;
    await _clearKeychainAfterReinstall();
    // قراءة واحدة لكل المفاتيح بدل 7 قراءات متتالية من Keystore/Keychain قبل runApp.
    final watch = Stopwatch()..start();
    final Map<String, String> stored;
    try {
      stored = Map<String, String>.of(await _secure.readAll());
    } catch (e, st) {
      SessionDiagnostics.record(SessionBootOutcome.readFailed, took: watch.elapsed, error: e, stack: st);
      rethrow;
    }
    await _migrateLegacyIfNeeded(stored);
    await LegacySessionCleanup.purge(_legacyBox);
    await _load(stored);
    await _recordBoot(watch.elapsed, stored.length);
  }

  Future<void> _recordBoot(Duration took, int keys) async {
    final wasSignedIn = _legacyBox.read<bool>(_signedInMarkerKey) == true;
    if (isLoggedIn) {
      // مستخدمون من إصدار سابق بلا العلامة: تُضاف الآن.
      if (!wasSignedIn) await _legacyBox.write(_signedInMarkerKey, true);
      SessionDiagnostics.record(SessionBootOutcome.signedIn, took: took, keys: keys);
    } else if (wasSignedIn) {
      // مرة واحدة: بعدها ضيف عادي حتى يدخل من جديد.
      await _legacyBox.remove(_signedInMarkerKey);
      SessionDiagnostics.record(SessionBootOutcome.lost, took: took, keys: keys);
    } else {
      SessionDiagnostics.record(SessionBootOutcome.guest, took: took, keys: keys);
    }
  }

  /// على iOS يبقى Keychain بعد حذف التطبيق، فيعود المستخدم مسجّلاً بعد إعادة التثبيت.
  /// GetStorage يُحذف مع التطبيق — إن كان فارغاً تماماً وبلا علامة فهذا تثبيت جديد.
  Future<void> _clearKeychainAfterReinstall() async {
    final hasMarker = _legacyBox.read<bool>(_installMarkerKey) == true;
    if (!hasMarker) {
      final isFreshInstall = (_legacyBox.getKeys<Iterable<String>>()).isEmpty;
      if (isFreshInstall && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _secure.deleteAll();
      }
      await _legacyBox.write(_installMarkerKey, true);
    }
  }

  /// ترحيل جلسة GetStorage القديمة + تنظيفها — مرة واحدة لكل إصدار تخزين.
  Future<void> _migrateLegacyIfNeeded(Map<String, String> stored) async {
    final version = stored[SessionKeys.storageVersion];
    if (version == SessionKeys.currentStorageVersion) return;

    if (version != null && version.isNotEmpty) {
      await _secure.deleteAll();
      stored.clear();
    }

    Future<void> copy(String legacyKey, String key) async {
      final value = _legacyBox.read(legacyKey)?.toString();
      if (value != null && value.isNotEmpty) {
        await _secure.write(key, value);
        stored[key] = value;
      }
    }

    await copy(LegacySessionKeys.token, SessionKeys.accessToken);
    await copy(LegacySessionKeys.name, SessionKeys.userName);
    await copy(LegacySessionKeys.phone, SessionKeys.userPhone);
    await copy(LegacySessionKeys.avatarUrl, SessionKeys.avatarUrl);

    final legacyStudentId = int.tryParse(_legacyBox.read(LegacySessionKeys.studentId)?.toString() ?? '');
    if (legacyStudentId != null && legacyStudentId > 0) {
      await _secure.write(SessionKeys.studentId, '$legacyStudentId');
      stored[SessionKeys.studentId] = '$legacyStudentId';
    }
    if (_legacyBox.read<bool>(LegacySessionKeys.phoneVerified) == true) {
      await _secure.write(SessionKeys.phoneVerified, 'true');
      stored[SessionKeys.phoneVerified] = 'true';
    }

    await _secure.write(SessionKeys.storageVersion, SessionKeys.currentStorageVersion);
    stored[SessionKeys.storageVersion] = SessionKeys.currentStorageVersion;
  }

  Future<void> _load(Map<String, String> stored) async {
    _token.value = stored[SessionKeys.accessToken];
    userName.value = stored[SessionKeys.userName];
    userPhone.value = stored[SessionKeys.userPhone];
    userAvatarUrl.value = stored[SessionKeys.avatarUrl];
    final storedVerified = stored[SessionKeys.phoneVerified];
    phoneVerified.value = storedVerified == null ? null : storedVerified == 'true';
    final storedEmailVerified = stored[SessionKeys.emailVerified];
    emailVerified.value = storedEmailVerified == null ? null : storedEmailVerified == 'true';

    final sid = int.tryParse(stored[SessionKeys.studentId] ?? '');
    _studentId.value = (sid != null && sid > 0) ? sid : null;

    // مسار صورة مؤقت من إصدارات سابقة — ملف كاش قد يحذفه النظام، لا نستخدمه.
    if (stored.containsKey(SessionKeys.avatarLocalPath)) {
      await _secure.delete(SessionKeys.avatarLocalPath);
    }
  }

  Future<void> saveStudentId(int id) async {
    if (_studentId.value == id) return;
    _studentId.value = id;
    await _secure.write(SessionKeys.studentId, '$id');
  }

  Future<void> saveAvatar({String? url}) async {
    if (url == null) return;
    final next = url.isEmpty ? null : url;
    if (userAvatarUrl.value == next) return;
    userAvatarUrl.value = next;
    if (next == null) {
      await _secure.delete(SessionKeys.avatarUrl);
    } else {
      await _secure.write(SessionKeys.avatarUrl, next);
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
    if (_token.value != token) {
      _token.value = token;
      await _secure.write(SessionKeys.accessToken, token);
      await _secure.write(SessionKeys.storageVersion, SessionKeys.currentStorageVersion);
      if (_boxReady) await _legacyBox.write(_signedInMarkerKey, true);
    }

    if (name != null && name.isNotEmpty && userName.value != name) {
      userName.value = name;
      await _secure.write(SessionKeys.userName, name);
    }
    if (phone != null && phone.isNotEmpty && userPhone.value != phone) {
      userPhone.value = phone;
      await _secure.write(SessionKeys.userPhone, phone);
    }
    if (avatarUrl != null) {
      await saveAvatar(url: avatarUrl);
    }
    if (verifiedPhone != null) {
      await savePhoneVerified(verifiedPhone);
    }
    if (studentId != null && studentId > 0) {
      await saveStudentId(studentId);
    }
  }

  Future<void> savePhoneVerified(bool verified) async {
    if (phoneVerified.value == verified) return;
    phoneVerified.value = verified;
    await _secure.write(SessionKeys.phoneVerified, verified ? 'true' : 'false');
  }

  Future<void> markPhoneVerified() => savePhoneVerified(true);

  Future<void> saveEmailVerified(bool verified) async {
    if (emailVerified.value == verified) return;
    emailVerified.value = verified;
    await _secure.write(SessionKeys.emailVerified, verified ? 'true' : 'false');
  }

  Future<void> clearSession() async {
    _token.value = null;
    userName.value = null;
    userPhone.value = null;
    userAvatarUrl.value = null;
    phoneVerified.value = null;
    emailVerified.value = null;
    _studentId.value = null;

    // خروج مقصود (أو انتهاء الجلسة): ليس «فقداناً» عند الإقلاع التالي.
    if (_boxReady) await _legacyBox.remove(_signedInMarkerKey);
    await _secure.deleteAll();
    // نُبقي إصدار التخزين حتى لا يُعاد الترحيل/التنظيف عند التشغيل التالي.
    await _secure.write(SessionKeys.storageVersion, SessionKeys.currentStorageVersion);
  }

  Future<void> saveAcademicCache(AcademicProfileCache cache) async {
    if (cache.isEmpty) {
      await clearAcademicCache();
      return;
    }
    await _secure.write(SessionKeys.academicProfileCache, cache.encode());
  }

  Future<AcademicProfileCache?> loadAcademicCache() async {
    final raw = await _secure.read(SessionKeys.academicProfileCache);
    return AcademicProfileCache.decode(raw);
  }

  Future<void> clearAcademicCache() async {
    await _secure.delete(SessionKeys.academicProfileCache);
  }

  Future<void> saveToken(String token) => saveSession(token: token);

  Future<void> clearToken() => clearSession();
}
