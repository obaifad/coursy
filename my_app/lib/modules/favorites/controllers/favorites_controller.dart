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

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;
    try {
      await _favoritesService.syncFromApi();
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeCourse(CourseModel course) async {
    if (removingIds.contains(course.id)) return;
    removingIds.add(course.id);
    try {
      await _favoritesService.toggleCourse(course.id);
      courses.removeWhere((item) => item.id == course.id);
      await _favoritesService.syncFromApi();
    } finally {
      removingIds.remove(course.id);
    }
  }
}
