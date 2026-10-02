import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/locale/locale_request_guard.dart';

class FavoritesController extends GetxController with InitialLoadState {
  final FavoritesService _favoritesService = Get.find();
  final CourseRepository _courseRepository = Get.find();

  final isLoading = true.obs;
  final removingIds = <int>{}.obs;
  final courses = <CourseModel>[].obs;

  Worker? _favoritesWorker;

  /// أثناء reloadFromService نفسها لا نريد أن يطلق الـ worker تحميلاً ثانياً لنفس القائمة.
  bool _syncing = false;

  static const _parallelFetches = 4;

  @override
  void onInit() {
    super.onInit();
    _favoritesWorker = ever(_favoritesService.items, (_) {
      if (_syncing) return;
      unawaited(_hydrateCoursesFromService(refreshAll: false));
    });
    loadFavorites();
  }

  @override
  void onClose() {
    _favoritesWorker?.dispose();
    super.onClose();
  }

  static void ensureRegistered() {
    if (!Get.isRegistered<FavoritesController>()) {
      Get.lazyPut<FavoritesController>(() => FavoritesController(), fenix: true);
    }
  }

  Future<void> loadFavorites() => reloadFromService(forceSync: true);

  Future<void> reloadFromService({bool forceSync = true}) async {
    isLoading.value = isInitialLoad;
    _syncing = true;
    try {
      if (forceSync) {
        await _favoritesService.syncFromApi(force: true);
      }
    } finally {
      _syncing = false;
    }
    try {
      await _hydrateCoursesFromService(refreshAll: true);
      markLoaded();
    } finally {
      isLoading.value = false;
    }
  }

  /// [refreshAll] = false: يجلب فقط الدورات الجديدة في المفضلة (بعد إضافة/حذف) ويُبقي المحمّلة.
  /// الجلب على دفعات متوازية بدل طلب متسلسل لكل دورة.
  Future<void> _hydrateCoursesFromService({required bool refreshAll}) async {
    final ids = _favoritesService.allCourseIds;
    if (ids.isEmpty) {
      courses.clear();
      return;
    }

    final known = refreshAll ? <int, CourseModel>{} : {for (final c in courses) c.id: c};
    final missing = ids.where((id) => !known.containsKey(id)).toList();
    final fetched = <int, CourseModel>{};
    for (var i = 0; i < missing.length; i += _parallelFetches) {
      final end = (i + _parallelFetches).clamp(0, missing.length);
      final results = await Future.wait(
        missing
            .sublist(i, end)
            .map(
              (id) => _courseRepository
                  .fetchCourseById(id)
                  .then<CourseModel?>((course) => course)
                  // تجاهل دورة محذوفة من الخادم
                  .catchError((Object _) => null),
            ),
      );
      for (final course in results) {
        if (course != null) fetched[course.id] = course;
      }
    }

    final current = _favoritesService.allCourseIds;
    courses.assignAll([
      for (final id in current)
        if (known[id] ?? fetched[id] case final course?) course,
    ]);
  }

  Future<void> removeCourse(CourseModel course) async {
    if (removingIds.contains(course.id)) return;
    removingIds.add(course.id);
    try {
      await _favoritesService.toggleCourse(course.id);
    } finally {
      removingIds.remove(course.id);
    }
  }

  void clearForLogout() {
    resetInitialLoad();
    courses.clear();
    removingIds.clear();
    isLoading.value = false;
  }
}
