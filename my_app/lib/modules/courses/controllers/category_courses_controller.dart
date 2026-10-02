import 'package:get/get.dart';

import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/locale/locale_request_guard.dart';

class CategoryCoursesController extends GetxController with InitialLoadState {
  final CourseRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final courses = <CourseModel>[].obs;
  final selectedSort = CourseSortOption.newest.obs;
  final title = ''.obs;

  List<CourseModel> get sortedCourses => sortCourses(courses, selectedSort.value);

  late final int categoryId;
  int _page = 1;
  static const _perPage = 12;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      categoryId = (arg['id'] as int?) ?? 0;
      title.value = arg['name']?.toString() ?? 'category_default_title'.tr;
    } else {
      categoryId = 0;
      title.value = 'category_default_title'.tr;
    }
    loadCourses();
  }

  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
  }

  Future<void> loadCourses() async {
    isLoading.value = isInitialLoad;
    _page = 1;
    try {
      final result = await _repository.fetchCoursesPage(
        page: _page,
        perPage: _perPage,
        query: {'category_id': categoryId},
      );
      courses.assignAll(result.items);
      hasMore.value = result.hasMore;
      markLoaded();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(
        page: nextPage,
        perPage: _perPage,
        query: {'category_id': categoryId},
      );
      courses.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
