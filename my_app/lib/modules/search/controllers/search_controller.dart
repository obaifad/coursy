import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/search_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/storage/recent_search_storage.dart';

class SearchPageController extends GetxController {
  final SearchRepository _searchRepository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final RecentSearchStorage _recentStorage = Get.find();

  final queryController = TextEditingController();

  final isSearching = false.obs;
  final errorMessage = RxnString();

  final selectedScope = SearchScope.all.obs;
  final selectedCityId = RxnInt();
  final selectedCategoryId = RxnInt();
  final selectedLevel = ''.obs;
  final selectedStudyType = ''.obs;

  final courses = <CourseModel>[].obs;
  final institutes = <InstituteModel>[].obs;
  final instructors = <InstructorModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final cities = <CityModel>[].obs;

  final totalCourses = 0.obs;
  final totalInstitutes = 0.obs;
  final totalInstructors = 0.obs;
  final queryText = ''.obs;

  RxList<String> get recentQueries => _recentStorage.queries;

  Timer? _debounce;
  static const _limit = 12;

  bool get hasActiveFilters =>
      selectedCityId.value != null ||
      selectedCategoryId.value != null ||
      selectedLevel.value.isNotEmpty ||
      selectedStudyType.value.isNotEmpty;

  int get activeFiltersCount {
    var n = 0;
    if (selectedCityId.value != null) n++;
    if (selectedCategoryId.value != null) n++;
    if (selectedLevel.value.isNotEmpty) n++;
    if (selectedStudyType.value.isNotEmpty) n++;
    return n;
  }

  bool get hasAnyResults =>
      courses.isNotEmpty || institutes.isNotEmpty || instructors.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    queryController.addListener(_onQueryChanged);
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      categories.assignAll(await _categoryRepository.fetchCategories());
    } catch (_) {}
    try {
      cities.assignAll(await _cityRepository.fetchCities());
    } catch (_) {}
  }

  void setScope(SearchScope scope) {
    if (selectedScope.value == scope) return;
    selectedScope.value = scope;
    runSearch(resetPage: true, saveRecent: false);
  }

  void _onQueryChanged() {
    queryText.value = queryController.text;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 360),
      () => runSearch(resetPage: true, saveRecent: false),
    );
  }

  Future<void> runSearch({bool resetPage = true, bool saveRecent = true, String? overrideQuery}) async {
    final text = (overrideQuery ?? queryController.text).trim();

    if (text.isEmpty && !hasActiveFilters) {
      _clearResults();
      errorMessage.value = null;
      return;
    }

    if (saveRecent && text.isNotEmpty) {
      await _recentStorage.add(text);
    }

    isSearching.value = true;
    errorMessage.value = null;

    try {
      final result = await _searchRepository.search(
        query: text,
        scope: selectedScope.value,
        limit: _limit,
        categoryId: selectedCategoryId.value,
        cityId: selectedCityId.value,
        level: selectedLevel.value.isEmpty ? null : selectedLevel.value,
        studyType: selectedStudyType.value.isEmpty ? null : selectedStudyType.value,
      );

      courses.assignAll(result.courses);
      institutes.assignAll(result.institutes);
      instructors.assignAll(result.instructors);
      totalCourses.value = result.totalCourses;
      totalInstitutes.value = result.totalInstitutes;
      totalInstructors.value = result.totalInstructors;
    } catch (e) {
      errorMessage.value = e.toString();
      _clearResults();
    } finally {
      isSearching.value = false;
    }
  }

  void _clearResults() {
    courses.clear();
    institutes.clear();
    instructors.clear();
    totalCourses.value = 0;
    totalInstitutes.value = 0;
    totalInstructors.value = 0;
  }

  Future<void> submitSearch() async {
    queryText.value = queryController.text;
    await runSearch(resetPage: true, saveRecent: true);
  }

  void applyFilters({int? cityId, int? categoryId, String? level, String? studyType}) {
    selectedCityId.value = cityId;
    selectedCategoryId.value = categoryId;
    selectedLevel.value = level ?? '';
    selectedStudyType.value = studyType ?? '';
    runSearch(resetPage: true, saveRecent: queryController.text.trim().isNotEmpty);
  }

  void clearFilters() {
    selectedCityId.value = null;
    selectedCategoryId.value = null;
    selectedLevel.value = '';
    selectedStudyType.value = '';
    runSearch(resetPage: true, saveRecent: false);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    queryController.removeListener(_onQueryChanged);
    queryController.dispose();
    super.onClose();
  }
}
