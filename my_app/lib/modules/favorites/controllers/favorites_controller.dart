import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/favorites_service.dart';

class FavoritesController extends GetxController {
  final FavoritesService _favoritesService = Get.find();
  final CourseRepository _courseRepository = Get.find();

  final isLoading = true.obs;
  final removingIds = <int>{}.obs;
  final courses = <CourseModel>[].obs;

  Worker? _favoritesWorker;

  @override
  void onInit() {
    super.onInit();
    _favoritesWorker = ever(_favoritesService.items, (_) {
      unawaited(_hydrateCoursesFromService());
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
    isLoading.value = true;
    try {
      if (forceSync) {
        await _favoritesService.syncFromApi(force: true);
      }
      await _hydrateCoursesFromService();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _hydrateCoursesFromService() async {
    final ids = _favoritesService.allCourseIds;
    if (ids.isEmpty) {
      courses.clear();
      return;
    }

    final loaded = <CourseModel>[];
    for (final id in ids) {
      try {
        loaded.add(await _courseRepository.fetchCourseById(id));
      } catch (_) {
        // تجاهل دورة محذوفة من الخادم
      }
    }
    courses.assignAll(loaded);
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
    courses.clear();
    removingIds.clear();
    isLoading.value = false;
  }
}
