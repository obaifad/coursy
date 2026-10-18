import 'package:get/get.dart';

import '../config/app_debug_log.dart';
import '../data/repositories/favorites_repository.dart';
import '../models/favorite_model.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';
import '../utils/auth_guard.dart';
import '../utils/app_toast.dart';

/// مفضلة مرتبطة بالخادم فقط: القراءة من /student/favorites والتعديل عبر مسار الدورة.
class FavoritesService extends GetxService {
  FavoritesService(this._repository, this._tokenStorage);

  final FavoritesRepository _repository;
  final TokenStorage _tokenStorage;

  final items = <FavoriteModel>[].obs;
  final isSyncing = false.obs;

  DateTime? _lastSyncedAt;
  static const _syncTtl = Duration(minutes: 2);

  void _log(String message) => AppDebugLog.repo('Favorites', message);

  bool isCourseFavorite(int courseId) =>
      items.any((f) => f.type == FavoriteTargetType.course && f.targetId == courseId);

  bool isInstituteFavorite(int instituteId) =>
      items.any((f) => f.type == FavoriteTargetType.institute && f.targetId == instituteId);

  bool isInstructorFavorite(int instructorId) =>
      items.any((f) => f.type == FavoriteTargetType.instructor && f.targetId == instructorId);

  FavoriteModel? findCourse(int courseId) {
    for (final f in items) {
      if (f.type == FavoriteTargetType.course && f.targetId == courseId) return f;
    }
    return null;
  }

  FavoriteModel? findInstitute(int instituteId) {
    for (final f in items) {
      if (f.type == FavoriteTargetType.institute && f.targetId == instituteId) return f;
    }
    return null;
  }

  FavoriteModel? findInstructor(int instructorId) {
    for (final f in items) {
      if (f.type == FavoriteTargetType.instructor && f.targetId == instructorId) return f;
    }
    return null;
  }

  /// رسالة آخر فشل في جلب المفضلة (null بعد نجاح) — لتمييز «لا مفضلة» عن «تعذّر التحميل».
  final lastSyncError = RxnString();

  Future<void> syncFromApi({bool force = false}) async {
    if (!_tokenStorage.isLoggedIn) {
      clearForLogout();
      return;
    }
    if (!force && _lastSyncedAt != null && DateTime.now().difference(_lastSyncedAt!) < _syncTtl) {
      return;
    }
    isSyncing.value = true;
    try {
      final fromApi = await _repository.fetchMine();
      items.assignAll(fromApi);
      _lastSyncedAt = DateTime.now();
      lastSyncError.value = null;
      _log('Synced ${items.length} favorites from API');
    } on ApiException catch (e) {
      lastSyncError.value = e.message;
      _log('Sync API failed (${e.statusCode}): ${e.message}');
    } catch (e) {
      lastSyncError.value = 'error_unexpected'.tr;
      _log('Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> toggleCourse(int courseId, {bool showFeedback = true}) async {
    if (!await AuthGuard.requireLogin(message: 'favorite_login_required'.tr)) return false;
    return _toggle(
      key: 'course:$courseId',
      showFeedback: showFeedback,
      find: () => findCourse(courseId),
      remove: (id) => _repository.removeFavorite(id, courseId: courseId),
      add: () => _repository.addFavorite(courseId: courseId),
      addedMsg: 'favorite_course_added'.tr,
      removedMsg: 'favorite_course_removed'.tr,
    );
  }

  Future<bool> toggleInstitute(int instituteId) async {
    if (!await AuthGuard.requireLogin(message: 'favorite_login_required'.tr)) return false;
    return _toggle(
      key: 'institute:$instituteId',
      find: () => findInstitute(instituteId),
      remove: (id) => _repository.removeFavorite(id),
      add: () => _repository.addFavorite(instituteId: instituteId),
      addedMsg: 'favorite_institute_added'.tr,
      removedMsg: 'favorite_institute_removed'.tr,
    );
  }

  Future<bool> toggleInstructor(int instructorId) async {
    if (!await AuthGuard.requireLogin(message: 'favorite_login_required'.tr)) return false;
    return _toggle(
      key: 'instructor:$instructorId',
      find: () => findInstructor(instructorId),
      remove: (id) => _repository.removeFavorite(id),
      add: () => _repository.addFavorite(instructorId: instructorId),
      addedMsg: 'favorite_instructor_added'.tr,
      removedMsg: 'favorite_instructor_removed'.tr,
    );
  }

  /// كل معرّفات الدورات في المفضلة القادمة من API فقط.
  List<int> get allCourseIds {
    final ids = <int>{};
    for (final f in items) {
      if (f.type == FavoriteTargetType.course) ids.add(f.targetId);
    }
    return ids.toList();
  }

  /// عناصر يجري تبديلها الآن: ضغطة ثانية (أو بطاقة ثانية للدورة نفسها) لا ترسل طلباً آخر.
  final _inFlight = <String>{};

  Future<bool> _toggle({
    required String key,
    required FavoriteModel? Function() find,
    required Future<void> Function(int id) remove,
    required Future<Map<String, dynamic>> Function() add,
    required String addedMsg,
    required String removedMsg,
    bool showFeedback = true,
  }) async {
    if (!_inFlight.add(key)) return find() != null;
    try {
      final existing = find();
      if (existing != null) {
        await remove(existing.id);
        items.removeWhere((f) => f.id == existing.id);
        _log('Removed favorite id=${existing.id}');
        // لا إشعار: القلب يرجع فارغاً (وفي المفضلة تتلاشى البطاقة).
        return false;
      }

      final body = await add();
      _log('ADD response: $body');
      final map = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
      if (map.containsKey('id')) {
        items.add(FavoriteModel.fromJson(map));
      } else {
        // بلا معرّف في الرد: نجلب القائمة الآن (force — وإلا تخطّاها كاش الدقيقتين فلا يتغيّر القلب).
        await syncFromApi(force: true);
      }
      // لا إشعار: القلب يصير أحمر مع نبضة وحركة.
      return true;
    } on ApiException catch (e) {
      _log('API failed: ${e.message}');
      AppToast.show('error'.tr, e.message);
      return find() != null;
    } catch (e) {
      // انقطاع أو رد غير متوقع: رسالة مفهومة بدل استثناء غير معالج.
      _log('Toggle error: $e');
      AppToast.show('error'.tr, 'connection_error'.tr);
      return find() != null;
    } finally {
      _inFlight.remove(key);
    }
  }

  void clearForLogout() {
    items.clear();
    _lastSyncedAt = null;
    isSyncing.value = false;
  }
}
