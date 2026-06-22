import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/repositories/favorites_repository.dart';
import '../models/favorite_model.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';
import '../utils/auth_guard.dart';

/// مفضلة مرتبطة بالخادم فقط: القراءة من /student/favorites والتعديل عبر مسار الدورة.
class FavoritesService extends GetxService {
  FavoritesService(this._repository, this._tokenStorage);

  final FavoritesRepository _repository;
  final TokenStorage _tokenStorage;

  final items = <FavoriteModel>[].obs;
  final isSyncing = false.obs;

  DateTime? _lastSyncedAt;
  static const _syncTtl = Duration(minutes: 2);

  void _log(String message) {
    debugPrint('[Favorites] $message');
  }

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

  Future<void> syncFromApi({bool force = false}) async {
    if (!_tokenStorage.isLoggedIn) {
      items.clear();
      return;
    }
    if (!force &&
        _lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) < _syncTtl) {
      return;
    }
    isSyncing.value = true;
    try {
      final fromApi = await _repository.fetchMine();
      items.assignAll(fromApi);
      _lastSyncedAt = DateTime.now();
      _log('Synced ${items.length} favorites from API');
    } on ApiException catch (e) {
      _log('Sync API failed (${e.statusCode}): ${e.message}');
    } catch (e) {
      _log('Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> toggleCourse(int courseId) async {
    if (!await AuthGuard.requireLogin(message: 'favorite_login_required'.tr)) return false;
    return _toggle(
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

  Future<bool> _toggle({
    required FavoriteModel? Function() find,
    required Future<void> Function(int id) remove,
    required Future<Map<String, dynamic>> Function() add,
    required String addedMsg,
    required String removedMsg,
  }) async {
    try {
      final existing = find();
      if (existing != null) {
        await remove(existing.id);
        items.removeWhere((f) => f.id == existing.id);
        _log('Removed favorite id=${existing.id}');
        Get.snackbar('favorite_removed_title'.tr, removedMsg);
        return false;
      }

      final body = await add();
      _log('ADD response: $body');
      final map = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
      if (map.containsKey('id')) {
        items.add(FavoriteModel.fromJson(map));
      } else {
        await syncFromApi();
      }
      Get.snackbar('favorite_added_title'.tr, addedMsg);
      return true;
    } on ApiException catch (e) {
      _log('API failed: ${e.message}');
      Get.snackbar('error'.tr, e.message);
      return find() != null;
    }
  }
}
