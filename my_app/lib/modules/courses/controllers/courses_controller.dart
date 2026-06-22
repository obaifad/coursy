import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/course_repository.dart';
import '../../../core/models/app_models.dart';

class CoursesController extends GetxController {
  final CourseRepository _repository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final courses = <CourseModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = RxnInt();
  final selectedSort = CourseSortOption.newest.obs;
  int _page = 1;
  static const _perPage = 10;

  final ScrollController scrollController = ScrollController();

  List<CourseModel> get sortedCourses => sortCourses(courses, selectedSort.value);

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScrollNearEnd);
    _loadCategories();
    loadCourses();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScrollNearEnd);
    scrollController.dispose();
    super.onClose();
  }

  void _onScrollNearEnd() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent - 280) return;
    loadMoreCourses();
  }

  Future<void> _loadCategories() async {
    try {
      categories.assignAll(await _categoryRepository.fetchCategories());
    } catch (_) {
      categories.clear();
    }
  }

  Future<void> reloadLocalizedData() async {
    await _loadCategories();
    await loadCourses();
  }

  void selectCategory(int? id) {
    selectedCategoryId.value = id;
    loadCourses();
  }

  void selectSort(CourseSortOption sort) {
    if (selectedSort.value == sort) return;
    selectedSort.value = sort;
  }

  Future<void> loadCourses() async {
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchCoursesPage(
        page: _page,
        perPage: _perPage,
        query: {
          if (selectedCategoryId.value != null) 'category_id': selectedCategoryId.value,
        },
      );
      courses.assignAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreCourses() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchCoursesPage(
        page: nextPage,
        perPage: _perPage,
        query: {
          if (selectedCategoryId.value != null) 'category_id': selectedCategoryId.value,
        },
      );
      courses.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
